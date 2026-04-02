import SwiftUI
import MapKit
import Combine

struct RoomListItem: Identifiable {
    let clientId: String
    let clientName: String
    let floor: Floor
    var id: String { "\(clientId)_\(floor.id ?? floor.name)" }
}

// MARK: - Client List
struct ClientListView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var clients: [Client] = []
    @State private var isLoading = false
    @State private var showAddClient = false
    @State private var searchText = ""
    @State private var showUpgradeAlert = false
    @State private var upgradeMessage = ""

    private var filtered: [Client] {
        searchText.isEmpty ? clients : clients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.adresse.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()

                if clients.isEmpty && !isLoading {
                    IPMEmptyState(
                        icon: "building.2",
                        title: ipmLocalized(appLanguage, de: "Noch keine Kunden", en: "No clients yet"),
                        subtitle: ipmLocalized(appLanguage, de: "Tippe auf + um loszulegen", en: "Tap + to get started")
                    )
                    .transition(.ipmFadeSlide)
                    .ipmFlowEntrance(delay: 0.04)
                } else {
                    List {
                        ForEach(filtered) { client in
                            NavigationLink(destination: ClientDetailView(client: client)) {
                                ClientRow(client: client)
                            }
                            .buttonStyle(IPMPressableStyle())
                            .listRowBackground(AdaptiveColor.card(scheme))
                            .listRowSeparatorTint(AdaptiveColor.cardSecondary(scheme))
                        }
                        .onDelete { indexSet in
                            Task {
                                for i in indexSet {
                                    try? await FirestoreService.shared.deleteClient(filtered[i])
                                }
                                await loadClients()
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AdaptiveColor.background(scheme))
                    .transition(.ipmFadeSlide)
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.88), value: clients.isEmpty)
            .animation(.spring(response: 0.36, dampingFraction: 0.9), value: filtered.count)
            .searchable(text: $searchText, prompt: ipmLocalized(appLanguage, de: "Kunden suchen", en: "Search clients"))
            .navigationTitle(ipmLocalized(appLanguage, de: "Kunden", en: "Clients"))
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        if let message = subscription.canAddClient(currentCount: clients.count) {
                            upgradeMessage = message
                            showUpgradeAlert = true
                            return
                        }
                        showAddClient = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(subscription.canAddClient(currentCount: clients.count) == nil ? IPMColors.green : IPMColors.brownMid.opacity(0.45))
                                .frame(width: 32, height: 32)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(subscription.canAddClient(currentCount: clients.count) == nil ? .white : IPMColors.brownMid)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddClient) {
                AddClientView(currentClientCount: clients.count) { await loadClients() }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .alert(ipmLocalized(appLanguage, de: "Limit erreicht", en: "Limit reached"), isPresented: $showUpgradeAlert) {
                Button(ipmLocalized(appLanguage, de: "OK", en: "OK"), role: .cancel) {}
            } message: {
                Text(upgradeMessage)
            }
            .task { await loadClients() }
            .refreshable { await loadClients() }
        }
    }

    private func loadClients() async {
        isLoading = true
        clients = (try? await FirestoreService.shared.fetchClients()) ?? []
        isLoading = false
    }
}

