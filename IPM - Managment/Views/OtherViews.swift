import SwiftUI
import FirebaseAuth

// MARK: - Fälligkeiten
struct FaelligkeitenView: View {
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var items: [DueTrapItem] = []
    @State private var isLoading = true
    @State private var quickCheckInItem: DueTrapItem?

    private var ueberfaellig: [DueTrapItem] { items.filter { $0.trap.faelligkeitStatus == .ueberfaellig } }
    private var heute: [DueTrapItem] {
        items
            .filter { $0.trap.faelligkeitStatus != .ueberfaellig }
            .filter { Calendar.current.isDateInToday($0.trap.naechstePruefung) }
    }
    private var dieseWoche: [DueTrapItem] {
        items
            .filter { $0.trap.faelligkeitStatus != .ueberfaellig }
            .filter { !Calendar.current.isDateInToday($0.trap.naechstePruefung) }
            .filter { $0.trap.naechstePruefung <= (Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()

                if items.isEmpty && !isLoading {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(IPMColors.ok.opacity(0.1)).frame(width: 80, height: 80)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(IPMColors.ok)
                        }
                        Text(ipmLocalized(appLanguage, de: "Alles erledigt", en: "All done"))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                        Text(ipmLocalized(appLanguage, de: "Keine Fallen fällig", en: "No traps due"))
                            .font(.system(size: 14))
                            .foregroundStyle(IPMColors.brownMid)
                    }
                } else {
                    List {
                        if !ueberfaellig.isEmpty {
                            Section {
                                ForEach(ueberfaellig) { item in
                                    NavigationLink(destination: TrapDetailView(
                                        trap: item.trap,
                                        clientId: item.clientId,
                                        floorId: item.floorId
                                    )) {
                                        FaelligkeitRow(item: item) {
                                            quickCheckInItem = item
                                        }
                                    }
                                    .listRowBackground(AdaptiveColor.card(scheme))
                                    .listRowSeparatorTint(AdaptiveColor.cardSecondary(scheme))
                                }
                            } header: {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(IPMColors.critical)
                                        .font(.system(size: 11))
                                    SectionLabel("\(ipmLocalized(appLanguage, de: "Überfällig", en: "Overdue")) (\(ueberfaellig.count))")
                                }
                            }
                        }

                        if !heute.isEmpty {
                            Section {
                                ForEach(heute) { item in
                                    NavigationLink(destination: TrapDetailView(
                                        trap: item.trap,
                                        clientId: item.clientId,
                                        floorId: item.floorId
                                    )) {
                                        FaelligkeitRow(item: item) {
                                            quickCheckInItem = item
                                        }
                                    }
                                    .listRowBackground(AdaptiveColor.card(scheme))
                                    .listRowSeparatorTint(AdaptiveColor.cardSecondary(scheme))
                                }
                            } header: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sun.max.fill")
                                        .foregroundStyle(IPMColors.warning)
                                        .font(.system(size: 11))
                                    SectionLabel("\(ipmLocalized(appLanguage, de: "Heute", en: "Today")) (\(heute.count))")
                                }
                            }
                        }

                        if !dieseWoche.isEmpty {
                            Section {
                                ForEach(dieseWoche) { item in
                                    NavigationLink(destination: TrapDetailView(
                                        trap: item.trap,
                                        clientId: item.clientId,
                                        floorId: item.floorId
                                    )) {
                                        FaelligkeitRow(item: item) {
                                            quickCheckInItem = item
                                        }
                                    }
                                    .listRowBackground(AdaptiveColor.card(scheme))
                                    .listRowSeparatorTint(AdaptiveColor.cardSecondary(scheme))
                                }
                            } header: {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.badge.exclamationmark.fill")
                                        .foregroundStyle(IPMColors.warning)
                                        .font(.system(size: 11))
                                    SectionLabel("\(ipmLocalized(appLanguage, de: "Diese Woche", en: "This week")) (\(dieseWoche.count))")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AdaptiveColor.background(scheme))
                }
            }
            .navigationTitle(ipmLocalized(appLanguage, de: "Fälligkeiten", en: "Due Items"))
            .overlay { if isLoading { ProgressView().tint(IPMColors.green) } }
            .task { await loadDue() }
            .refreshable { await loadDue() }
            .sheet(item: $quickCheckInItem) { item in
                AddInspectionView(
                    trap: item.trap,
                    clientId: item.clientId,
                    floorId: item.floorId
                ) {
                    await loadDue()
                }
            }
        }
    }

    private func loadDue() async {
        isLoading = true
        items = (try? await FirestoreService.shared.fetchDueTraps()) ?? []
        isLoading = false
    }
}

