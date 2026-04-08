import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
#if canImport(UIKit)
import UIKit
#endif

enum FirestoreServiceError: LocalizedError {
    case notAuthenticated
    private var appLanguage: String { UserDefaults.standard.string(forKey: "appLanguage") ?? "de" }

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return ipmLocalized(appLanguage, de: "Bitte zuerst anmelden.", en: "Please sign in first.")
        }
    }
}

// MARK: - Due Trap Item (typed struct, kein Tuple-Chaos)
struct DueTrapItem: Identifiable, Sendable {
    var id: String { trap.id ?? UUID().uuidString }
    let clientName: String
    let floorName: String
    let clientId: String
    let floorId: String
    let trap: Trap
}

struct TrapCatalogItem: Identifiable, Sendable {
    var id: String { trap.id ?? "\(clientId)_\(floorId)_\(trap.nummer)" }
    let clientName: String
    let floorName: String
    let clientId: String
    let floorId: String
    let trap: Trap
}

struct DashboardFindingCount: Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let count: Int
}

struct DashboardRoomSummary: Identifiable, Sendable {
    var id: String { "\(clientId)_\(floorId)" }
    let clientId: String
    let clientName: String
    let floorId: String
    let floor: Floor
    let totalTrapCount: Int
    let overdueCount: Int
    let dueTodayCount: Int
    let dueWeekCount: Int
    let dueMonthCount: Int
    let nextInspection: Date?
    let inspectionCount: Int
    let latestFindings: Int
    let averageFindings: Double
    let findingsDelta: Double?
    let findingsSeries: [Double]
    let latestTemperature: Double?
    let averageTemperature: Double?
    let temperatureDelta: Double?
    let temperatureSeries: [Double]
    let latestHumidity: Double?
    let averageHumidity: Double?
    let humidityDelta: Double?
    let humiditySeries: [Double]
    let topFindings: [DashboardFindingCount]
    let insectCounts: [String: Int]
}

struct DashboardTrapSummary: Identifiable, Sendable {
    var id: String { trapId }
    let clientId: String
    let clientName: String
    let floorId: String
    let floorName: String
    let trapId: String
    let trap: Trap
    let inspectionCount: Int
    let latestFindings: Int
    let averageFindings: Double
    let findingsDelta: Double?
    let latestTemperature: Double?
    let latestHumidity: Double?
    let topFindings: [DashboardFindingCount]
    let insectCounts: [String: Int]
    let roomKey: String
    let roomLabel: String
}

struct DashboardInsectSummary: Identifiable, Sendable {
    var id: String { name }
    let name: String
    let totalCount: Int
    let roomCount: Int
    let trapCount: Int
    let topRoomName: String?
    let topRoomCount: Int
    let topTrapName: String?
    let topTrapCount: Int
}

struct DashboardSnapshot: Sendable {
    let clients: [Client]
    let trapItems: [DueTrapItem]
    let roomSummaries: [DashboardRoomSummary]
    let trapSummaries: [DashboardTrapSummary]
    let insectSummaries: [DashboardInsectSummary]
}

actor FirestoreCache {
    struct Entry<Value: Sendable>: Sendable {
        let value: Value
        let createdAt: Date
    }

    private var clientsByUser: [String: Entry<[Client]>] = [:]
    private var floorsByKey: [String: Entry<[Floor]>] = [:]
    private var trapsByKey: [String: Entry<[Trap]>] = [:]
    private var inspectionsByKey: [String: Entry<[Inspection]>] = [:]
    private var dueByUser: [String: Entry<[DueTrapItem]>] = [:]
    private var allTrapsByUser: [String: Entry<[TrapCatalogItem]>] = [:]

    func clients(for userId: String, maxAge: TimeInterval) -> [Client]? {
        value(from: clientsByUser[userId], maxAge: maxAge)
    }

    func setClients(_ value: [Client], for userId: String) {
        clientsByUser[userId] = Entry(value: value, createdAt: Date())
    }

    func floors(for key: String, maxAge: TimeInterval) -> [Floor]? {
        value(from: floorsByKey[key], maxAge: maxAge)
    }

    func setFloors(_ value: [Floor], for key: String) {
        floorsByKey[key] = Entry(value: value, createdAt: Date())
    }

    func traps(for key: String, maxAge: TimeInterval) -> [Trap]? {
        value(from: trapsByKey[key], maxAge: maxAge)
    }

    func setTraps(_ value: [Trap], for key: String) {
        trapsByKey[key] = Entry(value: value, createdAt: Date())
    }

    func inspections(for key: String, maxAge: TimeInterval) -> [Inspection]? {
        value(from: inspectionsByKey[key], maxAge: maxAge)
    }

    func setInspections(_ value: [Inspection], for key: String) {
        inspectionsByKey[key] = Entry(value: value, createdAt: Date())
    }

    func due(for userId: String, maxAge: TimeInterval) -> [DueTrapItem]? {
        value(from: dueByUser[userId], maxAge: maxAge)
    }

    func setDue(_ value: [DueTrapItem], for userId: String) {
        dueByUser[userId] = Entry(value: value, createdAt: Date())
    }

    func allTraps(for userId: String, maxAge: TimeInterval) -> [TrapCatalogItem]? {
        value(from: allTrapsByUser[userId], maxAge: maxAge)
    }

    func setAllTraps(_ value: [TrapCatalogItem], for userId: String) {
        allTrapsByUser[userId] = Entry(value: value, createdAt: Date())
    }

    func invalidateAll(for userId: String) {
        clientsByUser.removeValue(forKey: userId)
        dueByUser.removeValue(forKey: userId)
        allTrapsByUser.removeValue(forKey: userId)
        floorsByKey = floorsByKey.filter { !$0.key.hasPrefix("\(userId)|") }
        trapsByKey = trapsByKey.filter { !$0.key.hasPrefix("\(userId)|") }
        inspectionsByKey = inspectionsByKey.filter { !$0.key.hasPrefix("\(userId)|") }
    }

    func invalidateDerived(for userId: String) {
        dueByUser.removeValue(forKey: userId)
        allTrapsByUser.removeValue(forKey: userId)
    }

    func invalidateClients(for userId: String) {
        clientsByUser.removeValue(forKey: userId)
    }

    func invalidateClientSubtree(userId: String, clientId: String) {
        floorsByKey.removeValue(forKey: "\(userId)|\(clientId)")
        trapsByKey = trapsByKey.filter { !$0.key.hasPrefix("\(userId)|\(clientId)|") }
        inspectionsByKey = inspectionsByKey.filter { !$0.key.hasPrefix("\(userId)|\(clientId)|") }
    }

    func invalidateFloors(for key: String) {
        floorsByKey.removeValue(forKey: key)
    }

    func invalidateTraps(for key: String) {
        trapsByKey.removeValue(forKey: key)
    }

    func invalidateInspections(for key: String) {
        inspectionsByKey.removeValue(forKey: key)
    }

    func invalidateInspectionsWithPrefix(prefix: String) {
        inspectionsByKey = inspectionsByKey.filter { !$0.key.hasPrefix(prefix) }
    }

    private func value<Value>(from entry: Entry<Value>?, maxAge: TimeInterval) -> Value? {
        guard let entry else { return nil }
        guard Date().timeIntervalSince(entry.createdAt) <= maxAge else { return nil }
        return entry.value
    }
}

