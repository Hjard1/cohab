import SwiftData
import SwiftUI
import Foundation

// MARK: - Asset type

enum AssetType: String, CaseIterable {
    case home       = "home"
    case car        = "car"
    case cabin      = "cabin"
    case investment = "investment"
    case savings    = "savings"
    case furniture  = "furniture"
    case pet        = "pet"
    case other      = "other"

    var displayName: String {
        let lang = AppStrings.shared.language
        switch self {
        case .home:
            switch lang {
            case .nb:          return "Bolig"
            case .sv:          return "Bostad"
            case .da:          return "Bolig"
            case .fi:          return "Asunto"
            case .de:          return "Immobilie"
            case .fr:          return "Logement"
            case .es:          return "Vivienda"
            default:           return "Home"
            }
        case .car:
            switch lang {
            case .nb, .sv, .da: return "Bil"
            case .fi:           return "Auto"
            case .de:           return "Auto"
            case .fr:           return "Voiture"
            case .es:           return "Coche"
            default:            return "Car"
            }
        case .cabin:
            switch lang {
            case .nb:          return "Hytte"
            case .sv:          return "Stuga"
            case .da:          return "Hytte"
            case .fi:          return "Mökki"
            case .de:          return "Ferienhaus"
            case .fr:          return "Résidence secondaire"
            case .es:          return "Casa de campo"
            default:           return "Cabin"
            }
        case .investment:
            switch lang {
            case .nb, .sv, .da: return "Investering"
            case .fi:           return "Sijoitus"
            case .de:           return "Kapitalanlage"
            case .fr:           return "Investissement"
            case .es:           return "Inversión"
            default:            return "Investment"
            }
        case .savings:
            switch lang {
            case .nb:          return "Sparing"
            case .sv:          return "Sparande"
            case .da:          return "Opsparing"
            case .fi:          return "Säästöt"
            case .de:          return "Ersparnisse"
            case .fr:          return "Épargne"
            case .es:          return "Ahorros"
            default:           return "Savings"
            }
        case .furniture:
            switch lang {
            case .nb:          return "Møbler"
            case .sv:          return "Möbler"
            case .da:          return "Møbler"
            case .fi:          return "Huonekalut"
            case .de:          return "Möbel"
            case .fr:          return "Mobilier"
            case .es:          return "Muebles"
            default:           return "Furniture"
            }
        case .pet:
            switch lang {
            case .nb:          return "Kjæledyr"
            case .sv:          return "Husdjur"
            case .da:          return "Kæledyr"
            case .fi:          return "Lemmikki"
            case .de:          return "Haustier"
            case .fr:          return "Animal de compagnie"
            case .es:          return "Mascota"
            default:           return "Pet"
            }
        case .other:
            switch lang {
            case .nb:          return "Annet"
            case .sv:          return "Övrigt"
            case .da:          return "Andet"
            case .fi:          return "Muu"
            case .de:          return "Sonstiges"
            case .fr:          return "Autre"
            case .es:          return "Otro"
            default:           return "Other"
            }
        }
    }

    var icon: String {
        switch self {
        case .home:       return "house.fill"
        case .car:        return "car.fill"
        case .cabin:      return "house.lodge.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .savings:    return "banknote.fill"
        case .furniture:  return "sofa.fill"
        case .pet:        return "pawprint.fill"
        case .other:      return "shippingbox.fill"
        }
    }

    var color: Color {
        switch self {
        case .home:       return Color(red: 0.10, green: 0.68, blue: 0.45)
        case .car:        return Color(red: 0.20, green: 0.49, blue: 0.96)
        case .cabin:      return Color(red: 0.93, green: 0.50, blue: 0.18)
        case .investment: return Color(red: 0.54, green: 0.31, blue: 0.96)
        case .savings:    return Color(red: 0.04, green: 0.65, blue: 0.75)
        case .furniture:  return Color(red: 0.68, green: 0.48, blue: 0.32)
        case .pet:        return Color(red: 0.62, green: 0.28, blue: 0.72)
        case .other:      return Color(.systemGray)
        }
    }

    // MARK: Field configuration

