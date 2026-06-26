import Foundation
import SwiftUI

// MARK: - Language enum

enum AppLanguage: String, CaseIterable {
    case en, nb, sv, da

    /// Derive language from ISO 3166 country code.
    static func from(country: String) -> AppLanguage {
        switch country {
        case "NO":          return .nb
        case "SE":          return .sv
        case "DK":          return .da
        default:            return .en
        }
    }

    var localeIdentifier: String {
        switch self {
        case .en: return "en"
        case .nb: return "nb"
        case .sv: return "sv"
        case .da: return "da"
        }
    }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .nb: return "Norsk"
        case .sv: return "Svenska"
        case .da: return "Dansk"
        }
    }
}

// MARK: - Localized strings

/// Access via `AppStrings.shared.disclaimer.title` etc.
/// Call `AppStrings.shared.language = .nb` to switch language.
final class AppStrings: ObservableObject {
    static let shared = AppStrings()
    @Published var language: AppLanguage = .en

    // MARK: Disclaimer

    var disclaimerTitle: String { s(en: "Important notice",
                                     nb: "Viktig informasjon",
                                     sv: "Viktig information",
                                     da: "Vigtig information") }

    var disclaimerBody: String { s(
        en: """
cohab is not a law firm and does not provide legal advice. \
This agreement is a standardised template for general use between two parties.

• Digital signatures may not be legally binding in all jurisdictions. \
Verify the validity of digital contracts under your local law before signing.

• This template may not cover every aspect of your situation. \
For significant legal matters — such as high-value property or complex ownership — \
consult a qualified solicitor or lawyer.

• The interest rate used in calculations is based on your central bank's policy rate \
and is for indicative purposes only.

• Keep your agreement up to date whenever your shared assets or contributions change.

By continuing, you acknowledge that cohab provides tools, not legal advice, \
and accepts no liability for the legal validity of any agreement in any jurisdiction.
""",
        nb: """
cohab er ikke et advokatfirma og yter ikke juridisk rådgivning. \
Denne avtalen er en standardisert mal for generell bruk mellom to parter.

• Elektronisk signering er ikke nødvendigvis juridisk bindende i alle jurisdiksjoner. \
Kontroller gyldigheten av digitale kontrakter etter gjeldende lov i ditt land.

• Malen dekker kanskje ikke alle sider av din situasjon. \
For viktige juridiske spørsmål — som kjøp av eiendom av høy verdi eller komplekse eierforhold — \
kontakt en kvalifisert advokat.

• Renten som brukes i beregningene er basert på sentralbankens styringsrente \
og er kun veiledende.

• Hold avtalen oppdatert når felles eiendeler eller bidrag endres.

Ved å fortsette erkjenner du at cohab tilbyr verktøy, ikke juridisk rådgivning, \
og fraskriver seg ethvert ansvar for den juridiske gyldigheten av en avtale i noen jurisdiksjon.
""",
        sv: """
cohab är inte en advokatbyrå och ger inte juridisk rådgivning. \
Detta avtal är en standardiserad mall för allmänt bruk mellan två parter.

• Elektronisk signering är inte nödvändigtvis juridiskt bindande i alla jurisdiktioner. \
Kontrollera giltigheten av digitala avtal enligt gällande lag i ditt land.

• Mallen kanske inte täcker alla aspekter av din situation. \
För viktiga juridiska frågor — som köp av högt värderad egendom eller komplexa ägarförhållanden — \
kontakta en kvalificerad jurist eller advokat.

• Räntan som används i beräkningarna baseras på centralbankens styrränta \
och är endast vägledande.

• Håll avtalet uppdaterat när gemensamma tillgångar eller bidrag förändras.

Genom att fortsätta erkänner du att cohab erbjuder verktyg, inte juridisk rådgivning, \
och avsäger sig allt ansvar för ett avtals juridiska giltighet i någon jurisdiktion.
""",
        da: """
cohab er ikke et advokatfirma og yder ikke juridisk rådgivning. \
Denne aftale er en standardiseret skabelon til generel brug mellem to parter.

• Elektronisk signering er ikke nødvendigvis juridisk bindende i alle jurisdiktioner. \
Kontrollér gyldigheden af digitale kontrakter i henhold til gældende lovgivning i dit land.

• Skabelonen dækker muligvis ikke alle aspekter af din situation. \
Kontakt en kvalificeret advokat ved vigtige juridiske spørgsmål — f.eks. køb af højværdi-ejendom \
eller komplekse ejerforhold.

• Den rente der anvendes i beregningerne er baseret på centralbankens referencerente \
og er kun vejledende.

• Hold aftalen opdateret, når fælles aktiver eller bidrag ændres.

Ved at fortsætte anerkender du, at cohab tilbyder værktøjer, ikke juridisk rådgivning, \
og fraskriver sig ethvert ansvar for et aftalets juridiske gyldighed i nogen jurisdiktion.
""") }

    var disclaimerAckLabel: String { s(
        en: "I understand — cohab provides tools, not legal advice",
        nb: "Jeg forstår — cohab er et verktøy, ikke juridisk rådgivning",
        sv: "Jag förstår — cohab är ett verktyg, inte juridisk rådgivning",
        da: "Jeg forstår — cohab er et værktøj, ikke juridisk rådgivning") }

