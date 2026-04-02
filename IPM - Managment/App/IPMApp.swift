import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@main
struct IPMApp: App {
    init() { FirebaseApp.configure() }
    var body: some Scene {
        WindowGroup { RootView() }
    }
}

enum SubscriptionTier: String, CaseIterable, Identifiable {
    case free
    case plus
    case pro

    var id: String { rawValue }
}

enum BillingCycle: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }
}

enum RegistrationEmailStatus {
    case idle
    case invalid
    case available
    case taken
    case unknown
}

struct SubscriptionLimits {
    let maxClients: Int?
    let maxRoomsPerClient: Int?
    let maxTrapsPerRoom: Int?
}

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var tier: SubscriptionTier {
        didSet { UserDefaults.standard.set(tier.rawValue, forKey: "subscriptionTier") }
    }
    @Published var billingCycle: BillingCycle {
        didSet { UserDefaults.standard.set(billingCycle.rawValue, forKey: "subscriptionBillingCycle") }
    }

    private var appLanguage: String { UserDefaults.standard.string(forKey: "appLanguage") ?? "de" }

    init() {
        let saved = UserDefaults.standard.string(forKey: "subscriptionTier") ?? SubscriptionTier.free.rawValue
        tier = SubscriptionTier(rawValue: saved) ?? .free
        let savedCycle = UserDefaults.standard.string(forKey: "subscriptionBillingCycle") ?? BillingCycle.monthly.rawValue
        billingCycle = BillingCycle(rawValue: savedCycle) ?? .monthly
    }

    var yearlyDiscount: Double { 0.10 }

    var limits: SubscriptionLimits {
        switch tier {
        case .free:
            return .init(maxClients: 1, maxRoomsPerClient: 5, maxTrapsPerRoom: 20)
        case .plus:
            return .init(maxClients: 3, maxRoomsPerClient: 15, maxTrapsPerRoom: 50)
        case .pro:
            return .init(maxClients: nil, maxRoomsPerClient: nil, maxTrapsPerRoom: nil)
        }
    }

    func tierTitle() -> String {
        switch tier {
        case .free: return "Free"
        case .plus: return "Plus"
        case .pro: return "Pro"
        }
    }

    func canAddClient(currentCount: Int) -> String? {
        guard let max = limits.maxClients, currentCount >= max else { return nil }
        return localizedSubscriptionMessage(
            de: "Limit erreicht: Im \(tierTitle())-Abo sind maximal \(max) Kunden möglich. Bitte Upgrade durchführen.",
            en: "Limit reached: The \(tierTitle()) plan allows up to \(max) clients. Please upgrade."
        )
    }

    func canAddRoom(currentCountForClient: Int) -> String? {
        guard let max = limits.maxRoomsPerClient, currentCountForClient >= max else { return nil }
        return localizedSubscriptionMessage(
            de: "Limit erreicht: Im \(tierTitle())-Abo sind maximal \(max) Räume pro Kunde möglich. Bitte Upgrade durchführen.",
            en: "Limit reached: The \(tierTitle()) plan allows up to \(max) rooms per client. Please upgrade."
        )
    }

    func canAddTrap(currentCountForRoom: Int) -> String? {
        guard let max = limits.maxTrapsPerRoom, currentCountForRoom >= max else { return nil }
        return localizedSubscriptionMessage(
            de: "Limit erreicht: Im \(tierTitle())-Abo sind maximal \(max) Fallen pro Raum möglich. Bitte Upgrade durchführen.",
            en: "Limit reached: The \(tierTitle()) plan allows up to \(max) traps per room. Please upgrade."
        )
    }

    private func localizedSubscriptionMessage(de: String, en: String) -> String {
        appLanguage.lowercased().hasPrefix("de") ? de : en
    }
}

// MARK: - Auth Manager
@MainActor
class AuthManager: ObservableObject {
    @Published private(set) var user: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var handle: AuthStateDidChangeListenerHandle?
    private var appLanguage: String { UserDefaults.standard.string(forKey: "appLanguage") ?? "de" }

    init() {
        user = Auth.auth().currentUser
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }
    deinit { if let h = handle { Auth.auth().removeStateDidChangeListener(h) } }

    var isLoggedIn: Bool { user != nil }

    func login(email: String, password: String) async -> Bool {
        let cleanEmail = normalizedEmail(from: email)
        if let validationError = validateCredentials(email: cleanEmail, password: password) {
            errorMessage = validationError
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await Auth.auth().signIn(withEmail: cleanEmail, password: password)
            return true
        } catch {
            errorMessage = authErrorMessage(from: error)
            return false
        }
    }

    func register(email: String, password: String) async -> Bool {
        let cleanEmail = normalizedEmail(from: email)
        if let validationError = validateCredentials(email: cleanEmail, password: password) {
            errorMessage = validationError
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await Auth.auth().createUser(withEmail: cleanEmail, password: password)
            return true
        } catch {
            errorMessage = authErrorMessage(from: error)
            return false
        }
    }