// MARK: - Alle Fallen
struct AllTrapsView: View {
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("selectedClientFilterId") private var selectedClientId = "__all_clients__"
    private let allClientsFilterKey = "__all_clients__"
    @State private var items: [TrapCatalogItem] = []
    @State private var clients: [Client] = []
    @State private var isLoading = true
    @State private var searchText = ""

    private var selectedClientName: String {
        guard selectedClientId != allClientsFilterKey else { return ipmLocalized(appLanguage, de: "Alle Kunden", en: "All clients") }
        return clients.first(where: { $0.id == selectedClientId })?.name ?? ipmLocalized(appLanguage, de: "Kunde wählen", en: "Select client")
    }

    private var filteredByClient: [TrapCatalogItem] {
        guard selectedClientId != allClientsFilterKey else { return items }
        return items.filter { $0.clientId == selectedClientId }
    }

    private var filtered: [TrapCatalogItem] {
        guard !searchText.isEmpty else { return filteredByClient }
        return filteredByClient.filter {
            $0.trap.nummer.localizedCaseInsensitiveContains(searchText) ||
            $0.floorName.localizedCaseInsensitiveContains(searchText) ||
            $0.clientName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()

                if filtered.isEmpty && !isLoading {
                    IPMEmptyState(
                        icon: "square.grid.2x2",
                        title: ipmLocalized(appLanguage, de: "Keine Fallen", en: "No traps"),
                        subtitle: ipmLocalized(appLanguage, de: "Im aktuellen Filter wurden keine Fallen gefunden", en: "No traps found for the current filter")
                    )
                } else {
                    List {
                        Section {
                            ForEach(filtered) { item in
                                NavigationLink(destination: TrapDetailView(trap: item.trap, clientId: item.clientId, floorId: item.floorId)) {
                                    FaelligkeitRow(item: DueTrapItem(clientName: item.clientName, floorName: item.floorName, clientId: item.clientId, floorId: item.floorId, trap: item.trap))
                                }
                                .listRowBackground(AdaptiveColor.card(scheme))
                                .listRowSeparatorTint(AdaptiveColor.cardSecondary(scheme))
                            }
                        } header: {
                            SectionLabel("\(ipmLocalized(appLanguage, de: "Fallen", en: "Traps")) (\(filtered.count))")
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AdaptiveColor.background(scheme))
                }
            }
            .navigationTitle(ipmLocalized(appLanguage, de: "Alle Fallen", en: "All traps"))
            .searchable(text: $searchText, prompt: ipmLocalized(appLanguage, de: "Fallen suchen", en: "Search traps"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(ipmLocalized(appLanguage, de: "Alle Kunden", en: "All clients")) {
                            selectedClientId = allClientsFilterKey
                        }
                        ForEach(clients) { client in
                            Button(client.name) {
                                selectedClientId = client.id ?? allClientsFilterKey
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedClientName)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(IPMColors.greenDark)
                    }
                }
            }
            .overlay { if isLoading { ProgressView().tint(IPMColors.green) } }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        isLoading = true
        async let loadedClients = try? FirestoreService.shared.fetchClients()
        async let loadedItems = try? FirestoreService.shared.fetchAllTraps()
        clients = await loadedClients ?? []
        items = await loadedItems ?? []
        if selectedClientId != allClientsFilterKey, !clients.contains(where: { $0.id == selectedClientId }) {
            selectedClientId = allClientsFilterKey
        }
        isLoading = false
    }
}

// MARK: - Fälligkeit Row
struct FaelligkeitRow: View {
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    let item: DueTrapItem
    var onQuickCheckIn: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(item.trap.faelligkeitStatus.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: item.trap.typ.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(item.trap.faelligkeitStatus.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.clientName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                Text("\(item.floorName) · \(ipmLocalized(appLanguage, de: "Falle", en: "Trap")) \(item.trap.nummer)")
                    .font(.system(size: 12))
                    .foregroundStyle(IPMColors.brownMid)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(item.trap.naechstePruefung.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(item.trap.faelligkeitStatus.color)
                StatusPill(status: item.trap.faelligkeitStatus)
                if let onQuickCheckIn {
                    Button(action: onQuickCheckIn) {
                        Label(ipmLocalized(appLanguage, de: "Check-in", en: "Check-in"), systemImage: "checkmark.circle")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(IPMColors.green)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Settings
struct SettingsView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var subscription: SubscriptionManager
    @EnvironmentObject var storeKit: StoreKitManager
    @Environment(\.colorScheme) var scheme
    @State private var newEmail = ""
    @State private var emailCurrentPassword = ""
    @State private var passwordCurrent = ""
    @State private var passwordNew = ""
    @State private var passwordConfirm = ""
    @State private var deletePassword = ""
    @State private var confirmAccountDeletion = false
    @State private var isEmailExpanded = false
    @State private var isPasswordExpanded = false
    @State private var isSubscriptionExpanded = false
    @State private var isDeleteExpanded = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var successMessage: String?
    @AppStorage("appLanguage") private var appLanguage = "de"

    private func tierLabel(_ tier: SubscriptionTier) -> String {
        switch tier {
        case .free: return "Free"
        case .plus: return "Plus"
        case .pro: return "Pro"
        }
    }

    private func billingCycleLabel(_ cycle: BillingCycle) -> String {
        switch cycle {
        case .monthly:
            return ipmLocalized(appLanguage, de: "Monatlich", en: "Monthly")
        case .yearly:
            return ipmLocalized(appLanguage, de: "Jährlich (-10%)", en: "Yearly (-10%)")
        }
    }

    private func limitText(_ value: Int?) -> String {
        guard let value else {
            return ipmLocalized(appLanguage, de: "Unbegrenzt", en: "Unlimited")
        }
        return "\(value)"
    }

    private func upgradeButtonTitle(for tier: SubscriptionTier) -> String {
        let price = storeKit.displayPrice(for: tier, cycle: subscription.billingCycle)
        let fallback = ipmLocalized(appLanguage, de: "Preis folgt", en: "Price pending")
        let priceText = price ?? fallback
        return "\(tierLabel(tier)) · \(priceText)"
    }

    private var requiresPasswordForDeletion: Bool {
        auth.user?.providerData.contains { $0.providerID == EmailAuthProviderID } ?? true
    }

    private var subscriptionStatusText: String {
        let tierText = tierLabel(subscription.tier)
        guard let expiration = storeKit.currentSubscriptionExpiration else { return tierText }
        let dateText = expiration.formatted(date: .abbreviated, time: .omitted)
        return "\(tierText) · \(ipmLocalized(appLanguage, de: "läuft bis", en: "valid until", fr: "valide jusqu’au", ptBR: "válido até", nl: "geldig tot")) \(dateText)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()
                List {
                    if let message = auth.errorMessage {
                        Section {
                            Text(message)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(IPMColors.critical)
                        }
                        .listRowBackground(AdaptiveColor.card(scheme))
                    }

                    if let successMessage {
                        Section {
                            Text(successMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(IPMColors.ok)
                        }
                        .listRowBackground(AdaptiveColor.card(scheme))
                    }

                    if let storeError = storeKit.errorMessage {
                        Section {
                            Text(storeError)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(IPMColors.critical)
                        }
                        .listRowBackground(AdaptiveColor.card(scheme))
                    }

                    Section {
                        DisclosureGroup(isExpanded: $isEmailExpanded) {
                            IPMFormField(label: ipmLocalized(appLanguage, de: "E-Mail", en: "Email"), text: $newEmail, icon: "envelope", keyboard: .emailAddress)
                            IPMFormField(label: ipmLocalized(appLanguage, de: "Aktuelles Passwort", en: "Current password"), text: $emailCurrentPassword, icon: "key", isSecure: true)
                            Button {
                                Task {
                                    if await auth.updateEmail(newEmail: newEmail, currentPassword: emailCurrentPassword) {
                                        successMessage = ipmLocalized(appLanguage, de: "E-Mail erfolgreich geändert.", en: "Email updated successfully.")
                                        emailCurrentPassword = ""
                                    }
                                }
                            } label: {
                                Text(ipmLocalized(appLanguage, de: "E-Mail speichern", en: "Save email"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(IPMColors.green)
                            }
                            .disabled(auth.isLoading || newEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || emailCurrentPassword.isEmpty)
                        } label: {
                            Label(ipmLocalized(appLanguage, de: "E-Mail", en: "Email"), systemImage: "envelope.fill")
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                        }
                        InfoRow(
                            icon: "person.fill",
                            label: ipmLocalized(appLanguage, de: "Name", en: "Name"),
                            value: auth.user?.displayName ?? "–",
                            color: IPMColors.green
                        )
                    } header: {
                        SectionLabel(ipmLocalized(appLanguage, de: "Account", en: "Account", fr: "Compte", ptBR: "Conta", nl: "Account"))
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        DisclosureGroup(isExpanded: $isPasswordExpanded) {
                            IPMFormField(label: ipmLocalized(appLanguage, de: "Aktuelles Passwort", en: "Current password"), text: $passwordCurrent, icon: "lock", isSecure: true)
                            IPMFormField(label: ipmLocalized(appLanguage, de: "Neues Passwort", en: "New password"), text: $passwordNew, icon: "lock.open", isSecure: true)
                            IPMFormField(label: ipmLocalized(appLanguage, de: "Neues Passwort wiederholen", en: "Confirm new password"), text: $passwordConfirm, icon: "checkmark.shield", isSecure: true)
                            Button {
                                guard passwordNew == passwordConfirm else {
                                    auth.errorMessage = ipmLocalized(appLanguage, de: "Die neuen Passwörter stimmen nicht überein.", en: "The new passwords do not match.")
                                    return
                                }
                                Task {
                                    if await auth.updatePassword(currentPassword: passwordCurrent, newPassword: passwordNew) {
                                        successMessage = ipmLocalized(appLanguage, de: "Passwort erfolgreich geändert.", en: "Password updated successfully.")
                                        passwordCurrent = ""
                                        passwordNew = ""
                                        passwordConfirm = ""
                                    }
                                }
                            } label: {
                                Text(ipmLocalized(appLanguage, de: "Passwort speichern", en: "Save password"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(IPMColors.green)
                            }
                            .disabled(auth.isLoading || passwordCurrent.isEmpty || passwordNew.isEmpty || passwordConfirm.isEmpty)
                        } label: {
                            Label(ipmLocalized(appLanguage, de: "Passwort", en: "Password"), systemImage: "lock.fill")
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                        }
                    } header: {
                        SectionLabel(ipmLocalized(appLanguage, de: "Sicherheit", en: "Security", fr: "Sécurité", ptBR: "Segurança", nl: "Beveiliging"))
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        InfoRow(
                            icon: "creditcard.fill",
                            label: ipmLocalized(appLanguage, de: "Abo-Status", en: "Subscription status"),
                            value: subscriptionStatusText,
                            color: IPMColors.brownMid
                        )
                        NavigationLink(destination: BillingSupportView()) {
                            InfoRow(
                                icon: "creditcard.and.123",
                                label: ipmLocalized(appLanguage, de: "Zahlung & Rechnungen", en: "Payment & invoices"),
                                value: ipmLocalized(appLanguage, de: "Verwalten", en: "Manage"),
                                color: IPMColors.green
                            )
                        }
                        DisclosureGroup(isExpanded: $isSubscriptionExpanded) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(IPMColors.green)
                                    .frame(width: 20)
                                Picker(ipmLocalized(appLanguage, de: "Abo", en: "Plan"), selection: $subscription.tier) {
                                    ForEach(SubscriptionTier.allCases) { tier in
                                        Text(tierLabel(tier)).tag(tier)
                                    }
                                }
                                .font(.system(size: 15))
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                                .tint(IPMColors.green)
                            }
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 13))
                                    .foregroundStyle(IPMColors.brownMid)
                                    .frame(width: 20)
                                Picker(ipmLocalized(appLanguage, de: "Abrechnung", en: "Billing"), selection: $subscription.billingCycle) {
                                    ForEach(BillingCycle.allCases) { cycle in
                                        Text(billingCycleLabel(cycle)).tag(cycle)
                                    }
                                }
                                .font(.system(size: 15))
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                                .tint(IPMColors.green)
                            }
                            InfoRow(
                                icon: "person.3.fill",
                                label: ipmLocalized(appLanguage, de: "Kunden", en: "Clients"),
                                value: limitText(subscription.limits.maxClients),
                                color: IPMColors.brownMid
                            )
                            InfoRow(
                                icon: "map.fill",
                                label: ipmLocalized(appLanguage, de: "Räume pro Kunde", en: "Rooms per client"),
                                value: limitText(subscription.limits.maxRoomsPerClient),
                                color: IPMColors.brownMid
                            )
                            InfoRow(
                                icon: "square.grid.2x2.fill",
                                label: ipmLocalized(appLanguage, de: "Fallen pro Raum", en: "Traps per room"),
                                value: limitText(subscription.limits.maxTrapsPerRoom),
                                color: IPMColors.brownMid
                            )

                            if subscription.tier != .pro {
                                Button {
                                    Task { _ = await storeKit.purchase(tier: .pro, cycle: subscription.billingCycle) }
                                } label: {
                                    Label(upgradeButtonTitle(for: .pro), systemImage: "applelogo")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(IPMColors.green)
                                }
                                .disabled(storeKit.isProcessingPurchase)
                            }

                            if subscription.tier == .free {
                                Button {
                                    Task { _ = await storeKit.purchase(tier: .plus, cycle: subscription.billingCycle) }
                                } label: {
                                    Label(upgradeButtonTitle(for: .plus), systemImage: "applelogo")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(IPMColors.greenDark)
                                }
                                .disabled(storeKit.isProcessingPurchase)
                            }

                            Button {
                                Task { await storeKit.restorePurchases() }
                            } label: {
                                Label(ipmLocalized(appLanguage, de: "Käufe wiederherstellen", en: "Restore purchases"), systemImage: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(IPMColors.brownMid)
                            }
                            .disabled(storeKit.isProcessingPurchase)
                        } label: {
                            Label(ipmLocalized(appLanguage, de: "Abo verwalten", en: "Manage subscription"), systemImage: "creditcard.fill")
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                        }
                    } header: {
                        SectionLabel(ipmLocalized(appLanguage, de: "Abo", en: "Subscription", fr: "Abonnement", ptBR: "Assinatura", nl: "Abonnement"))
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        DisclosureGroup(isExpanded: $isDeleteExpanded) {
                            if requiresPasswordForDeletion {
                                IPMFormField(
                                    label: ipmLocalized(appLanguage, de: "Aktuelles Passwort", en: "Current password"),
                                    text: $deletePassword,
                                    icon: "key",
                                    isSecure: true
                                )
                            }
                            Toggle(
                                ipmLocalized(appLanguage, de: "Ich verstehe: Konto und Daten werden endgültig gelöscht.", en: "I understand: account and data will be permanently deleted."),
                                isOn: $confirmAccountDeletion
                            )
                            .font(.system(size: 14))
                            .tint(IPMColors.critical)
                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                Label(
                                    ipmLocalized(appLanguage, de: "Konto endgültig löschen", en: "Delete account permanently"),
                                    systemImage: "trash.fill"
                                )
                                .font(.system(size: 14, weight: .semibold))
                            }
                            .disabled(
                                auth.isLoading ||
                                !confirmAccountDeletion ||
                                (requiresPasswordForDeletion && deletePassword.isEmpty)
                            )
                        } label: {
                            Label(ipmLocalized(appLanguage, de: "Konto löschen", en: "Delete account"), systemImage: "trash")
                                .foregroundStyle(IPMColors.critical)
                        }
                    } header: {
                        SectionLabel(ipmLocalized(appLanguage, de: "Kritisch", en: "Critical", fr: "Critique", ptBR: "Crítico", nl: "Kritiek"))
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        Button { showLogoutAlert = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text(ipmLocalized(appLanguage, de: "Abmelden", en: "Sign out"))
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundStyle(IPMColors.critical)
                        }
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))
                }
                .scrollContentBackground(.hidden)
                .background(AdaptiveColor.background(scheme))
            }
            .navigationTitle(ipmLocalized(appLanguage, de: "Account", en: "Account", fr: "Compte", ptBR: "Conta", nl: "Account"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: AdvancedSettingsView(appLanguage: appLanguage)) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(IPMColors.green)
                    }
                }
            }
            .alert(ipmLocalized(appLanguage, de: "Abmelden?", en: "Sign out?", fr: "Se déconnecter ?", ptBR: "Sair?", nl: "Uitloggen?"), isPresented: $showLogoutAlert) {
                Button(ipmLocalized(appLanguage, de: "Abbrechen", en: "Cancel", fr: "Annuler", ptBR: "Cancelar", nl: "Annuleren"), role: .cancel) {}
                Button(ipmLocalized(appLanguage, de: "Abmelden", en: "Sign out", fr: "Se déconnecter", ptBR: "Sair", nl: "Uitloggen"), role: .destructive) { auth.logout() }
            } message: {
                Text(ipmLocalized(appLanguage, de: "Du wirst aus deinem Konto abgemeldet.", en: "You will be signed out of your account.", fr: "Tu vas être déconnecté de ton compte.", ptBR: "Você será desconectado da sua conta.", nl: "Je wordt uit je account uitgelogd."))
            }
            .alert(ipmLocalized(appLanguage, de: "Konto wirklich löschen?", en: "Delete account now?", fr: "Supprimer le compte maintenant ?", ptBR: "Excluir conta agora?", nl: "Account nu verwijderen?"), isPresented: $showDeleteAlert) {
                Button(ipmLocalized(appLanguage, de: "Abbrechen", en: "Cancel", fr: "Annuler", ptBR: "Cancelar", nl: "Annuleren"), role: .cancel) {}
                Button(ipmLocalized(appLanguage, de: "Löschen", en: "Delete", fr: "Supprimer", ptBR: "Excluir", nl: "Verwijderen"), role: .destructive) {
                    Task {
                        if await auth.deleteAccount(currentPassword: deletePassword) {
                            successMessage = nil
                            deletePassword = ""
                            confirmAccountDeletion = false
                        }
                    }
                }
            } message: {
                Text(ipmLocalized(appLanguage, de: "Diese Aktion kann nicht rückgängig gemacht werden.", en: "This action cannot be undone.", fr: "Cette action est irréversible.", ptBR: "Esta ação não pode ser desfeita.", nl: "Deze actie kan niet ongedaan worden gemaakt."))
            }
            .onAppear {
                if newEmail.isEmpty { newEmail = auth.user?.email ?? "" }
                Task { await storeKit.startIfNeeded(subscription: subscription) }
            }
        }
    }
}

private struct AdvancedSettingsView: View {
    let appLanguage: String

