import SwiftUI

// MARK: - Main Tab
struct MainTabView: View {
    @AppStorage("appLanguage") private var appLanguage = "de"

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
            RoomListView()
                .tabItem { Label(ipmLocalized(appLanguage, de: "Räume", en: "Rooms"), systemImage: "map.fill") }
            AllTrapsView()
                .tabItem { Label(ipmLocalized(appLanguage, de: "Fallen", en: "Traps"), systemImage: "square.grid.2x2.fill") }
            SettingsView()
                .tabItem { Label(ipmLocalized(appLanguage, de: "Account", en: "Account"), systemImage: "person.circle") }
        }
        .tint(IPMColors.green)
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                IPMAnimatedBackdrop()

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(greetingText())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(IPMColors.brownMid)
                        Text("Dashboard")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    }
                    .ipmFlowEntrance(delay: 0.02)

                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        IPMColors.greenDark,
                                        IPMColors.green,
                                        IPMColors.greenLight
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(maxWidth: 600)
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)

                        Circle()
                            .fill(.white.opacity(0.14))
                            .frame(width: 150, height: 150)
                            .offset(x: hasAppeared ? 126 : 104, y: hasAppeared ? -78 : -58)
                            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: hasAppeared)

                        HStack(alignment: .bottom, spacing: 16) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("IPM Manager")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(ipmLocalized(appLanguage, de: "Kunden, Räume und Kontrollen sauber verknüpfen.", en: "Link clients, rooms, and inspections cleanly."))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.92))

                                HStack(spacing: 8) {
                                    dashboardTag(systemImage: "building.2.fill", title: ipmLocalized(appLanguage, de: "Kunden", en: "Clients"))
                                    dashboardTag(systemImage: "map.fill", title: ipmLocalized(appLanguage, de: "Räume", en: "Rooms"))
                                    dashboardTag(systemImage: "checklist", title: ipmLocalized(appLanguage, de: "Kontrollen", en: "Inspections"))
                                }
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                                .font(.system(size: 52, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.95))
                                .padding(16)
                                .background(.white.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .rotationEffect(.degrees(hasAppeared ? 0 : -7))
                                .scaleEffect(hasAppeared ? 1 : 0.94)
                                .animation(IPMMotion.screenSpring.delay(0.12), value: hasAppeared)
                        }
                        .padding(18)
                    }
                    .shadow(color: IPMColors.green.opacity(0.2), radius: 28, y: 16)
                    .ipmFlowEntrance(delay: 0.08)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(ipmLocalized(appLanguage, de: "Wir bauen die Kunden-, Räume- und Fallenlogik gerade grundlegend neu auf.", en: "We are currently rebuilding the client, room, and trap logic from the ground up."))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                        Text(ipmLocalized(appLanguage, de: "Das Dashboard bleibt bewusst leer, bis alle Werte sauber miteinander verknüpft sind.", en: "The dashboard is intentionally kept minimal until all values are cleanly linked together."))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(IPMColors.brownMid)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .ipmCard(cornerRadius: 18)
                    .ipmFlowEntrance(delay: 0.14)

                    NavigationLink(destination: ClientListView()) {
                        Label(
                            ipmLocalized(appLanguage, de: "Zu den Kunden", en: "Go to clients"),
                            systemImage: "building.2.fill"
                        )
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(IPMColors.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: IPMColors.green.opacity(0.26), radius: 14, y: 8)
                    }
                    .buttonStyle(.plain)
                    .ipmFlowEntrance(delay: 0.2)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .ipmNavigationBarHidden()
            .onAppear { hasAppeared = true }
        }
    }

    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return ipmLocalized(appLanguage, de: "Guten Morgen", en: "Good morning") }
        if hour < 18 { return ipmLocalized(appLanguage, de: "Guten Tag", en: "Good afternoon") }
        return ipmLocalized(appLanguage, de: "Guten Abend", en: "Good evening") }

    private func dashboardTag(systemImage: String, title: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.14))
            .clipShape(Capsule())
    }
}
