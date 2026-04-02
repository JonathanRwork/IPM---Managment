import SwiftUI
import FirebaseAuth

private enum DashboardDueRange: String, CaseIterable {
    case today
    case week
    case month
}

private enum DashboardAnalysisFocus: String, CaseIterable {
    case findings
    case temperature
    case humidity
    case climateRisk

    func title(language: String) -> String {
        switch self {
        case .findings:
            return ipmLocalized(language, de: "Befunde", en: "Findings")
        case .temperature:
            return ipmLocalized(language, de: "Temperatur", en: "Temperature")
        case .humidity:
            return ipmLocalized(language, de: "Feuchte", en: "Humidity")
        case .climateRisk:
            return ipmLocalized(language, de: "Klimarisiko", en: "Climate risk")
        }
    }

    var icon: String {
        switch self {
        case .findings: return "ant.fill"
        case .temperature: return "thermometer.medium"
        case .humidity: return "humidity.fill"
        case .climateRisk: return "waveform.path.ecg"
        }
    }
}

private enum DashboardRoomSort: String, CaseIterable {
    case impact
    case findings
    case temperature
    case humidity

    func title(language: String) -> String {
        switch self {
        case .impact:
            return ipmLocalized(language, de: "Wirkung", en: "Impact")
        case .findings:
            return ipmLocalized(language, de: "Befunde", en: "Findings")
        case .temperature:
            return ipmLocalized(language, de: "Temperatur", en: "Temperature")
        case .humidity:
            return ipmLocalized(language, de: "Feuchte", en: "Humidity")
        }
    }
}

private struct DashboardWarningItem: Identifiable {
    let id: String
    let title: String
    let message: String
    let color: Color
    let icon: String
}

private struct DashboardClientBenchmark: Identifiable {
    let clientId: String
    let clientName: String
    let roomCount: Int
    let findingsAverage: Double
    let humidityAverage: Double
    let riskScore: Double

    var id: String { clientId }
}

private enum DashboardDestination: String, Hashable, CaseIterable {
    case rooms
    case due
    case clients
    case traps

    func title(language: String) -> String {
        switch self {
        case .rooms:
            return ipmLocalized(language, de: "Räume", en: "Rooms")
        case .due:
            return ipmLocalized(language, de: "Fälligkeiten", en: "Due Items")
        case .clients:
            return ipmLocalized(language, de: "Kunden", en: "Clients")
        case .traps:
            return ipmLocalized(language, de: "Fallen", en: "Traps")
        }
    }

    var icon: String {
        switch self {
        case .rooms: return "map.fill"
        case .due: return "clock.fill"
        case .clients: return "building.2.fill"
        case .traps: return "square.grid.2x2.fill"
        }
    }
}

// MARK: - Main Tab
struct MainTabView: View {
    @EnvironmentObject var auth: AuthManager
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
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    private let allClientsFilterKey = "__all_clients__"
    @State private var clients: [Client] = []
    @State private var roomSummaries: [DashboardRoomSummary] = []
    @State private var dueItems: [DueTrapItem] = []
    @AppStorage("selectedClientFilterId") private var selectedClientId: String = "__all_clients__"
    @State private var isLoading = true
    @State private var navigationPath = NavigationPath()
    @AppStorage("dashboardDueRange") private var dueRangeRaw = DashboardDueRange.week.rawValue
    @AppStorage("dashboardAnalysisFocus") private var analysisFocusRaw = DashboardAnalysisFocus.findings.rawValue
    @AppStorage("dashboardRoomSort") private var roomSortRaw = DashboardRoomSort.impact.rawValue
    @State private var selectedRoomId: String?

    private var dueRange: DashboardDueRange {
        DashboardDueRange(rawValue: dueRangeRaw) ?? .week
    }
    private var analysisFocus: DashboardAnalysisFocus {
        DashboardAnalysisFocus(rawValue: analysisFocusRaw) ?? .findings
    }
    private var roomSort: DashboardRoomSort {
        DashboardRoomSort(rawValue: roomSortRaw) ?? .impact
    }

    private var clientScopedDueItems: [DueTrapItem] {
        guard selectedClientId != allClientsFilterKey else { return dueItems }
        return dueItems.filter { $0.clientId == selectedClientId }
    }

    private var filteredDueItems: [DueTrapItem] {
        let monthLimit = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        let weekLimit = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        switch dueRange {
        case .today:
            return clientScopedDueItems.filter { $0.trap.faelligkeitStatus == .ueberfaellig || Calendar.current.isDateInToday($0.trap.naechstePruefung) }
        case .week:
            return clientScopedDueItems.filter { $0.trap.faelligkeitStatus == .ueberfaellig || $0.trap.naechstePruefung <= weekLimit }
        case .month:
            return clientScopedDueItems.filter { $0.trap.faelligkeitStatus == .ueberfaellig || $0.trap.naechstePruefung <= monthLimit }
        }
    }

    private var filteredRoomSummaries: [DashboardRoomSummary] {
        guard selectedClientId != allClientsFilterKey else { return roomSummaries }
        return roomSummaries.filter { $0.clientId == selectedClientId }
    }

    private var visibleClientCount: Int {
        selectedClientId == allClientsFilterKey ? clients.count : (clients.contains { $0.id == selectedClientId } ? 1 : 0)
    }