// MARK: - Room List
struct RoomListView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    private let allClientsFilterKey = "__all_clients__"
    @AppStorage("selectedClientFilterId") private var selectedClientId: String = "__all_clients__"
    @State private var clients: [Client] = []
    @State private var rooms: [RoomListItem] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showAddFloor = false
    @State private var showClientPickerForAddFloor = false
    @State private var pendingAddFloorClientId = ""
    @State private var showUpgradeAlert = false
    @State private var upgradeMessage = ""

    private var clientFilteredRooms: [RoomListItem] {
        guard selectedClientId != allClientsFilterKey else { return rooms }
        return rooms.filter { $0.clientId == selectedClientId }
    }

    private var selectedClientDisplayName: String {
        guard selectedClientId != allClientsFilterKey else {
            return ipmLocalized(appLanguage, de: "Alle Kunden", en: "All clients")
        }
        return clients.first(where: { $0.id == selectedClientId })?.name
            ?? ipmLocalized(appLanguage, de: "Kunde wählen", en: "Select client")
    }

    private var filtered: [RoomListItem] {
        guard !searchText.isEmpty else { return clientFilteredRooms }
        return clientFilteredRooms.filter {
            $0.floor.name.localizedCaseInsensitiveContains(searchText) ||
            $0.clientName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()

                if filtered.isEmpty && !isLoading {
                    IPMEmptyState(
                        icon: "map",
                        title: ipmLocalized(appLanguage, de: "Keine Räume im Filter", en: "No rooms in filter"),
                        subtitle: ipmLocalized(appLanguage, de: "Wähle einen anderen Kunden oder lege einen Raum an", en: "Choose another client or create a room")
                    )
                    .transition(.ipmFadeSlide)
                    .ipmFlowEntrance(delay: 0.04)
                } else {
                    List {
                        ForEach(filtered) { item in
                            NavigationLink(destination: FloorDetailView(floor: item.floor, clientId: item.clientId)) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(IPMColors.green.opacity(0.16))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(IPMColors.green)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.floor.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                                        Text(item.clientName)
                                            .font(.system(size: 12))
                                            .foregroundStyle(IPMColors.brownMid)
                                    }
                                }
                                .padding(.vertical, 3)
                            }
                            .buttonStyle(IPMPressableStyle())
                            .listRowBackground(AdaptiveColor.card(scheme))
                            .listRowSeparatorTint(AdaptiveColor.cardSecondary(scheme))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AdaptiveColor.background(scheme))
                    .transition(.ipmFadeSlide)
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.88), value: filtered.isEmpty)
            .animation(.spring(response: 0.36, dampingFraction: 0.9), value: filtered.count)
            .searchable(text: $searchText, prompt: ipmLocalized(appLanguage, de: "Räume suchen", en: "Search rooms"))
            .navigationTitle(ipmLocalized(appLanguage, de: "Räume", en: "Rooms"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        guard !clients.isEmpty else { return }
                        if selectedClientId == allClientsFilterKey {
                            showClientPickerForAddFloor = true
                        } else {
                            let currentCount = rooms.filter { $0.clientId == selectedClientId }.count
                            if let message = subscription.canAddRoom(currentCountForClient: currentCount) {
                                upgradeMessage = message
                                showUpgradeAlert = true
                                return
                            }
                            pendingAddFloorClientId = selectedClientId
                            showAddFloor = true
                        }
                    } label: {
                        Label(ipmLocalized(appLanguage, de: "Raum", en: "Room"), systemImage: "plus.circle.fill")
                    }
                    .tint(selectedClientId != allClientsFilterKey &&
                          subscription.canAddRoom(currentCountForClient: rooms.filter { $0.clientId == selectedClientId }.count) != nil
                          ? IPMColors.brownMid : IPMColors.green)
                    .disabled(clients.isEmpty)
                    .opacity(clients.isEmpty ? 0.72 : 1)
                }
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
                            Text(selectedClientDisplayName)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(IPMColors.greenDark)
                    }
                }
            }
            .sheet(isPresented: $showAddFloor) {
                AddFloorView(
                    clientId: pendingAddFloorClientId,
                    currentFloorCount: rooms.filter { $0.clientId == pendingAddFloorClientId }.count
                ) { await loadRooms() }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                ipmLocalized(appLanguage, de: "Kunde für neuen Raum wählen", en: "Select client for new room"),
                isPresented: $showClientPickerForAddFloor,
                titleVisibility: .visible
            ) {
                ForEach(clients) { client in
                    Button(client.name) {
                        pendingAddFloorClientId = client.id ?? ""
                        guard !pendingAddFloorClientId.isEmpty else { return }
                        let currentCount = rooms.filter { $0.clientId == pendingAddFloorClientId }.count
                        if let message = subscription.canAddRoom(currentCountForClient: currentCount) {
                            upgradeMessage = message
                            showUpgradeAlert = true
                            return
                        }
                        showAddFloor = true
                    }
                }
                Button(ipmLocalized(appLanguage, de: "Abbrechen", en: "Cancel"), role: .cancel) {}
            }
            .alert(ipmLocalized(appLanguage, de: "Limit erreicht", en: "Limit reached"), isPresented: $showUpgradeAlert) {
                Button(ipmLocalized(appLanguage, de: "OK", en: "OK"), role: .cancel) {}
            } message: {
                Text(upgradeMessage)
            }
            .task { await loadRooms() }
            .refreshable { await loadRooms() }
        }
    }

    private func loadRooms() async {
        isLoading = true
        defer { isLoading = false }
        clients = (try? await FirestoreService.shared.fetchClients()) ?? []
        let result = await withTaskGroup(of: [RoomListItem].self) { group in
            for client in clients {
                guard let clientId = client.id else { continue }
                group.addTask {
                    let floors = (try? await FirestoreService.shared.fetchFloors(clientId: clientId)) ?? []
                    return floors.map { RoomListItem(clientId: clientId, clientName: client.name, floor: $0) }
                }
            }

            var allRooms: [RoomListItem] = []
            for await roomItems in group {
                allRooms += roomItems
            }
            return allRooms
        }
        rooms = result.sorted {
            if $0.clientName == $1.clientName { return $0.floor.name < $1.floor.name }
            return $0.clientName < $1.clientName
        }
        if selectedClientId != allClientsFilterKey, !clients.contains(where: { $0.id == selectedClientId }) {
            selectedClientId = allClientsFilterKey
        }
    }
}