    @EnvironmentObject var auth: AuthManager
    @Environment(\.colorScheme) var scheme
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("showTrapNumbers") private var showTrapNumbers = true
    @AppStorage("appLanguage") private var currentLanguage = "de"
    @AppStorage("defaultInspectionIntervalDays") private var defaultInspectionIntervalDays = 58
    @State private var csvExportURL: URL?
    @State private var pdfExportURL: URL?
    @State private var exportMessage: String?
    @State private var isExportingCSV = false
    @State private var isExportingPDF = false

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()
            List {
                if let message = exportMessage {
                    Section {
                        Text(message)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(IPMColors.ok)
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))
                }

                if let authError = auth.errorMessage {
                    Section {
                        Text(authError)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(IPMColors.critical)
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))
                }

                Section {
                    HStack {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(IPMColors.green)
                            .frame(width: 20)
                        Toggle(ipmLocalized(appLanguage, de: "Erinnerungen", en: "Notifications", fr: "Notifications", ptBR: "Notificações", nl: "Meldingen"), isOn: $notificationsEnabled)
                            .tint(IPMColors.green)
                    }
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 13))
                            .foregroundStyle(IPMColors.brownMid)
                            .frame(width: 20)
                        Stepper(value: $defaultInspectionIntervalDays, in: 1...365) {
                            Text("\(ipmLocalized(appLanguage, de: "Standard-Prüfintervall", en: "Default inspection interval", fr: "Intervalle d’inspection par défaut", ptBR: "Intervalo padrão de inspeção", nl: "Standaard inspectie-interval")): \(defaultInspectionIntervalDays) \(ipmLocalized(appLanguage, de: "Tage", en: "days", fr: "jours", ptBR: "dias", nl: "dagen"))")
                                .font(.system(size: 14))
                        }
                        .tint(IPMColors.green)
                    }
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(size: 13))
                            .foregroundStyle(IPMColors.brownMid)
                            .frame(width: 20)
                        Picker(ipmLocalized(appLanguage, de: "Sprache", en: "Language", fr: "Langue", ptBR: "Idioma", nl: "Taal"), selection: $currentLanguage) {
                            Text("Deutsch").tag("de")
                            Text("English").tag("en")
                            Text("Français").tag("fr")
                            Text("Português (Brasil)").tag("pt-BR")
                            Text("Nederlands").tag("nl")
                        }
                        .tint(IPMColors.green)
                    }
                    HStack {
                        Image(systemName: "number.square.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(IPMColors.brownMid)
                            .frame(width: 20)
                        Toggle(ipmLocalized(appLanguage, de: "Nummern auf Fallen-Pins", en: "Trap numbers on pins", fr: "Numéros sur les pièges", ptBR: "Números nos pinos das armadilhas", nl: "Valnummers op pins"), isOn: $showTrapNumbers)
                            .tint(IPMColors.green)
                    }
                } header: { SectionLabel(ipmLocalized(appLanguage, de: "Einstellungen", en: "Settings", fr: "Réglages", ptBR: "Configurações", nl: "Instellingen")) }
                .listRowBackground(AdaptiveColor.card(scheme))

                Section {
                    Button {
                        Task { await exportCSV() }
                    } label: {
                        Label(ipmLocalized(appLanguage, de: "Daten als CSV exportieren", en: "Export data as CSV"), systemImage: "doc.text")
                            .foregroundStyle(IPMColors.green)
                    }
                    .disabled(isExportingCSV)

                    if let csvExportURL {
                        ShareLink(item: csvExportURL) {
                            Label(ipmLocalized(appLanguage, de: "CSV teilen", en: "Share CSV"), systemImage: "square.and.arrow.up")
                                .foregroundStyle(IPMColors.brownMid)
                        }
                    }

                    Button {
                        Task { await exportPDF() }
                    } label: {
                        Label(ipmLocalized(appLanguage, de: "Daten als PDF exportieren", en: "Export data as PDF"), systemImage: "doc.richtext")
                            .foregroundStyle(IPMColors.green)
                    }
                    .disabled(isExportingPDF)

                    if let pdfExportURL {
                        ShareLink(item: pdfExportURL) {
                            Label(ipmLocalized(appLanguage, de: "PDF teilen", en: "Share PDF"), systemImage: "square.and.arrow.up")
                                .foregroundStyle(IPMColors.brownMid)
                        }
                    }
                } header: { SectionLabel(ipmLocalized(appLanguage, de: "Export", en: "Export", fr: "Export", ptBR: "Exportação", nl: "Export")) }
                .listRowBackground(AdaptiveColor.card(scheme))

                Section {
                    InfoRow(icon: "info.circle.fill", label: "Version", value: appVersion, color: IPMColors.brownMid)
                    NavigationLink(destination: ImpressumView()) {
                        InfoRow(icon: "building.2.fill", label: ipmLocalized(appLanguage, de: "Impressum", en: "Imprint"), value: "", color: IPMColors.brownMid)
                    }
                    NavigationLink(destination: PrivacyPolicyView()) {
                        InfoRow(icon: "hand.raised.fill", label: ipmLocalized(appLanguage, de: "Datenschutzerklärung", en: "Privacy Policy"), value: "", color: IPMColors.brownMid)
                    }
                    NavigationLink(destination: TermsConditionsView()) {
                        InfoRow(icon: "doc.plaintext.fill", label: ipmLocalized(appLanguage, de: "AGB", en: "Terms & Conditions"), value: "", color: IPMColors.brownMid)
                    }
                    NavigationLink(destination: ContactSupportView()) {
                        InfoRow(icon: "envelope.fill", label: ipmLocalized(appLanguage, de: "Kontakt / Support", en: "Contact / Support"), value: "", color: IPMColors.brownMid)
                    }
                } header: { SectionLabel(ipmLocalized(appLanguage, de: "App", en: "App", fr: "App", ptBR: "App", nl: "App")) }
                .listRowBackground(AdaptiveColor.card(scheme))
            }
            .scrollContentBackground(.hidden)
            .background(AdaptiveColor.background(scheme))
        }
        .navigationTitle(ipmLocalized(appLanguage, de: "Einstellungen", en: "Settings", fr: "Réglages", ptBR: "Configurações", nl: "Instellingen"))
        .onAppear { exportMessage = nil }
    }

    private func exportCSV() async {
        isExportingCSV = true
        defer { isExportingCSV = false }
        do {
            csvExportURL = try await FirestoreService.shared.exportAllDataToCSV(language: currentLanguage)
            exportMessage = ipmLocalized(currentLanguage, de: "CSV-Export erstellt.", en: "CSV export created.")
        } catch {
            exportMessage = error.localizedDescription
        }
    }

    private func exportPDF() async {
        isExportingPDF = true
        defer { isExportingPDF = false }
        do {
            pdfExportURL = try await FirestoreService.shared.exportAllDataToPDF(language: currentLanguage)
            exportMessage = ipmLocalized(currentLanguage, de: "PDF-Export erstellt.", en: "PDF export created.")
        } catch {
            exportMessage = error.localizedDescription
        }
    }
}

