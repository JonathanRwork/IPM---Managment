import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

private enum TrapSortMode: String, CaseIterable, Identifiable {
    case number
    case dueDate
    case status

    var id: String { rawValue }

    func title(language: String) -> String {
        switch self {
        case .number: return ipmLocalized(language, de: "Nummer", en: "Number")
        case .dueDate: return ipmLocalized(language, de: "Prüftermin", en: "Due date")
        case .status: return ipmLocalized(language, de: "Status", en: "Status")
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

// MARK: - Floor Detail
struct FloorDetailView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    let clientId: String
    @State private var currentFloor: Floor
    @State private var traps: [Trap] = []
    @State private var showAddTrap = false
    @State private var showEditFloor = false
    @State private var showUpgradeAlert = false
    @State private var upgradeMessage = ""
    @AppStorage("trapSortMode") private var trapSortModeRaw = TrapSortMode.number.rawValue

    init(floor: Floor, clientId: String) {
        self.clientId = clientId
        _currentFloor = State(initialValue: floor)
    }

    private var trapSortMode: TrapSortMode {
        TrapSortMode(rawValue: trapSortModeRaw) ?? .number
    }

    private var displayedTraps: [Trap] {
        switch trapSortMode {
        case .number:
            return traps.sorted { $0.nummer.localizedStandardCompare($1.nummer) == .orderedAscending }
        case .dueDate:
            return traps.sorted { $0.naechstePruefung < $1.naechstePruefung }
        case .status:
            return traps.sorted { trapPriority($0) < trapPriority($1) }
        }
    }

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                roomProfileCard

                // Fallen Liste
                List {
                    Section {
                        if displayedTraps.isEmpty {
                            IPMEmptyState(
                                icon: "square.grid.2x2",
                                title: ipmLocalized(appLanguage, de: "Noch keine Fallen", en: "No traps yet"),
                                subtitle: ipmLocalized(appLanguage, de: "Lege die erste Falle für diesen Raum an.", en: "Create the first trap for this room.")
                            )
                            .listRowBackground(AdaptiveColor.card(scheme))
                        }

                        ForEach(displayedTraps) { trap in
                            NavigationLink(destination: TrapDetailView(trap: trap, clientId: clientId, floorId: currentFloor.id ?? "")) {
                                TrapListRow(trap: trap)
                            }
                            .listRowBackground(AdaptiveColor.card(scheme))
                            .listRowSeparatorTint(AdaptiveColor.cardSecondary(scheme))
                        }
                        .onDelete { indexSet in
                            Task {
                                for i in indexSet {
                                    let trap = displayedTraps[i]
                                    try? await FirestoreService.shared.deleteTrap(trap, clientId: clientId, floorId: currentFloor.id ?? "")
                                }
                                await loadTraps()
                            }
                        }

                        Button {
                            if let message = subscription.canAddTrap(currentCountForRoom: displayedTraps.count) {
                                upgradeMessage = message
                                showUpgradeAlert = true
                                return
                            }
                            showAddTrap = true
                        } label: {
                            Label(ipmLocalized(appLanguage, de: "Falle hinzufügen", en: "Add trap"), systemImage: "plus.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(subscription.canAddTrap(currentCountForRoom: displayedTraps.count) == nil ? IPMColors.green : IPMColors.brownMid)
                        }
                        .listRowBackground(AdaptiveColor.card(scheme))

                    } header: { SectionLabel("\(ipmLocalized(appLanguage, de: "Fallen", en: "Traps")) (\(displayedTraps.count))") }
                }
                .scrollContentBackground(.hidden)
                .background(AdaptiveColor.background(scheme))
            }
        }
        .navigationTitle(currentFloor.name)
        .ipmNavigationBarTitleDisplayModeInline()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(TrapSortMode.allCases) { mode in
                        Button(mode.title(language: appLanguage)) {
                            trapSortModeRaw = mode.rawValue
                        }
                    }
                } label: {
                    Label(ipmLocalized(appLanguage, de: "Sortieren", en: "Sort"), systemImage: "arrow.up.arrow.down.circle")
                }
                .tint(IPMColors.green)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditFloor = true
                } label: {
                    Label(ipmLocalized(appLanguage, de: "Raum bearbeiten", en: "Edit room"), systemImage: "slider.horizontal.3")
                }
                .tint(IPMColors.green)
            }
        }
        .sheet(isPresented: $showAddTrap) {
            AddTrapView(clientId: clientId, floorId: currentFloor.id ?? "", existingTraps: traps) { await loadTraps() }
        }
        .sheet(isPresented: $showEditFloor) {
            EditFloorView(floor: currentFloor, clientId: clientId) { updatedFloor in
                currentFloor = updatedFloor
            }
        }
        .alert(ipmLocalized(appLanguage, de: "Limit erreicht", en: "Limit reached"), isPresented: $showUpgradeAlert) {
            Button(ipmLocalized(appLanguage, de: "OK", en: "OK"), role: .cancel) {}
        } message: {
            Text(upgradeMessage)
        }
        .task { await loadTraps() }
        .refreshable { await loadTraps() }
    }

    private var roomProfileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(IPMColors.green.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "square.split.2x1")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(IPMColors.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(currentFloor.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))

                    if let descriptor = [currentFloor.gebaeude, currentFloor.stockwerk]
                        .compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) })
                        .filter({ !$0.isEmpty })
                        .joined(separator: " · ")
                        .nilIfEmpty {
                        Text(descriptor)
                            .font(.system(size: 13))
                            .foregroundStyle(IPMColors.brownMid)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(displayedTraps.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(IPMColors.greenDark)
                    Text(ipmLocalized(appLanguage, de: "Fallen", en: "Traps"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(IPMColors.brownMid)
                }
            }

            HStack(spacing: 10) {
                if let frequency = currentFloor.besuchsfrequenz?.trimmingCharacters(in: .whitespacesAndNewlines), !frequency.isEmpty {
                    roomMetaChip(icon: "calendar", text: frequency)
                }
                if let accessibility = currentFloor.erreichbarkeit {
                    roomMetaChip(icon: "figure.walk", text: accessibility.title(language: appLanguage))
                }
            }

            if let notes = currentFloor.beschreibung?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 13))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AdaptiveColor.card(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func roomMetaChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(IPMColors.greenDark)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(IPMColors.green.opacity(0.10))
        .clipShape(Capsule())
    }

    private func loadTraps() async {
        traps = (try? await FirestoreService.shared.fetchTraps(clientId: clientId, floorId: currentFloor.id ?? "")) ?? []
    }

    private func trapPriority(_ trap: Trap) -> Int {
        switch trap.faelligkeitStatus {
        case .ueberfaellig: return 0
        case .bald: return 1
        case .ok: return 2
        }
    }
}