// MARK: - Client Row
struct ClientRow: View {
    @Environment(\.colorScheme) var scheme
    let client: Client

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(IPMColors.brownMid.opacity(0.12))
                    .frame(width: 42, height: 42)
                Text(String(client.name.prefix(1)).uppercased())
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(IPMColors.brownMid)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(client.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                Text(client.adresse)
                    .font(.system(size: 12))
                    .foregroundStyle(IPMColors.brownMid)
                    .lineLimit(1)
                if !client.kontaktName.isEmpty {
                    Text(client.kontaktName)
                        .font(.system(size: 11))
                        .foregroundStyle(IPMColors.brownMid.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Client Detail
struct ClientDetailView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    let client: Client
    @State private var currentClient: Client
    @State private var floors: [Floor] = []
    @State private var showAddFloor = false
    @State private var showEditClient = false
    @State private var isExporting = false
    @State private var exportFileURL: URL?
    @State private var exportError: String?
    @State private var showUpgradeAlert = false
    @State private var upgradeMessage = ""

    init(client: Client) {
        self.client = client
        _currentClient = State(initialValue: client)
    }

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()
            List {
                Section {
                    InfoRow(icon: "building.2.fill", label: ipmLocalized(appLanguage, de: "Kunde", en: "Client"), value: currentClient.name, color: IPMColors.greenDark)
                    InfoRow(icon: "mappin.circle.fill", label: ipmLocalized(appLanguage, de: "Adresse", en: "Address"), value: currentClient.adresse, color: IPMColors.brown)
                    AddressStaticMapView(address: currentClient.adresse, appLanguage: appLanguage)
                    if !currentClient.kontaktName.isEmpty {
                        InfoRow(icon: "person.fill", label: ipmLocalized(appLanguage, de: "Ansprechpartner", en: "Contact"), value: currentClient.kontaktName, color: IPMColors.green)
                    }
                    if !currentClient.kontaktTelefon.isEmpty {
                        InfoRow(icon: "phone.fill", label: ipmLocalized(appLanguage, de: "Telefon", en: "Phone"), value: currentClient.kontaktTelefon, color: IPMColors.green)
                    }
                    if !currentClient.zahlungsmethode.isEmpty {
                        InfoRow(icon: "creditcard.fill", label: ipmLocalized(appLanguage, de: "Zahlung", en: "Payment"), value: currentClient.zahlungsmethode, color: IPMColors.brownMid)
                    }
                } header: { SectionLabel(ipmLocalized(appLanguage, de: "Kontakt", en: "Contact")) }
                .listRowBackground(AdaptiveColor.card(scheme))

                if !currentClient.notizen.isEmpty {
                    Section {
                        Text(currentClient.notizen)
                            .font(.system(size: 14))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                            .padding(.vertical, 4)
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Notizen", en: "Notes")) }
                    .listRowBackground(AdaptiveColor.card(scheme))
                }

                Section {
                    ForEach(floors) { floor in
                        NavigationLink(destination: FloorDetailView(floor: floor, clientId: currentClient.id ?? "")) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(IPMColors.green.opacity(0.12))
                                        .frame(width: 34, height: 34)
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(IPMColors.green)
                                }
                                Text(floor.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowBackground(AdaptiveColor.card(scheme))
                    }
                    .onDelete { indexSet in
                        Task {
                            for i in indexSet {
                                try? await FirestoreService.shared.deleteFloor(floors[i], clientId: currentClient.id ?? "")
                            }
                            await loadFloors()
                        }
                    }

                    Button {
                        if let message = subscription.canAddRoom(currentCountForClient: floors.count) {
                            upgradeMessage = message
                            showUpgradeAlert = true
                            return
                        }
                        showAddFloor = true
                    } label: {
                        Label(ipmLocalized(appLanguage, de: "Raum hinzufügen", en: "Add room"), systemImage: "plus.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(subscription.canAddRoom(currentCountForClient: floors.count) == nil ? IPMColors.green : IPMColors.brownMid)
                    }
                    .listRowBackground(AdaptiveColor.card(scheme))
                } header: { SectionLabel("\(ipmLocalized(appLanguage, de: "Räume / Etagen", en: "Rooms / Floors")) (\(floors.count))") }

                Section {
                    Button {
                        Task { await exportLocationData() }
                    } label: {
                        HStack {
                            if isExporting {
                                ProgressView().tint(IPMColors.green)
                            }
                            Label(
                                ipmLocalized(appLanguage, de: "Als Excel exportieren", en: "Export as Excel"),
                                systemImage: "square.and.arrow.up"
                            )
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(IPMColors.green)
                        }
                    }
                    .disabled(isExporting)
                    .listRowBackground(AdaptiveColor.card(scheme))

                    if let exportFileURL {
                        ShareLink(item: exportFileURL) {
                            Label(ipmLocalized(appLanguage, de: "Export teilen", en: "Share export"), systemImage: "doc.badge.arrow.up")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(IPMColors.greenDark)
                        }
                        .listRowBackground(AdaptiveColor.card(scheme))
                    }

                    if let exportError {
                        Text(exportError)
                            .font(.system(size: 12))
                            .foregroundStyle(IPMColors.critical)
                            .listRowBackground(AdaptiveColor.card(scheme))
                    }
                } header: { SectionLabel(ipmLocalized(appLanguage, de: "Export", en: "Export")) }
            }
            .scrollContentBackground(.hidden)
            .background(AdaptiveColor.background(scheme))
        }
        .navigationTitle(currentClient.name)
        .ipmNavigationBarTitleDisplayModeLarge()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(ipmLocalized(appLanguage, de: "Bearbeiten", en: "Edit")) {
                    showEditClient = true
                }
                .foregroundStyle(IPMColors.green)
            }
        }
        .sheet(isPresented: $showAddFloor) {
            AddFloorView(clientId: currentClient.id ?? "", currentFloorCount: floors.count) { await loadFloors() }
        }
        .sheet(isPresented: $showEditClient) {
            EditClientView(client: currentClient) { updatedClient in
                currentClient = updatedClient
            }
        }
        .alert(ipmLocalized(appLanguage, de: "Limit erreicht", en: "Limit reached"), isPresented: $showUpgradeAlert) {
            Button(ipmLocalized(appLanguage, de: "OK", en: "OK"), role: .cancel) {}
        } message: {
            Text(upgradeMessage)
        }
        .task { await loadFloors() }
        .refreshable { await loadFloors() }
    }

    private func loadFloors() async {
        floors = (try? await FirestoreService.shared.fetchFloors(clientId: currentClient.id ?? "")) ?? []
    }

    private func exportLocationData() async {
        isExporting = true
        exportError = nil
        do {
            exportFileURL = try await FirestoreService.shared.exportClientDataToCSV(client: currentClient, language: appLanguage)
        } catch {
            exportError = error.localizedDescription
        }
        isExporting = false
    }
}

private struct EditClientView: View {
    let client: Client
    let onSave: (Client) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"

