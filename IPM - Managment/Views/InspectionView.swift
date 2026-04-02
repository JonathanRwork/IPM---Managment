import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Add Inspection
struct AddInspectionView: View {
    let trap: Trap
    let clientId: String
    let floorId: String
    let existingInspection: Inspection?
    let onSave: () async -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"

    @State private var datum = Date()
    @State private var temperatur = ""
    @State private var luftfeuchtigkeit = ""
    @State private var notizen = ""
    @State private var befunde: [String: Int] = [:]
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedPhotoData: [Data] = []
    @State private var isSaving = false
    @State private var didSave = false
    @State private var generatedReportURL: URL?
    @State private var saveMessage: String?
    private let maxPhotosPerInspection = 3

    private var existingPhotoCount: Int { existingInspection?.fotoURLs.count ?? 0 }
    private var remainingPhotoSlots: Int { max(0, maxPhotosPerInspection - existingPhotoCount) }

    init(
        trap: Trap,
        clientId: String,
        floorId: String,
        existingInspection: Inspection? = nil,
        onSave: @escaping () async -> Void
    ) {
        self.trap = trap
        self.clientId = clientId
        self.floorId = floorId
        self.existingInspection = existingInspection
        self.onSave = onSave

        _datum = State(initialValue: existingInspection?.datum ?? Date())
        if let temp = existingInspection?.temperatur {
            _temperatur = State(initialValue: String(format: "%.1f", temp))
        } else {
            _temperatur = State(initialValue: "")
        }
        if let humidity = existingInspection?.luftfeuchtigkeit {
            _luftfeuchtigkeit = State(initialValue: String(format: "%.0f", humidity))
        } else {
            _luftfeuchtigkeit = State(initialValue: "")
        }
        _notizen = State(initialValue: existingInspection?.notizen ?? "")
        _befunde = State(initialValue: existingInspection?.befunde ?? [:])
    }