// MARK: - FirestoreService
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let cache = FirestoreCache()
    // Längerer In-Memory-Cache reduziert Re-Loads beim Tab-Wechsel deutlich.
    private let cacheTTL: TimeInterval = 180

    private var userId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    private func ensureAuthenticated() throws {
        guard !userId.isEmpty else { throw FirestoreServiceError.notAuthenticated }
    }

    // MARK: Refs
    private func clientsRef() -> CollectionReference {
        db.collection("users").document(userId).collection("clients")
    }
    private func floorsRef(clientId: String) -> CollectionReference {
        clientsRef().document(clientId).collection("floors")
    }
    private func trapsRef(clientId: String, floorId: String) -> CollectionReference {
        floorsRef(clientId: clientId).document(floorId).collection("traps")
    }
    private func inspectionsRef(clientId: String, floorId: String, trapId: String) -> CollectionReference {
        trapsRef(clientId: clientId, floorId: floorId).document(trapId).collection("inspections")
    }

    private func floorsCacheKey(clientId: String) -> String { "\(userId)|\(clientId)" }
    private func trapsCacheKey(clientId: String, floorId: String) -> String { "\(userId)|\(clientId)|\(floorId)" }
    private func inspectionsCacheKey(clientId: String, floorId: String, trapId: String) -> String { "\(userId)|\(clientId)|\(floorId)|\(trapId)" }

    nonisolated private func isOverdue(_ date: Date, now: Date = Date()) -> Bool {
        let days = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
        return days < 0
    }

    nonisolated private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    nonisolated private func delta(_ values: [Double]) -> Double? {
        guard values.count >= 2 else { return nil }
        return values[values.count - 1] - values[values.count - 2]
    }

    nonisolated private func buildInsectSummaries(from trapSummaries: [DashboardTrapSummary]) -> [DashboardInsectSummary] {
        struct Accumulator {
            var totalCount = 0
            var roomCounts: [String: Int] = [:]
            var trapCounts: [String: Int] = [:]
            var roomIds: Set<String> = []
            var trapIds: Set<String> = []
        }

        var grouped: [String: Accumulator] = [:]
        for trapSummary in trapSummaries {
            for (name, count) in trapSummary.insectCounts where count > 0 {
                grouped[name, default: Accumulator()].totalCount += count
                grouped[name, default: Accumulator()].roomCounts[trapSummary.roomLabel, default: 0] += count
                grouped[name, default: Accumulator()].trapCounts["\(trapSummary.floorName) · \(trapSummary.trap.nummer)", default: 0] += count
                grouped[name, default: Accumulator()].roomIds.insert(trapSummary.roomKey)
                grouped[name, default: Accumulator()].trapIds.insert(trapSummary.trapId)
            }
        }

        return grouped.map { name, accumulator in
            let topRoom = accumulator.roomCounts.max { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key.localizedStandardCompare(rhs.key) == .orderedDescending
                }
                return lhs.value < rhs.value
            }
            let topTrap = accumulator.trapCounts.max { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key.localizedStandardCompare(rhs.key) == .orderedDescending
                }
                return lhs.value < rhs.value
            }

            return DashboardInsectSummary(
                name: name,
                totalCount: accumulator.totalCount,
                roomCount: accumulator.roomIds.count,
                trapCount: accumulator.trapIds.count,
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

    nonisolated static func nextInspectionDate(
        from inspections: [Inspection],
        fallbackDate: Date,
        intervalDays: Int
    ) -> Date {
        let latestInspectionDate = inspections.map(\.datum).max() ?? fallbackDate
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: latestInspectionDate) ?? latestInspectionDate
    }

    private func deleteClientSubtree(clientId: String) async throws {
        let floorsSnapshot = try await floorsRef(clientId: clientId).getDocuments()
        for floorDoc in floorsSnapshot.documents {
            try await deleteFloorSubtree(clientId: clientId, floorId: floorDoc.documentID)
        }
    }

    private func deleteFloorSubtree(clientId: String, floorId: String) async throws {
        let trapsSnapshot = try await trapsRef(clientId: clientId, floorId: floorId).getDocuments()
        for trapDoc in trapsSnapshot.documents {
            try await deleteTrapSubtree(clientId: clientId, floorId: floorId, trapId: trapDoc.documentID)
        }
        try await floorsRef(clientId: clientId).document(floorId).delete()
    }

    private func deleteTrapSubtree(clientId: String, floorId: String, trapId: String) async throws {
        let inspectionsSnapshot = try await inspectionsRef(clientId: clientId, floorId: floorId, trapId: trapId).getDocuments()
        for inspectionDoc in inspectionsSnapshot.documents {
            if let inspection = try? inspectionDoc.data(as: Inspection.self) {
                await deleteInspectionAttachments(for: inspection)
            }
            try await inspectionDoc.reference.delete()
        }
        try await trapsRef(clientId: clientId, floorId: floorId).document(trapId).delete()
    }

    private func deleteInspectionAttachments(for inspection: Inspection) async {
        for photoURL in inspection.fotoURLs {
            await deleteStoredPhoto(at: photoURL)
        }
    }

    private func deleteStoredPhoto(at urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        if url.isFileURL {
            try? FileManager.default.removeItem(at: url)
            return
        }

        guard urlString.hasPrefix("gs://") || urlString.hasPrefix("https://") else { return }
        do {
            let reference = storage.reference(forURL: urlString)
            try await reference.delete()
        } catch {
            // Ignore missing or already-deleted files during cleanup.
        }
    }

    // MARK: - Clients
    func fetchClients() async throws -> [Client] {
        try ensureAuthenticated()
        if let cached = await cache.clients(for: userId, maxAge: cacheTTL) {
            return cached
        }
        let snap = try await clientsRef().order(by: "name").getDocuments()
        let clients = snap.documents.compactMap { try? $0.data(as: Client.self) }
        await cache.setClients(clients, for: userId)
        return clients
    }

    func saveClient(_ client: Client) async throws {
        try ensureAuthenticated()
        if let id = client.id {
            try clientsRef().document(id).setData(from: client)
        } else {
            _ = try clientsRef().addDocument(from: client)
        }
        await cache.invalidateClients(for: userId)
        await cache.invalidateDerived(for: userId)
    }

    func deleteClient(_ client: Client) async throws {
        try ensureAuthenticated()
        guard let id = client.id else { return }
        try await deleteClientSubtree(clientId: id)
        try await clientsRef().document(id).delete()
        await cache.invalidateClients(for: userId)
        await cache.invalidateClientSubtree(userId: userId, clientId: id)
        await cache.invalidateDerived(for: userId)
    }

    // MARK: - Floors
    func fetchFloors(clientId: String) async throws -> [Floor] {
        try ensureAuthenticated()
        let key = floorsCacheKey(clientId: clientId)
        if let cached = await cache.floors(for: key, maxAge: cacheTTL) {
            return cached
        }
        let snap = try await floorsRef(clientId: clientId).order(by: "name").getDocuments()
        let floors = snap.documents.compactMap { try? $0.data(as: Floor.self) }
        await cache.setFloors(floors, for: key)
        return floors
    }

    func saveFloor(_ floor: Floor, clientId: String) async throws {
        try ensureAuthenticated()
        if let id = floor.id {
            try floorsRef(clientId: clientId).document(id).setData(from: floor)
        } else {
            _ = try floorsRef(clientId: clientId).addDocument(from: floor)
        }
        await cache.invalidateFloors(for: floorsCacheKey(clientId: clientId))
        await cache.invalidateDerived(for: userId)
    }

    func deleteFloor(_ floor: Floor, clientId: String) async throws {
        try ensureAuthenticated()
        guard let id = floor.id else { return }
        try await deleteFloorSubtree(clientId: clientId, floorId: id)
        await cache.invalidateFloors(for: floorsCacheKey(clientId: clientId))
        await cache.invalidateTraps(for: trapsCacheKey(clientId: clientId, floorId: id))
        await cache.invalidateInspectionsWithPrefix(prefix: "\(userId)|\(clientId)|\(id)|")
        await cache.invalidateDerived(for: userId)
    }

    // MARK: - Traps
    func fetchTraps(clientId: String, floorId: String) async throws -> [Trap] {
        try ensureAuthenticated()
        let key = trapsCacheKey(clientId: clientId, floorId: floorId)
        if let cached = await cache.traps(for: key, maxAge: cacheTTL) {
            return cached
        }
        let snap = try await trapsRef(clientId: clientId, floorId: floorId).order(by: "nummer").getDocuments()
        let traps = snap.documents.compactMap { try? $0.data(as: Trap.self) }
        await cache.setTraps(traps, for: key)
        return traps
    }

    func saveTrap(_ trap: Trap, clientId: String, floorId: String) async throws {
        try ensureAuthenticated()
        if let id = trap.id {
            try trapsRef(clientId: clientId, floorId: floorId).document(id).setData(from: trap)
        } else {
            _ = try trapsRef(clientId: clientId, floorId: floorId).addDocument(from: trap)
        }
        await cache.invalidateTraps(for: trapsCacheKey(clientId: clientId, floorId: floorId))
        await cache.invalidateDerived(for: userId)
    }

    func deleteTrap(_ trap: Trap, clientId: String, floorId: String) async throws {
        try ensureAuthenticated()
        guard let id = trap.id else { return }
        try await deleteTrapSubtree(clientId: clientId, floorId: floorId, trapId: id)
        await cache.invalidateTraps(for: trapsCacheKey(clientId: clientId, floorId: floorId))
        await cache.invalidateInspections(for: inspectionsCacheKey(clientId: clientId, floorId: floorId, trapId: id))
        await cache.invalidateDerived(for: userId)
    }

    func updateTrapNextInspection(trapId: String, clientId: String, floorId: String, from date: Date, intervalDays: Int) async throws {
        try ensureAuthenticated()
        let nextDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: date) ?? date
        try await trapsRef(clientId: clientId, floorId: floorId).document(trapId).updateData([
            "naechstePruefung": Timestamp(date: nextDate)
        ])
        await cache.invalidateTraps(for: trapsCacheKey(clientId: clientId, floorId: floorId))
        await cache.invalidateDerived(for: userId)
    }

    func updateTrapPosition(trapId: String, clientId: String, floorId: String, positionX: Double, positionY: Double) async throws {
        try ensureAuthenticated()
        try await trapsRef(clientId: clientId, floorId: floorId).document(trapId).updateData([
            "positionX": min(1, max(0, positionX)),
            "positionY": min(1, max(0, positionY))
        ])
        await cache.invalidateTraps(for: trapsCacheKey(clientId: clientId, floorId: floorId))
        await cache.invalidateDerived(for: userId)
    }

    // MARK: - Inspections
    func fetchInspections(clientId: String, floorId: String, trapId: String) async throws -> [Inspection] {
        try ensureAuthenticated()
        let key = inspectionsCacheKey(clientId: clientId, floorId: floorId, trapId: trapId)
        if let cached = await cache.inspections(for: key, maxAge: cacheTTL) {
            return cached
        }
        let snap = try await inspectionsRef(clientId: clientId, floorId: floorId, trapId: trapId)
            .order(by: "datum", descending: true)
            .getDocuments()
        let inspections = snap.documents.compactMap { try? $0.data(as: Inspection.self) }
        await cache.setInspections(inspections, for: key)
        return inspections
    }

    func saveInspection(_ inspection: Inspection, clientId: String, floorId: String, trapId: String, intervalDays: Int) async throws {
        try ensureAuthenticated()
        // 1. Inspection speichern
        if let id = inspection.id {
            try inspectionsRef(clientId: clientId, floorId: floorId, trapId: trapId).document(id).setData(from: inspection)
        } else {
            _ = try inspectionsRef(clientId: clientId, floorId: floorId, trapId: trapId).addDocument(from: inspection)
        }
        // 2. Nächste Prüfung direkt per updateData – kein extra Read nötig
        try await updateTrapNextInspection(trapId: trapId, clientId: clientId, floorId: floorId, from: inspection.datum, intervalDays: intervalDays)
        await cache.invalidateInspections(for: inspectionsCacheKey(clientId: clientId, floorId: floorId, trapId: trapId))
        await cache.invalidateDerived(for: userId)
    }

    func deleteInspection(
        _ inspection: Inspection,
        clientId: String,
        floorId: String,
        trapId: String,
        intervalDays: Int,
        fallbackDate: Date
    ) async throws {
        try ensureAuthenticated()
        guard let inspectionId = inspection.id else { return }
        let cacheKey = inspectionsCacheKey(clientId: clientId, floorId: floorId, trapId: trapId)

        try await inspectionsRef(clientId: clientId, floorId: floorId, trapId: trapId).document(inspectionId).delete()
        await deleteInspectionAttachments(for: inspection)
        await cache.invalidateInspections(for: cacheKey)

        let remainingSnapshot = try await inspectionsRef(clientId: clientId, floorId: floorId, trapId: trapId)
            .order(by: "datum", descending: true)
            .getDocuments()
        let remaining = remainingSnapshot.documents.compactMap { try? $0.data(as: Inspection.self) }
        await cache.setInspections(remaining, for: cacheKey)

        let nextDate = Self.nextInspectionDate(from: remaining, fallbackDate: fallbackDate, intervalDays: intervalDays)
        try await trapsRef(clientId: clientId, floorId: floorId).document(trapId).updateData([
            "naechstePruefung": Timestamp(date: nextDate)
        ])

        await cache.invalidateInspections(for: inspectionsCacheKey(clientId: clientId, floorId: floorId, trapId: trapId))
        await cache.invalidateTraps(for: trapsCacheKey(clientId: clientId, floorId: floorId))
        await cache.invalidateDerived(for: userId)
    }

    // MARK: - Dashboard: Fällige Fallen
    func fetchDashboardSnapshot() async throws -> DashboardSnapshot {
        try ensureAuthenticated()
        let clients = try await fetchClients()
        let clientSnapshots = clients.compactMap { client -> (id: String, client: Client)? in
            guard let id = client.id else { return nil }
            return (id: id, client: client)
        }

        let now = Date()
        let weekLimit = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        let monthLimit = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now

        let aggregated = try await withThrowingTaskGroup(of: ([DueTrapItem], [DashboardRoomSummary], [DashboardTrapSummary]).self) { group in
            for entry in clientSnapshots {
                group.addTask {
                    let floors = try await self.fetchFloors(clientId: entry.id)
                    let floorSnapshots: [(id: String, floor: Floor)] = await MainActor.run {
                        floors.compactMap { floor in
                            guard let id = floor.id else { return nil }
                            return (id: id, floor: floor)
                        }
                    }
                    var clientTrapItems: [DueTrapItem] = []
                    var clientRooms: [DashboardRoomSummary] = []
                    var clientTrapSummaries: [DashboardTrapSummary] = []

                    for floorSnapshot in floorSnapshots {
                        let floorId = floorSnapshot.id
                        let floor = floorSnapshot.floor
                        let traps = try await self.fetchTraps(clientId: entry.id, floorId: floorId)
                        let trapSnapshots: [(id: String, trap: Trap)] = await MainActor.run {
                            traps.compactMap { trap in
                                guard let trapId = trap.id else { return nil }
                                return (id: trapId, trap: trap)
                            }
                        }
                        let inspectionsByTrap = try await withThrowingTaskGroup(of: (String, [Inspection]).self) { inspectionGroup in
                            for trapSnapshot in trapSnapshots {
                                inspectionGroup.addTask {
                                    (
                                        trapSnapshot.id,
                                        try await self.fetchInspections(
                                            clientId: entry.id,
                                            floorId: floorId,
                                            trapId: trapSnapshot.id
                                        )
                                    )
                                }
                            }

                            var collected: [(trapId: String, inspections: [Inspection])] = []
                            for try await result in inspectionGroup {
                                collected.append((trapId: result.0, inspections: result.1))
                            }
                            return collected
                        }
                        let inspectionLookup = Dictionary(uniqueKeysWithValues: inspectionsByTrap)
                        let trapItems = traps.map {
                            DueTrapItem(
                                clientName: entry.client.name,
                                floorName: floor.name,
                                clientId: entry.id,
                                floorId: floorId,
                                trap: $0
                            )
                        }

                        var orderedInspectionsByRoom: [Inspection] = []
                        var roomInsectCounts: [String: Int] = [:]

                        for trapSnapshot in trapSnapshots {
                            let orderedInspections = (inspectionLookup[trapSnapshot.id] ?? [])
                                .sorted { $0.datum < $1.datum }
                            orderedInspectionsByRoom += orderedInspections

                            let findingsSeries = orderedInspections.suffix(8).map { inspection in
                                Double(inspection.befunde.values.reduce(0, +))
                            }
                            let temperatureSeries = orderedInspections.compactMap(\.temperatur).suffix(8)
                            let humiditySeries = orderedInspections.compactMap(\.luftfeuchtigkeit).suffix(8)
                            let insectCounts = orderedInspections.reduce(into: [String: Int]()) { partialResult, inspection in
                                for (name, count) in inspection.befunde where count > 0 {
                                    partialResult[name, default: 0] += count
                                    roomInsectCounts[name, default: 0] += count
                                }
                            }
                            let topFindings = insectCounts
                                .sorted {
                                    if $0.value == $1.value {
                                        return $0.key.localizedStandardCompare($1.key) == .orderedAscending
                                    }
                                    return $0.value > $1.value
                                }
                                .prefix(3)
                                .map { DashboardFindingCount(name: $0.key, count: $0.value) }

                            clientTrapSummaries.append(
                                DashboardTrapSummary(
                                    clientId: entry.id,
                                    clientName: entry.client.name,
                                    floorId: floorId,
                                    floorName: floor.name,
                                    trapId: trapSnapshot.id,
                                    trap: trapSnapshot.trap,
                                    inspectionCount: orderedInspections.count,
                                    latestFindings: Int(findingsSeries.last ?? 0),
                                    averageFindings: self.average(Array(findingsSeries)) ?? 0,
                                    findingsDelta: self.delta(Array(findingsSeries)),
                                    latestTemperature: temperatureSeries.last,
                                    latestHumidity: humiditySeries.last,
                                    topFindings: topFindings,
                                    insectCounts: insectCounts,
                                    roomKey: "\(entry.id)_\(floorId)",
                                    roomLabel: "\(entry.client.name) · \(floor.name)"
                                )
                            )
                        }

                        let overdueCount = traps.filter { self.isOverdue($0.naechstePruefung, now: now) }.count
                        let dueTodayCount = traps.filter {
                            !self.isOverdue($0.naechstePruefung, now: now) &&
                            Calendar.current.isDateInToday($0.naechstePruefung)
                        }.count
                        let dueWeekCount = traps.filter {
                            self.isOverdue($0.naechstePruefung, now: now) ||
                            $0.naechstePruefung <= weekLimit
                        }.count
                        let dueMonthCount = traps.filter {
                            self.isOverdue($0.naechstePruefung, now: now) ||
                            $0.naechstePruefung <= monthLimit
                        }.count
                        let nextInspection = traps.map(\.naechstePruefung).min()
                        let orderedInspections = orderedInspectionsByRoom.sorted { $0.datum < $1.datum }
                        let findingsSeries = orderedInspections.suffix(8).map { inspection in
                            Double(inspection.befunde.values.reduce(0, +))
                        }
                        let temperatureSeries = orderedInspections.compactMap(\.temperatur).suffix(8)
                        let humiditySeries = orderedInspections.compactMap(\.luftfeuchtigkeit).suffix(8)
                        let latestFindings = orderedInspections.last.map { $0.befunde.values.reduce(0, +) } ?? 0
                        let roomTopFindings = roomInsectCounts
                            .sorted {
                                if $0.value == $1.value {
                                    return $0.key.localizedStandardCompare($1.key) == .orderedAscending
                                }
                                return $0.value > $1.value
                            }
                            .prefix(4)
                            .map { DashboardFindingCount(name: $0.key, count: $0.value) }

                        clientTrapItems += trapItems
                        clientRooms.append(
                            DashboardRoomSummary(
                                clientId: entry.id,
                                clientName: entry.client.name,
                                floorId: floorId,
                                floor: floor,
                                totalTrapCount: traps.count,
                                overdueCount: overdueCount,
                                dueTodayCount: dueTodayCount,
                                dueWeekCount: dueWeekCount,
                                dueMonthCount: dueMonthCount,
                                nextInspection: nextInspection,
                                inspectionCount: orderedInspections.count,
                                latestFindings: latestFindings,
                                averageFindings: self.average(findingsSeries) ?? 0,
                                findingsDelta: self.delta(findingsSeries),
                                findingsSeries: Array(findingsSeries),
                                latestTemperature: temperatureSeries.last,
                                averageTemperature: self.average(Array(temperatureSeries)),
                                temperatureDelta: self.delta(Array(temperatureSeries)),
                                temperatureSeries: Array(temperatureSeries),
                                latestHumidity: humiditySeries.last,
                                averageHumidity: self.average(Array(humiditySeries)),
                                humidityDelta: self.delta(Array(humiditySeries)),
                                humiditySeries: Array(humiditySeries),
                                topFindings: roomTopFindings,
                                insectCounts: roomInsectCounts
                            )
                        )
                    }

                    return (clientTrapItems, clientRooms, clientTrapSummaries)
                }
            }

            var trapItems: [DueTrapItem] = []
            var roomSummaries: [DashboardRoomSummary] = []
            var trapSummaries: [DashboardTrapSummary] = []
            for try await (items, rooms, traps) in group {
                trapItems += items
                roomSummaries += rooms
                trapSummaries += traps
            }
            return (trapItems, roomSummaries, trapSummaries)
        }

        let sortedTrapItems = aggregated.0.sorted { lhs, rhs in
            if lhs.trap.naechstePruefung == rhs.trap.naechstePruefung {
                return lhs.trap.nummer.localizedStandardCompare(rhs.trap.nummer) == .orderedAscending
            }
            return lhs.trap.naechstePruefung < rhs.trap.naechstePruefung
        }
        let sortedRooms = aggregated.1.sorted { lhs, rhs in
            let leftScore = (lhs.overdueCount * 100) + (lhs.dueTodayCount * 20) + lhs.dueWeekCount
            let rightScore = (rhs.overdueCount * 100) + (rhs.dueTodayCount * 20) + rhs.dueWeekCount
            if leftScore == rightScore {
                return lhs.floor.name.localizedStandardCompare(rhs.floor.name) == .orderedAscending
            }
            return leftScore > rightScore
        }
        let sortedTrapSummaries = aggregated.2.sorted { lhs, rhs in
            if lhs.latestFindings == rhs.latestFindings {
                return lhs.trap.naechstePruefung < rhs.trap.naechstePruefung
            }
            return lhs.latestFindings > rhs.latestFindings
        }
        let insectSummaries = buildInsectSummaries(from: sortedTrapSummaries)

        return DashboardSnapshot(
            clients: clients,
            trapItems: sortedTrapItems,
            roomSummaries: sortedRooms,
            trapSummaries: sortedTrapSummaries,
            insectSummaries: insectSummaries
        )
    }

    func fetchDueTraps() async throws -> [DueTrapItem] {
        try ensureAuthenticated()
        if let cached = await cache.due(for: userId, maxAge: cacheTTL) {
            return cached
        }
        // Wenn bereits der gesamte Fallen-Katalog gecached ist, fällige Einträge daraus ableiten.
        if let cachedCatalog = await cache.allTraps(for: userId, maxAge: cacheTTL) {
            let soonDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            let derived = cachedCatalog
                .filter { $0.trap.naechstePruefung <= soonDate }
                .map {
                    DueTrapItem(
                        clientName: $0.clientName,
                        floorName: $0.floorName,
                        clientId: $0.clientId,
                        floorId: $0.floorId,
                        trap: $0.trap
                    )
                }
                .sorted { $0.trap.naechstePruefung < $1.trap.naechstePruefung }
            await cache.setDue(derived, for: userId)
            return derived
        }
        let clients = try await fetchClients()
        let clientSnapshots: [(id: String, name: String)] = await MainActor.run {
            clients.compactMap {
                guard let id = $0.id else { return nil }
                return (id: id, name: $0.name)
            }
        }
        let soonDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let results = try await withThrowingTaskGroup(of: [DueTrapItem].self) { group in
            for client in clientSnapshots {
                let cId = client.id
                let clientName = client.name
                group.addTask {
                    let floors = try await self.fetchFloors(clientId: cId)
                    let floorSnapshots: [(id: String, name: String)] = await MainActor.run {
                        floors.compactMap {
                            guard let id = $0.id else { return nil }
                            return (id: id, name: $0.name)
                        }
                    }
                    return try await withThrowingTaskGroup(of: [DueTrapItem].self) { floorGroup in
                        for floor in floorSnapshots {
                            let fId = floor.id
                            let floorName = floor.name
                            floorGroup.addTask {
                                let traps = try await self.fetchTraps(clientId: cId, floorId: fId)
                                return traps
                                    .filter { $0.naechstePruefung <= soonDate }
                                    .map {
                                        DueTrapItem(
                                            clientName: clientName,
                                            floorName: floorName,
                                            clientId: cId,
                                            floorId: fId,
                                            trap: $0
                                        )
                                    }
                            }
                        }

                        var floorItems: [DueTrapItem] = []
                        for try await items in floorGroup {
                            floorItems += items
                        }
                        return floorItems
                    }
                }
            }

            var allItems: [DueTrapItem] = []
            for try await items in group {
                allItems += items
            }
            return allItems
        }

        let sorted = results.sorted { $0.trap.naechstePruefung < $1.trap.naechstePruefung }
        await cache.setDue(sorted, for: userId)
        return sorted
    }

    func fetchAllTraps() async throws -> [TrapCatalogItem] {
        try ensureAuthenticated()
        if let cached = await cache.allTraps(for: userId, maxAge: cacheTTL) {
            return cached
        }
        let clients = try await fetchClients()
        let clientSnapshots: [(id: String, name: String)] = await MainActor.run {
            clients.compactMap {
                guard let id = $0.id else { return nil }
                return (id: id, name: $0.name)
            }
        }
        let results = try await withThrowingTaskGroup(of: [TrapCatalogItem].self) { group in
            for client in clientSnapshots {
                let cId = client.id
                let clientName = client.name
                group.addTask {
                    let floors = try await self.fetchFloors(clientId: cId)
                    let floorSnapshots: [(id: String, name: String)] = await MainActor.run {
                        floors.compactMap {
                            guard let id = $0.id else { return nil }
                            return (id: id, name: $0.name)
                        }
                    }
                    return try await withThrowingTaskGroup(of: [TrapCatalogItem].self) { floorGroup in
                        for floor in floorSnapshots {
                            let fId = floor.id
                            let floorName = floor.name
                            floorGroup.addTask {
                                let traps = try await self.fetchTraps(clientId: cId, floorId: fId)
                                return traps.map {
                                    TrapCatalogItem(
                                        clientName: clientName,
                                        floorName: floorName,
                                        clientId: cId,
                                        floorId: fId,
                                        trap: $0
                                    )
                                }
                            }
                        }

                        var floorItems: [TrapCatalogItem] = []
                        for try await items in floorGroup {
                            floorItems += items
                        }
                        return floorItems
                    }
                }
            }

            var allItems: [TrapCatalogItem] = []
            for try await items in group {
                allItems += items
            }
            return allItems
        }

        let sorted = results.sorted {
            if $0.clientName == $1.clientName {
                if $0.floorName == $1.floorName {
                    return $0.trap.nummer.localizedStandardCompare($1.trap.nummer) == .orderedAscending
                }
                return $0.floorName.localizedStandardCompare($1.floorName) == .orderedAscending
            }
            return $0.clientName.localizedStandardCompare($1.clientName) == .orderedAscending
        }
        await cache.setAllTraps(sorted, for: userId)
        return sorted
    }

    func uploadInspectionPhotos(photoData: [Data], clientId: String, floorId: String, trapId: String) async throws -> [String] {
        try ensureAuthenticated()
        guard !photoData.isEmpty else { return [] }
        let limitedPhotoData = Array(photoData.prefix(3))
        var urls: [String] = []
        urls.reserveCapacity(limitedPhotoData.count)

        for (index, data) in limitedPhotoData.enumerated() {
            let fileName = "\(trapId)-\(Int(Date().timeIntervalSince1970))-\(index).jpg"
            let ref = storage.reference().child("inspections/\(userId)/\(clientId)/\(floorId)/\(trapId)/\(fileName)")
            let meta = StorageMetadata()
            meta.contentType = "image/jpeg"
#if canImport(UIKit)
            let normalizedData = UIImage(data: data)?.jpegData(compressionQuality: 0.82) ?? data
#else
            let normalizedData = data
#endif
            _ = try await ref.putDataAsync(normalizedData, metadata: meta)
            urls.append(try await ref.downloadURL().absoluteString)
        }
        return urls
    }

    func storeInspectionPhotosLocally(photoData: [Data], clientId: String, floorId: String, trapId: String) throws -> [String] {
        try ensureAuthenticated()
        guard !photoData.isEmpty else { return [] }
        let limitedPhotoData = Array(photoData.prefix(3))

        let baseDirectory = (FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory)
        let directory = baseDirectory
            .appendingPathComponent("inspectionPhotos", isDirectory: true)
            .appendingPathComponent(userId, isDirectory: true)
            .appendingPathComponent(clientId, isDirectory: true)
            .appendingPathComponent(floorId, isDirectory: true)
            .appendingPathComponent(trapId, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var localURLs: [String] = []
        localURLs.reserveCapacity(limitedPhotoData.count)

        for data in limitedPhotoData {
            let fileURL = directory.appendingPathComponent("\(UUID().uuidString).jpg")
#if canImport(UIKit)
            let normalizedData = UIImage(data: data)?.jpegData(compressionQuality: 0.82) ?? data
#else
            let normalizedData = data
#endif
            try normalizedData.write(to: fileURL, options: .atomic)
            localURLs.append(fileURL.absoluteString)
        }
        return localURLs
    }

    func fetchClient(clientId: String) async throws -> Client? {
        try ensureAuthenticated()
        let snapshot = try await clientsRef().document(clientId).getDocument()
        return try? snapshot.data(as: Client.self)
    }

    func fetchFloor(clientId: String, floorId: String) async throws -> Floor? {
        try ensureAuthenticated()
        let snapshot = try await floorsRef(clientId: clientId).document(floorId).getDocument()
        return try? snapshot.data(as: Floor.self)
    }

    func exportInspectionReportToPDF(
        client: Client,
        floor: Floor?,
        trap: Trap,
        inspection: Inspection,
        language: String,
        photoData: [Data] = []
    ) async throws -> URL {
        try ensureAuthenticated()
        let stamp = DateFormatter.ipmExportStamp.string(from: Date())
        let fileName = "IPM_Inspection_\(sanitizeFileName(client.name))_\(trap.nummer)_\(stamp).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

#if canImport(UIKit)
        var images: [UIImage] = []
        if !photoData.isEmpty {
            images = photoData.compactMap { UIImage(data: $0) }
        } else {
            for urlString in inspection.fotoURLs {
                guard let remoteURL = URL(string: urlString),
                      let data = try? Data(contentsOf: remoteURL),
                      let image = UIImage(data: data) else { continue }
                images.append(image)
            }
        }

        let title = ipmLocalized(language, de: "Prüfbericht", en: "Inspection report")
        let clientLabel = ipmLocalized(language, de: "Kunde", en: "Client")
        let addressLabel = ipmLocalized(language, de: "Adresse", en: "Address")
        let roomLabel = ipmLocalized(language, de: "Raum", en: "Room")
        let trapLabel = ipmLocalized(language, de: "Falle", en: "Trap")
        let typeLabel = ipmLocalized(language, de: "Typ", en: "Type")
        let dateLabel = ipmLocalized(language, de: "Kontrolldatum", en: "Inspection date")
        let totalLabel = ipmLocalized(language, de: "Gesamtbefund", en: "Total count")
        let notesLabel = ipmLocalized(language, de: "Notizen", en: "Notes")
        let photosLabel = ipmLocalized(language, de: "Fotos", en: "Photos")

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        try renderer.writePDF(to: url) { context in
            let horizontalPadding: CGFloat = 32
            let bodyWidth = pageRect.width - (horizontalPadding * 2)
            var y: CGFloat = 36

            let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 20)]
            let sectionAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 13)]
            let bodyAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]

            func drawLine(_ text: String, attrs: [NSAttributedString.Key: Any], spacing: CGFloat = 6) {
                let ns = text as NSString
                let measured = ns.boundingRect(
                    with: CGSize(width: bodyWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs,
                    context: nil
                )
                let lineHeight = max(18, ceil(measured.height))
                if y + lineHeight > pageRect.height - 36 {
                    context.beginPage()
                    y = 36
                }
                ns.draw(in: CGRect(x: horizontalPadding, y: y, width: bodyWidth, height: lineHeight), withAttributes: attrs)
                y += lineHeight + spacing
            }

            context.beginPage()
            drawLine(title, attrs: titleAttrs, spacing: 10)
            drawLine("\(clientLabel): \(client.name)", attrs: bodyAttrs)
            drawLine("\(addressLabel): \(client.adresse)", attrs: bodyAttrs)
            drawLine("\(roomLabel): \(floor?.name ?? "-")", attrs: bodyAttrs)
            drawLine("\(trapLabel): \(trap.nummer)", attrs: bodyAttrs)
            drawLine("\(typeLabel): \(trap.typ.rawValue)", attrs: bodyAttrs)
            drawLine("\(dateLabel): \(inspection.datum.formatted(date: .complete, time: .shortened))", attrs: bodyAttrs)
            drawLine("\(totalLabel): \(inspection.gesamtBefund)", attrs: bodyAttrs, spacing: 12)

            let sortedFindings = inspection.befunde
                .filter { $0.value > 0 }
                .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            if !sortedFindings.isEmpty {
                drawLine(ipmLocalized(language, de: "Befunde", en: "Findings"), attrs: sectionAttrs)
                for (name, count) in sortedFindings {
                    drawLine("• \(name): \(count)", attrs: bodyAttrs, spacing: 4)
                }
                y += 4
            }

            if !inspection.notizen.isEmpty {
                drawLine("\(notesLabel):", attrs: sectionAttrs, spacing: 4)
                drawLine(inspection.notizen, attrs: bodyAttrs, spacing: 10)
            }

            if !images.isEmpty {
                drawLine("\(photosLabel) (\(images.count))", attrs: sectionAttrs, spacing: 8)
                let spacing: CGFloat = 10
                let imageWidth = (bodyWidth - spacing) / 2
                let imageHeight: CGFloat = 120
                var x = horizontalPadding
                var column = 0
                for image in images {
                    if y + imageHeight > pageRect.height - 36 {
                        context.beginPage()
                        y = 36
                        x = horizontalPadding
                        column = 0
                    }
                    image.draw(in: CGRect(x: x, y: y, width: imageWidth, height: imageHeight))
                    if column == 0 {
                        x += imageWidth + spacing
                        column = 1
                    } else {
                        x = horizontalPadding
                        column = 0
                        y += imageHeight + spacing
                    }
                }
            }
        }
        return url