    var valueLabel: String {
        let lang = AppStrings.shared.language
        switch self {
        case .savings:
            switch lang { case .nb: return "Nåværende saldo"; case .sv: return "Aktuellt saldo"; case .da: return "Nuværende saldo"; case .fi: return "Nykyinen saldo"; case .de: return "Aktueller Kontostand"; case .fr: return "Solde actuel"; case .es: return "Saldo actual"; default: return "Current balance" }
        case .investment:
            switch lang { case .nb: return "Porteføljeverdi"; case .sv: return "Portföljvärde"; case .da: return "Porteføljeværdi"; case .fi: return "Salkun arvo"; case .de: return "Portfoliowert"; case .fr: return "Valeur du portefeuille"; case .es: return "Valor del portfolio"; default: return "Portfolio value" }
        case .furniture:
            switch lang { case .nb: return "Estimert totalverdi"; case .sv: return "Uppskattat totalvärde"; case .da: return "Estimeret totalværdi"; case .fi: return "Arvioitu kokonaisarvo"; case .de: return "Geschätzter Gesamtwert"; case .fr: return "Valeur totale estimée"; case .es: return "Valor total estimado"; default: return "Total estimated value" }
        case .pet:
            switch lang { case .nb: return "Estimert verdi (valgfritt)"; case .sv: return "Uppskattat värde (valfritt)"; case .da: return "Estimeret værdi (valgfrit)"; case .fi: return "Arvioitu arvo (valinnainen)"; case .de: return "Geschätzter Wert (optional)"; case .fr: return "Valeur estimée (optionnel)"; case .es: return "Valor estimado (opcional)"; default: return "Estimated value (optional)" }
        default:
            switch lang { case .nb: return "Gjeldende markedsverdi"; case .sv: return "Aktuellt marknadsvärde"; case .da: return "Aktuel markedsværdi"; case .fi: return "Nykyinen markkina-arvo"; case .de: return "Aktueller Marktwert"; case .fr: return "Valeur marchande actuelle"; case .es: return "Valor de mercado actual"; default: return "Current market value" }
        }
    }

    var valuePlaceholder: String {
        switch self {
        case .home:       return "350,000"
        case .cabin:      return "150,000"
        case .car:        return "15,000"
        case .investment: return "50,000"
        case .savings:    return "10,000"
        case .furniture:  return "5,000"
        case .pet:        return "0"
        case .other:      return "0"
        }
    }

    /// Whether this asset type can have an outstanding loan/finance balance.
    var showLoan: Bool {
        switch self {
        case .investment, .savings, .furniture, .pet: return false
        default:                                       return true
        }
    }

    var loanLabel: String {
        let lang = AppStrings.shared.language
        switch self {
        case .car:
            switch lang { case .nb: return "Gjenstående billån"; case .sv: return "Återstående billån"; case .da: return "Resterende billån"; case .fi: return "Jäljellä oleva autolaina"; case .de: return "Restschuld Auto"; case .fr: return "Crédit auto restant"; case .es: return "Financiación pendiente del coche"; default: return "Remaining car finance" }
        case .other:
            switch lang { case .nb: return "Utestående gjeld"; case .sv: return "Utestående skuld"; case .da: return "Udestående gæld"; case .fi: return "Jäljellä oleva velka"; case .de: return "Ausstehende Schulden"; case .fr: return "Dette en cours"; case .es: return "Deuda pendiente"; default: return "Outstanding debt" }
        default:
            switch lang { case .nb: return "Gjenstående lån"; case .sv: return "Återstående lån"; case .da: return "Resterende lån"; case .fi: return "Jäljellä oleva laina"; case .de: return "Restschuld"; case .fr: return "Emprunt restant"; case .es: return "Hipoteca pendiente"; default: return "Remaining mortgage" }
        }
    }