private struct BillingSupportView: View {
    @Environment(\.colorScheme) var scheme
    @Environment(\.openURL) private var openURL
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()
            List {
                Section {
                    Button {
                        openURL(AppLegalLinks.manageSubscriptions)
                    } label: {
                        InfoRow(
                            icon: "creditcard.fill",
                            label: ipmLocalized(appLanguage, de: "Zahlungsmethode verwalten", en: "Manage payment method"),
                            value: ipmLocalized(appLanguage, de: "Im App Store öffnen", en: "Open in App Store"),
                            color: IPMColors.green
                        )
                    }

                    Button {
                        openURL(AppLegalLinks.billingHistory)
                    } label: {
                        InfoRow(
                            icon: "doc.text.fill",
                            label: ipmLocalized(appLanguage, de: "Rechnungshistorie", en: "Billing history"),
                            value: ipmLocalized(appLanguage, de: "Rechnungen anzeigen", en: "View invoices"),
                            color: IPMColors.brownMid
                        )
                    }
                } header: {
                    SectionLabel(ipmLocalized(appLanguage, de: "Abrechnung", en: "Billing"))
                }
                .listRowBackground(AdaptiveColor.card(scheme))
            }
            .scrollContentBackground(.hidden)
            .background(AdaptiveColor.background(scheme))
        }
        .navigationTitle(ipmLocalized(appLanguage, de: "Zahlung & Rechnungen", en: "Payment & Invoices"))
        .ipmNavigationBarTitleDisplayModeInline()
    }
}