    var disclaimerFooter: String { s(
        en: "cohab is not a law firm. This is a standardised template. Digital signatures may not be legally binding in all jurisdictions. Consult a lawyer for significant legal matters.",
        nb: "cohab er ikke et advokatfirma. Dette er en standardisert mal. Elektronisk signering er ikke bindende i alle jurisdiksjoner. Kontakt advokat ved viktige juridiske spørsmål.",
        sv: "cohab är inte en advokatbyrå. Detta är en standardiserad mall. Elektronisk signering är inte bindande i alla jurisdiktioner. Kontakta en advokat vid viktiga juridiska frågor.",
        da: "cohab er ikke et advokatfirma. Dette er en standardiseret skabelon. Elektronisk signering er ikke bindende i alle jurisdiktioner. Kontakt en advokat ved vigtige juridiske spørgsmål.") }

    // MARK: Onboarding

    var onboardingTagline: String { s(
        en: "Track ownership.\nTrust the numbers.",
        nb: "Registrer eierskap.\nStol på tallene.",
        sv: "Registrera ägandet.\nLita på siffrorna.",
        da: "Registrér ejerskab.\nStol på tallene.") }

    var onboardingSubtitle: String { s(
        en: "A shared record of what you own together\n— and what's fair if anything changes.",
        nb: "Et felles register over det dere eier sammen\n— og hva som er rettferdig hvis noe endres.",
        sv: "En gemensam förteckning över vad ni äger tillsammans\n— och vad som är rättvist om något förändras.",
        da: "En fælles oversigt over hvad I ejer sammen\n— og hvad der er rimeligt, hvis noget ændres.") }

    var onboardingGetStarted: String { s(en: "Get started", nb: "Kom i gang", sv: "Kom igång", da: "Kom i gang") }
    var onboardingContinue: String   { s(en: "Continue",    nb: "Fortsett",   sv: "Fortsätt", da: "Fortsæt") }
    var onboardingStartTracking: String { s(en: "Start tracking", nb: "Start registrering", sv: "Börja registrera", da: "Start registrering") }

    // MARK: Dashboard

    var dashboardAssets: String       { s(en: "Assets",          nb: "Eiendeler",    sv: "Tillgångar",    da: "Aktiver") }
    var dashboardIfSettledToday: String { s(en: "If settled today", nb: "Ved oppgjør i dag", sv: "Vid uppgörelse idag", da: "Ved opgørelse i dag") }
    var dashboardAddAsset: String     { s(en: "Add asset",        nb: "Legg til eiendel", sv: "Lägg till tillgång", da: "Tilføj aktiv") }
    var dashboardShowCalculation: String { s(en: "Show calculation", nb: "Vis utregning", sv: "Visa beräkning", da: "Vis beregning") }
    var dashboardHideCalculation: String { s(en: "Hide calculation", nb: "Skjul utregning", sv: "Dölj beräkning", da: "Skjul beregning") }

    // MARK: Agreement

    var agreementTitle: String    { s(en: "Ownership Agreement", nb: "Eierskapsavtale",   sv: "Ägaravtal",      da: "Ejerskabsaftale") }
    var agreementGenerate: String { s(en: "Generate & sign agreement", nb: "Generer og signer avtale", sv: "Generera och signera avtal", da: "Generér og underskriv aftale") }
    var agreementUpdate: String   { s(en: "Update & resend agreement", nb: "Oppdater og send avtale på nytt", sv: "Uppdatera och skicka om avtal", da: "Opdatér og gensend aftale") }
    var agreementSigned: String   { s(en: "Signed by both parties", nb: "Signert av begge parter", sv: "Undertecknat av båda parter", da: "Underskrevet af begge parter") }
    var agreementPending: String  { s(en: "Pending signatures", nb: "Venter på signering", sv: "Väntar på underskrift", da: "Afventer underskrift") }
    var agreementNotSigned: String { s(en: "Not signed yet", nb: "Ikke signert ennå", sv: "Ej undertecknat", da: "Ikke underskrevet endnu") }
    var agreementUpdateNeeded: String { s(en: "Update needed", nb: "Oppdatering nødvendig", sv: "Uppdatering krävs", da: "Opdatering nødvendig") }

    // MARK: Settlement

    var settlementNetProceeds: String { s(en: "NET PROCEEDS",      nb: "NETTO PROVENY",   sv: "NETTOINTÄKT",     da: "NETTOPROVENU") }
    var settlementSurplus: String     { s(en: "SURPLUS",           nb: "OVERSKUDD",       sv: "ÖVERSKOTT",       da: "OVERSKUD") }
    var settlementShortfall: String   { s(en: "SHORTFALL",         nb: "UNDERDEKNING",    sv: "UNDERSKOTT",      da: "UNDERDÆKNING") }
    var settlementFinalPayout: String { s(en: "FINAL PAYOUT",      nb: "ENDELIG UTBETALING", sv: "SLUTLIG UTBETALNING", da: "ENDELIG UDBETALING") }
    var settlementCurrentValue: String { s(en: "Current value",    nb: "Gjeldende verdi", sv: "Aktuellt värde",  da: "Aktuel værdi") }
    var settlementRemainingLoan: String { s(en: "Remaining loan",  nb: "Gjenstående lån", sv: "Återstående lån", da: "Resterende lån") }
    var settlementSaleCosts: String   { s(en: "Sale costs",        nb: "Salgskostnader",  sv: "Försäljningskostnader", da: "Salgsomkostninger") }

    // MARK: Helper

    private func s(en: String, nb: String, sv: String, da: String) -> String {
        switch language {
        case .en: return en
        case .nb: return nb
        case .sv: return sv
        case .da: return da
        }
    }
}
