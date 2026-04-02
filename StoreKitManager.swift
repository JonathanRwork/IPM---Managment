import Foundation
import Combine
import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {
    @Published private(set) var productsByID: [String: Product] = [:]
    @Published var isLoadingProducts = false
    @Published var isProcessingPurchase = false
    @Published var errorMessage: String?
    @Published private(set) var currentSubscriptionExpiration: Date?

    private let plusMonthlyID = "ipm.plus.monthly"
    private let plusYearlyID = "ipm.plus.yearly"
    private let proMonthlyID = "ipm.pro.monthly"
    private let proYearlyID = "ipm.pro.yearly"

    private var productIDs: Set<String> {
        [plusMonthlyID, plusYearlyID, proMonthlyID, proYearlyID]
    }

    private weak var subscriptionManager: SubscriptionManager?
    private var updatesTask: Task<Void, Never>?
    private var hasStarted = false

    deinit {
        updatesTask?.cancel()
    }

    func startIfNeeded(subscription: SubscriptionManager) async {
        subscriptionManager = subscription

        guard !hasStarted else {
            await refreshEntitlements()
            return
        }

        hasStarted = true
        await loadProducts()
        await refreshEntitlements()
        startObservingTransactions()
    }

    func stop() {
        updatesTask?.cancel()
        updatesTask = nil
        hasStarted = false
        currentSubscriptionExpiration = nil
    }

    func displayPrice(for tier: SubscriptionTier, cycle: BillingCycle) -> String? {
        guard let productID = productID(for: tier, cycle: cycle) else { return nil }
        return productsByID[productID]?.displayPrice
    }

    func purchase(tier: SubscriptionTier, cycle: BillingCycle) async -> Bool {
        guard let productID = productID(for: tier, cycle: cycle) else {
            errorMessage = localized(de: "Für Free ist kein Kauf nötig.", en: "No purchase needed for Free.")
            return false
        }

        var product = productsByID[productID]
        if product == nil {
            await loadProducts()
            product = productsByID[productID]
        }

        guard let product else {
            errorMessage = localized(de: "Abo-Produkt nicht gefunden. Prüfe Produkt-IDs in App Store Connect.", en: "Subscription product not found. Check product IDs in App Store Connect.")
            return false
        }

        isProcessingPurchase = true
        errorMessage = nil
        defer { isProcessingPurchase = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .pending:
                errorMessage = localized(de: "Kauf ausstehend. Bitte Bestätigung abwarten.", en: "Purchase pending. Please wait for confirmation.")
                return false
            case .userCancelled:
                return false
            @unknown default:
                errorMessage = localized(de: "Unbekanntes Kauf-Ergebnis.", en: "Unknown purchase result.")
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        errorMessage = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: productIDs)
            productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private struct EntitlementSnapshot {
        let productID: String
        let expirationDate: Date?
    }

    private func refreshEntitlements() async {
        var entitlements: [EntitlementSnapshot] = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                entitlements.append(
                    EntitlementSnapshot(
                        productID: transaction.productID,
                        expirationDate: transaction.expirationDate
                    )
                )
            }
        }
        applyBestEntitlement(from: entitlements)
    }

    private func startObservingTransactions() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.refreshEntitlements()
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func applyBestEntitlement(from entitlements: [EntitlementSnapshot]) {
        guard let subscription = subscriptionManager else { return }
        guard let bestEntitlement = entitlements.max(by: entitlementSort(lhs:rhs:)) else {
            currentSubscriptionExpiration = nil
            subscription.tier = .free
            subscription.billingCycle = .monthly
            return
        }

        currentSubscriptionExpiration = bestEntitlement.expirationDate
        switch bestEntitlement.productID {
        case proYearlyID:
            subscription.billingCycle = .yearly
            subscription.tier = .pro
        case proMonthlyID:
            subscription.billingCycle = .monthly
            subscription.tier = .pro
        case plusYearlyID:
            subscription.billingCycle = .yearly
            subscription.tier = .plus
        case plusMonthlyID:
            subscription.billingCycle = .monthly
            subscription.tier = .plus
        default:
            subscription.billingCycle = .monthly
            subscription.tier = .free
        }
    }

    private func entitlementSort(lhs: EntitlementSnapshot, rhs: EntitlementSnapshot) -> Bool {
        let lhsRank = entitlementRank(for: lhs.productID)
        let rhsRank = entitlementRank(for: rhs.productID)
        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }
        return (lhs.expirationDate ?? .distantPast) < (rhs.expirationDate ?? .distantPast)
    }

    private func entitlementRank(for productID: String) -> Int {
        switch productID {
        case proYearlyID: return 4
        case proMonthlyID: return 3
        case plusYearlyID: return 2
        case plusMonthlyID: return 1
        default: return 0
        }
    }

    private func productID(for tier: SubscriptionTier, cycle: BillingCycle) -> String? {
        switch (tier, cycle) {
        case (.free, _): return nil
        case (.plus, .monthly): return plusMonthlyID
        case (.plus, .yearly): return plusYearlyID
        case (.pro, .monthly): return proMonthlyID
        case (.pro, .yearly): return proYearlyID
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signed):
            return signed
        case .unverified:
            throw NSError(domain: "StoreKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: localized(de: "Transaktion konnte nicht verifiziert werden.", en: "Transaction could not be verified.")])
        }
    }

    private func localized(de: String, en: String) -> String {
        let appLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "de"
        return ipmLocalized(appLanguage, de: de, en: en)
    }
}