    /// Label for the "address" / secondary identifier field.
    var secondaryLabel: String {
        let lang = AppStrings.shared.language
        switch self {
        case .home, .cabin:
            switch lang { case .nb: return "Adresse"; case .sv: return "Adress"; case .da: return "Adresse"; case .fi: return "Osoite"; case .de: return "Adresse"; case .fr: return "Adresse"; case .es: return "Dirección"; default: return "Address" }
        case .car:
            switch lang { case .nb: return "Registreringsnummer"; case .sv: return "Registreringsnummer"; case .da: return "Registreringsnummer"; case .fi: return "Rekisterinumero"; case .de: return "Kennzeichen"; case .fr: return "Immatriculation"; case .es: return "Matrícula"; default: return "Registration plate" }
        case .investment:
            switch lang { case .nb: return "Leverandør / konto"; case .sv: return "Leverantör / konto"; case .da: return "Udbyder / konto"; case .fi: return "Palveluntarjoaja / tili"; case .de: return "Anbieter / Konto"; case .fr: return "Prestataire / compte"; case .es: return "Proveedor / cuenta"; default: return "Provider / account" }
        case .savings:
            switch lang { case .nb: return "Bank / kontonavn"; case .sv: return "Bank / kontonamn"; case .da: return "Bank / kontonavn"; case .fi: return "Pankki / tilin nimi"; case .de: return "Bank / Kontoname"; case .fr: return "Banque / nom du compte"; case .es: return "Banco / nombre de cuenta"; default: return "Bank / account name" }
        case .furniture:
            switch lang { case .nb: return "Plassering / rom"; case .sv: return "Plats / rum"; case .da: return "Placering / rum"; case .fi: return "Sijainti / huone"; case .de: return "Standort / Zimmer"; case .fr: return "Emplacement / pièce"; case .es: return "Ubicación / habitación"; default: return "Location / room" }
        case .pet:
            switch lang { case .nb: return "Art / rase"; case .sv: return "Art / ras"; case .da: return "Art / race"; case .fi: return "Laji / rotu"; case .de: return "Art / Rasse"; case .fr: return "Espèce / race"; case .es: return "Especie / raza"; default: return "Species / breed" }
        case .other:
            switch lang { case .nb: return "Notater"; case .sv: return "Anteckningar"; case .da: return "Noter"; case .fi: return "Muistiinpanot"; case .de: return "Notizen"; case .fr: return "Notes"; case .es: return "Notas"; default: return "Notes" }
        }
    }

    var secondaryPlaceholder: String {
        switch self {
        case .home:       return "10 Baker Street…"
        case .cabin:      return "…"
        case .car:        return "AB12 CDE"
        case .investment: return "e.g. Vanguard ISA…"
        case .savings:    return "e.g. Barclays…"
        case .furniture:  return "e.g. Living room"
        case .pet:        return "e.g. Golden Retriever"
        case .other:      return "…"
        }
    }

    var defaultSalesCostFraction: Double {
        switch self {
        case .home, .cabin: return 0.02
        default:            return 0.0
        }
    }

    /// Property types use a registered % (land registry). All other types use a person/shared picker.
    var ownershipUsesPercent: Bool {
        switch self {
        case .home, .cabin: return true
        default:            return false
        }
    }

    var ownershipHint: String {
        switch self {
        case .home, .cabin:
            return "Percentage registered at the land registry (title deed). Use the Ownership calculator if you're unsure."
        case .car:
            return "Who legally owns the vehicle? Split if jointly purchased and financed."
        case .investment:
            return "Proportion of this portfolio each partner holds."
        case .savings:
            return "Share each partner holds in this account."
        case .furniture:
            return "Overall ownership split. Individual items can be assigned per person."
        case .pet:
            return "Who is the primary owner of this pet?"
        case .other:
            return "Proportion each partner owns of this asset."
        }
    }

    var ownershipLabel: String {
        switch self {
        case .home, .cabin: return "registered share"
        default:            return "ownership share"
        }
    }

    var contributionSubtitle: String {
        let nb = AppStrings.shared.language == .nb
        switch self {
        case .home, .cabin:
            return nb ? "Innskudd, oppussing, ekstra nedbetalinger…" : "Deposits, renovations, extra mortgage payments…"
        case .car:
            return nb ? "Kjøpsbetaling, engangsbetalinger…" : "Initial deposit, lump-sum payments…"
        case .investment:
            return nb ? "Startinnskudd, tilleggsbetalinger…" : "Initial contributions, additional deposits…"
        case .savings:
            return nb ? "Overføringer, innskudd…" : "Transfers in, lump-sum deposits…"
        case .furniture:
            return nb ? "Administrer enkeltgjenstander i møbellisten" : "Manage individual items in the furniture list"
        case .pet:
            return nb ? "Kjøpspris, veterinærkostnader, andre utgifter…" : "Purchase price, vet bills, other costs…"
        case .other:
            return nb ? "Bidrag og forbedringer…" : "Contributions and improvements…"
        }
    }

    /// Furniture and pets use a simple item/info view rather than equity settlement
    var isSimpleAsset: Bool { self == .furniture || self == .pet }
}

// MARK: - Design tokens

extension Color {
    // Partner identity — RESERVED: do not use for CTAs or brand chrome
    static let cohGreen     = Color(red: 0.10, green: 0.60, blue: 0.38)   // Partner A
    static let cohBlue      = Color(red: 0.20, green: 0.49, blue: 0.96)   // Partner B

    // Surface
    static let cohBg        = Color(red: 0.980, green: 0.976, blue: 0.965)
    static let cohCard      = Color.white

