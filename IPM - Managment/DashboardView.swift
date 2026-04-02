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

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(greetingText())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(IPMColors.brownMid)
                        Text("Dashboard")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    }

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
                            .offset(x: 110, y: -70)

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
                        }
                        .padding(18)
                    }

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
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .ipmNavigationBarHidden()
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