    private var gesamtSchaedlinge: Int {
        Schaedling.schaedlingsArten.compactMap { befunde[$0] }.reduce(0, +)
    }
    private var gesamtGaeste: Int {
        Schaedling.gasteArten.compactMap { befunde[$0] }.reduce(0, +)
    }
    private var gesamtBefund: Int { gesamtSchaedlinge + gesamtGaeste }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()
                List {
                    if didSave || saveMessage != nil {
                        Section {
                            if didSave {
                                Text(ipmLocalized(appLanguage, de: "Kontrolle gespeichert.", en: "Inspection saved."))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(IPMColors.ok)
                                if let generatedReportURL {
                                    ShareLink(item: generatedReportURL) {
                                        Label(ipmLocalized(appLanguage, de: "Bericht teilen", en: "Share report"), systemImage: "square.and.arrow.up")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(IPMColors.green)
                                    }
                                }
                            }
                            if let saveMessage {
                                Text(saveMessage)
                                    .font(.system(size: 12))
                                    .foregroundStyle(didSave ? IPMColors.brownMid : IPMColors.critical)
                            }
                        } header: { SectionLabel(ipmLocalized(appLanguage, de: "Ergebnis", en: "Result")) }
                        .listRowBackground(AdaptiveColor.card(scheme))
                    }

                    // Live Summary Banner
                    Section {
                        HStack(spacing: 8) {
                            BefundBadge(value: gesamtSchaedlinge, label: ipmLocalized(appLanguage, de: "Schädlinge", en: "Pests"),
                                        color: gesamtSchaedlinge > 0 ? IPMColors.critical : IPMColors.ok)
                            BefundBadge(value: gesamtGaeste, label: ipmLocalized(appLanguage, de: "Gäste", en: "Guests"),
                                        color: gesamtGaeste > 0 ? IPMColors.warning : IPMColors.brownMid)
                            BefundBadge(value: gesamtBefund, label: ipmLocalized(appLanguage, de: "Gesamt", en: "Total"),
                                        color: gesamtBefund > 0 ? IPMColors.befund : IPMColors.green)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    // Messung
                    Section {
                        DatePicker(ipmLocalized(appLanguage, de: "Datum & Uhrzeit", en: "Date & time"), selection: $datum, displayedComponents: [.date, .hourAndMinute])
                            .font(.system(size: 15))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                            .tint(IPMColors.green)

                        HStack(spacing: 10) {
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 13)).foregroundStyle(IPMColors.brownMid).frame(width: 18)
                            TextField(ipmLocalized(appLanguage, de: "Temperatur", en: "Temperature"), text: $temperatur)
                                .ipmKeyboardType(.decimalPad)
                                .font(.system(size: 15))
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                            Text("°C").font(.system(size: 13)).foregroundStyle(IPMColors.brownMid)
                        }

                        HStack(spacing: 10) {
                            Image(systemName: "humidity")
                                .font(.system(size: 13)).foregroundStyle(IPMColors.brownMid).frame(width: 18)
                            TextField(ipmLocalized(appLanguage, de: "Luftfeuchtigkeit", en: "Humidity"), text: $luftfeuchtigkeit)
                                .ipmKeyboardType(.decimalPad)
                                .font(.system(size: 15))
                                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                            Text("%").font(.system(size: 13)).foregroundStyle(IPMColors.brownMid)
                        }
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Messung", en: "Measurement")) }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    // Schädlinge
                    Section {
                        ForEach(Schaedling.schaedlingsArten, id: \.self) { art in
                            CounterRow(
                                art: art,
                                anzahl: Binding(
                                    get: { befunde[art] ?? 0 },
                                    set: { befunde[art] = $0 == 0 ? nil : $0 }
                                ),
                                isSchaedling: true
                            )
                        }
                    } header: {
                        HStack {
                            SectionLabel(ipmLocalized(appLanguage, de: "Schädlinge", en: "Pests"))
                            Spacer()
                            if gesamtSchaedlinge > 0 {
                                Text("\(gesamtSchaedlinge)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(IPMColors.critical)
                                    .padding(.horizontal, 7).padding(.vertical, 2)
                                    .background(IPMColors.critical.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    // Gäste
                    Section {
                        ForEach(Schaedling.gasteArten, id: \.self) { art in
                            CounterRow(
                                art: art,
                                anzahl: Binding(
                                    get: { befunde[art] ?? 0 },
                                    set: { befunde[art] = $0 == 0 ? nil : $0 }
                                ),
                                isSchaedling: false
                            )
                        }
                    } header: {
                        HStack {
                            SectionLabel(ipmLocalized(appLanguage, de: "Gäste", en: "Guests"))
                            Spacer()
                            if gesamtGaeste > 0 {
                                Text("\(gesamtGaeste)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(IPMColors.warning)
                                    .padding(.horizontal, 7).padding(.vertical, 2)
                                    .background(IPMColors.warning.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    // Notizen
                    Section {
                        TextField(ipmLocalized(appLanguage, de: "Bemerkungen, Auffälligkeiten...", en: "Notes, observations..."), text: $notizen, axis: .vertical)
                            .lineLimit(3...5)
                            .font(.system(size: 14))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Notizen", en: "Notes")) }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: max(remainingPhotoSlots, 1),
                            matching: .images
                        ) {
                            Label(ipmLocalized(appLanguage, de: "Fotos hinzufügen", en: "Add photos"), systemImage: "photo.on.rectangle.angled")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(IPMColors.green)
                        }
                        .disabled(remainingPhotoSlots == 0)

                        Text(
                            ipmLocalized(
                                appLanguage,
                                de: "Maximal \(maxPhotosPerInspection) Fotos pro Kontrolle (\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\(maxPhotosPerInspection)).",
                                en: "Maximum \(maxPhotosPerInspection) photos per inspection (\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\(maxPhotosPerInspection))."
                            )
                        )
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(IPMColors.brownMid)

                        if !selectedPhotoData.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(selectedPhotoData.enumerated()), id: \.offset) { _, data in
                                        #if canImport(UIKit)
                                        if let image = UIImage(data: data) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 88, height: 88)
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        }
                                        #endif
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Fotos", en: "Photos")) }
                    .listRowBackground(AdaptiveColor.card(scheme))
                }
                .scrollContentBackground(.hidden)
                .background(AdaptiveColor.background(scheme))
            }
            .navigationTitle(existingInspection == nil ? ipmLocalized(appLanguage, de: "Kontrolle erfassen", en: "Add inspection") : ipmLocalized(appLanguage, de: "Kontrolle bearbeiten", en: "Edit inspection"))
            .ipmNavigationBarTitleDisplayModeInline()
            .onChange(of: selectedPhotoItems) { _, newItems in
                Task { await loadSelectedPhotos(from: newItems) }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(didSave ? ipmLocalized(appLanguage, de: "Fertig", en: "Done") : ipmLocalized(appLanguage, de: "Abbrechen", en: "Cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(IPMColors.brownMid)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(ipmLocalized(appLanguage, de: "Speichern", en: "Save")) { Task { await saveInspection() } }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSaving ? IPMColors.brownMid : IPMColors.green)
                    .disabled(isSaving || (didSave && existingInspection == nil))
                }
            }
        }
    }

    private func loadSelectedPhotos(from items: [PhotosPickerItem]) async {
        let allowedCount = max(0, remainingPhotoSlots)
        guard allowedCount > 0 else {
            selectedPhotoData = []
            return
        }
        var loaded: [Data] = []
        for item in items.prefix(allowedCount) {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }
        selectedPhotoData = Array(loaded.prefix(allowedCount))
    }

    private func saveInspection() async {
        isSaving = true
        defer { isSaving = false }
        guard let trapId = trap.id else { return }
        saveMessage = nil
        generatedReportURL = nil
        var photoWarning: String?

        var inspection = existingInspection ?? Inspection(
            datum: datum,
            temperatur: Double(temperatur.replacingOccurrences(of: ",", with: ".")),
            luftfeuchtigkeit: Double(luftfeuchtigkeit.replacingOccurrences(of: ",", with: ".")),
            notizen: notizen
        )
        inspection.datum = datum
        inspection.temperatur = Double(temperatur.replacingOccurrences(of: ",", with: "."))
        inspection.luftfeuchtigkeit = Double(luftfeuchtigkeit.replacingOccurrences(of: ",", with: "."))
        inspection.notizen = notizen
        inspection.befunde = befunde.filter { $0.value > 0 }
        if existingInspection != nil {
            inspection.fotoURLs = existingInspection?.fotoURLs ?? []
        }

        // Ensure photo payload is ready even if the async picker conversion is still in flight.
        if selectedPhotoData.isEmpty && !selectedPhotoItems.isEmpty {
            await loadSelectedPhotos(from: selectedPhotoItems)
        }

        let uploadCandidates = Array(selectedPhotoData.prefix(max(0, maxPhotosPerInspection - inspection.fotoURLs.count)))
        if !uploadCandidates.isEmpty {
            do {
                let localPaths = try FirestoreService.shared.storeInspectionPhotosLocally(
                    photoData: uploadCandidates,
                    clientId: clientId,
                    floorId: floorId,
                    trapId: trapId
                )
                inspection.fotoURLs.append(contentsOf: localPaths)
                inspection.fotoURLs = Array(inspection.fotoURLs.prefix(maxPhotosPerInspection))
            } catch {
                photoWarning = ipmLocalized(
                    appLanguage,
                    de: "Lokales Speichern der Fotos fehlgeschlagen. Kontrolle wurde ohne neue Fotos gespeichert.",
                    en: "Local photo save failed. Inspection was saved without new photos."
                )
            }
        } else if !selectedPhotoItems.isEmpty && remainingPhotoSlots > 0 {
            photoWarning = ipmLocalized(
                appLanguage,
                de: "Fotos konnten nicht geladen werden. Kontrolle wurde ohne neue Fotos gespeichert.",
                en: "Photos could not be loaded. Inspection was saved without new photos."
            )
        }

        do {
            try await FirestoreService.shared.saveInspection(
                inspection,
                clientId: clientId,
                floorId: floorId,
                trapId: trapId,
                intervalDays: trap.pruefIntervallTage
            )
            await onSave()
            didSave = true
            if let photoWarning {
                saveMessage = photoWarning
            }
            dismiss()
        } catch {
            saveMessage = error.localizedDescription
            didSave = false
        }
    }
}

// MARK: - Befund Summary Badge
private struct BefundBadge: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(color.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Counter Row
private struct CounterRow: View {
    @Environment(\.colorScheme) var scheme
    let art: String
    @Binding var anzahl: Int
    let isSchaedling: Bool

    private var accentColor: Color { isSchaedling ? IPMColors.critical : IPMColors.warning }

    var body: some View {
        HStack(spacing: 0) {
            Text(art)
                .font(.system(size: 13))
                .foregroundStyle(anzahl > 0 ? AdaptiveColor.textPrimary(scheme) : IPMColors.brownMid)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 12)

            HStack(spacing: 4) {
                Button {
                    if anzahl > 0 { withAnimation(.spring(response: 0.2)) { anzahl -= 1 } }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(anzahl > 0 ? accentColor : IPMColors.brownMid.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .background(anzahl > 0 ? accentColor.opacity(0.1) : AdaptiveColor.cardSecondary(scheme))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Text("\(anzahl)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(anzahl > 0 ? accentColor : IPMColors.brownMid.opacity(0.4))
                    .frame(minWidth: 28, alignment: .center)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.2), value: anzahl)

                Button {
                    withAnimation(.spring(response: 0.2)) { anzahl += 1 }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 3)
    }
}
