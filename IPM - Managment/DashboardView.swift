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

private enum DashboardComparisonMode: String, CaseIterable, Identifiable {
    case rooms
    case traps
    case insects

    var id: String { rawValue }

    func title(language: String) -> String {
        switch self {
        case .rooms: return ipmLocalized(language, de: "Räume", en: "Rooms")
        case .traps: return ipmLocalized(language, de: "Fallen", en: "Traps")
        case .insects: return ipmLocalized(language, de: "Insekten", en: "Insects")
        }
    }

    var symbol: String {
        switch self {
        case .rooms: return "square.grid.3x3.square"
        case .traps: return "sensor.tag.radiowaves.forward"
        case .insects: return "ant.fill"
        }
    }
}

private enum DashboardMetric: String, CaseIterable, Identifiable {
    case findings
    case temperature
    case humidity
    case urgency

    var id: String { rawValue }

    func title(language: String) -> String {
        switch self {
        case .findings: return ipmLocalized(language, de: "Befund", en: "Findings")
        case .temperature: return ipmLocalized(language, de: "Temperatur", en: "Temperature")
        case .humidity: return ipmLocalized(language, de: "Feuchtigkeit", en: "Humidity")
        case .urgency: return ipmLocalized(language, de: "Fälligkeit", en: "Urgency")
        }
    }

    var symbol: String {
        switch self {
        case .findings: return "waveform.path.ecg.rectangle"
        case .temperature: return "thermometer.medium"
        case .humidity: return "humidity.fill"
        case .urgency: return "clock.badge.exclamationmark.fill"
        }
    }
}

private struct DashboardRoomCard: Identifiable {
    let id: String
    let clientName: String
    let floorName: String
    let trapCount: Int
    let inspectionCount: Int
    let totalFindings: Int
    let averageTemperature: Double?
    let averageHumidity: Double?
    let urgencyScore: Double
    let dueCount: Int
    let topFindings: [DashboardFindingCount]
    let insectCounts: [String: Int]
}

private struct DashboardInsectCard: Identifiable {
    let id: String
    let name: String
    let totalCount: Int
    let roomCount: Int
    let trapCount: Int
    let topRoomName: String?
    let topRoomCount: Int
    let topTrapName: String?
    let topTrapCount: Int
}