private enum AppLegalLinks {
    static let imprint = URL(string: "https://rottecklabs.com/imprint")!
    static let privacy = URL(string: "https://rottecklabs.com/privacy")!
    static let terms = URL(string: "https://rottecklabs.com/terms")!
    static let support = URL(string: "https://rottecklabs.com/support")!
    static let supportEmail = URL(string: "mailto:support@rottecklabs.com")!
    static let manageSubscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
    static let billingHistory = URL(string: "https://reportaproblem.apple.com")!
}

// MARK: - Impressum
struct ImpressumView: View {
    @Environment(\.colorScheme) var scheme
    @Environment(\.openURL) private var openURL
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()
            List {
                Section {
                    Text("Rotteck Labs\nJonathan Rottenkolber")
                        .font(.system(size: 14))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    Button(ipmLocalized(appLanguage, de: "Online-Impressum öffnen", en: "Open online imprint")) {
                        openURL(AppLegalLinks.imprint)
                    }
                }
                .listRowBackground(AdaptiveColor.card(scheme))
            }
            .scrollContentBackground(.hidden)
            .background(AdaptiveColor.background(scheme))
        }
        .navigationTitle(ipmLocalized(appLanguage, de: "Impressum", en: "Imprint"))
        .ipmNavigationBarTitleDisplayModeInline()
    }
}

