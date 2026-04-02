import SwiftUI

private enum OnboardingSource: String, CaseIterable, Identifiable {
    case instagram
    case tiktok
    case linkedin
    case google
    case friends
    case recommendation

    var id: String { rawValue }

    func title(language: String) -> String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .linkedin: return "LinkedIn"
        case .google: return "Google"
        case .friends:
            return ipmLocalized(language, de: "Freunde", en: "Friends", fr: "Amis", ptBR: "Amigos", nl: "Vrienden")
        case .recommendation:
            return ipmLocalized(language, de: "Empfehlung", en: "Recommendation", fr: "Recommandation", ptBR: "Recomendação", nl: "Aanbeveling")
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var appear = false
    @State private var didInitialize = false
    @State private var showSignIn = false

    @State private var signInEmail = ""
    @State private var signInPassword = ""

    @State private var step = 0
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var emailStatus: RegistrationEmailStatus = .idle
    @State private var isCheckingEmail = false
    @State private var emailCheckTask: Task<Void, Never>?
    @State private var source: OnboardingSource = .instagram
    @State private var customerCount = 1
    @State private var selectedPlan: SubscriptionTier = .free
    @State private var showUpgradeDialog = false

    private let totalSteps = 7

    private var fullName: String {
        "\(firstName.trimmingCharacters(in: .whitespacesAndNewlines)) \(lastName.trimmingCharacters(in: .whitespacesAndNewlines))"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var progress: Double {
        Double(step + 1) / Double(totalSteps)
    }

    private var emailStatusText: String {
        if isCheckingEmail {
            return ipmLocalized(appLanguage, de: "Prüfe E-Mail...", en: "Checking email...")
        }
        switch emailStatus {
        case .idle:
            return ""
        case .invalid:
            return ipmLocalized(appLanguage, de: "Bitte eine gültige E-Mail eingeben.", en: "Please enter a valid email.")
        case .available:
            return ipmLocalized(appLanguage, de: "E-Mail ist verfügbar.", en: "Email is available.")
        case .taken:
            return ipmLocalized(appLanguage, de: "E-Mail ist bereits vergeben.", en: "Email is already taken.")
        case .unknown:
            return ipmLocalized(appLanguage, de: "E-Mail konnte gerade nicht geprüft werden.", en: "Could not check email right now.")
        }
    }

    private var emailStatusColor: Color {
        if isCheckingEmail {
            return IPMColors.brownMid
        }
        switch emailStatus {
        case .available:
            return IPMColors.ok
        case .taken, .invalid:
            return IPMColors.critical
        case .unknown:
            return IPMColors.warning
        case .idle:
            return IPMColors.brownMid
        }
    }

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()

            Circle()
                .fill(IPMColors.green.opacity(0.06))
                .frame(width: 420, height: 420)
                .offset(x: 120, y: -220)
                .blur(radius: 64)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                topHeader

                Spacer(minLength: 14)

                if showSignIn {
                    signInCard
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    onboardingCard
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                Spacer(minLength: 26)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 14)
            .animation(.spring(response: 0.6, dampingFraction: 0.86), value: appear)
        }
        .confirmationDialog(
            ipmLocalized(appLanguage, de: "Abo-Empfehlung", en: "Plan recommendation"),
            isPresented: $showUpgradeDialog,
            titleVisibility: .visible
        ) {
            Button(ipmLocalized(appLanguage, de: "Plus wählen", en: "Choose Plus")) {
                selectedPlan = .plus
                step = min(totalSteps - 1, step + 1)
            }
            Button(ipmLocalized(appLanguage, de: "Pro wählen", en: "Choose Pro")) {
                selectedPlan = .pro
                step = min(totalSteps - 1, step + 1)
            }
            Button(ipmLocalized(appLanguage, de: "Erstmal Free", en: "Stay on Free")) {
                selectedPlan = .free
                step = min(totalSteps - 1, step + 1)
            }
        } message: {
            Text(ipmLocalized(
                appLanguage,
                de: "Mit mehreren Kunden passt Plus oder Pro meistens besser. Du kannst später jederzeit wechseln.",
                en: "With multiple clients, Plus or Pro is usually a better fit. You can switch anytime later."
            ))
        }
        .onAppear {
            appear = true
            if !didInitialize {
                showSignIn = hasCompletedOnboarding
                didInitialize = true
            }
        }
        .onChange(of: email) { _, newValue in
            triggerEmailCheck(for: newValue)
        }
        .onDisappear {
            emailCheckTask?.cancel()
        }
    }

    private var topHeader: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    brandLockup(compact: true)
                    Text(showSignIn
                         ? ipmLocalized(appLanguage, de: "Schnell anmelden", en: "Quick sign in")
                         : ipmLocalized(appLanguage, de: "Onboarding", en: "Onboarding"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(IPMColors.brownMid)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        showSignIn.toggle()
                        auth.errorMessage = nil
                    }
                } label: {
                    Text(showSignIn
                         ? ipmLocalized(appLanguage, de: "Neu hier? Starten", en: "New here? Start")
                         : ipmLocalized(appLanguage, de: "Schon ein Konto?", en: "Already have an account?"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(IPMColors.greenDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AdaptiveColor.card(scheme))
                        .clipShape(Capsule())
                }
            }

            if !showSignIn {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(ipmLocalized(appLanguage, de: "Schritt \(step + 1) von \(totalSteps)", en: "Step \(step + 1) of \(totalSteps)"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(IPMColors.brownMid)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(IPMColors.greenDark)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(IPMColors.brownMid.opacity(0.18))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [IPMColors.green, IPMColors.greenDark],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, geo.size.width * progress), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }

    private var signInCard: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [IPMColors.greenDark, IPMColors.green, IPMColors.greenLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 168)

                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: 120, height: 120)
                    .offset(x: 120, y: -50)

                VStack(alignment: .leading, spacing: 10) {
                    Label(ipmLocalized(appLanguage, de: "Sicherer Zugriff", en: "Secure access"), systemImage: "lock.shield.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))

                    Text(ipmLocalized(appLanguage, de: "Verwalte Kunden, Räume und Kontrollen ohne visuelles Durcheinander.", en: "Manage clients, rooms, and inspections without visual clutter."))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
            }

            Text(ipmLocalized(appLanguage, de: "Willkommen zurück", en: "Welcome back"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                .frame(maxWidth: .infinity, alignment: .leading)

            IPMTextField(placeholder: ipmLocalized(appLanguage, de: "E-Mail", en: "Email"), text: $signInEmail, icon: "envelope", keyboard: .emailAddress)
            IPMTextField(placeholder: ipmLocalized(appLanguage, de: "Passwort", en: "Password"), text: $signInPassword, icon: "lock", isSecure: true)

            if let error = auth.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(IPMColors.critical)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task {
                    let success = await auth.login(email: signInEmail, password: signInPassword)
                    if success {
                        signInEmail = signInEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        signInPassword = ""
                    }
                }
            } label: {
                ZStack {
                    if auth.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(ipmLocalized(appLanguage, de: "Anmelden", en: "Sign in"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(colors: [IPMColors.green, IPMColors.greenDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: IPMColors.green.opacity(0.35), radius: 12, y: 6)
                .opacity(signInEmail.isEmpty || signInPassword.isEmpty || auth.isLoading ? 0.6 : 1)
            }
            .disabled(signInEmail.isEmpty || signInPassword.isEmpty || auth.isLoading)

            HStack {
                Rectangle().fill(IPMColors.brownMid.opacity(0.25)).frame(height: 1)
                Text(ipmLocalized(appLanguage, de: "oder", en: "or"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(IPMColors.brownMid)
                Rectangle().fill(IPMColors.brownMid.opacity(0.25)).frame(height: 1)
            }

            Button {
                Task { await auth.signInWithGoogle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                    Text(ipmLocalized(appLanguage, de: "Mit Google anmelden", en: "Sign in with Google"))
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AdaptiveColor.cardSecondary(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(auth.isLoading)
        }
        .ipmCard(padding: 24)
    }

    private var onboardingCard: some View {
        VStack(spacing: 18) {
            Group {
                switch step {
                case 0:
                    onboardingWelcomeStep
                case 1:
                    onboardingNameStep
                case 2:
                    onboardingUsernameStep
                case 3:
                    onboardingCredentialStep
                case 4:
                    onboardingSourceStep
                case 5:
                    onboardingCustomerCountStep
                default:
                    onboardingSummaryStep
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let error = auth.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(IPMColors.critical)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                if step > 0 {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            step -= 1
                            auth.errorMessage = nil
                        }
                    } label: {
                        Text(ipmLocalized(appLanguage, de: "Zurück", en: "Back"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(IPMColors.brownMid)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AdaptiveColor.cardSecondary(scheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                Button {
                    handlePrimaryAction()
                } label: {
                    ZStack {
                        if auth.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(step == totalSteps - 1
                                 ? ipmLocalized(appLanguage, de: "Konto erstellen", en: "Create account")
                                 : ipmLocalized(appLanguage, de: "Weiter", en: "Continue"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(colors: [IPMColors.green, IPMColors.greenDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: IPMColors.green.opacity(0.3), radius: 10, y: 6)
                    .opacity(canContinueCurrentStep ? 1 : 0.6)
                }
                .disabled(!canContinueCurrentStep || auth.isLoading)
            }
        }
        .ipmCard(padding: 24)
    }

    private var onboardingWelcomeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                brandLockup(compact: false)
            }

            Text(ipmLocalized(appLanguage, de: "Willkommen bei IPM Manager", en: "Welcome to IPM Manager"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))

            Text(ipmLocalized(appLanguage, de: "In wenigen Schritten richten wir dein Konto ein, damit du sofort loslegen kannst.", en: "We will set up your account in a few quick steps so you can start right away."))
                .font(.system(size: 14))
                .foregroundStyle(IPMColors.brownMid)

            HStack(spacing: 10) {
                Label(ipmLocalized(appLanguage, de: "Räume & Fallen", en: "Rooms & traps"), systemImage: "map.fill")
                Label(ipmLocalized(appLanguage, de: "Kontrollrhythmus", en: "Inspection rhythm"), systemImage: "clock.fill")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(IPMColors.greenDark)
        }
    }

    private func brandLockup(compact: Bool) -> some View {
        HStack(spacing: compact ? 10 : 12) {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 12 : 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [IPMColors.greenDark, IPMColors.green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: compact ? 38 : 52, height: compact ? 38 : 52)

                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.system(size: compact ? 18 : 24, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: compact ? 1 : 2) {
                Text("IPM")
                    .font(.system(size: compact ? 18 : 22, weight: .black, design: .rounded))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                Text("Manager")
                    .font(.system(size: compact ? 13 : 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(IPMColors.greenDark)
            }
        }
    }

    private var onboardingNameStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ipmLocalized(appLanguage, de: "Wie heißt du?", en: "What is your name?"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))

            IPMTextField(placeholder: ipmLocalized(appLanguage, de: "Vorname", en: "First name"), text: $firstName, icon: "person")
            IPMTextField(placeholder: ipmLocalized(appLanguage, de: "Nachname", en: "Last name"), text: $lastName, icon: "person.fill")
        }
    }

    private var onboardingCredentialStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ipmLocalized(appLanguage, de: "Dein Login", en: "Your login"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))

            IPMTextField(placeholder: ipmLocalized(appLanguage, de: "E-Mail", en: "Email"), text: $email, icon: "envelope", keyboard: .emailAddress)
            if !emailStatusText.isEmpty {
                Label(emailStatusText, systemImage: emailStatus == .available ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(emailStatusColor)
            }
            IPMTextField(placeholder: ipmLocalized(appLanguage, de: "Passwort", en: "Password"), text: $password, icon: "lock", isSecure: true)

            Text(ipmLocalized(appLanguage, de: "Mindestens 6 Zeichen.", en: "At least 6 characters."))
                .font(.system(size: 12))
                .foregroundStyle(IPMColors.brownMid)
        }
    }

    private var onboardingUsernameStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ipmLocalized(appLanguage, de: "Wähle einen Benutzernamen", en: "Choose a username"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))

            IPMTextField(placeholder: ipmLocalized(appLanguage, de: "Benutzername", en: "Username"), text: $username, icon: "at")

            Text(ipmLocalized(appLanguage, de: "Dieser Name wird in deinem Profil angezeigt.", en: "This name will be shown on your profile."))
                .font(.system(size: 12))
                .foregroundStyle(IPMColors.brownMid)
        }
    }

    private var onboardingSourceStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ipmLocalized(appLanguage, de: "Wie bist du auf uns gekommen?", en: "How did you hear about us?"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))

            ForEach(OnboardingSource.allCases) { option in
                Button {
                    source = option
                } label: {
                    HStack {
                        Text(option.title(language: appLanguage))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                        Spacer()
                        Image(systemName: source == option ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(source == option ? IPMColors.green : IPMColors.brownMid.opacity(0.5))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AdaptiveColor.cardSecondary(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private var onboardingCustomerCountStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ipmLocalized(appLanguage, de: "Wie viele Kunden betreust du aktuell?", en: "How many clients do you currently manage?"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))

            Stepper(value: $customerCount, in: 1...200) {
                HStack {
                    Text(ipmLocalized(appLanguage, de: "Kunden", en: "Clients"))
                    Spacer()
                    Text("\(customerCount)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(IPMColors.greenDark)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
            }
            .padding(12)
            .background(AdaptiveColor.cardSecondary(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            if customerCount > 1 {
                Text(ipmLocalized(appLanguage, de: "Tipp: Für mehrere Kunden lohnt sich meist Plus oder Pro.", en: "Tip: Plus or Pro is usually better for multiple clients."))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(IPMColors.warning)
            }
        }
    }

    private var onboardingSummaryStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ipmLocalized(appLanguage, de: "Fast geschafft", en: "Almost done"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))

            Text(ipmLocalized(appLanguage, de: "Prüfe kurz deine Angaben und erstelle dann dein Konto.", en: "Quickly review your details and create your account."))
                .font(.system(size: 14))
                .foregroundStyle(IPMColors.brownMid)

            InfoRow(icon: "person.fill", label: ipmLocalized(appLanguage, de: "Name", en: "Name"), value: fullName, color: IPMColors.green)
            InfoRow(icon: "at", label: ipmLocalized(appLanguage, de: "Benutzername", en: "Username"), value: username, color: IPMColors.greenDark)
            InfoRow(icon: "envelope.fill", label: ipmLocalized(appLanguage, de: "E-Mail", en: "Email"), value: email, color: IPMColors.brownMid)
            InfoRow(icon: "megaphone.fill", label: ipmLocalized(appLanguage, de: "Quelle", en: "Source"), value: source.title(language: appLanguage), color: IPMColors.brownMid)
            InfoRow(icon: "person.3.fill", label: ipmLocalized(appLanguage, de: "Kunden", en: "Clients"), value: "\(customerCount)", color: IPMColors.brownMid)
            InfoRow(icon: "crown.fill", label: ipmLocalized(appLanguage, de: "Abo", en: "Plan"), value: selectedPlan.rawValue.capitalized, color: IPMColors.greenDark)
        }
    }

    private var canContinueCurrentStep: Bool {
        switch step {
        case 0:
            return true
        case 1:
            return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 3:
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && password.count >= 6
                && !isCheckingEmail
                && emailStatus != .taken
                && emailStatus != .invalid
        case 4, 5:
            return true
        default:
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && password.count >= 6
                && !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func handlePrimaryAction() {
        auth.errorMessage = nil

        if step == 5 {
            if customerCount > 1 {
                showUpgradeDialog = true
            } else {
                step += 1
            }
            return
        }

        if step < totalSteps - 1 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                step += 1
            }
            return
        }

        Task {
            let success = await auth.register(email: email, password: password)
            guard success else { return }

            let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanUsername.isEmpty {
                _ = await auth.updateDisplayName(cleanUsername)
            }

            UserDefaults.standard.set(source.rawValue, forKey: "onboardingSource")
            UserDefaults.standard.set(customerCount, forKey: "onboardingCustomerCount")
            UserDefaults.standard.set(selectedPlan.rawValue, forKey: "subscriptionTier")
            hasCompletedOnboarding = true

            email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            password = ""
        }
    }

    private func triggerEmailCheck(for value: String) {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        emailCheckTask?.cancel()

        guard step == 3 else {
            isCheckingEmail = false
            emailStatus = .idle
            return
        }

        guard !clean.isEmpty else {
            isCheckingEmail = false
            emailStatus = .idle
            return
        }

        if !clean.contains("@") || !clean.contains(".") {
            isCheckingEmail = false
            emailStatus = .invalid
            return
        }

        isCheckingEmail = true
        emailStatus = .idle
        emailCheckTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            let status = await auth.checkRegistrationEmailStatus(email: clean)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                let latest = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard latest == clean else { return }
                isCheckingEmail = false
                emailStatus = status
            }
        }
    }
}
