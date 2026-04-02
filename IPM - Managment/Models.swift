import SwiftUI
import FirebaseFirestore

// MARK: - Client
struct Client: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    var name: String
    var adresse: String
    var kontaktName: String
    var kontaktTelefon: String
    var notizen: String
    var zahlungsmethode: String
    var createdAt: Date

    init(
        name: String,
        adresse: String,
        kontaktName: String = "",
        kontaktTelefon: String = "",
        notizen: String = "",
        zahlungsmethode: String = ""
    ) {
        self.name = name
        self.adresse = adresse
        self.kontaktName = kontaktName
        self.kontaktTelefon = kontaktTelefon
        self.notizen = notizen
        self.zahlungsmethode = zahlungsmethode
        self.createdAt = Date()
    }
}

// MARK: - Floor
struct Floor: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    var name: String
    var grundrissURL: String?
    var createdAt: Date

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

// MARK: - Trap
struct Trap: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    var nummer: String
    var typ: TrapType
    var positionX: Double
    var positionY: Double
    var aufstellDatum: Date
    var pruefIntervallTage: Int
    var naechstePruefung: Date
    var notizen: String

    var istFaellig: Bool {
        naechstePruefung <= Date()
    }

    var pruefIntervallWochen: Int {
        max(1, Int(round(Double(pruefIntervallTage) / 7.0)))
    }

    var faelligkeitStatus: FaelligkeitStatus {
        let tage = Calendar.current.dateComponents([.day], from: Date(), to: naechstePruefung).day ?? 0
        if tage < 0 { return .ueberfaellig }
        if tage <= 7 { return .bald }
        return .ok
    }

    init(
        nummer: String,
        typ: TrapType,
        positionX: Double = 0.5,
        positionY: Double = 0.5,
        pruefIntervallTage: Int = 56
    ) {
        self.nummer = nummer
        self.typ = typ
        self.positionX = positionX
        self.positionY = positionY
        self.aufstellDatum = Date()
        self.pruefIntervallTage = pruefIntervallTage
        self.naechstePruefung = Calendar.current.date(byAdding: .day, value: pruefIntervallTage, to: Date()) ?? Date()
        self.notizen = ""
    }
}

// MARK: - TrapType
enum TrapType: String, Codable, CaseIterable, Sendable {
    case gTrap = "G-Trap"
    case sTrap = "S-Trap"
    case klebefalle = "Klebefalle"
    case koederstation = "Köderstation"
    case insektenfalle = "Insektenfalle"
    case custom = "Eigene"

    var icon: String {
        switch self {
        case .gTrap:       return "square.grid.2x2"
        case .sTrap:       return "s.square"
        case .klebefalle:  return "rectangle.fill"
        case .koederstation: return "circle.hexagongrid"
        case .insektenfalle: return "ant"
        case .custom:      return "plus.square"
        }
    }

    func localizedName(language: String) -> String {
        switch self {
        case .gTrap:
            return "G-Trap"
        case .sTrap:
            return "S-Trap"
        case .klebefalle:
            return language == "en" ? "Glue trap" : "Klebefalle"
        case .koederstation:
            return language == "en" ? "Bait station" : "Köderstation"
        case .insektenfalle:
            return language == "en" ? "Insect trap" : "Insektenfalle"
        case .custom:
            return language == "en" ? "Custom" : "Eigene"
        }
    }
}

// MARK: - FaelligkeitStatus
enum FaelligkeitStatus: Sendable {
    case ok, bald, ueberfaellig

    var color: Color {
        switch self {
        case .ok:          return IPMColors.ok
        case .bald:        return IPMColors.warning
        case .ueberfaellig: return IPMColors.critical
        }
    }

    func label(language: String) -> String {
        switch self {
        case .ok:          return "OK"
        case .bald:        return language == "en" ? "Due soon" : "Bald fällig"
        case .ueberfaellig: return language == "en" ? "Overdue" : "Überfällig"
        }
    }
}

// MARK: - Inspection
struct Inspection: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    var datum: Date
    var temperatur: Double?
    var luftfeuchtigkeit: Double?
    var notizen: String
    var befunde: [String: Int]
    var fotoURLs: [String]

    var gesamtBefund: Int { befunde.values.reduce(0, +) }

    init(
        datum: Date = Date(),
        temperatur: Double? = nil,
        luftfeuchtigkeit: Double? = nil,
        notizen: String = ""
    ) {
        self.datum = datum
        self.temperatur = temperatur
        self.luftfeuchtigkeit = luftfeuchtigkeit
        self.notizen = notizen
        self.befunde = [:]
        self.fotoURLs = []
    }
}

// MARK: - Schädlinge (direkt aus Excel übernommen)
enum Schaedling {
    static let schaedlingsArten: [String] = [
        "Silberfischchen (Lepisma sacharina)",
        "Papierfischchen (Ctenolepisma longicaudata)",
        "Ofenfischchen (Thermobia domestica)",
        "Gemeiner Nagekäfer (Anobium punctatum)",
        "Larve Nagekäfer",
        "Brotkäfer (Stegobium paniceum)",
        "Larve Brotkäfer",
        "Diebskäfer / Messingkäfer (Ptinus)",
        "Kabinettkäfer (Anthrenus museorum)",
        "Australischer Diebkäfer (Ptinus tectus)",
        "Wollkrautblütenkäfer (Anthrenus verbasci)",
        "Berlinkäfer (Trogoderma angustum)",
        "Gemeiner Speckkäfer (Dermestes lardarius)",
        "Brauner Pelzkäfer (Attagenus smirnovi)",
        "Larve Pelzkäfer",
        "Hausbock (Hylotrupes bajulus)",
        "Larve Hausbock",
        "Dörrobstmotte (Plodia interpunctella)",
        "Kleidermotte (Tineola bisselliella)",
        "Pelzmotte (Tinea pellionella)"
    ]

    static let gasteArten: [String] = [
        "Staubläuse (Psocoptera)",
        "Fliegen klein / Mücken",
        "Fliegen groß",
        "Schmetterlingsmücken",
        "Fransenflügler",
        "Trauermücken",
        "Wespen",
        "Ameisen",
        "Platanenwanzen",
        "Mauerasseln",
        "Schwarzer Moderkäfer",
        "Laufkäfer",
        "Marienkäfer",
        "Spinnen",
        "Unbekannt"
    ]

    static var alle: [String] { schaedlingsArten + gasteArten }
}