private struct EditFloorView: View {
    let floor: Floor
    let clientId: String
    let onSave: (Floor) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"

    @State private var name: String
    @State private var stockwerk: String
    @State private var gebaeude: String
    @State private var beschreibung: String
    @State private var besuchsfrequenz: String
    @State private var erreichbarkeit: RoomAccessibility
    @State private var isSaving = false
    @State private var saveError: String?

    init(floor: Floor, clientId: String, onSave: @escaping (Floor) -> Void) {
        self.floor = floor
        self.clientId = clientId
        self.onSave = onSave
        _name = State(initialValue: floor.name)
        _stockwerk = State(initialValue: floor.stockwerk ?? "")
        _gebaeude = State(initialValue: floor.gebaeude ?? "")
        _beschreibung = State(initialValue: floor.beschreibung ?? "")
        _besuchsfrequenz = State(initialValue: floor.besuchsfrequenz ?? "")
        _erreichbarkeit = State(initialValue: floor.erreichbarkeit ?? .treppe)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()
                List {
                    Section {
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Raumname", en: "Room name"), text: $name, icon: "map")
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Stockwerk", en: "Floor level"), text: $stockwerk, icon: "stairs")
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Gebäude", en: "Building"), text: $gebaeude, icon: "building.2")
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Besuchsfrequenz", en: "Visit frequency"), text: $besuchsfrequenz, icon: "calendar")
                    } header: {
                        SectionLabel(ipmLocalized(appLanguage, de: "Raumdaten", en: "Room details"))
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        Picker(ipmLocalized(appLanguage, de: "Erreichbarkeit", en: "Accessibility"), selection: $erreichbarkeit) {
                            ForEach(RoomAccessibility.allCases, id: \.self) { option in
                                Text(option.title(language: appLanguage)).tag(option)
                            }
                        }
                        .tint(IPMColors.green)
                    } header: {
                        SectionLabel(ipmLocalized(appLanguage, de: "Zugang", en: "Access"))
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        TextField(ipmLocalized(appLanguage, de: "Beschreibung, Besonderheiten, Risiken...", en: "Description, special notes, risks..."), text: $beschreibung, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.system(size: 14))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    } header: {
                        SectionLabel(ipmLocalized(appLanguage, de: "Beschreibung", en: "Description"))
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    if let saveError {
                        Section {
                            Text(saveError)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(IPMColors.critical)
                        }
                        .listRowBackground(AdaptiveColor.card(scheme))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(ipmLocalized(appLanguage, de: "Raum bearbeiten", en: "Edit room"))
            .ipmNavigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ipmLocalized(appLanguage, de: "Abbrechen", en: "Cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(IPMColors.brownMid)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(ipmLocalized(appLanguage, de: "Speichern", en: "Save")) {
                        Task { await saveFloor() }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(canSave ? IPMColors.green : IPMColors.brownMid)
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveFloor() async {
        isSaving = true
        defer { isSaving = false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            saveError = ipmLocalized(appLanguage, de: "Der Raumname ist erforderlich.", en: "Room name is required.")
            return
        }

        var updatedFloor = floor
        updatedFloor.name = trimmedName
        updatedFloor.stockwerk = stockwerk.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        updatedFloor.gebaeude = gebaeude.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        updatedFloor.beschreibung = beschreibung.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        updatedFloor.besuchsfrequenz = besuchsfrequenz.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        updatedFloor.erreichbarkeit = erreichbarkeit

        do {
            try await FirestoreService.shared.saveFloor(updatedFloor, clientId: clientId)
            onSave(updatedFloor)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

// MARK: - Trap Pin
struct TrapPin: View {
    @AppStorage("showTrapNumbers") private var showTrapNumbers = true
    let trap: Trap
    var compactNumbers: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(trap.faelligkeitStatus.color)
                    .frame(width: 30, height: 30)
                    .shadow(color: trap.faelligkeitStatus.color.opacity(0.5), radius: 4, y: 2)
                Image(systemName: trap.typ.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            if showTrapNumbers && !compactNumbers {
                Text(trap.nummer)
                    .font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Trap List Row
struct TrapListRow: View {
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    let trap: Trap

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(trap.faelligkeitStatus.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: trap.typ.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(trap.faelligkeitStatus.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("\(ipmLocalized(appLanguage, de: "Falle", en: "Trap")) \(trap.nummer)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                HStack(spacing: 6) {
                    Text(trap.typ.localizedName(language: appLanguage)).font(.system(size: 11)).foregroundStyle(IPMColors.brownMid)
                    Text("·").foregroundStyle(IPMColors.brownMid.opacity(0.5))
                    Text(trap.naechstePruefung.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(trap.faelligkeitStatus.color)
                }
            }
            Spacer()
            StatusPill(status: trap.faelligkeitStatus)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Trap Detail
struct TrapDetailView: View {
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    let trap: Trap
    let clientId: String
    let floorId: String
    @State private var inspections: [Inspection] = []
    @State private var showAddInspection = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()
            List {
                // Header
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(trap.faelligkeitStatus.color.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: trap.typ.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(trap.faelligkeitStatus.color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(ipmLocalized(appLanguage, de: "Falle", en: "Trap")) \(trap.nummer)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                            Text(trap.typ.localizedName(language: appLanguage))
                                .font(.system(size: 13))
                                .foregroundStyle(IPMColors.brownMid)
                            StatusPill(status: trap.faelligkeitStatus)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(AdaptiveColor.card(scheme))

                Section {
                    InfoRow(icon: "calendar.badge.plus", label: ipmLocalized(appLanguage, de: "Aufgestellt", en: "Installed"),
                            value: trap.aufstellDatum.formatted(date: .long, time: .omitted), color: IPMColors.green)
                    InfoRow(icon: "clock.arrow.2.circlepath", label: ipmLocalized(appLanguage, de: "Prüfintervall", en: "Inspection interval"),
                            value: "\(trap.pruefIntervallWochen) \(appLanguage == "en" ? "weeks" : "Wochen")", color: IPMColors.brownMid)
                    InfoRow(icon: "calendar.badge.exclamationmark", label: ipmLocalized(appLanguage, de: "Nächste Prüfung", en: "Next inspection"),
                            value: trap.naechstePruefung.formatted(date: .long, time: .omitted),
                            color: trap.faelligkeitStatus.color)
                    if !trap.notizen.isEmpty {
                        InfoRow(icon: "note.text", label: ipmLocalized(appLanguage, de: "Notizen", en: "Notes"), value: trap.notizen, color: IPMColors.brownMid)
                    }
                } header: { SectionLabel(ipmLocalized(appLanguage, de: "Details", en: "Details")) }
                .listRowBackground(AdaptiveColor.card(scheme))

                Section {
                    TrapPestTrendView(inspections: inspections)
                } header: { SectionLabel(ipmLocalized(appLanguage, de: "Ungeziefer-Entwicklung", en: "Pest trend")) }
                .listRowBackground(AdaptiveColor.card(scheme))

                Section {
                    Button { showAddInspection = true } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(IPMColors.green)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            Text(ipmLocalized(appLanguage, de: "Neue Kontrolle erfassen", en: "Add inspection"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(IPMColors.green)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listRowBackground(AdaptiveColor.card(scheme))

                Section {
                    if isLoading {
                        HStack { Spacer(); ProgressView().tint(IPMColors.green); Spacer() }
                            .padding(.vertical, 12)
                            .listRowBackground(AdaptiveColor.card(scheme))
                    } else if inspections.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "tray").font(.title2).foregroundStyle(IPMColors.brownMid.opacity(0.3))
                                Text(ipmLocalized(appLanguage, de: "Noch keine Kontrollen", en: "No inspections yet")).font(.system(size: 13)).foregroundStyle(IPMColors.brownMid)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .listRowBackground(AdaptiveColor.card(scheme))
                    } else {
                        ForEach(Array(inspections.enumerated()), id: \.element.id) { index, inspection in
                            NavigationLink(destination: InspectionDetailView(
                                inspection: inspection,
                                trap: trap,
                                clientId: clientId,
                                floorId: floorId
                            ) {
                                await loadInspections()
                            }) {
                                VStack(spacing: 0) {
                                    InspectionCard(
                                        inspection: inspection,
                                        previousInspection: index + 1 < inspections.count ? inspections[index + 1] : nil
                                    )

                                    if index < inspections.count - 1 {
                                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                                            .fill(IPMColors.brownMid.opacity(0.28))
                                            .frame(height: 4)
                                            .padding(.top, 12)
                                            .padding(.horizontal, 2)
                                    }
                                }
                            }
                            .listRowBackground(AdaptiveColor.card(scheme))
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            Task {
                                guard let trapId = trap.id else { return }
                                for index in indexSet {
                                    let inspection = inspections[index]
                                    try? await FirestoreService.shared.deleteInspection(
                                        inspection,
                                        clientId: clientId,
                                        floorId: floorId,
                                        trapId: trapId,
                                        intervalDays: trap.pruefIntervallTage,
                                        fallbackDate: trap.aufstellDatum
                                    )
                                }
                                await loadInspections()
                            }
                        }
                    }
                } header: { SectionLabel("\(ipmLocalized(appLanguage, de: "Kontrollverlauf", en: "Inspection history")) (\(inspections.count))") }
            }
            .scrollContentBackground(.hidden)
            .background(AdaptiveColor.background(scheme))
        }
        .navigationTitle("\(ipmLocalized(appLanguage, de: "Falle", en: "Trap")) \(trap.nummer)")
        .ipmNavigationBarTitleDisplayModeInline()
        .sheet(isPresented: $showAddInspection) {
            AddInspectionView(trap: trap, clientId: clientId, floorId: floorId) {
                await loadInspections()
            }
        }
        .task { await loadInspections() }
    }

    private func loadInspections() async {
        isLoading = true
        guard let trapId = trap.id else { isLoading = false; return }
        inspections = (try? await FirestoreService.shared.fetchInspections(clientId: clientId, floorId: floorId, trapId: trapId)) ?? []
        isLoading = false
    }
}

// MARK: - Trap Pest Trend
private struct TrapPestTrendView: View {
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    let inspections: [Inspection]
    @State private var metric: TrendMetric = .pests

    private enum TrendMetric: String, CaseIterable, Identifiable {
        case pests
        case guests
        case temperature
        case humidity

        var id: String { rawValue }
    }

    private struct TrendPoint {
        let date: Date
        let value: Double
    }

    private var ordered: [Inspection] {
        inspections.sorted { $0.datum < $1.datum }
    }

    private var series: [TrendPoint] {
        switch metric {
        case .pests:
            return ordered.map { inspection in
                let value = Schaedling.schaedlingsArten.reduce(0) { partial, pest in
                    partial + (inspection.befunde[pest] ?? 0)
                }
                return TrendPoint(date: inspection.datum, value: Double(value))
            }
        case .guests:
            return ordered.map { inspection in
                let value = Schaedling.gasteArten.reduce(0) { partial, pest in
                    partial + (inspection.befunde[pest] ?? 0)
                }
                return TrendPoint(date: inspection.datum, value: Double(value))
            }
        case .temperature:
            return ordered.compactMap { inspection in
                guard let value = inspection.temperatur else { return nil }
                return TrendPoint(date: inspection.datum, value: value)
            }
        case .humidity:
            return ordered.compactMap { inspection in
                guard let value = inspection.luftfeuchtigkeit else { return nil }
                return TrendPoint(date: inspection.datum, value: value)
            }
        }
    }

    private var values: [Double] {
        series.map(\.value)
    }

    private var latest: Double? {
        values.last
    }

    private var previous: Double? {
        guard values.count >= 2 else { return nil }
        return values[values.count - 2]
    }

    private var deltaValue: Double? {
        guard let latest, let previous else { return nil }
        return latest - previous
    }

    private var metricTitle: String {
        switch metric {
        case .pests:
            return ipmLocalized(appLanguage, de: "Tiere", en: "Pests")
        case .guests:
            return ipmLocalized(appLanguage, de: "Gäste", en: "Guests")
        case .temperature:
            return ipmLocalized(appLanguage, de: "Temperatur", en: "Temperature")
        case .humidity:
            return ipmLocalized(appLanguage, de: "Feuchtigkeit", en: "Humidity")
        }
    }

    private var deltaText: String {
        guard let delta = deltaValue else {
            return ipmLocalized(appLanguage, de: "Noch nicht genug Daten für Trend.", en: "Not enough data for trend yet.")
        }
        if abs(delta) < 0.0001 {
            return ipmLocalized(appLanguage, de: "Keine Veränderung zur letzten Kontrolle.", en: "No change since last inspection.")
        }
        let prefix = delta > 0 ? "+" : ""
        return "\(prefix)\(formattedValue(delta, includeUnit: true)) \(ipmLocalized(appLanguage, de: "zur letzten Kontrolle.", en: "since last inspection."))"
    }

    private var deltaColor: Color {
        guard let delta = deltaValue else { return IPMColors.brownMid }
        switch metric {
        case .pests, .guests:
            if delta > 0 { return IPMColors.critical }
            if delta < 0 { return IPMColors.ok }
        case .temperature, .humidity:
            if delta > 0 { return IPMColors.warning }
            if delta < 0 { return IPMColors.ok }
        }
        return IPMColors.brownMid
    }

    private var deltaIcon: String {
        guard let delta = deltaValue else { return "minus" }
        if delta > 0 { return "arrow.up.right" }
        if delta < 0 { return "arrow.down.right" }
        return "minus"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(metricTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                Spacer()
                Menu {
                    ForEach(TrendMetric.allCases) { item in
                        Button(item == metric ? "✓ \(title(for: item))" : title(for: item)) {
                            metric = item
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(metricTitle)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(IPMColors.greenDark)
                }
            }

            if series.count < 2 {
                Text(ipmLocalized(appLanguage, de: "Mindestens 2 Kontrollen mit diesem Wert nötig, um eine Entwicklung anzuzeigen.", en: "At least 2 inspections with this metric are required to show a trend."))
                    .font(.system(size: 13))
                    .foregroundStyle(IPMColors.brownMid)
                if let latest {
                    Text("\(ipmLocalized(appLanguage, de: "Aktuell", en: "Current")): \(formattedValue(latest, includeUnit: true))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                }
            } else {
                IPMSparkline(values: values)
                    .stroke(deltaColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .frame(height: 64)
                    .padding(.vertical, 4)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ipmLocalized(appLanguage, de: "Aktuell", en: "Current"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(IPMColors.brownMid)
                        Text(formattedValue(latest ?? 0, includeUnit: true))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(ipmLocalized(appLanguage, de: "Durchschnitt", en: "Average"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(IPMColors.brownMid)
                        Text(formattedValue(values.reduce(0, +) / Double(values.count), includeUnit: true))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: deltaIcon)
                        .font(.system(size: 11, weight: .bold))
                    Text(deltaText)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(deltaColor)
            }
        }
        .padding(.vertical, 4)
    }

    private func title(for item: TrendMetric) -> String {
        switch item {
        case .pests:
            return ipmLocalized(appLanguage, de: "Tiere", en: "Pests")
        case .guests:
            return ipmLocalized(appLanguage, de: "Gäste", en: "Guests")
        case .temperature:
            return ipmLocalized(appLanguage, de: "Temperatur", en: "Temperature")
        case .humidity:
            return ipmLocalized(appLanguage, de: "Feuchtigkeit", en: "Humidity")
        }
    }

    private func formattedValue(_ value: Double, includeUnit: Bool) -> String {
        switch metric {
        case .pests, .guests:
            let rounded = Int(round(value))
            return "\(rounded)"
        case .temperature:
            let base = String(format: "%.1f", value)
            return includeUnit ? "\(base)°C" : base
        case .humidity:
            let base = String(format: "%.0f", value)
            return includeUnit ? "\(base)%" : base
        }
    }
}

private struct IPMSparkline: Shape {
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

// MARK: - Inspection Card (in Liste)
struct InspectionCard: View {
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    let inspection: Inspection
    let previousInspection: Inspection?

    private var pestCount: Int { inspection.gesamtBefund }
    private var previousPestCount: Int? { previousInspection?.gesamtBefund }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(inspection.datum.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                }
                Spacer()
                if inspection.gesamtBefund > 0 {
                    Label("\(inspection.gesamtBefund)", systemImage: "ant.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(IPMColors.critical)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(IPMColors.critical.opacity(0.1))
                        .clipShape(Capsule())
                } else {
                    Label(ipmLocalized(appLanguage, de: "Leer", en: "Empty"), systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(IPMColors.ok)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(IPMColors.ok.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 10) {
                inspectionMetricPill(
                    title: ipmLocalized(appLanguage, de: "Temperatur", en: "Temperature"),
                    value: inspection.temperatur.map { "\(String(format: "%.1f", $0)) °C" } ?? "—",
                    systemImage: "thermometer.medium",
                    tint: IPMColors.warning
                )
                inspectionMetricPill(
                    title: ipmLocalized(appLanguage, de: "Feuchte", en: "Humidity"),
                    value: inspection.luftfeuchtigkeit.map { "\(String(format: "%.0f", $0)) %" } ?? "—",
                    systemImage: "humidity",
                    tint: IPMColors.green
                )
            }

            if previousInspection != nil {
                HStack(spacing: 8) {
                    inspectionDeltaTag(
                        title: ipmLocalized(appLanguage, de: "Befund", en: "Findings"),
                        current: Double(pestCount),
                        previous: previousPestCount.map(Double.init),
                        unit: ""
                    )
                    inspectionDeltaTag(
                        title: "°C",
                        current: inspection.temperatur,
                        previous: previousInspection?.temperatur,
                        unit: "°C"
                    )
                    inspectionDeltaTag(
                        title: "%",
                        current: inspection.luftfeuchtigkeit,
                        previous: previousInspection?.luftfeuchtigkeit,
                        unit: "%"
                    )
                }
            }

            let top = inspection.befunde.filter { $0.value > 0 }.sorted { $0.value > $1.value }.prefix(3)
            if !top.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(top), id: \.key) { art, anzahl in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(anzahl > 0 ? IPMColors.befund : IPMColors.brownMid.opacity(0.3))
                                .frame(width: 5, height: 20)

                            Text(art)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            Text("\(anzahl)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(IPMColors.befund)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(IPMColors.befund.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(AdaptiveColor.cardSecondary(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }

            if !inspection.notizen.isEmpty {
                Text(inspection.notizen)
                    .font(.system(size: 10.5))
                    .italic()
                    .foregroundStyle(IPMColors.brownMid.opacity(0.78))
                    .lineLimit(2)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(AdaptiveColor.cardSecondary(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.vertical, 4)
    }

    private func inspectionMetricPill(title: String, value: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 28, height: 28)
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(IPMColors.brownMid)
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AdaptiveColor.cardSecondary(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func inspectionDeltaTag(title: String, current: Double?, previous: Double?, unit: String) -> some View {
        let deltaText: String
        let tint: Color

        if let current, let previous {
            let delta = current - previous
            if abs(delta) < 0.0001 {
                deltaText = "0\(unit)"
                tint = IPMColors.brownMid
            } else {
                let prefix = delta > 0 ? "+" : ""
                if unit == "°C" {
                    deltaText = "\(prefix)\(String(format: "%.1f", delta))\(unit)"
                } else if unit == "%" {
                    deltaText = "\(prefix)\(String(format: "%.0f", delta))\(unit)"
                } else {
                    deltaText = "\(prefix)\(Int(delta))"
                }
                tint = delta > 0 ? IPMColors.warning : IPMColors.ok
            }
        } else {
            deltaText = "—"
            tint = IPMColors.brownMid
        }

        return HStack(spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
            Text(deltaText)
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Inspection Detail
struct InspectionDetailView: View {
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    let inspection: Inspection
    let trap: Trap
    let clientId: String
    let floorId: String
    let onUpdated: (() async -> Void)?
    @State private var currentInspection: Inspection
    @State private var showEditInspection = false

    init(
        inspection: Inspection,
        trap: Trap,
        clientId: String,
        floorId: String,
        onUpdated: (() async -> Void)? = nil
    ) {
        self.inspection = inspection
        self.trap = trap
        self.clientId = clientId
        self.floorId = floorId
        self.onUpdated = onUpdated
        _currentInspection = State(initialValue: inspection)
    }

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentInspection.datum.formatted(date: .complete, time: .shortened))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                        }
                        Spacer()
                        if currentInspection.gesamtBefund > 0 {
                            Label("\(currentInspection.gesamtBefund) \(ipmLocalized(appLanguage, de: "Tiere", en: "pests"))", systemImage: "ant.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(IPMColors.critical)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(IPMColors.critical.opacity(0.1))
                                .clipShape(Capsule())
                        } else {
                            Label(ipmLocalized(appLanguage, de: "Leer", en: "Empty"), systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(IPMColors.ok)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(IPMColors.ok.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .listRowBackground(AdaptiveColor.card(scheme))

                if let temp = currentInspection.temperatur, let hum = currentInspection.luftfeuchtigkeit {
                    Section {
                        InfoRow(icon: "thermometer.medium", label: ipmLocalized(appLanguage, de: "Temperatur", en: "Temperature"), value: "\(String(format: "%.1f", temp)) °C", color: IPMColors.warning)
                        InfoRow(icon: "humidity", label: ipmLocalized(appLanguage, de: "Luftfeuchtigkeit", en: "Humidity"), value: "\(String(format: "%.0f", hum)) %", color: IPMColors.green)
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Messung", en: "Measurement")) }
                    .listRowBackground(AdaptiveColor.card(scheme))
                }

                let schaedlinge = currentInspection.befunde
                    .filter { $0.value > 0 && Schaedling.schaedlingsArten.contains($0.key) }
                    .sorted { $0.value > $1.value }
                if !schaedlinge.isEmpty {
                    Section {
                        ForEach(schaedlinge, id: \.key) { art, anzahl in
                            HStack {
                                Text(art).font(.system(size: 14)).foregroundStyle(AdaptiveColor.textPrimary(scheme))
                                Spacer()
                                Text("\(anzahl)").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(IPMColors.critical)
                            }
                            .listRowBackground(AdaptiveColor.card(scheme))
                        }
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Schädlinge", en: "Pests")) }
                }

                let gaeste = currentInspection.befunde
                    .filter { $0.value > 0 && Schaedling.gasteArten.contains($0.key) }
                    .sorted { $0.value > $1.value }
                if !gaeste.isEmpty {
                    Section {
                        ForEach(gaeste, id: \.key) { art, anzahl in
                            HStack {
                                Text(art).font(.system(size: 14)).foregroundStyle(AdaptiveColor.textPrimary(scheme))
                                Spacer()
                                Text("\(anzahl)").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(IPMColors.warning)
                            }
                            .listRowBackground(AdaptiveColor.card(scheme))
                        }
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Gäste", en: "Guests")) }
                }

                if !currentInspection.notizen.isEmpty {
                    Section {
                        Text(currentInspection.notizen)
                            .font(.system(size: 14))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Notizen", en: "Notes")) }
                    .listRowBackground(AdaptiveColor.card(scheme))
                }

                if !currentInspection.fotoURLs.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(currentInspection.fotoURLs.enumerated()), id: \.offset) { _, urlString in
                                    PersistentInspectionPhotoView(urlString: urlString)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Fotos", en: "Photos")) }
                    .listRowBackground(AdaptiveColor.card(scheme))
                }
            }
            .scrollContentBackground(.hidden)
            .background(AdaptiveColor.background(scheme))
        }
        .navigationTitle(ipmLocalized(appLanguage, de: "Kontrolle", en: "Inspection"))
        .ipmNavigationBarTitleDisplayModeInline()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(ipmLocalized(appLanguage, de: "Bearbeiten", en: "Edit")) {
                    showEditInspection = true
                }
                .foregroundStyle(IPMColors.green)
            }
        }
        .sheet(isPresented: $showEditInspection) {
            AddInspectionView(
                trap: trap,
                clientId: clientId,
                floorId: floorId,
                existingInspection: currentInspection
            ) {
                await refreshInspection()
                await onUpdated?()
            }
        }
    }

    private func refreshInspection() async {
        guard let trapId = trap.id, let inspectionId = currentInspection.id else { return }
        let all = (try? await FirestoreService.shared.fetchInspections(clientId: clientId, floorId: floorId, trapId: trapId)) ?? []
        if let updated = all.first(where: { $0.id == inspectionId }) {
            currentInspection = updated
        }
    }
}

private struct PersistentInspectionPhotoView: View {
    let urlString: String
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView().tint(IPMColors.green)
            } else {
                Color.gray.opacity(0.15)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(IPMColors.brownMid.opacity(0.5))
                    }
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .task(id: urlString) {
            await loadImage()
        }
    }

    @MainActor
    private func loadImage() async {
        isLoading = true
        defer { isLoading = false }
        if let parsedURL = URL(string: urlString), parsedURL.isFileURL {
            if let data = try? Data(contentsOf: parsedURL), let localImage = UIImage(data: data) {
                image = localImage
            } else {
                image = nil
            }
            return
        }

        if FileManager.default.fileExists(atPath: urlString) {
            let fileURL = URL(fileURLWithPath: urlString)
            if let data = try? Data(contentsOf: fileURL), let localImage = UIImage(data: data) {
                image = localImage
            } else {
                image = nil
            }
            return
        }

        guard let remoteURL = URL(string: urlString) else { return }

        let fileURL = cachedFileURL(for: remoteURL)
        if let data = try? Data(contentsOf: fileURL), let cachedImage = UIImage(data: data) {
            image = cachedImage
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            guard let downloaded = UIImage(data: data) else { return }
            image = downloaded
            try? ensureCacheDirectoryExists()
            try? data.write(to: fileURL, options: .atomic)
        } catch {
            image = nil
        }
    }

    private func cachedFileURL(for remoteURL: URL) -> URL {
        let encodedKey = Data(remoteURL.absoluteString.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
        return cacheDirectoryURL().appendingPathComponent("\(encodedKey).img")
    }

    private func cacheDirectoryURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("IPMPhotoCache", isDirectory: true)
    }

    private func ensureCacheDirectoryExists() throws {
        try FileManager.default.createDirectory(at: cacheDirectoryURL(), withIntermediateDirectories: true)
    }
}

// MARK: - Add Trap
struct AddTrapView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    let clientId: String
    let floorId: String
    let existingTraps: [Trap]
    let onSave: () async -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var nummer = ""
    @State private var typ = TrapType.gTrap
    @State private var intervallWochen = 8
    @State private var isSaving = false
    @State private var limitError: String?

    private var canSave: Bool {
        !nummer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()
                List {
                    Section {
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Fallennummer (z.B. 1031-1)", en: "Trap number (e.g. 1031-1)"), text: $nummer, icon: "number")
                        HStack(spacing: 10) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 13)).foregroundStyle(IPMColors.brownMid).frame(width: 18)
                            Picker(ipmLocalized(appLanguage, de: "Typ", en: "Type"), selection: $typ) {
                                ForEach(TrapType.allCases, id: \.self) {
                                    Text($0.localizedName(language: appLanguage)).tag($0)
                                }
                            }
                            .tint(IPMColors.green)
                            .font(.system(size: 15))
                        }
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Falle", en: "Trap")) }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "clock")
                                .font(.system(size: 13)).foregroundStyle(IPMColors.brownMid).frame(width: 18)
                            Stepper("\(intervallWochen) \(appLanguage == "en" ? "weeks" : "Wochen")", value: $intervallWochen, in: 6...16)
                                .font(.system(size: 15))
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                        }
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Prüfintervall", en: "Inspection interval")) }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    if let limitError {
                        Section {
                            Text(limitError)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(IPMColors.critical)
                        }
                        .listRowBackground(AdaptiveColor.card(scheme))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(ipmLocalized(appLanguage, de: "Neue Falle", en: "New trap"))
            .ipmNavigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ipmLocalized(appLanguage, de: "Abbrechen", en: "Cancel")) { dismiss() }.foregroundStyle(IPMColors.brownMid)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(ipmLocalized(appLanguage, de: "Speichern", en: "Save")) {
                        Task {
                            if let msg = subscription.canAddTrap(currentCountForRoom: existingTraps.count) {
                                limitError = msg
                                return
                            }
                            isSaving = true
                            try? await FirestoreService.shared.saveTrap(
                                Trap(
                                    nummer: nummer,
                                    typ: typ,
                                    pruefIntervallTage: intervallWochen * 7
                                ),
                                clientId: clientId, floorId: floorId
                            )
                            await onSave()
                            dismiss()
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(canSave ? IPMColors.green : IPMColors.brownMid.opacity(0.68))
                    .disabled(!canSave)
                }
            }
        }
    }

}