    // Text scale (all WCAG AA on cohBg)
    static let cohInk       = Color(red: 0.13, green: 0.12, blue: 0.11)   // ~16:1
    static let cohSecondary = Color(red: 0.40, green: 0.38, blue: 0.36)   // ~5.5:1
    static let cohMuted     = Color(red: 0.50, green: 0.48, blue: 0.46)   // ~4.6:1
    static let cohTertiary  = Color(red: 0.58, green: 0.55, blue: 0.52)   // ~3.8:1

    // Asset icon container — neutral warm grey, same for ALL asset types
    static let cohIconBg    = Color(red: 0.93, green: 0.91, blue: 0.88)
    static let cohIconFg    = Color(red: 0.35, green: 0.32, blue: 0.28)   // ~5.1:1 on cohIconBg
}

// MARK: - SwiftData models

@Model
final class Household {
    var id: UUID
    var partnerAName: String
    var partnerBName: String
    var currency: String
    var annualInterestRate: Double
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var assets: [Asset]
    @Relationship(deleteRule: .cascade) var expenses: [SharedExpense]

    var country: String = "GB"                  // ISO 3166 country code
    var setupMode: String = "memory"            // "formal" | "memory"
    var avatarA: String = "person.fill"             // SF Symbol for partner A
    var avatarB: String = "person.fill"             // SF Symbol for partner B
    var includeDissolutionClause: Bool = true
    // Advanced optional clauses (default off — simple contract is the default)
    var includeAdvancedClauses: Bool = false
    var includeSeparatePropertyClause: Bool = false
    var includeBuyoutRightsClause: Bool = false
    var includeDisposalConsentClause: Bool = false
    var includeDisputeResolutionClause: Bool = false
    var includeDebtClause: Bool = false
    var emailA: String = ""
    var emailB: String = ""
    var agreementStatus: String = "none"        // "none" | "pending" | "signed"
    var docusealSlug: String = ""
    var docusealViewUrl: String = ""           // signingUrlA — usable as view/download link post-signing
    var signedAt: Date? = nil
    var relationshipType: String = "couple"    // "couple" | "housemates" | "business"

    init(
        partnerAName: String,
        partnerBName: String,
        country: String = "GB",
        currency: String = "GBP",
        annualInterestRate: Double = 0.05,
        setupMode: String = "memory",
        includeDissolutionClause: Bool = true,
        emailA: String = "",
        emailB: String = "",
        relationshipType: String = "couple"
    ) {
        self.id = UUID()
        self.partnerAName = partnerAName
        self.partnerBName = partnerBName
        self.country = country
        self.currency = currency
        self.annualInterestRate = annualInterestRate
        self.createdAt = Date()
        self.setupMode = setupMode
        self.includeDissolutionClause = includeDissolutionClause
        self.emailA = emailA
        self.emailB = emailB
        self.agreementStatus = "none"
        self.docusealSlug = ""
        self.relationshipType = relationshipType
        self.assets = []
        self.expenses = []
    }

    var isFormalMode: Bool { setupMode == "formal" }

    // Monthly budget — saved from expense split calculator
    var budgetIncomeA: Double = 0
    var budgetIncomeB: Double = 0
    var budgetTotalExpenses: Double = 0
    var budgetSplitA: Double = 0.5     // Partner A's fraction of shared costs
    var budgetFairnessMode: String = "" // "byIncome" | "equalLeft"
    var budgetSavedAt: Date? = nil
    var hasBudget: Bool { budgetTotalExpenses > 0 }

    // Snapshot of what was included in the last submitted agreement.
    var signedAssetCount: Int = 0
    var signedContribCount: Int = 0
    var signedDataSnapshot: String = ""   // catches value/ownership/amount changes

    /// Fingerprint of all data that matters for the agreement content.
    var currentDataSnapshot: String {
        let totalValue   = assets.reduce(0.0) { $0 + $1.currentValue }
        let totalLoan    = assets.reduce(0.0) { $0 + $1.remainingLoan }
        let totalContrib = assets.flatMap { $0.contributions }.reduce(0.0) { $0 + $1.amount }
        let ownership    = assets.sorted { $0.id.uuidString < $1.id.uuidString }
                                 .map { String(Int($0.ownershipShareA * 100)) }.joined(separator: ",")
        return "\(assets.count)|\(assets.reduce(0){$0+$1.contributions.count})|\(Int(totalValue))|\(Int(totalLoan))|\(Int(totalContrib))|\(ownership)"
    }