#else
        throw NSError(
            domain: "IPMExport",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: ipmLocalized(language, de: "PDF-Bericht ist nur unter iOS verfügbar.", en: "PDF report is only available on iOS.")]
        )
#endif
    }

    // MARK: - Account Data Deletion
    func deleteAllUserData() async throws {
        try ensureAuthenticated()
        let uid = userId
        guard !uid.isEmpty else { return }

        let clientsSnapshot = try await clientsRef().getDocuments()
        for clientDoc in clientsSnapshot.documents {
            try await deleteClientSubtree(clientId: clientDoc.documentID)
            try await clientDoc.reference.delete()
        }

        do {
            try await db.collection("users").document(uid).delete()
        } catch {
            // Continue account deletion flow even if the profile document does not exist.
        }

        do {
            let rootRef = storage.reference().child("inspections/\(uid)")
            try await deleteStorageTree(at: rootRef)
        } catch {
            // Continue account deletion flow even if there are no files to delete.
        }

        deleteLocalInspectionFiles(for: uid)
        deleteTemporaryExportFiles()
        await cache.invalidateAll(for: uid)
    }

    // MARK: - Export (Excel-kompatible CSV)
    func exportAllDataToCSV(language: String) async throws -> URL {
        try ensureAuthenticated()
        let clients = try await fetchClients()
        let headers = language == "en"
            ? ["Client", "Address", "Rooms", "Traps", "Inspections", "Generated At"]
            : ["Kunde", "Adresse", "Räume", "Fallen", "Kontrollen", "Erstellt am"]
        var lines: [String] = [headers.map(escapeCSV).joined(separator: ",")]

        let exportDate = DateFormatter.ipmExportStamp.string(from: Date())
        for client in clients {
            guard let clientId = client.id else { continue }
            let floors = try await fetchFloors(clientId: clientId)
            var trapsCount = 0
            var inspectionsCount = 0

            for floor in floors {
                guard let floorId = floor.id else { continue }
                let traps = try await fetchTraps(clientId: clientId, floorId: floorId)
                trapsCount += traps.count
                for trap in traps {
                    guard let trapId = trap.id else { continue }
                    let inspections = try await fetchInspections(clientId: clientId, floorId: floorId, trapId: trapId)
                    inspectionsCount += inspections.count
                }
            }

            let row = [
                client.name,
                client.adresse,
                "\(floors.count)",
                "\(trapsCount)",
                "\(inspectionsCount)",
                exportDate
            ]
            lines.append(row.map(escapeCSV).joined(separator: ","))
        }

        let csv = "\u{FEFF}" + lines.joined(separator: "\n")
        let fileName = "IPM_Account_Export_\(exportDate).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func exportAllDataToPDF(language: String) async throws -> URL {
        try ensureAuthenticated()
        let clients = try await fetchClients()
        let exportDate = DateFormatter.ipmExportStamp.string(from: Date())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("IPM_Account_Export_\(exportDate).pdf")

        var lines: [String] = []
        lines.append(language == "en" ? "IPM Account Export" : "IPM Konto-Export")
        lines.append((language == "en" ? "Generated: " : "Erstellt: ") + exportDate)
        lines.append("")

        if clients.isEmpty {
            lines.append(language == "en" ? "No data available." : "Keine Daten vorhanden.")
        } else {
            for client in clients {
                guard let clientId = client.id else { continue }
                let floors = try await fetchFloors(clientId: clientId)
                var trapsCount = 0
                var inspectionsCount = 0
                for floor in floors {
                    guard let floorId = floor.id else { continue }
                    let traps = try await fetchTraps(clientId: clientId, floorId: floorId)
                    trapsCount += traps.count
                    for trap in traps {
                        guard let trapId = trap.id else { continue }
                        inspectionsCount += try await fetchInspections(clientId: clientId, floorId: floorId, trapId: trapId).count
                    }
                }
                lines.append((language == "en" ? "Client: " : "Kunde: ") + client.name)
                lines.append((language == "en" ? "Address: " : "Adresse: ") + client.adresse)
                lines.append((language == "en" ? "Rooms: " : "Räume: ") + "\(floors.count)")
                lines.append((language == "en" ? "Traps: " : "Fallen: ") + "\(trapsCount)")
                lines.append((language == "en" ? "Inspections: " : "Kontrollen: ") + "\(inspectionsCount)")
                lines.append("")
            }
        }

#if canImport(UIKit)
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        try renderer.writePDF(to: url) { context in
            var y: CGFloat = 40
            let horizontalPadding: CGFloat = 32
            let bodyWidth = pageRect.width - (horizontalPadding * 2)
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18)
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]

            context.beginPage()
            for (index, line) in lines.enumerated() {
                let attrs = index == 0 ? titleAttrs : bodyAttrs
                let nsLine = line as NSString
                let measured = nsLine.boundingRect(
                    with: CGSize(width: bodyWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs,
                    context: nil
                )
                let lineHeight = max(18, ceil(measured.height))
                if y + lineHeight > pageRect.height - 40 {
                    context.beginPage()
                    y = 40
                }
                nsLine.draw(
                    in: CGRect(x: horizontalPadding, y: y, width: bodyWidth, height: lineHeight),
                    withAttributes: attrs
                )
                y += lineHeight + 6
            }
        }
        return url