    private var criticalCount: Int { clientScopedDueItems.filter { $0.trap.faelligkeitStatus == .ueberfaellig }.count }
    private var dueTodayCount: Int {
        clientScopedDueItems
            .filter { $0.trap.faelligkeitStatus != .ueberfaellig }
            .filter { Calendar.current.isDateInToday($0.trap.naechstePruefung) }
            .count
    }
    private var dueThisWeekCount: Int {
        let limit = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return clientScopedDueItems
            .filter { $0.trap.faelligkeitStatus != .ueberfaellig }
            .filter { !Calendar.current.isDateInToday($0.trap.naechstePruefung) }
            .filter { $0.trap.naechstePruefung <= limit }
            .count
    }
    private var dueThisMonthCount: Int {
        let limit = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return clientScopedDueItems
            .filter { $0.trap.faelligkeitStatus != .ueberfaellig }
            .filter { !Calendar.current.isDateInToday($0.trap.naechstePruefung) }
            .filter { $0.trap.naechstePruefung <= limit }
            .count
    }
    private var dueMonthRemainderCount: Int {
        max(dueThisMonthCount - dueThisWeekCount, 0)
    }
    private var totalTrapCountInScope: Int { clientScopedDueItems.count }
    private var roomCountInScope: Int { filteredRoomSummaries.count }
    private var nextDueDateText: String {
        guard let nextItem = prioritizedDueItems.first else {
            return ipmLocalized(appLanguage, de: "Keine offenen Fälligkeiten", en: "No open due items")
        }

        if nextItem.trap.faelligkeitStatus == .ueberfaellig {
            return ipmLocalized(appLanguage, de: "Sofort prüfen", en: "Check immediately")
        }

        return nextItem.trap.naechstePruefung.formatted(date: .abbreviated, time: .omitted)
    }
    private var dueSectionTitle: String {
        if criticalCount > 0 {
            return ipmLocalized(appLanguage, de: "Dringende Aufgaben", en: "Urgent tasks")
        }
        if dueTodayCount > 0 {
            return ipmLocalized(appLanguage, de: "Heute im Fokus", en: "Today's focus")
        }
        return ipmLocalized(appLanguage, de: "Nächste Fälligkeiten", en: "Upcoming due items")
    }
    private var dashboardStatusTitle: String {
        if criticalCount > 0 {
            return ipmLocalized(appLanguage, de: "Akuter Handlungsbedarf", en: "Immediate action needed")
        }
        if dueTodayCount > 0 {
            return ipmLocalized(appLanguage, de: "Heute einplanen", en: "Schedule for today")
        }
        if filteredDueItems.isEmpty {
            return ipmLocalized(appLanguage, de: "Alles im Plan", en: "Everything on track")
        }
        return ipmLocalized(appLanguage, de: "Nächste Einsätze im Blick", en: "Upcoming visits in view")
    }
    private var prioritizedRooms: [DashboardRoomSummary] {
        filteredRoomSummaries.sorted { lhs, rhs in
            let left = sortValue(for: lhs)
            let right = sortValue(for: rhs)
            if left == right {
                return lhs.floor.name.localizedStandardCompare(rhs.floor.name) == .orderedAscending
            }
            return left > right
        }
    }
    private var selectedRoomSummary: DashboardRoomSummary? {
        if let selectedRoomId, let room = prioritizedRooms.first(where: { $0.id == selectedRoomId }) {
            return room
        }
        return prioritizedRooms.first
    }
    private var topComparisonRooms: [DashboardRoomSummary] {
        Array(prioritizedRooms.prefix(6))
    }
    private var warningItems: [DashboardWarningItem] {
        var items: [DashboardWarningItem] = []
        if let hottestRiskRoom = prioritizedRooms.first(where: { climateRiskScore(for: $0) >= 18 }) {
            items.append(
                DashboardWarningItem(
                    id: "risk_\(hottestRiskRoom.id)",
                    title: ipmLocalized(appLanguage, de: "Akutes Klimarisiko", en: "Acute climate risk"),
                    message: ipmLocalized(
                        appLanguage,
                        de: "\(hottestRiskRoom.floor.name): hohe Feuchte/Temperatur treffen auf aktive Befunde.",
                        en: "\(hottestRiskRoom.floor.name): high humidity/temperature is coinciding with active findings."
                    ),
                    color: IPMColors.critical,
                    icon: "exclamationmark.triangle.fill"
                )
            )
        }
        if let risingHumidityRoom = prioritizedRooms.first(where: { ($0.humidityDelta ?? 0) >= 5 }) {
            items.append(
                DashboardWarningItem(
                    id: "humidity_\(risingHumidityRoom.id)",
                    title: ipmLocalized(appLanguage, de: "Feuchte steigt", en: "Humidity rising"),
                    message: ipmLocalized(
                        appLanguage,
                        de: "\(risingHumidityRoom.floor.name): Feuchteanstieg um \(formatSigned(risingHumidityRoom.humidityDelta ?? 0, digits: 0))%. Ursache prüfen.",
                        en: "\(risingHumidityRoom.floor.name): humidity is up \(formatSigned(risingHumidityRoom.humidityDelta ?? 0, digits: 0))%. Check the cause."
                    ),
                    color: IPMColors.warning,
                    icon: "humidity.fill"
                )
            )
        }
        if let improvingRoom = prioritizedRooms.first(where: { ($0.findingsDelta ?? 0) <= -1 }) {
            items.append(
                DashboardWarningItem(
                    id: "improving_\(improvingRoom.id)",
                    title: ipmLocalized(appLanguage, de: "Maßnahmen wirken", en: "Measures are working"),
                    message: ipmLocalized(
                        appLanguage,
                        de: "\(improvingRoom.floor.name): Befunde sinken um \(formatSigned(improvingRoom.findingsDelta ?? 0, digits: 0)).",
                        en: "\(improvingRoom.floor.name): findings are down \(formatSigned(improvingRoom.findingsDelta ?? 0, digits: 0))."
                    ),
                    color: IPMColors.ok,
                    icon: "checkmark.seal.fill"
                )
            )
        }
        return Array(items.prefix(3))
    }
    private var clientBenchmarks: [DashboardClientBenchmark] {
        let grouped = Dictionary(grouping: filteredRoomSummaries, by: \.clientId)
        return grouped.compactMap { clientId, rooms in
            guard let first = rooms.first else { return nil }
            let avgFindings = rooms.map(\.averageFindings).reduce(0, +) / Double(max(rooms.count, 1))
            let humidityValues = rooms.compactMap(\.latestHumidity)
            let avgHumidity = humidityValues.isEmpty ? 0 : humidityValues.reduce(0, +) / Double(humidityValues.count)
            let risk = rooms.map(climateRiskScore(for:)).reduce(0, +) / Double(max(rooms.count, 1))
            return DashboardClientBenchmark(
                clientId: clientId,
                clientName: first.clientName,
                roomCount: rooms.count,
                findingsAverage: avgFindings,
                humidityAverage: avgHumidity,
                riskScore: risk
            )
        }
        .sorted { lhs, rhs in
            if lhs.riskScore == rhs.riskScore {
                return lhs.clientName.localizedStandardCompare(rhs.clientName) == .orderedAscending
            }
            return lhs.riskScore > rhs.riskScore
        }
    }
    private var selectedRoomImpactText: String {
        guard let room = selectedRoomSummary else {
            return ipmLocalized(appLanguage, de: "Noch keine Vergleichsdaten verfügbar.", en: "No comparison data available yet.")
        }
        if let humidity = room.latestHumidity, humidity >= 65, room.latestFindings > 0 {
            return ipmLocalized(
                appLanguage,
                de: "Hohe Feuchte von \(formatNumber(humidity, digits: 0))% trifft auf aktive Befunde. Diese Bedingungen begünstigen Schädlingsdruck.",
                en: "High humidity of \(formatNumber(humidity, digits: 0))% coincides with active findings. These conditions can increase pest pressure."
            )
        }
        if let humidityDelta = room.humidityDelta, let findingsDelta = room.findingsDelta, humidityDelta > 4, findingsDelta > 0 {
            return ipmLocalized(
                appLanguage,
                de: "Steigende Feuchte (+\(formatSigned(humidityDelta, digits: 0))) läuft mit mehr Befunden zusammen. Raum kontrollieren und Ursache prüfen.",
                en: "Humidity is rising (\(formatSigned(humidityDelta, digits: 0))) together with more findings. Reinspect the room and check the cause."
            )
        }
        if let temperatureDelta = room.temperatureDelta, let findingsDelta = room.findingsDelta, temperatureDelta > 1.5, findingsDelta > 0 {
            return ipmLocalized(
                appLanguage,
                de: "Wärmere Bedingungen (\(formatSigned(temperatureDelta, digits: 1)) °C) gehen hier mit höherer Aktivität einher.",
                en: "Warmer conditions (\(formatSigned(temperatureDelta, digits: 1)) °C) are coinciding with higher activity here."
            )
        }
        if let findingsDelta = room.findingsDelta, findingsDelta < 0 {
            return ipmLocalized(
                appLanguage,
                de: "Die Befunde sinken um \(formatSigned(findingsDelta, digits: 0)). Maßnahmen zeigen Wirkung.",
                en: "Findings are down by \(formatSigned(findingsDelta, digits: 0)). Current measures are having an effect."
            )
        }
        return ipmLocalized(
            appLanguage,
            de: "Der Raum ist stabil. Temperatur, Feuchte und Befunde weiter beobachten.",
            en: "This room is stable. Keep monitoring temperature, humidity, and findings."
        )
    }
    private var prioritizedDueItems: [DueTrapItem] {
        filteredDueItems.sorted { lhs, rhs in
            let leftPriority = duePriority(for: lhs.trap.naechstePruefung, status: lhs.trap.faelligkeitStatus)
            let rightPriority = duePriority(for: rhs.trap.naechstePruefung, status: rhs.trap.faelligkeitStatus)
            if leftPriority == rightPriority {
                return lhs.trap.naechstePruefung < rhs.trap.naechstePruefung
            }
            return leftPriority < rightPriority
        }
    }