    /// True when any agreement-relevant data has changed since the last submission.
    var agreementNeedsUpdate: Bool {
        guard agreementStatus != "none" else { return false }
        let currentContribs = assets.reduce(0) { $0 + $1.contributions.count }
        if assets.count != signedAssetCount { return true }
        if currentContribs != signedContribCount { return true }
        if !signedDataSnapshot.isEmpty && currentDataSnapshot != signedDataSnapshot { return true }
        return false
    }

    /// Human-readable summary of what changed since last signing.
    var changesSinceSigning: String {
        let assetDiff   = assets.count - signedAssetCount
        let contribDiff = assets.reduce(0) { $0 + $1.contributions.count } - signedContribCount
        var parts: [String] = []
        if assetDiff == 1   { parts.append("1 new asset") }
        if assetDiff > 1    { parts.append("\(assetDiff) new assets") }
        if assetDiff < 0    { parts.append("\(-assetDiff) asset\(-assetDiff == 1 ? "" : "s") removed") }
        if contribDiff == 1 { parts.append("1 new contribution") }
        if contribDiff > 1  { parts.append("\(contribDiff) new contributions") }
        if parts.isEmpty && agreementNeedsUpdate { parts.append("values updated") }
        return parts.joined(separator: " · ")
    }

    var currencySymbol: String {
        switch currency {
        case "GBP": return "£"
        case "USD": return "$"
        case "EUR": return "€"
        case "AUD": return "A$"
        case "CAD": return "C$"
        case "NZD": return "NZ$"
        case "SGD": return "S$"
        case "JPY": return "¥"
        case "CHF": return "Fr\u{00A0}"
        case "ISK": return "kr\u{00A0}"
        case "NOK", "SEK", "DKK": return "kr\u{00A0}"   // non-breaking space keeps symbol+amount together
        default: return currency + "\u{00A0}"
        }
    }
}

@Model
final class Asset {
    var id: UUID
    var assetType: String       // AssetType.rawValue, default "home"
    var label: String
    var address: String
    var currentValue: Double
    var remainingLoan: Double
    var salesCostFraction: Double
    var ownershipShareA: Double
    var purchaseDate: Date

    @Relationship(deleteRule: .cascade) var contributions: [ContributionRecord]
    @Relationship(deleteRule: .cascade) var furnitureItems: [FurnitureItem]

    init(
        assetType: String = "home",
        label: String,
        address: String = "",
        currentValue: Double,
        remainingLoan: Double = 0,
        salesCostFraction: Double = 0.02,
        ownershipShareA: Double = 0.5,
        purchaseDate: Date = Date()
    ) {
        self.id = UUID()
        self.assetType = assetType
        self.label = label
        self.address = address
        self.currentValue = currentValue
        self.remainingLoan = remainingLoan
        self.salesCostFraction = salesCostFraction
        self.ownershipShareA = ownershipShareA
        self.purchaseDate = purchaseDate
        self.contributions = []
        self.furnitureItems = []
    }

    var netEquity: Double { currentValue - remainingLoan }
    var estimatedSalesCost: Double { currentValue * salesCostFraction }
    var netProceeds: Double { netEquity - estimatedSalesCost }
    var type: AssetType { AssetType(rawValue: assetType) ?? .other }
}

@Model
final class ContributionRecord {
    var id: UUID
    var ownerKey: String
    var amount: Double
    var date: Date
    var label: String
    var category: String

    init(
        ownerKey: String,
        amount: Double,
        date: Date = Date(),
        label: String,
        category: String = "other"
    ) {
        self.id = UUID()
        self.ownerKey = ownerKey
        self.amount = amount
        self.date = date
        self.label = label
        self.category = category
    }
}

// MARK: - FurnitureItem

@Model
final class FurnitureItem {
    var id: UUID
    var label: String
    var currentValue: Double
    var ownerKey: String   // "A", "B", "shared"

    init(label: String, currentValue: Double = 0, ownerKey: String = "shared") {
        self.id = UUID()
        self.label = label
        self.currentValue = currentValue
        self.ownerKey = ownerKey
    }
}

@Model
final class SharedExpense {
    var id: UUID
    var label: String
    var amount: Double
    var paidByKey: String
    var splitRatioA: Double
    var date: Date
    var category: String
    var isRecurring: Bool

    init(
        label: String,
        amount: Double,
        paidByKey: String,
        splitRatioA: Double = 0.5,
        date: Date = Date(),
        category: String = "other",
        isRecurring: Bool = false
    ) {
        self.id = UUID()
        self.label = label
        self.amount = amount
        self.paidByKey = paidByKey
        self.splitRatioA = splitRatioA
        self.date = date
        self.category = category
        self.isRecurring = isRecurring
    }
}