#else
        throw NSError(
            domain: "IPMExport",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: ipmLocalized(language, de: "PDF-Export ist nur unter iOS verfügbar.", en: "PDF export is only available on iOS.")]
        )
#endif
    }

    func exportClientDataToCSV(client: Client, language: String) async throws -> URL {
        try ensureAuthenticated()
        guard let clientId = client.id else {
            throw NSError(domain: "IPMExport", code: 1, userInfo: [
                NSLocalizedDescriptionKey: ipmLocalized(language, de: "Ungültiger Kunde für Export.", en: "Invalid client for export.")
            ])
        }

        let pestColumns = Schaedling.alle
        let baseHeaders: [String] = language == "en"
            ? [
                "Location",
                "Room",
                "Trap Number",
                "Trap Type",
                "Installed Date",
                "Next Inspection",
                "Interval (weeks)",
                "Inspection Count",
                "Latest Inspection",
                "Latest Temperature (°C)",
                "Latest Humidity (%)",
                "Total Pest Count",
                "Notes"
            ]
            : [
                "Standort",
                "Raum",
                "Fallennummer",
                "Fallen-Typ",
                "Aufgestellt am",
                "Nächste Prüfung",
                "Intervall (Wochen)",
                "Anzahl Kontrollen",
                "Letzte Kontrolle",
                "Letzte Temperatur (°C)",
                "Letzte Feuchtigkeit (%)",
                "Gesamt Tieranzahl",
                "Notizen"
            ]
        let headers = baseHeaders + pestColumns

        var lines: [String] = [headers.map(escapeCSV).joined(separator: ",")]
        let floors = try await fetchFloors(clientId: clientId)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for floor in floors {
            guard let floorId = floor.id else { continue }
            let traps = try await fetchTraps(clientId: clientId, floorId: floorId)

            for trap in traps {
                guard let trapId = trap.id else { continue }
                let inspections = try await fetchInspections(clientId: clientId, floorId: floorId, trapId: trapId)
                let sortedInspections = inspections.sorted { $0.datum < $1.datum }
                let latestInspection = sortedInspections.last
                let trapNotes = latestInspection?.notizen.isEmpty == false ? latestInspection?.notizen ?? "" : trap.notizen

                var pestSums: [String: Int] = [:]
                for pest in pestColumns { pestSums[pest] = 0 }
                for inspection in sortedInspections {
                    for (pest, count) in inspection.befunde {
                        guard count > 0 else { continue }
                        pestSums[pest, default: 0] += count
                    }
                }

                let totalPestCount = pestSums.values.reduce(0, +)
                let latestDate = latestInspection.map { dateFormatter.string(from: $0.datum) } ?? ""
                let latestTemp = latestInspection?.temperatur.map { String(format: "%.1f", $0) } ?? ""
                let latestHumidity = latestInspection?.luftfeuchtigkeit.map { String(format: "%.0f", $0) } ?? ""

                let baseRow: [String] = [
                    client.name,
                    floor.name,
                    trap.nummer,
                    trap.typ.rawValue,
                    dateFormatter.string(from: trap.aufstellDatum),
                    dateFormatter.string(from: trap.naechstePruefung),
                    String(trap.pruefIntervallWochen),
                    String(sortedInspections.count),
                    latestDate,
                    latestTemp,
                    latestHumidity,
                    String(totalPestCount),
                    trapNotes
                ]
                let pestValues = pestColumns.map { String(pestSums[$0, default: 0]) }
                lines.append((baseRow + pestValues).map(escapeCSV).joined(separator: ","))
            }
        }

        let csv = "\u{FEFF}" + lines.joined(separator: "\n")
        let stamp = DateFormatter.ipmExportStamp.string(from: Date())
        let fileName = "IPM_Export_\(sanitizeFileName(client.name))_\(stamp).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func escapeCSV(_ text: String) -> String {
        "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private func sanitizeFileName(_ text: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return text.components(separatedBy: invalid).joined(separator: "_").replacingOccurrences(of: " ", with: "_")
    }

    private func deleteStorageTree(at reference: StorageReference) async throws {
        let listResult = try await reference.listAll()
        for item in listResult.items {
            try await item.delete()
        }
        for prefix in listResult.prefixes {
            try await deleteStorageTree(at: prefix)
        }
    }

    private func deleteLocalInspectionFiles(for uid: String) {
        let baseDirectory = (FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory)
        let userPhotoDirectory = baseDirectory
            .appendingPathComponent("inspectionPhotos", isDirectory: true)
            .appendingPathComponent(uid, isDirectory: true)
        try? FileManager.default.removeItem(at: userPhotoDirectory)
    }

    private func deleteTemporaryExportFiles() {
        let tempDirectory = FileManager.default.temporaryDirectory
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: tempDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        for item in items {
            let name = item.lastPathComponent
            if name.hasPrefix("IPM_"), name.hasSuffix(".csv") || name.hasSuffix(".pdf") {
                try? FileManager.default.removeItem(at: item)
            }
        }
    }
}

private extension DateFormatter {
    static let ipmExportStamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return formatter
    }()
}