    @State private var name: String
    @State private var adresse: String
    @State private var kontaktName: String
    @State private var kontaktTelefon: String
    @State private var notizen: String
    @State private var zahlungsmethode: String
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSaveErrorAlert = false

    init(client: Client, onSave: @escaping (Client) -> Void) {
        self.client = client
        self.onSave = onSave
        _name = State(initialValue: client.name)
        _adresse = State(initialValue: client.adresse)
        _kontaktName = State(initialValue: client.kontaktName)
        _kontaktTelefon = State(initialValue: client.kontaktTelefon)
        _notizen = State(initialValue: client.notizen)
        _zahlungsmethode = State(initialValue: client.zahlungsmethode)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()
                List {
                    Section {
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Firmenname *", en: "Company name *"), text: $name, icon: "building.2")
                        AddressLookupField(text: $adresse, appLanguage: appLanguage)
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Pflichtfelder", en: "Required fields")) }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Ansprechpartner", en: "Contact person"), text: $kontaktName, icon: "person")
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Telefon", en: "Phone"), text: $kontaktTelefon, icon: "phone", keyboard: .phonePad)
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Zahlungsmethode", en: "Payment method"), text: $zahlungsmethode, icon: "creditcard")
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Kontakt", en: "Contact")) }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        TextField(ipmLocalized(appLanguage, de: "Notizen...", en: "Notes..."), text: $notizen, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.system(size: 14))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Notizen", en: "Notes")) }
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
            .navigationTitle(ipmLocalized(appLanguage, de: "Kunde bearbeiten", en: "Edit client"))
            .ipmNavigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ipmLocalized(appLanguage, de: "Abbrechen", en: "Cancel")) { dismiss() }
                        .foregroundStyle(IPMColors.brownMid)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(ipmLocalized(appLanguage, de: "Speichern", en: "Save")) {
                        Task { await saveClient() }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(name.isEmpty || adresse.isEmpty || isSaving ? IPMColors.brownMid : IPMColors.green)
                    .disabled(name.isEmpty || adresse.isEmpty || isSaving)
                }
            }
        }
        .alert(ipmLocalized(appLanguage, de: "Speichern fehlgeschlagen", en: "Save failed"), isPresented: $showSaveErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? ipmLocalized(appLanguage, de: "Unbekannter Fehler.", en: "Unknown error."))
        }
    }

    private func saveClient() async {
        isSaving = true
        defer { isSaving = false }
        saveError = nil

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = adresse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedAddress.isEmpty else {
            saveError = ipmLocalized(appLanguage, de: "Name und Adresse sind erforderlich.", en: "Name and address are required.")
            showSaveErrorAlert = true
            return
        }

        var updated = client
        updated.name = trimmedName
        updated.adresse = trimmedAddress
        updated.kontaktName = kontaktName
        updated.kontaktTelefon = kontaktTelefon
        updated.notizen = notizen
        updated.zahlungsmethode = zahlungsmethode
        do {
            try await FirestoreService.shared.saveClient(updated)
            onSave(updated)
            dismiss()
        } catch {
            saveError = error.localizedDescription
            showSaveErrorAlert = true
        }
    }
}