    private var selectedClientDisplayName: String {
        guard selectedClientId != allClientsFilterKey else {
            return ipmLocalized(appLanguage, de: "Alle Kunden", en: "All clients")
        }
        return clients.first(where: { $0.id == selectedClientId })?.name
            ?? ipmLocalized(appLanguage, de: "Kunde wählen", en: "Select client")
    }

    private var focusSummary: String {
        if criticalCount > 0 {
            return ipmLocalized(
                appLanguage,
                de: "\(criticalCount) überfällig. Diese Räume zuerst anfahren.",
                en: "\(criticalCount) overdue. Visit these rooms first."
            )
        }
        if dueTodayCount > 0 {
            return ipmLocalized(
                appLanguage,
                de: "\(dueTodayCount) heute fällig. Tagesroute danach priorisieren.",
                en: "\(dueTodayCount) due today. Prioritize the route around them."
            )
        }
        return ipmLocalized(
            appLanguage,
            de: "Keine akuten Punkte. Nächste Fälligkeiten im Blick behalten.",
            en: "No critical items. Keep an eye on upcoming due items."
        )
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Dashboard")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                                Text(dashboardStatusTitle)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(IPMColors.brownMid)
                            }
                            Spacer()
                            NavigationLink(value: DashboardDestination.due) {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(IPMColors.green)
                                    .frame(width: 42, height: 42)
                                    .background(AdaptiveColor.card(scheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .ipmFlowEntrance(delay: 0.02)

                        HStack {
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
                                HStack(spacing: 8) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(selectedClientDisplayName)
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(1)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundStyle(IPMColors.greenDark)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AdaptiveColor.card(scheme))
                                .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .ipmFlowEntrance(delay: 0.04)

                        HStack(spacing: 8) {
                            ForEach(DashboardDueRange.allCases, id: \.rawValue) { range in
                                dueRangeChip(range)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .ipmFlowEntrance(delay: 0.06)

                        DashboardSummaryBar(
                            appLanguage: appLanguage,
                            roomCount: roomCountInScope,
                            trapCount: totalTrapCountInScope,
                            overdueCount: criticalCount,
                            todayCount: dueTodayCount,
                            weekCount: dueThisWeekCount,
                            nextDueText: nextDueDateText,
                            focusTitle: analysisFocus.title(language: appLanguage),
                            focusSummary: selectedRoomImpactText
                        )
                        .padding(.horizontal, 20)
                        .ipmFlowEntrance(delay: 0.08)

                        if !warningItems.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(warningItems) { item in
                                    DashboardWarningCard(item: item)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        HStack(spacing: 10) {
                            Menu {
                                ForEach(DashboardAnalysisFocus.allCases, id: \.rawValue) { focus in
                                    Button(focus == analysisFocus ? "✓ \(focus.title(language: appLanguage))" : focus.title(language: appLanguage)) {
                                        analysisFocusRaw = focus.rawValue
                                    }
                                }
                            } label: {
                                dashboardFilterPill(
                                    icon: analysisFocus.icon,
                                    title: analysisFocus.title(language: appLanguage)
                                )
                            }

                            Menu {
                                ForEach(DashboardRoomSort.allCases, id: \.rawValue) { sort in
                                    Button(sort == roomSort ? "✓ \(sort.title(language: appLanguage))" : sort.title(language: appLanguage)) {
                                        roomSortRaw = sort.rawValue
                                    }
                                }
                            } label: {
                                dashboardFilterPill(
                                    icon: "arrow.up.arrow.down.circle",
                                    title: roomSort.title(language: appLanguage)
                                )
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        if !prioritizedRooms.isEmpty {
                            dashboardSectionHeader(
                                title: ipmLocalized(appLanguage, de: "Raumvergleich", en: "Room comparison"),
                                subtitle: ipmLocalized(appLanguage, de: "Direkter Vergleich nach \(analysisFocus.title(language: appLanguage))", en: "Direct comparison by \(analysisFocus.title(language: appLanguage))"),
                                destination: .rooms,
                                trailingText: ipmLocalized(appLanguage, de: "Alle Räume", en: "All rooms")
                            )
                            .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(Array(topComparisonRooms.enumerated()), id: \.element.id) { idx, room in
                                    NavigationLink(destination: FloorDetailView(floor: room.floor, clientId: room.clientId)) {
                                        DashboardRoomPriorityRow(
                                            summary: room,
                                            appLanguage: appLanguage,
                                            range: dueRange,
                                            focus: analysisFocus,
                                            isSelected: room.id == selectedRoomSummary?.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded {
                                        selectedRoomId = room.id
                                    })

                                    if idx < min(topComparisonRooms.count, 6) - 1 {
                                        Divider()
                                            .padding(.leading, 68)
                                            .padding(.trailing, 14)
                                    }
                                }
                            }
                            .ipmCard(padding: 0, cornerRadius: 16)
                            .padding(.horizontal, 20)

                            dashboardSectionHeader(
                                title: ipmLocalized(appLanguage, de: "Heatmap", en: "Heatmap"),
                                subtitle: ipmLocalized(appLanguage, de: "Schneller Überblick über Risikozonen", en: "Quick overview of risk zones"),
                                destination: .rooms,
                                trailingText: analysisFocus.title(language: appLanguage)
                            )
                            .padding(.horizontal, 20)

                            DashboardHeatmapGrid(
                                rooms: topComparisonRooms,
                                appLanguage: appLanguage,
                                focus: analysisFocus,
                                selectedRoomId: selectedRoomSummary?.id,
                                onSelect: { roomId in selectedRoomId = roomId }
                            )
                            .padding(.horizontal, 20)

                            if let selectedRoomSummary {
                                DashboardAnalyticsPanel(
                                    summary: selectedRoomSummary,
                                    appLanguage: appLanguage,
                                    focus: analysisFocus,
                                    impactText: selectedRoomImpactText
                                )
                                .padding(.horizontal, 20)
                            }
                        }

                        if clientBenchmarks.count > 1 {
                            dashboardSectionHeader(
                                title: ipmLocalized(appLanguage, de: "Kunden-Benchmark", en: "Client benchmark"),
                                subtitle: ipmLocalized(appLanguage, de: "Vergleich nach Raumzustand und Klima", en: "Comparison by room condition and climate"),
                                destination: .clients,
                                trailingText: ipmLocalized(appLanguage, de: "Alle Kunden", en: "All clients")
                            )
                            .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(Array(clientBenchmarks.prefix(5).enumerated()), id: \.element.id) { idx, benchmark in
                                    NavigationLink(destination: ClientListView()) {
                                        DashboardClientBenchmarkRow(
                                            benchmark: benchmark,
                                            appLanguage: appLanguage,
                                            bestRiskScore: clientBenchmarks.map(\.riskScore).min() ?? benchmark.riskScore,
                                            worstRiskScore: clientBenchmarks.map(\.riskScore).max() ?? benchmark.riskScore
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    if idx < min(clientBenchmarks.count, 5) - 1 {
                                        Divider()
                                            .padding(.leading, 14)
                                            .padding(.trailing, 14)
                                    }
                                }
                            }
                            .ipmCard(padding: 0, cornerRadius: 16)
                            .padding(.horizontal, 20)
                        }

                        if !prioritizedDueItems.isEmpty {
                            dashboardSectionHeader(
                                title: dueSectionTitle,
                                subtitle: ipmLocalized(appLanguage, de: "\(prioritizedDueItems.count) Einträge im gewählten Zeitraum", en: "\(prioritizedDueItems.count) items in the selected range"),
                                destination: .due,
                                trailingText: "\(ipmLocalized(appLanguage, de: "Alle", en: "All")) \(prioritizedDueItems.count)"
                            )
                            .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(Array(prioritizedDueItems.prefix(10).enumerated()), id: \.element.id) { idx, item in
                                    NavigationLink(destination: TrapDetailView(
                                        trap: item.trap,
                                        clientId: item.clientId,
                                        floorId: item.floorId
                                    )) {
                                        DashboardDueRow(item: item)
                                    }
                                    .buttonStyle(.plain)

                                    if idx < min(prioritizedDueItems.count, 10) - 1 {
                                        Divider()
                                            .padding(.leading, 34)
                                            .padding(.horizontal, 14)
                                    }
                                }
                            }
                            .ipmCard(padding: 0, cornerRadius: 16)
                            .padding(.horizontal, 20)
                        }

                        if selectedClientId != allClientsFilterKey && filteredRoomSummaries.isEmpty && filteredDueItems.isEmpty && !isLoading {
                            Text(ipmLocalized(appLanguage, de: "Für diesen Kunden sind aktuell keine Dashboard-Daten vorhanden.", en: "No dashboard data is currently available for this client."))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(IPMColors.brownMid)
                                .padding(.horizontal, 20)
                                .multilineTextAlignment(.center)
                        }

                        if !clients.isEmpty {
                            HStack {
                                Spacer()
                                NavigationLink(destination: ClientListView()) {
                                    Label(ipmLocalized(appLanguage, de: "Kunden verwalten", en: "Manage clients"), systemImage: "building.2")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(IPMColors.brownMid)
                                }
                                Spacer()
                            }
                        }

                        // Empty State
                        if clients.isEmpty && !isLoading {
                            IPMEmptyState(
                                icon: "ant.circle",
                                title: ipmLocalized(appLanguage, de: "Noch keine Daten", en: "No data yet"),
                                subtitle: ipmLocalized(appLanguage, de: "Lege zuerst Kunden und Räume an", en: "Create clients and rooms first")
                            )
                            .transition(.ipmFadeSlide)
                        }

                        Spacer().frame(height: 20)
                    }
                }
                .refreshable { await loadData() }

                if isLoading {
                    ProgressView().tint(IPMColors.green)
                }
            }
            .ipmNavigationBarHidden()
            .animation(.spring(response: 0.38, dampingFraction: 0.88), value: filteredDueItems.count)
            .animation(.spring(response: 0.38, dampingFraction: 0.88), value: filteredRoomSummaries.count)
            .animation(.spring(response: 0.34, dampingFraction: 0.9), value: selectedClientId)
            .task { await loadData() }
            .navigationDestination(for: DashboardDestination.self) { destination in
                switch destination {
                case .rooms:
                    RoomListView()
                case .due:
                    FaelligkeitenView()
                case .clients:
                    ClientListView()
                case .traps:
                    AllTrapsView()
                }
            }
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        let snapshot = try? await FirestoreService.shared.fetchDashboardSnapshot()
        clients = snapshot?.clients ?? []
        dueItems = snapshot?.trapItems ?? []
        roomSummaries = snapshot?.roomSummaries ?? []
        if selectedClientId != allClientsFilterKey, !clients.contains(where: { $0.id == selectedClientId }) {
            selectedClientId = allClientsFilterKey
        }
        if let selectedRoomId, !roomSummaries.contains(where: { $0.id == selectedRoomId }) {
            self.selectedRoomId = roomSummaries.first?.id
        } else if self.selectedRoomId == nil {
            self.selectedRoomId = roomSummaries.first?.id
        }
    }

    private func duePriority(for date: Date, status: FaelligkeitStatus) -> Int {
        if status == .ueberfaellig { return 0 }
        if Calendar.current.isDateInToday(date) { return 1 }
        let limit = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        if date <= limit { return 2 }
        return 3
    }

    private func title(for range: DashboardDueRange) -> String {
        switch range {
        case .today: return ipmLocalized(appLanguage, de: "Heute", en: "Today")
        case .week: return ipmLocalized(appLanguage, de: "Woche", en: "Week")
        case .month: return ipmLocalized(appLanguage, de: "Monat", en: "Month")
        }
    }

    private func dueRangeChip(_ range: DashboardDueRange) -> some View {
        let selected = dueRange == range
        return Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                dueRangeRaw = range.rawValue
            }
        } label: {
            Text(title(for: range))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? Color.white : IPMColors.greenDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(selected ? IPMColors.green : AdaptiveColor.card(scheme))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func dashboardSectionHeader(
        title: String,
        subtitle: String,
        destination: DashboardDestination,
        trailingText: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(IPMColors.brownMid)
            }
            Spacer()
            NavigationLink(value: destination) {
                Text(trailingText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(IPMColors.green)
            }
            .buttonStyle(.plain)
        }
    }

    private func roomPriorityValue(_ room: DashboardRoomSummary) -> Int {
        let inRangeCount: Int
        switch dueRange {
        case .today:
            inRangeCount = room.overdueCount + room.dueTodayCount
        case .week:
            inRangeCount = room.dueWeekCount
        case .month:
            inRangeCount = room.dueMonthCount
        }
        return (room.overdueCount * 100) + (room.dueTodayCount * 20) + (inRangeCount * 5) + room.totalTrapCount
    }

    private func sortValue(for room: DashboardRoomSummary) -> Double {
        switch roomSort {
        case .impact:
            return Double(roomPriorityValue(room)) + climateRiskScore(for: room)
        case .findings:
            return Double(room.latestFindings) + max(room.findingsDelta ?? 0, 0) * 4
        case .temperature:
            return room.latestTemperature ?? -.infinity
        case .humidity:
            return room.latestHumidity ?? -.infinity
        }
    }

    private func climateRiskScore(for room: DashboardRoomSummary) -> Double {
        let humidityPressure = max((room.latestHumidity ?? 0) - 60, 0) * 0.8
        let temperaturePressure = max((room.latestTemperature ?? 0) - 24, 0) * 1.2
        let findingsPressure = Double(room.latestFindings) * 2.5
        return humidityPressure + temperaturePressure + findingsPressure
    }

    private func dashboardFilterPill(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(IPMColors.greenDark)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AdaptiveColor.card(scheme))
        .clipShape(Capsule())
    }

    private func formatNumber(_ value: Double, digits: Int) -> String {
        String(format: "%.\(digits)f", value)
    }

    private func formatSigned(_ value: Double, digits: Int) -> String {
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.\(digits)f", value))"
    }

}

private struct DashboardSummaryBar: View {
    @Environment(\.colorScheme) var scheme
    let appLanguage: String
    let roomCount: Int
    let trapCount: Int
    let overdueCount: Int
    let todayCount: Int
    let weekCount: Int
    let nextDueText: String
    let focusTitle: String
    let focusSummary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ipmLocalized(appLanguage, de: "Heute / Nächster Einsatz", en: "Today / Next visit"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    Text(nextDueText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(IPMColors.brownMid)
                }
                Spacer()
                Text(overdueCount > 0 ? "\(overdueCount)" : "\(todayCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(overdueCount > 0 ? IPMColors.critical : IPMColors.warning)
            }

            Text("\(focusTitle): \(focusSummary)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(IPMColors.brownMid)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                metricCell(title: ipmLocalized(appLanguage, de: "Räume", en: "Rooms"), value: roomCount, color: IPMColors.green)
                metricCell(title: ipmLocalized(appLanguage, de: "Fallen", en: "Traps"), value: trapCount, color: IPMColors.brownMid)
                metricCell(title: ipmLocalized(appLanguage, de: "Heute", en: "Today"), value: todayCount, color: IPMColors.warning)
                metricCell(title: ipmLocalized(appLanguage, de: "7 Tage", en: "7 days"), value: weekCount + overdueCount, color: IPMColors.critical)
            }
        }
        .ipmCard(cornerRadius: 16)
    }

    private func metricCell(title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(IPMColors.brownMid)
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DashboardWarningCard: View {
    let item: DashboardWarningItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(item.color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(item.color)
                Text(item.message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(item.color.opacity(0.9))
            }
            Spacer()
        }
        .padding(12)
        .background(item.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct DashboardHeatmapGrid: View {
    @Environment(\.colorScheme) var scheme
    let rooms: [DashboardRoomSummary]
    let appLanguage: String
    let focus: DashboardAnalysisFocus
    let selectedRoomId: String?
    let onSelect: (String) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(rooms) { room in
                Button {
                    onSelect(room.id)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(tileColor(for: room))
                                .frame(width: 10, height: 10)
                            Spacer()
                            if room.id == selectedRoomId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(tileColor(for: room))
                            }
                        }
                        Text(room.floor.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                            .lineLimit(2)
                        Text(room.clientName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(IPMColors.brownMid)
                            .lineLimit(1)
                        Text(tileValue(for: room))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(tileColor(for: room))
                    }
                    .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                    .padding(12)
                    .background(tileColor(for: room).opacity(room.id == selectedRoomId ? 0.18 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(tileColor(for: room).opacity(room.id == selectedRoomId ? 0.7 : 0.15), lineWidth: 1.2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tileColor(for room: DashboardRoomSummary) -> Color {
        switch focus {
        case .findings:
            return room.latestFindings > 0 ? IPMColors.critical : IPMColors.ok
        case .temperature:
            return (room.latestTemperature ?? 0) >= 24 ? IPMColors.warning : IPMColors.ok
        case .humidity:
            return (room.latestHumidity ?? 0) >= 65 ? IPMColors.warning : IPMColors.ok
        case .climateRisk:
            let risk = Double(room.latestFindings) * 2.5 + max((room.latestTemperature ?? 0) - 24, 0) * 1.2 + max((room.latestHumidity ?? 0) - 60, 0) * 0.8
            return risk >= 18 ? IPMColors.critical : (risk >= 8 ? IPMColors.warning : IPMColors.ok)
        }
    }

    private func tileValue(for room: DashboardRoomSummary) -> String {
        switch focus {
        case .findings:
            return "\(room.latestFindings) \(ipmLocalized(appLanguage, de: "Bef.", en: "find."))"
        case .temperature:
            return room.latestTemperature.map { "\(String(format: "%.1f", $0))°C" } ?? "-"
        case .humidity:
            return room.latestHumidity.map { "\(String(format: "%.0f", $0))%" } ?? "-"
        case .climateRisk:
            let risk = Int(round(Double(room.latestFindings) * 2.5 + max((room.latestTemperature ?? 0) - 24, 0) * 1.2 + max((room.latestHumidity ?? 0) - 60, 0) * 0.8))
            return "\(risk)"
        }
    }
}

private struct DashboardRoomPriorityRow: View {
    @Environment(\.colorScheme) var scheme
    let summary: DashboardRoomSummary
    let appLanguage: String
    let range: DashboardDueRange
    let focus: DashboardAnalysisFocus
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accentColor.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Text(focusValueText)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                Text(focusLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(summary.floor.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    if summary.overdueCount > 0 {
                        Text("\(summary.overdueCount) \(ipmLocalized(appLanguage, de: "überfällig", en: "overdue"))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(IPMColors.critical)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(IPMColors.critical.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(summary.clientName)
                    .font(.system(size: 12))
                    .foregroundStyle(IPMColors.brownMid)
                HStack(spacing: 10) {
                    smallMetric(title: ipmLocalized(appLanguage, de: "Fallen", en: "Traps"), text: "\(summary.totalTrapCount)", color: IPMColors.brownMid)
                    smallMetric(title: ipmLocalized(appLanguage, de: "Befunde", en: "Findings"), text: "\(summary.latestFindings)", color: summary.latestFindings > 0 ? IPMColors.critical : IPMColors.ok)
                    if let nextInspection = summary.nextInspection {
                        Label(nextInspection.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(IPMColors.brownMid)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(IPMColors.brownMid)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(isSelected ? AdaptiveColor.cardSecondary(scheme) : Color.clear)
    }

    private var accentColor: Color {
        if summary.overdueCount > 0 { return IPMColors.critical }
        if focus == .findings, summary.latestFindings > 0 { return IPMColors.critical }
        if focus == .humidity, let latestHumidity = summary.latestHumidity, latestHumidity >= 65 { return IPMColors.warning }
        if focus == .temperature, let latestTemperature = summary.latestTemperature, latestTemperature >= 24 { return IPMColors.warning }
        if rangeCount > 0 { return IPMColors.warning }
        return IPMColors.green
    }

    private var rangeCount: Int {
        switch range {
        case .today:
            return summary.overdueCount + summary.dueTodayCount
        case .week:
            return summary.dueWeekCount
        case .month:
            return summary.dueMonthCount
        }
    }

    private var rangeLabel: String {
        switch range {
        case .today:
            return ipmLocalized(appLanguage, de: "heute", en: "today")
        case .week:
            return "7d"
        case .month:
            return "30d"
        }
    }

    private var focusValueText: String {
        switch focus {
        case .findings:
            return "\(summary.latestFindings)"
        case .temperature:
            guard let value = summary.latestTemperature else { return "-" }
            return String(format: "%.1f", value)
        case .humidity:
            guard let value = summary.latestHumidity else { return "-" }
            return String(format: "%.0f", value)
        case .climateRisk:
            return "\(Int(round(climateRisk)))"
        }
    }

    private var focusLabel: String {
        switch focus {
        case .findings:
            return ipmLocalized(appLanguage, de: "Bef.", en: "Find.")
        case .temperature:
            return "°C"
        case .humidity:
            return "%"
        case .climateRisk:
            return ipmLocalized(appLanguage, de: "Risiko", en: "Risk")
        }
    }

    private var climateRisk: Double {
        let humidityPressure = max((summary.latestHumidity ?? 0) - 60, 0) * 0.8
        let temperaturePressure = max((summary.latestTemperature ?? 0) - 24, 0) * 1.2
        let findingsPressure = Double(summary.latestFindings) * 2.5
        return humidityPressure + temperaturePressure + findingsPressure
    }

    private func smallMetric(title: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(IPMColors.brownMid)
            Text(text)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
        }
    }
}

private struct DashboardClientBenchmarkRow: View {
    @Environment(\.colorScheme) var scheme
    let benchmark: DashboardClientBenchmark
    let appLanguage: String
    let bestRiskScore: Double
    let worstRiskScore: Double

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accentColor.opacity(0.14))
                    .frame(width: 44, height: 44)
                Text(rankText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(benchmark.clientName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                HStack(spacing: 10) {
                    metric(label: ipmLocalized(appLanguage, de: "Räume", en: "Rooms"), value: "\(benchmark.roomCount)", color: IPMColors.brownMid)
                    metric(label: ipmLocalized(appLanguage, de: "Ø Befunde", en: "Avg findings"), value: String(format: "%.1f", benchmark.findingsAverage), color: IPMColors.critical)
                    metric(label: ipmLocalized(appLanguage, de: "Ø Feuchte", en: "Avg humidity"), value: String(format: "%.0f%%", benchmark.humidityAverage), color: IPMColors.green)
                }
            }
            Spacer()
            Text(String(format: "%.1f", benchmark.riskScore))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }

    private var accentColor: Color {
        if benchmark.riskScore >= bestRiskScore + ((worstRiskScore - bestRiskScore) * 0.66) { return IPMColors.critical }
        if benchmark.riskScore >= bestRiskScore + ((worstRiskScore - bestRiskScore) * 0.33) { return IPMColors.warning }
        return IPMColors.ok
    }

    private var rankText: String {
        if benchmark.riskScore == bestRiskScore {
            return "A"
        }
        if benchmark.riskScore == worstRiskScore {
            return "C"
        }
        return "B"
    }

    private func metric(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(IPMColors.brownMid)
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
        }
    }
}

private struct DashboardAnalyticsPanel: View {
    @Environment(\.colorScheme) var scheme
    let summary: DashboardRoomSummary
    let appLanguage: String
    let focus: DashboardAnalysisFocus
    let impactText: String

    private var focusSeries: [Double] {
        switch focus {
        case .findings: return summary.findingsSeries
        case .temperature: return summary.temperatureSeries
        case .humidity: return summary.humiditySeries
        case .climateRisk:
            let count = max(summary.findingsSeries.count, max(summary.temperatureSeries.count, summary.humiditySeries.count))
            guard count > 0 else { return [] }
            return Array(0..<count).map { index in
                let findings = summary.findingsSeries.indices.contains(index) ? summary.findingsSeries[index] : 0
                let temp = summary.temperatureSeries.indices.contains(index) ? summary.temperatureSeries[index] : 0
                let humidity = summary.humiditySeries.indices.contains(index) ? summary.humiditySeries[index] : 0
                return findings * 2.5 + max(temp - 24, 0) * 1.2 + max(humidity - 60, 0) * 0.8
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(summary.floor.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    Text(summary.clientName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(IPMColors.brownMid)
                }
                Spacer()
                if !focusSeries.isEmpty {
                    dashboardDeltaBadge
                }
            }

            if focusSeries.count >= 2 {
                DashboardSparklineCard(
                    title: focus.title(language: appLanguage),
                    values: focusSeries,
                    accentColor: accentColor,
                    currentText: currentValueText,
                    averageText: averageValueText,
                    deltaText: deltaText
                )
            }

            HStack(spacing: 10) {
                insightMetric(title: ipmLocalized(appLanguage, de: "Kontrollen", en: "Inspections"), value: "\(summary.inspectionCount)", color: IPMColors.brownMid)
                insightMetric(title: ipmLocalized(appLanguage, de: "Temp.", en: "Temp."), value: summary.latestTemperature.map { "\(String(format: "%.1f", $0))°C" } ?? "-", color: IPMColors.warning)
                insightMetric(title: ipmLocalized(appLanguage, de: "Feuchte", en: "Humidity"), value: summary.latestHumidity.map { "\(String(format: "%.0f", $0))%" } ?? "-", color: IPMColors.green)
            }

            Text(impactText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accentColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .ipmCard(cornerRadius: 16)
    }

    private var accentColor: Color {
        switch focus {
        case .findings: return summary.latestFindings > 0 ? IPMColors.critical : IPMColors.ok
        case .temperature: return IPMColors.warning
        case .humidity: return IPMColors.green
        case .climateRisk: return IPMColors.befund
        }
    }

    private var currentValueText: String {
        switch focus {
        case .findings: return "\(summary.latestFindings)"
        case .temperature: return summary.latestTemperature.map { "\(String(format: "%.1f", $0))°C" } ?? "-"
        case .humidity: return summary.latestHumidity.map { "\(String(format: "%.0f", $0))%" } ?? "-"
        case .climateRisk:
            let current = focusSeries.last ?? 0
            return String(format: "%.0f", current)
        }
    }

    private var averageValueText: String {
        switch focus {
        case .findings: return String(format: "%.1f", summary.averageFindings)
        case .temperature: return summary.averageTemperature.map { "\(String(format: "%.1f", $0))°C" } ?? "-"
        case .humidity: return summary.averageHumidity.map { "\(String(format: "%.0f", $0))%" } ?? "-"
        case .climateRisk:
            guard !focusSeries.isEmpty else { return "-" }
            return String(format: "%.0f", focusSeries.reduce(0, +) / Double(focusSeries.count))
        }
    }

    private var deltaText: String {
        switch focus {
        case .findings:
            return (summary.findingsDelta.map { signedText($0, suffix: "") }) ?? ipmLocalized(appLanguage, de: "keine Entwicklung", en: "no trend")
        case .temperature:
            return (summary.temperatureDelta.map { signedText($0, suffix: "°C") }) ?? ipmLocalized(appLanguage, de: "keine Entwicklung", en: "no trend")
        case .humidity:
            return (summary.humidityDelta.map { signedText($0, suffix: "%") }) ?? ipmLocalized(appLanguage, de: "keine Entwicklung", en: "no trend")
        case .climateRisk:
            guard focusSeries.count >= 2 else { return ipmLocalized(appLanguage, de: "keine Entwicklung", en: "no trend") }
            return signedText(focusSeries[focusSeries.count - 1] - focusSeries[focusSeries.count - 2], suffix: "")
        }
    }

    private var dashboardDeltaBadge: some View {
        Text(deltaText)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accentColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private func insightMetric(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(IPMColors.brownMid)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AdaptiveColor.cardSecondary(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func signedText(_ value: Double, suffix: String) -> String {
        let prefix = value > 0 ? "+" : ""
        if suffix.isEmpty {
            return "\(prefix)\(String(format: "%.1f", value))"
        }
        return "\(prefix)\(String(format: "%.1f", value))\(suffix)"
    }
}

private struct DashboardSparklineCard: View {
    @Environment(\.colorScheme) var scheme
    let title: String
    let values: [Double]
    let accentColor: Color
    let currentText: String
    let averageText: String
    let deltaText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
            DashboardSparkline(values: values)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .frame(height: 74)
            HStack(spacing: 14) {
                statBlock(title: "Current", value: currentText)
                Divider()
                statBlock(title: "Average", value: averageText)
                Divider()
                statBlock(title: "Delta", value: deltaText)
            }
        }
        .padding(12)
        .background(AdaptiveColor.cardSecondary(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(IPMColors.brownMid)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
        }
    }
}

private struct DashboardSparkline: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let range = max(maxValue - minValue, 1)

        for (index, value) in values.enumerated() {
            let x = rect.minX + (rect.width * CGFloat(index) / CGFloat(values.count - 1))
            let normalized = (value - minValue) / range
            let y = rect.maxY - CGFloat(normalized) * rect.height
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

// MARK: - Dashboard Due Row
struct DashboardDueRow: View {
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    let item: DueTrapItem

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.trap.faelligkeitStatus.color)
                .frame(width: 8, height: 8)
                .padding(.leading, 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.clientName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                Text("\(item.floorName) · \(ipmLocalized(appLanguage, de: "Falle", en: "Trap")) \(item.trap.nummer)")
                    .font(.system(size: 12))
                    .foregroundStyle(IPMColors.brownMid)
            }
            Spacer()
            Text(item.trap.naechstePruefung.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(item.trap.faelligkeitStatus.color)
                .padding(.trailing, 14)
        }
        .padding(.vertical, 10)
    }
}
