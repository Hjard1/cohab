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

    // MARK: Onboarding — new screens

    var onboardingHero: String { s(
        en: "Own it together.\nKnow where you stand.",
        nb: "Eie det sammen.\nVit hvor dere står.",
        sv: "Äg det tillsammans.\nVet var ni står.",
        da: "Ej det sammen.\nVid hvor I står.") }

    var onboardingHeroSub: String { s(
        en: "Remove the uncertainty. Get in control of what you own — alone and together.",
        nb: "Fjern usikkerheten. Ta kontroll over hva dere eier — alene og sammen.",
        sv: "Ta bort osäkerheten. Ta kontroll över vad ni äger — ensamma och tillsammans.",
        da: "Fjern usikkerheden. Tag kontrol over hvad I ejer — alene og sammen.") }

    var onboardingAlreadyHaveAccount: String { s(
        en: "I already have an account",
        nb: "Jeg har allerede en konto",
        sv: "Jag har redan ett konto",
        da: "Jeg har allerede en konto") }

    var onboardingWhereDoYouLive: String { s(
        en: "Where do you\nlive?",
        nb: "Hvor bor\ndere?",
        sv: "Var bor\nni?",
        da: "Hvor bor\nI?") }

    var onboardingCountrySub: String { s(
        en: "Laws around cohabitation vary by country.",
        nb: "Samboerregler varierer fra land til land.",
        sv: "Sambolagarnas regler varierar från land till land.",
        da: "Regler om samliv varierer fra land til land.") }

    var onboardingWhoDoYouShare: String { s(
        en: "Who do you\nshare with?",
        nb: "Hvem deler\ndere med?",
        sv: "Vem delar\nni med?",
        da: "Hvem deler\nI med?") }

    var onboardingPartnerSub: String { s(
        en: "We'll use this to personalise your dashboard.",
        nb: "Vi bruker dette til å tilpasse dashbordet ditt.",
        sv: "Vi använder detta för att anpassa din instrumentpanel.",
        da: "Vi bruger dette til at tilpasse dit dashboard.") }

    var onboardingYourName: String  { s(en: "YOUR NAME",     nb: "DITT NAVN",      sv: "DITT NAMN",    da: "DIT NAVN") }
    var onboardingPartnerName: String { s(en: "PARTNER'S NAME", nb: "PARTNERS NAVN", sv: "PARTNERNS NAMN", da: "PARTNERS NAVN") }
    var onboardingYourEmail: String { s(en: "YOUR EMAIL",    nb: "DIN E-POST",     sv: "DIN E-POST",   da: "DIN E-MAIL") }
    var onboardingPartnerEmail: String { s(en: "PARTNER'S EMAIL", nb: "PARTNERS E-POST", sv: "PARTNERNS E-POST", da: "PARTNERS E-MAIL") }

    var onboardingRelationship: String { s(en: "RELATIONSHIP", nb: "FORHOLD", sv: "RELATION", da: "FORHOLD") }
    var onboardingCouple: String     { s(en: "Couple",            nb: "Par",               sv: "Par",             da: "Par") }
    var onboardingHousemates: String { s(en: "Housemates",        nb: "Samboere",          sv: "Sambos",          da: "Samboere") }
    var onboardingBusiness: String   { s(en: "Business partners", nb: "Forretningspartnere", sv: "Affärspartners", da: "Forretningspartnere") }

    var onboardingProtect: String { s(
        en: "Protect what you\nbuild together.",
        nb: "Beskytt det dere\nbygger sammen.",
        sv: "Skydda det ni\nbygger tillsammans.",
        da: "Beskyt det I\nbygger sammen.") }

    var onboardingProtectSub: String { s(
        en: "A cohabitation agreement is a legal document that protects both partners if circumstances change.",
        nb: "En samboerkontrakt er et dokument som beskytter begge parter hvis situasjonen endrer seg.",
        sv: "Ett samboavtal är ett dokument som skyddar båda parter om situationen förändras.",
        da: "En samlejekontrakt er et dokument der beskytter begge parter hvis situationen ændrer sig.") }

    var onboardingYesAgreement: String { s(
        en: "Yes, add an agreement",
        nb: "Ja, legg til en avtale",
        sv: "Ja, lägg till ett avtal",
        da: "Ja, tilføj en aftale") }

    var onboardingYesAgreementSub: String { s(
        en: "A simple document recording who owns what. You'll set it up after adding your assets.",
        nb: "Et enkelt dokument som registrerer hvem som eier hva. Du setter det opp etter å ha lagt til eiendeler.",
        sv: "Ett enkelt dokument som registrerar vem som äger vad. Du sätter upp det efter att ha lagt till tillgångar.",
        da: "Et enkelt dokument der registrerer hvem der ejer hvad. Du opsætter det efter at have tilføjet aktiver.") }

    var onboardingSkipForNow: String { s(
        en: "Not right now",
        nb: "Ikke nå",
        sv: "Inte just nu",
        da: "Ikke lige nu") }

    var onboardingSkipSub: String { s(
        en: "You can always add this later from the Agreement tab.",
        nb: "Du kan alltid legge dette til senere fra Avtale-fanen.",
        sv: "Du kan alltid lägga till detta senare från fliken Avtal.",
        da: "Du kan altid tilføje dette senere fra Aftale-fanen.") }

    var onboardingAgreementNote: String { s(
        en: "The agreement records ownership shares, contributions, and what happens to assets if you separate — nothing more. You confirm your own ownership; cohab doesn't verify identity.",
        nb: "Avtalen registrerer eierandeler, bidrag og hva som skjer med eiendeler ved brudd — ingenting mer. Du bekrefter ditt eget eierskap; cohab verifiserer ikke identitet.",
        sv: "Avtalet registrerar ägarandelar, bidrag och vad som händer med tillgångar vid separation — inget mer. Du bekräftar ditt eget ägande; cohab verifierar inte identitet.",
        da: "Aftalen registrerer ejerandele, bidrag og hvad der sker med aktiver ved separation — intet mere. Du bekræfter dit eget ejerskab; cohab verificerer ikke identitet.") }

    var onboardingWhatDoYouShare: String { s(
        en: "What do you\nshare?",
        nb: "Hva eier\ndere sammen?",
        sv: "Vad äger\nni gemensamt?",
        da: "Hvad ejer\nI sammen?") }

    var onboardingWhatSub: String { s(
        en: "Add the assets you own together.",
        nb: "Legg til eiendelene dere eier sammen.",
        sv: "Lägg till tillgångarna ni äger tillsammans.",
        da: "Tilføj de aktiver I ejer sammen.") }

    var onboardingAllSet: String { s(
        en: "You're all set.",
        nb: "Dere er klare.",
        sv: "Ni är redo.",
        da: "I er klar.") }

    var onboardingDisclaimerAck: String { s(
        en: "I understand — cohab provides tools, not legal advice",
        nb: "Jeg forstår — cohab er et verktøy, ikke juridisk rådgivning",
        sv: "Jag förstår — cohab är ett verktyg, inte juridisk rådgivning",
        da: "Jeg forstår — cohab er et værktøj, ikke juridisk rådgivning") }

    // MARK: Navigation tabs

    var tabHome: String       { s(en: "Home",      nb: "Hjem",     sv: "Hem",     da: "Hjem") }
    var tabAssets: String     { s(en: "Assets",    nb: "Eiendeler", sv: "Tillgångar", da: "Aktiver") }
    var tabAgreement: String  { s(en: "Agreement", nb: "Avtale",   sv: "Avtal",   da: "Aftale") }
    var tabCalculators: String { s(en: "Calculators", nb: "Kalkulatorer", sv: "Kalkylatorer", da: "Kalkulatorer") }

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