private struct AddressStaticMapView: View {
    let address: String
    let appLanguage: String
    @State private var region: MKCoordinateRegion?
    @State private var destinationMapItem: MKMapItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let region {
                Map(
                    position: .constant(.region(region)),
                    interactionModes: [.zoom, .pan]
                ) {
                    Marker(
                        "",
                        coordinate: region.center
                    )
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(IPMColors.green.opacity(0.2), lineWidth: 1)
                }
                .padding(.vertical, 4)

                if let destinationMapItem {
                    Button {
                        openRoute(to: destinationMapItem)
                    } label: {
                        Label(
                            ipmLocalized(appLanguage, de: "Route starten", en: "Start route"),
                            systemImage: "car.fill"
                        )
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(IPMColors.green)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task(id: address) {
            await resolveAddress()
        }
    }

    @MainActor
    private func resolveAddress() async {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            region = nil
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let first = response.mapItems.first else {
                region = nil
                destinationMapItem = nil
                return
            }
            let coordinate = first.location.coordinate
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            destinationMapItem = first
        } catch {
            region = nil
            destinationMapItem = nil
        }
    }

    private func openRoute(to destination: MKMapItem) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        MKMapItem.openMaps(with: [MKMapItem.forCurrentLocation(), destination], launchOptions: options)
    }
}