    func checkRegistrationEmailStatus(email: String) async -> RegistrationEmailStatus {
        let cleanEmail = normalizedEmail(from: email)
        guard !cleanEmail.isEmpty else { return .idle }
        guard cleanEmail.contains("@"), cleanEmail.contains(".") else { return .invalid }
        // `fetchSignInMethods(forEmail:)` is deprecated and unreliable when
        // Email Enumeration Protection is enabled, so availability is checked
        // at actual account creation time instead.
        return .unknown
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            errorMessage = nil
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
    }

    func updateDisplayName(_ newName: String) async -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = localized(de: "Name darf nicht leer sein.", en: "Name cannot be empty.")
            return false
        }
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = localized(de: "Nicht angemeldet.", en: "Not signed in.")
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let request = currentUser.createProfileChangeRequest()
            request.displayName = trimmed
            try await commitProfileChanges(request)
            user = Auth.auth().currentUser
            return true
        } catch {
            errorMessage = authErrorMessage(from: error)
            return false
        }
    }

    func updateEmail(newEmail: String, currentPassword: String) async -> Bool {
        let cleanEmail = normalizedEmail(from: newEmail)
        guard cleanEmail.contains("@"), cleanEmail.contains(".") else {
            errorMessage = localized(de: "Bitte eine gültige E-Mail-Adresse eingeben.", en: "Please enter a valid email address.")
            return false
        }
        guard !currentPassword.isEmpty else {
            errorMessage = localized(de: "Bitte aktuelles Passwort eingeben.", en: "Please enter current password.")
            return false
        }
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = localized(de: "Nicht angemeldet.", en: "Not signed in.")
            return false
        }
        guard let currentEmail = currentUser.email else {
            errorMessage = localized(de: "Aktuelle E-Mail konnte nicht gelesen werden.", en: "Could not read current email.")
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await reauthenticate(email: currentEmail, password: currentPassword, user: currentUser)
            try await sendEmailUpdateVerification(user: currentUser, to: cleanEmail)
            user = Auth.auth().currentUser
            return true
        } catch {
            errorMessage = authErrorMessage(from: error)
            return false
        }
    }

    func updatePassword(currentPassword: String, newPassword: String) async -> Bool {
        guard newPassword.count >= 6 else {
            errorMessage = localized(de: "Neues Passwort muss mindestens 6 Zeichen haben.", en: "New password must be at least 6 characters.")
            return false
        }
        guard !currentPassword.isEmpty else {
            errorMessage = localized(de: "Bitte aktuelles Passwort eingeben.", en: "Please enter current password.")
            return false
        }
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = localized(de: "Nicht angemeldet.", en: "Not signed in.")
            return false
        }
        guard let currentEmail = currentUser.email else {
            errorMessage = localized(de: "Aktuelle E-Mail konnte nicht gelesen werden.", en: "Could not read current email.")
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await reauthenticate(email: currentEmail, password: currentPassword, user: currentUser)
            try await updatePassword(user: currentUser, to: newPassword)
            return true
        } catch {
            errorMessage = authErrorMessage(from: error)
            return false
        }
    }

    func deleteAccount(currentPassword: String) async -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = localized(de: "Nicht angemeldet.", en: "Not signed in.")
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let hasPasswordProvider = currentUser.providerData.contains { $0.providerID == EmailAuthProviderID }
            if hasPasswordProvider {
                guard let currentEmail = currentUser.email else {
                    errorMessage = localized(de: "Aktuelle E-Mail konnte nicht gelesen werden.", en: "Could not read current email.")
                    return false
                }
                guard !currentPassword.isEmpty else {
                    errorMessage = localized(de: "Bitte aktuelles Passwort eingeben.", en: "Please enter current password.")
                    return false
                }
                try await reauthenticate(email: currentEmail, password: currentPassword, user: currentUser)
            }

            try await FirestoreService.shared.deleteAllUserData()
            try await deleteCurrentUser(currentUser)
            clearLocalAccountState()
            user = nil
            return true
        } catch {
            errorMessage = authErrorMessage(from: error)
            return false
        }
    }

    func signInWithGoogle() async {
#if canImport(GoogleSignIn)
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                errorMessage = localized(de: "Google-Anmeldung ist nicht konfiguriert.", en: "Google sign-in is not configured.")
                return
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

#if os(iOS)
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = scene.windows.first?.rootViewController else {
                errorMessage = localized(de: "Google-Anmeldung konnte nicht gestartet werden.", en: "Google sign-in could not be started.")
                return
            }
            let signInResult = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController,
                hint: nil,
                additionalScopes: []
            )
#elseif os(macOS)
            guard let window = NSApplication.shared.keyWindow else {
                errorMessage = localized(de: "Google-Anmeldung konnte nicht gestartet werden.", en: "Google sign-in could not be started.")
                return
            }
            let signInResult = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: window,
                hint: nil,
                additionalScopes: []
            )
#else
            errorMessage = localized(de: "Google-Anmeldung wird auf dieser Plattform nicht unterstützt.", en: "Google sign-in is not supported on this platform.")
            return
#endif

            guard let idToken = signInResult.user.idToken?.tokenString else {
                errorMessage = localized(de: "Google-ID-Token fehlt.", en: "Google ID token is missing.")
                return
            }

            let accessToken = signInResult.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            _ = try await Auth.auth().signIn(with: credential)
        } catch {
            errorMessage = authErrorMessage(from: error)
        }