private struct PrivacyPolicyView: View {
    @Environment(\.colorScheme) var scheme
    @Environment(\.openURL) private var openURL
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()
            List {
                Section {
                    Text(ipmLocalized(
                        appLanguage,
                        de: "Datenschutzerklärung: Diese App verarbeitet Kontodaten und betriebliche Prüfungsdaten zur Bereitstellung der IPM-Funktionen. Details findest du in der vollständigen Online-Richtlinie.",
                        en: "Privacy Policy: This app processes account and operational inspection data to provide IPM features. See the full online policy for details."
                    ))
                    .font(.system(size: 14))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    Button(ipmLocalized(appLanguage, de: "Vollständige Datenschutzerklärung öffnen", en: "Open full privacy policy")) {
                        openURL(AppLegalLinks.privacy)
                    }
                }
                .listRowBackground(AdaptiveColor.card(scheme))
            }
            .scrollContentBackground(.hidden)
            .background(AdaptiveColor.background(scheme))
        }
        .navigationTitle(ipmLocalized(appLanguage, de: "Datenschutzerklärung", en: "Privacy Policy"))
        .ipmNavigationBarTitleDisplayModeInline()
    }
}

private struct TermsConditionsView: View {
    @Environment(\.colorScheme) var scheme
    @Environment(\.openURL) private var openURL
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()
            List {
                Section {
                    Text(ipmLocalized(
                        appLanguage,
                        de: "AGB: Die Nutzung der App erfolgt gemäß den geltenden Nutzungsbedingungen. Bitte lies die vollständige Version online.",
                        en: "Terms & Conditions: App usage is subject to the applicable terms. Please read the full version online."
                    ))
                    .font(.system(size: 14))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    Button(ipmLocalized(appLanguage, de: "AGB öffnen", en: "Open terms")) {
                        openURL(AppLegalLinks.terms)
                    }
                }
                .listRowBackground(AdaptiveColor.card(scheme))
            }
            .scrollContentBackground(.hidden)
            .background(AdaptiveColor.background(scheme))
        }
        .navigationTitle(ipmLocalized(appLanguage, de: "AGB", en: "Terms & Conditions"))
        .ipmNavigationBarTitleDisplayModeInline()
    }
}

private struct ContactSupportView: View {
    @Environment(\.colorScheme) var scheme
    @Environment(\.openURL) private var openURL
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()
            List {
                Section {
                    Button {
                        openURL(AppLegalLinks.supportEmail)
                    } label: {
                        InfoRow(
                            icon: "envelope.fill",
                            label: ipmLocalized(appLanguage, de: "E-Mail Support", en: "Email support"),
                            value: "support@rottecklabs.com",
                            color: IPMColors.green
                        )
                    }
                    Button {
                        openURL(AppLegalLinks.support)
                    } label: {
                        InfoRow(
                            icon: "globe",
                            label: ipmLocalized(appLanguage, de: "Support-Seite", en: "Support page"),
                            value: "rottecklabs.com/support",
                            color: IPMColors.brownMid
                        )
                    }
                }
                .listRowBackground(AdaptiveColor.card(scheme))
            }
            .scrollContentBackground(.hidden)
            .background(AdaptiveColor.background(scheme))
        }
        .navigationTitle(ipmLocalized(appLanguage, de: "Kontakt / Support", en: "Contact / Support"))
        .ipmNavigationBarTitleDisplayModeInline()
    }
}