// MARK: - Add Client
struct AddClientView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    let currentClientCount: Int
    let onSave: () async -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var name = ""
    @State private var adresse = ""
    @State private var kontaktName = ""
    @State private var kontaktTelefon = ""
    @State private var notizen = ""
    @State private var zahlungsmethode = ""
    @State private var isSaving = false
    @State private var limitError: String?
    @State private var saveError: String?
    @State private var showSaveErrorAlert = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !adresse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSaving
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()
                List {
                    Section {
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Firmenname *", en: "Company name *"), text: $name, icon: "building.2")
                        AddressLookupField(text: $adresse, appLanguage: appLanguage)
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Pflichtfelder", en: "Required fields")) }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Ansprechpartner", en: "Contact person"), text: $kontaktName, icon: "person")
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Telefon", en: "Phone"), text: $kontaktTelefon, icon: "phone", keyboard: .phonePad)
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Zahlungsmethode", en: "Payment method"), text: $zahlungsmethode, icon: "creditcard")
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Kontakt", en: "Contact")) }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    Section {
                        TextField(ipmLocalized(appLanguage, de: "Notizen...", en: "Notes..."), text: $notizen, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.system(size: 14))
                            .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "Notizen", en: "Notes")) }
                    .listRowBackground(AdaptiveColor.card(scheme))

                    if let limitError {
                        Section {
                            Text(limitError)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(IPMColors.critical)
                        }
                        .listRowBackground(AdaptiveColor.card(scheme))
                    }

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
            .navigationTitle(ipmLocalized(appLanguage, de: "Neuer Kunde", en: "New client"))
            .ipmNavigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ipmLocalized(appLanguage, de: "Abbrechen", en: "Cancel")) { dismiss() }.foregroundStyle(IPMColors.brownMid)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(ipmLocalized(appLanguage, de: "Speichern", en: "Save")) {
                        Task {
                            saveError = nil
                            if let msg = subscription.canAddClient(currentCount: currentClientCount) {
                                limitError = msg
                                saveError = msg
                                showSaveErrorAlert = true
                                return
                            }
                            isSaving = true
                            defer { isSaving = false }
                            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            let trimmedAddress = adresse.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmedName.isEmpty, !trimmedAddress.isEmpty else {
                                saveError = ipmLocalized(appLanguage, de: "Name und Adresse sind erforderlich.", en: "Name and address are required.")
                                showSaveErrorAlert = true
                                return
                            }
                            let c = Client(name: trimmedName, adresse: trimmedAddress, kontaktName: kontaktName, kontaktTelefon: kontaktTelefon, notizen: notizen, zahlungsmethode: zahlungsmethode)
                            do {
                                try await FirestoreService.shared.saveClient(c)
                                await onSave()
                                dismiss()
                            } catch {
                                saveError = error.localizedDescription
                                showSaveErrorAlert = true
                            }
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(canSave ? IPMColors.green : IPMColors.brownMid.opacity(0.68))
                    .disabled(!canSave)
                }
            }
        }
        .alert(ipmLocalized(appLanguage, de: "Kunde konnte nicht gespeichert werden", en: "Could not save client"), isPresented: $showSaveErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? limitError ?? ipmLocalized(appLanguage, de: "Unbekannter Fehler.", en: "Unknown error."))
        }
    }
}

private struct AddressLookupField: View {
    @Binding var text: String
    let appLanguage: String
    @StateObject private var viewModel = AddressSearchViewModel()
    @State private var typingFinishedTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            IPMFormField(
                label: ipmLocalized(appLanguage, de: "Adresse *", en: "Address *"),
                text: $text,
                icon: "mappin"
            )