// MARK: - Dashboard
struct DashboardView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"

    @State private var snapshot: DashboardSnapshot?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var hasAppeared = false

    @State private var comparisonMode: DashboardComparisonMode = .rooms
    @State private var selectedMetric: DashboardMetric = .findings
    @State private var selectedClientId = "__all_clients__"
    @State private var selectedTrapType = "__all_trap_types__"
    @State private var selectedInsect = "__all_insects__"
    @State private var searchText = ""

    private let allClientsKey = "__all_clients__"
    private let allTrapTypesKey = "__all_trap_types__"
    private let allInsectsKey = "__all_insects__"

    var body: some View {
        NavigationStack {
            ZStack {
                IPMAnimatedBackdrop()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        dashboardHeader
                            .ipmFlowEntrance(delay: 0.02)

                        dashboardOverviewCard
                            .ipmFlowEntrance(delay: 0.08)

                        dashboardFilterPanel
                            .ipmFlowEntrance(delay: 0.14)

                        dashboardContent
                            .ipmFlowEntrance(delay: 0.2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
                .refreshable { await loadDashboard(forceRefresh: true) }

                if isLoading && snapshot == nil {
                    ProgressView()
                        .tint(IPMColors.green)
                }
            }
            .ipmNavigationBarHidden()
            .task { await loadDashboard() }
            .onAppear { hasAppeared = true }
        }
    }

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingText())
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(IPMColors.brownMid)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    Text(ipmLocalized(
                        appLanguage,
                        de: "Räume, Fallen und Insekten direkt miteinander vergleichen.",
                        en: "Compare rooms, traps, and insects side by side."
                    ))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(IPMColors.brownMid)
                }

                Spacer(minLength: 0)

                Button {
                    Task { await loadDashboard(forceRefresh: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                        .padding(12)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial.opacity(0.94))
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(scheme == .dark ? 0.08 : 0.24), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dashboardOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(ipmLocalized(appLanguage, de: "Analyse live", en: "Live analytics"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(IPMColors.greenDark)

                    Text(activeOverviewTitle)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))

                    Text(activeOverviewSubtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(IPMColors.brownMid)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(.white.opacity(scheme == .dark ? 0.12 : 0.18))
                        .background(Circle().fill(.ultraThinMaterial.opacity(0.92)))
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.55), .white.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )
                        .frame(width: 82, height: 82)

                    Image(systemName: comparisonMode.symbol)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.96))
                }
                .shadow(color: IPMColors.shadow.opacity(0.12), radius: 18, y: 10)
            }

            HStack(spacing: 10) {
                dashboardSummaryStat(
                    title: ipmLocalized(appLanguage, de: "Räume", en: "Rooms"),
                    value: "\(roomCards.count)",
                    icon: "square.grid.3x3.square"
                )
                dashboardSummaryStat(
                    title: ipmLocalized(appLanguage, de: "Fallen", en: "Traps"),
                    value: "\(filteredTrapSummaries.count)",
                    icon: "sensor.tag.radiowaves.forward"
                )
                dashboardSummaryStat(
                    title: ipmLocalized(appLanguage, de: "Insekten", en: "Insects"),
                    value: "\(insectCards.count)",
                    icon: "ant.fill"
                )
            }

            NavigationLink(destination: ClientListView()) {
                HStack(spacing: 12) {
                    Label(
                        ipmLocalized(appLanguage, de: "Zu den Kunden und Räumen", en: "Go to clients and rooms"),
                        systemImage: "building.2.fill"
                    )
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    IPMColors.greenDark.opacity(0.96),
                                    IPMColors.green.opacity(0.88),
                                    IPMColors.glassGreen.opacity(0.58)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(0.22), lineWidth: 1)
                        )
                )
                .shadow(color: IPMColors.green.opacity(0.2), radius: 16, y: 10)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(dashboardGlassBackground)
        .shadow(color: IPMColors.shadow.opacity(0.1), radius: 20, y: 10)
    }

    private var dashboardFilterPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ForEach(DashboardComparisonMode.allCases) { mode in
                    Button {
                        withAnimation(IPMMotion.sectionSpring) {
                            comparisonMode = mode
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: mode.symbol)
                            Text(mode.title(language: appLanguage))
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(comparisonMode == mode ? .white : AdaptiveColor.textPrimary(scheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(comparisonMode == mode ? IPMColors.green : .white.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(IPMColors.greenDark)

                    TextField(
                        ipmLocalized(appLanguage, de: "Nach Raum, Falle oder Insekt suchen", en: "Search rooms, traps, or insects"),
                        text: $searchText
                    )
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.regularMaterial.opacity(0.82))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.white.opacity(scheme == .dark ? 0.08 : 0.22), lineWidth: 1)
                        )
                )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    dashboardMenuPill(
                        title: selectedClientTitle,
                        systemImage: "building.2.fill"
                    ) {
                        Button(ipmLocalized(appLanguage, de: "Alle Kunden", en: "All clients")) {
                            selectedClientId = allClientsKey
                        }
                        ForEach(snapshot?.clients ?? []) { client in
                            Button(client.name) {
                                selectedClientId = client.id ?? allClientsKey
                            }
                        }
                    }

                    dashboardMenuPill(
                        title: selectedTrapTypeTitle,
                        systemImage: "sensor.tag.radiowaves.forward"
                    ) {
                        Button(ipmLocalized(appLanguage, de: "Alle Fallentypen", en: "All trap types")) {
                            selectedTrapType = allTrapTypesKey
                        }
                        ForEach(availableTrapTypes, id: \.rawValue) { trapType in
                            Button(trapType.localizedName(language: appLanguage)) {
                                selectedTrapType = trapType.rawValue
                            }
                        }
                    }

                    dashboardMenuPill(
                        title: selectedInsectTitle,
                        systemImage: "ant.fill"
                    ) {
                        Button(ipmLocalized(appLanguage, de: "Alle Insekten", en: "All insects")) {
                            selectedInsect = allInsectsKey
                        }
                        ForEach(availableInsects, id: \.self) { insect in
                            Button(insect) {
                                selectedInsect = insect
                            }
                        }
                    }

                    dashboardMenuPill(
                        title: selectedMetric.title(language: appLanguage),
                        systemImage: selectedMetric.symbol
                    ) {
                        ForEach(DashboardMetric.allCases) { metric in
                            Button(metric.title(language: appLanguage)) {
                                selectedMetric = metric
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(dashboardGlassBackground)
    }

    @ViewBuilder
    private var dashboardContent: some View {
        if let errorMessage, snapshot == nil {
            IPMEmptyState(
                icon: "exclamationmark.triangle.fill",
                title: ipmLocalized(appLanguage, de: "Dashboard konnte nicht geladen werden", en: "Dashboard could not be loaded"),
                subtitle: errorMessage
            )
        } else if filteredTrapSummaries.isEmpty {
            IPMEmptyState(
                icon: "slider.horizontal.3",
                title: ipmLocalized(appLanguage, de: "Kein Treffer im aktuellen Filter", en: "No matches in current filter"),
                subtitle: ipmLocalized(appLanguage, de: "Passe Kunde, Fallentyp, Insekt oder Suche an.", en: "Adjust client, trap type, insect, or search.")
            )
        } else {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    title: comparisonMode.title(language: appLanguage),
                    subtitle: sectionSubtitle
                )

                switch comparisonMode {
                case .rooms:
                    roomHeatmapSection
                case .traps:
                    trapComparisonSection
                case .insects:
                    insectComparisonSection
                }
            }
        }
    }

    private var roomHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(roomCards) { room in
                    let intensity = normalizedRoomValue(for: room)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(room.floorName)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                                Text(room.clientName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(IPMColors.brownMid)
                            }
                            Spacer(minLength: 0)
                            dashboardIntensityOrb(intensity: intensity)
                        }

                        Text(roomMetricValueText(room))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))

                        HStack(spacing: 8) {
                            dashboardTinyMetric(
                                title: ipmLocalized(appLanguage, de: "Fallen", en: "Traps"),
                                value: "\(room.trapCount)"
                            )
                            dashboardTinyMetric(
                                title: ipmLocalized(appLanguage, de: "Kontrollen", en: "Checks"),
                                value: "\(room.inspectionCount)"
                            )
                            dashboardTinyMetric(
                                title: ipmLocalized(appLanguage, de: "Fällig", en: "Due"),
                                value: "\(room.dueCount)"
                            )
                        }

                        if !room.topFindings.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(Array(room.topFindings.prefix(2))) { finding in
                                    dashboardFindingChip(finding)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
                    .background(roomHeatmapBackground(intensity: intensity))
                }
            }
        }
    }

    private var trapComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(filteredTrapSummaries) { trap in
                let intensity = normalizedTrapValue(for: trap)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(IPMColors.green.opacity(0.16 + (intensity * 0.24)))
                                .frame(width: 52, height: 52)
                            Image(systemName: trap.trap.typ.icon)
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.96))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(ipmLocalized(appLanguage, de: "Falle", en: "Trap")) \(trap.trap.nummer)")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                            Text("\(trap.clientName) · \(trap.floorName)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(IPMColors.brownMid)
                            Text(trap.trap.typ.localizedName(language: appLanguage))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(IPMColors.greenDark)
                        }

                        Spacer(minLength: 0)

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(trapMetricValueText(trap))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                            Text(trap.trap.faelligkeitStatus.label(language: appLanguage))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(trap.trap.faelligkeitStatus.color)
                        }
                    }

                    HStack(spacing: 8) {
                        dashboardTinyMetric(
                            title: ipmLocalized(appLanguage, de: "Checks", en: "Checks"),
                            value: "\(trap.inspectionCount)"
                        )
                        dashboardTinyMetric(
                            title: ipmLocalized(appLanguage, de: "Befund", en: "Findings"),
                            value: "\(trap.latestFindings)"
                        )
                        dashboardTinyMetric(
                            title: ipmLocalized(appLanguage, de: "Nächste", en: "Next"),
                            value: trap.trap.naechstePruefung.formatted(date: .abbreviated, time: .omitted)
                        )
                    }

                    if !trap.topFindings.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(trap.topFindings) { finding in
                                dashboardFindingChip(finding)
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            IPMColors.glassWhite.opacity(0.24 + (intensity * 0.12)),
                                            .clear,
                                            IPMColors.green.opacity(0.14 + (intensity * 0.18))
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(.white.opacity(scheme == .dark ? 0.08 : 0.24), lineWidth: 1)
                        )
                )
            }
        }
    }

    private var insectComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(insectCards) { insect in
                let intensity = normalizedInsectValue(for: insect)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(insect.name)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                            Text("\(insect.roomCount) \(ipmLocalized(appLanguage, de: "Räume", en: "rooms")) · \(insect.trapCount) \(ipmLocalized(appLanguage, de: "Fallen", en: "traps"))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(IPMColors.brownMid)
                        }

                        Spacer(minLength: 0)

                        Text("\(insect.totalCount)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    }

                    HStack(spacing: 8) {
                        dashboardTinyMetric(
                            title: ipmLocalized(appLanguage, de: "Top Raum", en: "Top room"),
                            value: insect.topRoomName ?? "—"
                        )
                        dashboardTinyMetric(
                            title: ipmLocalized(appLanguage, de: "Top Falle", en: "Top trap"),
                            value: insect.topTrapName ?? "—"
                        )
                    }

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(IPMColors.green.opacity(0.12))
                        .frame(height: 10)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [IPMColors.greenDark, IPMColors.greenLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(maxWidth: .infinity)
                                .mask(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .frame(width: max(36, intensity * 280), height: 10)
                                }
                        }
                }
                .padding(16)
                .background(dashboardGlassBackground)
            }
        }
    }

    private var dashboardGlassBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                IPMColors.glassWhite.opacity(0.3),
                                .clear,
                                IPMColors.glassGreen.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(scheme == .dark ? 0.08 : 0.26), lineWidth: 1)
            )
    }

    private func roomHeatmapBackground(intensity: Double) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                IPMColors.glassWhite.opacity(0.24 + (intensity * 0.16)),
                                .clear,
                                IPMColors.green.opacity(0.1 + (intensity * 0.28))
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(scheme == .dark ? 0.08 : 0.26), lineWidth: 1)
            )
            .shadow(color: IPMColors.green.opacity(0.08 + (intensity * 0.12)), radius: 18, y: 10)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(IPMColors.brownMid)
        }
    }

    private func dashboardSummaryStat(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(IPMColors.brownMid)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial.opacity(0.76))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(scheme == .dark ? 0.06 : 0.22), lineWidth: 1)
                )
        )
    }

    private func dashboardTinyMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(IPMColors.brownMid)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(scheme == .dark ? 0.06 : 0.2), lineWidth: 1)
                )
        )
    }

    private func dashboardFindingChip(_ finding: DashboardFindingCount) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(IPMColors.green.opacity(0.88))
                .frame(width: 7, height: 7)
            Text(finding.name)
                .lineLimit(1)
            Text("\(finding.count)")
                .fontWeight(.bold)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.regularMaterial.opacity(0.7))
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(scheme == .dark ? 0.08 : 0.2), lineWidth: 1)
                )
        )
    }

    private func dashboardIntensityOrb(intensity: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(0.92),
                        IPMColors.greenLight.opacity(0.55 + (intensity * 0.3)),
                        IPMColors.green.opacity(0.55 + (intensity * 0.22))
                    ],
                    center: .center,
                    startRadius: 2,
                    endRadius: 22
                )
            )
            .frame(width: 24, height: 24)
            .shadow(color: IPMColors.green.opacity(0.22 + (intensity * 0.2)), radius: 12, y: 4)
    }

    private func dashboardMenuPill<MenuContent: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> MenuContent
    ) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.regularMaterial.opacity(0.76))
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(scheme == .dark ? 0.08 : 0.22), lineWidth: 1)
                    )
            )
        }
    }

    private var activeOverviewTitle: String {
        switch comparisonMode {
        case .rooms:
            if let room = roomCards.first {
                return "\(room.floorName) \(ipmLocalized(appLanguage, de: "führt gerade", en: "is leading right now"))"
            }
            return ipmLocalized(appLanguage, de: "Raumvergleich aktiv", en: "Room comparison active")
        case .traps:
            if let trap = filteredTrapSummaries.first {
                return "\(ipmLocalized(appLanguage, de: "Falle", en: "Trap")) \(trap.trap.nummer) \(ipmLocalized(appLanguage, de: "sticht heraus", en: "stands out"))"
            }
            return ipmLocalized(appLanguage, de: "Fallenvergleich aktiv", en: "Trap comparison active")
        case .insects:
            if let insect = insectCards.first {
                return insect.name
            }
            return ipmLocalized(appLanguage, de: "Insektenvergleich aktiv", en: "Insect comparison active")
        }
    }

    private var activeOverviewSubtitle: String {
        switch comparisonMode {
        case .rooms:
            return ipmLocalized(
                appLanguage,
                de: "Die Heatmap zeigt dir sofort, welcher Raum im aktuellen Filter bei \(selectedMetric.title(language: appLanguage).lowercased()) auffällt.",
                en: "The heatmap instantly shows which room stands out for the current filter and metric."
            )
        case .traps:
            return ipmLocalized(
                appLanguage,
                de: "Vergleiche jede Falle nach Typ, Befund, Klima und Fälligkeit direkt in einer Liste.",
                en: "Compare every trap by type, findings, climate, and urgency in one list."
            )
        case .insects:
            return ipmLocalized(
                appLanguage,
                de: "Sieh sofort, welches Insekt wo sitzt und welche Räume oder Fallen am stärksten betroffen sind.",
                en: "See immediately which insect appears where and which rooms or traps are hit the most."
            )
        }
    }

    private var sectionSubtitle: String {
        switch comparisonMode {
        case .rooms:
            return ipmLocalized(appLanguage, de: "Heatmap pro Raum im aktuellen Filter.", en: "Heatmap per room for the active filter.")
        case .traps:
            return ipmLocalized(appLanguage, de: "Jede Falle direkt vergleichbar.", en: "Every trap directly comparable.")
        case .insects:
            return ipmLocalized(appLanguage, de: "Alle Insekten nach Verteilung und Last.", en: "All insects by spread and load.")
        }
    }

    private var availableTrapTypes: [TrapType] {
        let trapTypes = Set(snapshot?.trapSummaries.map(\.trap.typ) ?? [])
        return TrapType.allCases.filter { trapTypes.contains($0) }
    }

    private var availableInsects: [String] {
        (snapshot?.insectSummaries.map(\.name) ?? []).sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    private var selectedClientTitle: String {
        guard selectedClientId != allClientsKey else {
            return ipmLocalized(appLanguage, de: "Alle Kunden", en: "All clients")
        }
        return snapshot?.clients.first(where: { $0.id == selectedClientId })?.name
            ?? ipmLocalized(appLanguage, de: "Kunde", en: "Client")
    }

    private var selectedTrapTypeTitle: String {
        guard selectedTrapType != allTrapTypesKey else {
            return ipmLocalized(appLanguage, de: "Alle Fallentypen", en: "All trap types")
        }
        return TrapType(rawValue: selectedTrapType)?.localizedName(language: appLanguage)
            ?? ipmLocalized(appLanguage, de: "Fallentyp", en: "Trap type")
    }

    private var selectedInsectTitle: String {
        guard selectedInsect != allInsectsKey else {
            return ipmLocalized(appLanguage, de: "Alle Insekten", en: "All insects")
        }
        return selectedInsect
    }

    private var filteredTrapSummaries: [DashboardTrapSummary] {
        guard let snapshot else { return [] }
        return snapshot.trapSummaries
            .filter { trap in
                if selectedClientId != allClientsKey && trap.clientId != selectedClientId {
                    return false
                }
                if selectedTrapType != allTrapTypesKey && trap.trap.typ.rawValue != selectedTrapType {
                    return false
                }
                if selectedInsect != allInsectsKey && (trap.insectCounts[selectedInsect] ?? 0) == 0 {
                    return false
                }
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let needle = searchText.lowercased()
                    let haystacks = [
                        trap.clientName.lowercased(),
                        trap.floorName.lowercased(),
                        trap.trap.nummer.lowercased(),
                        trap.trap.typ.localizedName(language: appLanguage).lowercased()
                    ] + trap.insectCounts.keys.map { $0.lowercased() }
                    return haystacks.contains { $0.contains(needle) }
                }
                return true
            }
            .sorted { lhs, rhs in
                let left = trapMetricValue(for: lhs)
                let right = trapMetricValue(for: rhs)
                if left == right {
                    return lhs.trap.nummer.localizedStandardCompare(rhs.trap.nummer) == .orderedAscending
                }
                return left > right
            }
    }

    private var roomCards: [DashboardRoomCard] {
        let grouped = Dictionary(grouping: filteredTrapSummaries, by: \.roomKey)
        return grouped.compactMap { roomKey, traps in
            guard let first = traps.first else { return nil }
            let inspectionCount = traps.reduce(0) { $0 + $1.inspectionCount }
            let topFindingsMap = traps.reduce(into: [String: Int]()) { partialResult, trap in
                for (name, count) in trap.insectCounts where count > 0 {
                    partialResult[name, default: 0] += count
                }
            }
            let topFindings = topFindingsMap
                .sorted {
                    if $0.value == $1.value {
                        return $0.key.localizedStandardCompare($1.key) == .orderedAscending
                    }
                    return $0.value > $1.value
                }
                .prefix(3)
                .map { DashboardFindingCount(name: $0.key, count: $0.value) }

            let temperatures = traps.compactMap(\.latestTemperature)
            let humidityValues = traps.compactMap(\.latestHumidity)
            let dueCount = traps.filter { $0.trap.faelligkeitStatus != .ok }.count

            return DashboardRoomCard(
                id: roomKey,
                clientName: first.clientName,
                floorName: first.floorName,
                trapCount: traps.count,
                inspectionCount: inspectionCount,
                totalFindings: topFindingsMap.values.reduce(0, +),
                averageTemperature: temperatures.isEmpty ? nil : temperatures.reduce(0, +) / Double(temperatures.count),
                averageHumidity: humidityValues.isEmpty ? nil : humidityValues.reduce(0, +) / Double(humidityValues.count),
                urgencyScore: traps.reduce(0) { $0 + urgencyValue(for: $1.trap) },
                dueCount: dueCount,
                topFindings: topFindings,
                insectCounts: topFindingsMap
            )
        }
        .sorted { lhs, rhs in
            let left = roomMetricValue(for: lhs)
            let right = roomMetricValue(for: rhs)
            if left == right {
                return lhs.floorName.localizedStandardCompare(rhs.floorName) == .orderedAscending
            }
            return left > right
        }
    }

    private var insectCards: [DashboardInsectCard] {
        var grouped: [String: (total: Int, rooms: [String: Int], traps: [String: Int], roomIds: Set<String>, trapIds: Set<String>)] = [:]
        for trap in filteredTrapSummaries {
            for (name, count) in trap.insectCounts where count > 0 {
                grouped[name, default: (0, [:], [:], [], [])].total += count
                grouped[name, default: (0, [:], [:], [], [])].rooms["\(trap.clientName) · \(trap.floorName)", default: 0] += count
                grouped[name, default: (0, [:], [:], [], [])].traps["\(trap.floorName) · \(trap.trap.nummer)", default: 0] += count
                grouped[name, default: (0, [:], [:], [], [])].roomIds.insert(trap.roomKey)
                grouped[name, default: (0, [:], [:], [], [])].trapIds.insert(trap.id)
            }
        }

        return grouped.map { name, value in
            let topRoom = value.rooms.max(by: { $0.value < $1.value })
            let topTrap = value.traps.max(by: { $0.value < $1.value })
            return DashboardInsectCard(
                id: name,
                name: name,
                totalCount: value.total,
                roomCount: value.roomIds.count,
                trapCount: value.trapIds.count,
                topRoomName: topRoom?.key,
                topRoomCount: topRoom?.value ?? 0,
                topTrapName: topTrap?.key,
                topTrapCount: topTrap?.value ?? 0
            )
        }
        .sorted {
            if $0.totalCount == $1.totalCount {
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            return $0.totalCount > $1.totalCount
        }
    }

    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return ipmLocalized(appLanguage, de: "Guten Morgen", en: "Good morning") }
        if hour < 18 { return ipmLocalized(appLanguage, de: "Guten Tag", en: "Good afternoon") }
        return ipmLocalized(appLanguage, de: "Guten Abend", en: "Good evening")
    }

    private func trapMetricValue(for trap: DashboardTrapSummary) -> Double {
        switch selectedMetric {
        case .findings:
            if selectedInsect != allInsectsKey {
                return Double(trap.insectCounts[selectedInsect] ?? 0)
            }
            return Double(trap.latestFindings)
        case .temperature:
            return trap.latestTemperature ?? 0
        case .humidity:
            return trap.latestHumidity ?? 0
        case .urgency:
            return urgencyValue(for: trap.trap)
        }
    }

    private func roomMetricValue(for room: DashboardRoomCard) -> Double {
        switch selectedMetric {
        case .findings:
            if selectedInsect != allInsectsKey {
                return Double(room.insectCounts[selectedInsect] ?? 0)
            }
            return Double(room.totalFindings)
        case .temperature:
            return room.averageTemperature ?? 0
        case .humidity:
            return room.averageHumidity ?? 0
        case .urgency:
            return room.urgencyScore
        }
    }

    private func urgencyValue(for trap: Trap) -> Double {
        switch trap.faelligkeitStatus {
        case .ueberfaellig: return 100
        case .bald: return 65
        case .ok: return 20
        }
    }

    private func normalizedRoomValue(for room: DashboardRoomCard) -> Double {
        let maxValue = roomCards.map(roomMetricValue(for:)).max() ?? 1
        guard maxValue > 0 else { return 0.14 }
        return max(0.14, min(1, roomMetricValue(for: room) / maxValue))
    }

    private func normalizedTrapValue(for trap: DashboardTrapSummary) -> Double {
        let maxValue = filteredTrapSummaries.map(trapMetricValue(for:)).max() ?? 1
        guard maxValue > 0 else { return 0.14 }
        return max(0.14, min(1, trapMetricValue(for: trap) / maxValue))
    }

    private func normalizedInsectValue(for insect: DashboardInsectCard) -> Double {
        let maxValue = Double(insectCards.map(\.totalCount).max() ?? 1)
        guard maxValue > 0 else { return 0.14 }
        return max(0.14, min(1, Double(insect.totalCount) / maxValue))
    }

    private func roomMetricValueText(_ room: DashboardRoomCard) -> String {
        switch selectedMetric {
        case .findings:
            if selectedInsect != allInsectsKey {
                let value = room.insectCounts[selectedInsect] ?? 0
                return "\(value)×"
            }
            return "\(room.totalFindings)"
        case .temperature:
            return room.averageTemperature.map { "\(String(format: "%.1f", $0)) °C" } ?? "—"
        case .humidity:
            return room.averageHumidity.map { "\(String(format: "%.0f", $0)) %" } ?? "—"
        case .urgency:
            return "\(room.dueCount) \(ipmLocalized(appLanguage, de: "fällig", en: "due"))"
        }
    }

    private func trapMetricValueText(_ trap: DashboardTrapSummary) -> String {
        switch selectedMetric {
        case .findings:
            if selectedInsect != allInsectsKey {
                return "\((trap.insectCounts[selectedInsect] ?? 0))×"
            }
            return "\(trap.latestFindings)"
        case .temperature:
            return trap.latestTemperature.map { "\(String(format: "%.1f", $0)) °C" } ?? "—"
        case .humidity:
            return trap.latestHumidity.map { "\(String(format: "%.0f", $0)) %" } ?? "—"
        case .urgency:
            return trap.trap.faelligkeitStatus.label(language: appLanguage)
        }
    }

    private func loadDashboard(forceRefresh: Bool = false) async {
        if forceRefresh {
            snapshot = nil
        }
        isLoading = true
        errorMessage = nil

        do {
            snapshot = try await FirestoreService.shared.fetchDashboardSnapshot()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
