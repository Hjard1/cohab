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
        case .cabin:      return "tent.fill"
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
        let s = AppStrings.shared
        switch self {
        case .home, .cabin:
            return s.localized(en: "Percentage registered at the land registry (title deed).", nb: "Prosentandel registrert i matrikkelen (skjøtet).", sv: "Procentandel registrerad i fastighetsregistret (lagfart).", da: "Procentandel registreret i tingbogen (skøde).", fi: "Kiinteistörekisteriin merkitty prosenttiosuus (lainhuuto).", de: "Im Grundbuch eingetragener Prozentsatz (Urkunde).", fr: "Pourcentage enregistré au cadastre (acte de propriété).", es: "Porcentaje registrado en el registro de la propiedad (escritura).")
        case .car:
            return s.localized(en: "Who legally owns the vehicle? Split if jointly purchased and financed.", nb: "Hvem eier kjøretøyet juridisk? Del hvis det er kjøpt og finansiert sammen.", sv: "Vem äger fordonet juridiskt? Dela om det köptes och finansierades tillsammans.", da: "Hvem ejer køretøjet juridisk? Del det, hvis det er købt og finansieret sammen.", fi: "Kuka omistaa ajoneuvon juridisesti? Jakakaa se, jos se on ostettu ja rahoitettu yhdessä.", de: "Wer besitzt das Fahrzeug rechtlich? Teilen Sie es auf, wenn es gemeinsam gekauft und finanziert wurde.", fr: "Qui possède légalement le véhicule ? Répartissez-le s'il a été acheté et financé ensemble.", es: "¿Quién es el propietario legal del vehículo? Divídelo si se compró y financió conjuntamente.")
        case .investment:
            return s.localized(en: "Proportion of this portfolio each partner holds.", nb: "Andel av denne porteføljen hver partner eier.", sv: "Andel av denna portfölj som varje partner äger.", da: "Andel af denne portefølje, som hver partner ejer.", fi: "Osuus tästä salkusta, jonka kumpikin omistaa.", de: "Anteil dieses Portfolios, den jeder Partner hält.", fr: "Part de ce portefeuille détenue par chaque partenaire.", es: "Proporción de esta cartera que posee cada miembro.")
        case .savings:
            return s.localized(en: "Share each partner holds in this account.", nb: "Andel hver partner har i denne kontoen.", sv: "Andel som varje partner har på detta konto.", da: "Andel hver partner har på denne konto.", fi: "Osuus, joka kummallakin on tällä tilillä.", de: "Anteil, den jeder Partner auf diesem Konto hat.", fr: "Part détenue par chaque partenaire sur ce compte.", es: "Parte que posee cada miembro en esta cuenta.")
        case .furniture:
            return s.localized(en: "Overall ownership split. Individual items can be assigned per person.", nb: "Total eierskap. Enkeltgjenstander kan tilordnes per person.", sv: "Totalt ägande. Enskilda föremål kan tilldelas per person.", da: "Samlet ejerskab. Enkeltgenstande kan tildeles pr. person.", fi: "Kokonaisomistus. Yksittäiset esineet voidaan kohdistaa henkilölle.", de: "Gesamtanteil. Einzelne Gegenstände können einer Person zugeordnet werden.", fr: "Répartition globale. Les objets individuels peuvent être attribués à chacun.", es: "Propiedad global. Los artículos individuales pueden asignarse a cada persona.")
        case .pet:
            return s.localized(en: "Who is the primary owner of this pet?", nb: "Hvem er primær eier av dette kjæledyret?", sv: "Vem är huvudsaklig ägare till detta husdjur?", da: "Hvem er den primære ejer af dette kæledyr?", fi: "Kuka on tämän lemmikin ensisijainen omistaja?", de: "Wer ist der Haupteigentümer dieses Haustiers?", fr: "Qui est le propriétaire principal de cet animal ?", es: "¿Quién es el propietario principal de esta mascota?")
        case .other:
            return s.localized(en: "Proportion each partner owns of this asset.", nb: "Andel hver partner eier av denne eiendelen.", sv: "Andel som varje partner äger av denna tillgång.", da: "Andel hver partner ejer af dette aktiv.", fi: "Osuus tästä omaisuudesta, jonka kumpikin omistaa.", de: "Anteil dieses Vermögenswerts, den jeder Partner besitzt.", fr: "Part de cet actif détenue par chaque partenaire.", es: "Proporción de este activo que posee cada miembro.")
        }
    }

    var ownershipLabel: String {
        let s = AppStrings.shared
        switch self {
        case .home, .cabin: return s.localized(en: "registered share", nb: "registrert andel", sv: "registrerad andel", da: "registreret andel", fi: "rekisteröity osuus", de: "eingetragener Anteil", fr: "quote-part enregistrée", es: "cuota registrada")
        default:            return s.localized(en: "ownership share", nb: "eierandel", sv: "ägarandel", da: "ejerandel", fi: "omistusosuus", de: "Eigentumsanteil", fr: "quote-part", es: "cuota de propiedad")
        }
    }

    var contributionSubtitle: String {
        let s = AppStrings.shared
        switch self {
        case .home, .cabin:
            return s.localized(en: "Deposits, renovations, extra mortgage payments…", nb: "Innskudd, oppussing, ekstra nedbetalinger…", sv: "Insatser, renoveringar, extra amorteringar…", da: "Udbetalinger, renoveringer, ekstra afdrag…", fi: "Käsirahat, remontit, ylimääräiset lyhennykset…", de: "Anzahlungen, Renovierungen, zusätzliche Tilgungen…", fr: "Apports, rénovations, remboursements supplémentaires…", es: "Depósitos, reformas, pagos hipotecarios extra…")
        case .car:
            return s.localized(en: "Initial deposit, lump-sum payments…", nb: "Kjøpsbetaling, engangsbetalinger…", sv: "Köpsbetalning, engångsbetalningar…", da: "Købsbetaling, engangsbetalinger…", fi: "Ostomaksu, kertamaksut…", de: "Kaufzahlung, Einmalzahlungen…", fr: "Paiement initial, paiements uniques…", es: "Pago inicial, pagos únicos…")
        case .investment:
            return s.localized(en: "Initial contributions, additional deposits…", nb: "Startinnskudd, tilleggsbetalinger…", sv: "Startinsats, tilläggsbetalningar…", da: "Startindskud, tillægsbetalinger…", fi: "Alkumaksu, lisämaksut…", de: "Anfangsbeiträge, zusätzliche Einzahlungen…", fr: "Contributions initiales, versements supplémentaires…", es: "Aportaciones iniciales, depósitos adicionales…")
        case .savings:
            return s.localized(en: "Transfers in, lump-sum deposits…", nb: "Overføringer, innskudd…", sv: "Överföringar, insättningar…", da: "Overførsler, indskud…", fi: "Siirrot, talletukset…", de: "Überweisungen, Einzahlungen…", fr: "Virements, versements uniques…", es: "Transferencias, depósitos…")
        case .furniture:
            return s.localized(en: "Manage individual items in the furniture list", nb: "Administrer enkeltgjenstander i møbellisten", sv: "Hantera enskilda föremål i möbellistan", da: "Administrér enkelte genstande i møbellisten", fi: "Hallitse yksittäisiä esineitä huonekaluluettelossa", de: "Einzelne Gegenstände in der Möbelliste verwalten", fr: "Gérer les objets individuels dans la liste de mobilier", es: "Gestiona artículos individuales en la lista de muebles")
        case .pet:
            return s.localized(en: "Purchase price, vet bills, other costs…", nb: "Kjøpspris, veterinærkostnader, andre utgifter…", sv: "Köppris, veterinärkostnader, andra utgifter…", da: "Købspris, dyrlægeudgifter, andre omkostninger…", fi: "Ostohinta, eläinlääkärikulut, muut kulut…", de: "Kaufpreis, Tierarztkosten, andere Ausgaben…", fr: "Prix d'achat, frais vétérinaires, autres coûts…", es: "Precio de compra, gastos veterinarios, otros costes…")
        case .other:
            return s.localized(en: "Contributions and improvements…", nb: "Bidrag og forbedringer…", sv: "Bidrag och förbättringar…", da: "Bidrag og forbedringer…", fi: "Maksut ja parannukset…", de: "Beiträge und Verbesserungen…", fr: "Contributions et améliorations…", es: "Aportaciones y mejoras…")
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
    static let cohSecondary = Color(red: 0.32, green: 0.30, blue: 0.28)   // ~7:1
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
    // True when the other partner deleted their account — read-only mode
    var partnerLeft: Bool? = nil
    var relationshipType: String = "partner"   // "partner" | "friend" | "married"
    var agreementType: String = "cohabitation" // "cohabitation" | "rental"

    // Rental details — only meaningful when agreementType == "rental".
    // Local-only, like the advanced clause toggles below (not synced to Supabase).
    var rentPayerKey: String = ""   // "a" | "b" | "" (both rent jointly from a third-party landlord)
    var rentAmount: Double = 0
    var rentPaymentDay: Int = 1     // day of month, 1-28

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
        relationshipType: String = "partner",
        agreementType: String = "cohabitation"
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
        self.agreementType = agreementType
        self.assets = []
        self.expenses = []
    }

    var isFormalMode: Bool { setupMode == "formal" }

    // Monthly budget — saved from expense split calculator
    var budgetIncomeA: Double = 0
    var budgetIncomeB: Double = 0
    var budgetTotalExpenses: Double = 0
    var budgetSplitA: Double = 0.5     // Partner A's fraction of shared costs
    var budgetFairnessMode: String = "" // currently always "custom" (manual split)
    var budgetSavedAt: Date? = nil
    // Physical amount each partner pays out, and the net settling transfer.
    var budgetPaysA: Double = 0
    var budgetPaysB: Double = 0
    var budgetNetTransfer: Double = 0  // + = B owes A, − = A owes B (per month)
    // Hide the budget card from the dashboard without deleting the data.
    // Synced, so it applies to both partners.
    var budgetHidden: Bool = false
    var hasBudget: Bool { budgetTotalExpenses > 0 }

    /// What each partner effectively bears after the transfer settles.
    var budgetEffectivePayA: Double { budgetPaysA - budgetNetTransfer }
    var budgetEffectivePayB: Double { budgetPaysB + budgetNetTransfer }

    // Live expense-split working state — synced via Supabase so both partners
    // see and edit the same numbers in the calculator.
    var presetAmounts: [Double] = [0, 0, 0, 0, 0]
    var presetPayers: [String] = ["a", "a", "a", "a", "a"]
    var presetSplits: [Double] = [0.5, 0.5, 0.5, 0.5, 0.5]
    var expenseIncomeA: Double = 0
    var expenseIncomeB: Double = 0
    var expensesUpdatedAt: Date? = nil

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
        // Rate is printed in the contract, so a change must flag a re-sign.
        let rate = String(format: "%.4f", annualInterestRate)
        // Rental terms + advanced clause toggles also change the contract text.
        let clauses = [includeSeparatePropertyClause, includeBuyoutRightsClause,
                       includeDisposalConsentClause, includeDisputeResolutionClause,
                       includeDebtClause, includeDissolutionClause]
                       .map { $0 ? "1" : "0" }.joined()
        let rental = "\(Int(rentAmount))/\(rentPayerKey)/\(rentPaymentDay)"
        return "\(assets.count)|\(assets.reduce(0){$0+$1.contributions.count})|\(Int(totalValue))|\(Int(totalLoan))|\(Int(totalContrib))|\(ownership)|\(rate)|\(clauses)|\(rental)"
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
        let s = AppStrings.shared
        let assetDiff   = assets.count - signedAssetCount
        let contribDiff = assets.reduce(0) { $0 + $1.contributions.count } - signedContribCount
        var parts: [String] = []
        if assetDiff == 1   { parts.append("1 " + s.localized(en: "new asset", nb: "ny eiendel", sv: "ny tillgång", da: "nyt aktiv", fi: "uusi kohde", de: "neuer Vermögenswert", fr: "nouvel actif", es: "nuevo activo")) }
        if assetDiff > 1    { parts.append("\(assetDiff) " + s.localized(en: "new assets", nb: "nye eiendeler", sv: "nya tillgångar", da: "nye aktiver", fi: "uutta kohdetta", de: "neue Vermögenswerte", fr: "nouveaux actifs", es: "nuevos activos")) }
        if assetDiff < 0 {
            let n = -assetDiff
            parts.append("\(n) " + (n == 1
                ? s.localized(en: "asset removed", nb: "eiendel fjernet", sv: "tillgång borttagen", da: "aktiv fjernet", fi: "kohde poistettu", de: "Vermögenswert entfernt", fr: "actif supprimé", es: "activo eliminado")
                : s.localized(en: "assets removed", nb: "eiendeler fjernet", sv: "tillgångar borttagna", da: "aktiver fjernet", fi: "kohdetta poistettu", de: "Vermögenswerte entfernt", fr: "actifs supprimés", es: "activos eliminados")))
        }
        if contribDiff == 1 { parts.append("1 " + s.localized(en: "new contribution", nb: "nytt bidrag", sv: "nytt bidrag", da: "nyt bidrag", fi: "uusi maksu", de: "neuer Beitrag", fr: "nouvelle contribution", es: "nueva aportación")) }
        if contribDiff > 1  { parts.append("\(contribDiff) " + s.localized(en: "new contributions", nb: "nye bidrag", sv: "nya bidrag", da: "nye bidrag", fi: "uutta maksua", de: "neue Beiträge", fr: "nouvelles contributions", es: "nuevas aportaciones")) }
        if parts.isEmpty && agreementNeedsUpdate {
            parts.append(s.localized(en: "values updated", nb: "verdier oppdatert", sv: "värden uppdaterade", da: "værdier opdateret", fi: "arvot päivitetty", de: "Werte aktualisiert", fr: "valeurs mises à jour", es: "valores actualizados"))
        }
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
    var sortOrder: Int
    var purchaseDate: Date
    var isOwnershipRegistered: Bool?

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
        sortOrder: Int = 0,
        purchaseDate: Date = Date(),
        isOwnershipRegistered: Bool? = nil
    ) {
        self.id = UUID()
        self.assetType = assetType
        self.label = label
        self.address = address
        self.currentValue = currentValue
        self.remainingLoan = remainingLoan
        self.salesCostFraction = salesCostFraction
        self.ownershipShareA = ownershipShareA
        self.sortOrder = sortOrder
        self.purchaseDate = purchaseDate
        self.isOwnershipRegistered = isOwnershipRegistered
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