#else
        errorMessage = localized(de: "Google SDK fehlt: Bitte in Xcode das Package 'GoogleSignIn-iOS' hinzufügen.", en: "Google SDK missing: add the 'GoogleSignIn-iOS' package in Xcode.")
#endif
    }

    private func normalizedEmail(from raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func validateCredentials(email: String, password: String) -> String? {
        guard !email.isEmpty, !password.isEmpty else {
            return localized(de: "Bitte E-Mail und Passwort eingeben.", en: "Please enter email and password.")
        }
        guard email.contains("@"), email.contains(".") else {
            return localized(de: "Bitte eine gültige E-Mail-Adresse eingeben.", en: "Please enter a valid email address.")
        }
        guard password.count >= 6 else {
            return localized(de: "Passwort muss mindestens 6 Zeichen haben.", en: "Password must be at least 6 characters.")
        }
        return nil
    }

    private func authErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        guard let authCode = AuthErrorCode(rawValue: nsError.code) else {
            return nsError.localizedDescription
        }

        switch authCode {
        case .invalidEmail:
            return localized(de: "Ungültige E-Mail-Adresse.", en: "Invalid email address.")
        case .wrongPassword, .invalidCredential:
            return localized(de: "E-Mail oder Passwort ist falsch.", en: "Email or password is incorrect.")
        case .userNotFound:
            return localized(de: "Kein Benutzer mit dieser E-Mail gefunden.", en: "No user found for this email.")
        case .emailAlreadyInUse:
            return localized(de: "Diese E-Mail wird bereits verwendet.", en: "This email is already in use.")
        case .weakPassword:
            return localized(de: "Das Passwort ist zu schwach.", en: "The password is too weak.")
        case .networkError:
            return localized(de: "Netzwerkfehler. Bitte Verbindung prüfen.", en: "Network error. Please check your connection.")
        case .tooManyRequests:
            return localized(de: "Zu viele Versuche. Bitte später erneut versuchen.", en: "Too many attempts. Please try again later.")
        case .requiresRecentLogin:
            return localized(de: "Bitte erneut anmelden und nochmal versuchen.", en: "Please sign in again and try once more.")
        default:
            return nsError.localizedDescription
        }
    }

    private func localized(de: String, en: String) -> String {
        appLanguage.lowercased().hasPrefix("de") ? de : en
    }

    private func commitProfileChanges(_ request: UserProfileChangeRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            request.commitChanges { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    private func reauthenticate(email: String, password: String, user: FirebaseAuth.User) async throws {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.reauthenticate(with: credential) { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    private func sendEmailUpdateVerification(user: FirebaseAuth.User, to newEmail: String) async throws {
        try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
    }

    private func updatePassword(user: FirebaseAuth.User, to newPassword: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.updatePassword(to: newPassword) { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    private func deleteCurrentUser(_ user: FirebaseAuth.User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            user.delete { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    private func clearLocalAccountState() {
        let defaults = UserDefaults.standard
        let keysToRemove = [
            "hasCompletedOnboarding",
            "onboardingSource",
            "onboardingCustomerCount",
            "selectedClientFilterId",
            "trapSortMode",
            "subscriptionTier",
            "subscriptionBillingCycle"
        ]

        for key in keysToRemove {
            defaults.removeObject(forKey: key)
        }
    }

}

// MARK: - Root
struct RootView: View {
    @StateObject private var auth = AuthManager()
    @StateObject private var subscription = SubscriptionManager()
    @StateObject private var storeKit = StoreKitManager()
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("didInitializeAppLanguage") private var didInitializeAppLanguage = false

    var body: some View {
        Group {
            if auth.isLoggedIn {
                MainTabView()
                    .environmentObject(auth)
                    .environmentObject(subscription)
                    .environmentObject(storeKit)
            }
            else { LoginView().environmentObject(auth) }
        }
        .environment(\.locale, Locale(identifier: appLanguage))
        .task(id: auth.isLoggedIn) {
            if auth.isLoggedIn {
                await storeKit.startIfNeeded(subscription: subscription)
            } else {
                storeKit.stop()
            }
        }
#if canImport(GoogleSignIn)
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
#endif
        .onAppear {
            initializeLanguageFromSystemIfNeeded()
        }
    }

    private func initializeLanguageFromSystemIfNeeded() {
        guard !didInitializeAppLanguage else { return }
        appLanguage = preferredAppLanguage()
        didInitializeAppLanguage = true
    }

    private func preferredAppLanguage() -> String {
        for identifier in Locale.preferredLanguages {
            let lowercased = identifier.lowercased()
            if lowercased.hasPrefix("de") { return "de" }
            if lowercased.hasPrefix("en") { return "en" }
            if lowercased.hasPrefix("fr") { return "fr" }
            if lowercased.hasPrefix("nl") { return "nl" }
            if lowercased.hasPrefix("pt-br") || lowercased.hasPrefix("pt_br") || lowercased.hasPrefix("pt") {
                return "pt-BR"
            }
        }
        return "en"
    }
}