            if viewModel.shouldShowSuggestions &&
                !viewModel.results.isEmpty &&
                text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(viewModel.results.prefix(6).enumerated()), id: \.offset) { index, completion in
                        Button {
                            Task { await apply(completion: completion) }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(completion.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(IPMColors.greenDark)
                                if !completion.subtitle.isEmpty {
                                    Text(completion.subtitle)
                                        .font(.system(size: 12))
                                        .foregroundStyle(IPMColors.brownMid)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        if index < min(viewModel.results.count, 6) - 1 {
                            Divider().padding(.leading, 10)
                        }
                    }
                }
                .background(IPMColors.green.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if let previewRegion = viewModel.mapPreviewRegion {
                Map(
                    position: .constant(.region(previewRegion)),
                    interactionModes: [.zoom, .pan]
                ) {
                    Marker(
                        "",
                        coordinate: previewRegion.center
                    )
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(IPMColors.green.opacity(0.2), lineWidth: 1)
                }
            }
        }
        .onAppear {
            viewModel.query = text
        }
        .onChange(of: text) { _, newValue in
            if viewModel.query != newValue {
                viewModel.query = newValue
                viewModel.shouldShowSuggestions = true
                typingFinishedTask?.cancel()
                typingFinishedTask = Task {
                    try? await Task.sleep(nanoseconds: 900_000_000)
                    guard !Task.isCancelled else { return }
                    await viewModel.finishTyping()
                }
            }
        }
    }

    private func apply(completion: MKLocalSearchCompletion) async {
        if let resolvedAddress = await viewModel.resolve(completion: completion) {
            text = resolvedAddress
        } else {
            let fallback = [completion.title, completion.subtitle]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            text = fallback
        }
        await viewModel.finishTyping()
    }
}

@MainActor
private final class AddressSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query: String = "" {
        didSet {
            completer.queryFragment = query.trimmingCharacters(in: .whitespacesAndNewlines)
            scheduleMapPreview(for: query)
        }
    }
    @Published var results: [MKLocalSearchCompletion] = []
    @Published var mapPreviewRegion: MKCoordinateRegion?
    @Published var shouldShowSuggestions = true

    private let completer = MKLocalSearchCompleter()
    private var mapSearchTask: Task<Void, Never>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }

    func clearResults() {
        results = []
    }

    func finishTyping() async {
        shouldShowSuggestions = false
        clearResults()
        await resolveMapPreview(for: query)
    }

    func resolve(completion: MKLocalSearchCompletion) async -> String? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            if let first = response.mapItems.first {
                updateMapRegion(from: first)
                return formatAddress(from: first)
            }
        } catch {
            return nil
        }
        return nil
    }

    private func scheduleMapPreview(for input: String) {
        mapSearchTask?.cancel()
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            mapPreviewRegion = nil
            return
        }
        mapSearchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self?.resolveMapPreview(for: trimmed)
        }
    }

    private func resolveMapPreview(for input: String) async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            mapPreviewRegion = nil
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let first = response.mapItems.first else {
                mapPreviewRegion = nil
                return
            }
            updateMapRegion(from: first)
        } catch {
            mapPreviewRegion = nil
        }
    }

    private func updateMapRegion(from mapItem: MKMapItem) {
        let coordinate = mapItem.location.coordinate
        mapPreviewRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    private func formatAddress(from mapItem: MKMapItem) -> String {
        if #available(iOS 26.0, *) {
            if let singleLineAddress = mapItem.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true),
               !singleLineAddress.isEmpty {
                return singleLineAddress
            }

            if let fullAddress = mapItem.address?.fullAddress,
               !fullAddress.isEmpty {
                return fullAddress.replacingOccurrences(of: "\n", with: ", ")
            }
        }

        return mapItem.name ?? ""
    }
}

// MARK: - Add Floor
struct AddFloorView: View {
    @EnvironmentObject var subscription: SubscriptionManager
    let clientId: String
    let currentFloorCount: Int
    let onSave: () async -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var scheme
    @AppStorage("appLanguage") private var appLanguage = "de"
    @State private var name = ""
    @State private var limitError: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveColor.background(scheme).ignoresSafeArea()
                List {
                    Section {
                        IPMFormField(label: ipmLocalized(appLanguage, de: "Raumname", en: "Room name"), text: $name, icon: "map")
                    } header: { SectionLabel(ipmLocalized(appLanguage, de: "z.B. EG · Lager · Keller · OG", en: "e.g. ground floor · storage · basement · upper floor")) }
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
            .navigationTitle(ipmLocalized(appLanguage, de: "Neuer Raum", en: "New room"))
            .ipmNavigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ipmLocalized(appLanguage, de: "Abbrechen", en: "Cancel")) { dismiss() }.foregroundStyle(IPMColors.brownMid)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(ipmLocalized(appLanguage, de: "Speichern", en: "Save")) {
                        Task {
                            if let msg = subscription.canAddRoom(currentCountForClient: currentFloorCount) {
                                limitError = msg
                                return
                            }
                            try? await FirestoreService.shared.saveFloor(Floor(name: name), clientId: clientId)
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
