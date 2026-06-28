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
    var dashboardNetEquity: String    { s(en: "Net equity",       nb: "Netto egenkapital", sv: "Nettoeget kapital", da: "Netto egenkapital") }
    var dashboardContribFirst: String { s(en: "Contributions returned first, surplus split by ownership",
                                           nb: "Bidrag utbetales først, deretter fordeles overskuddet etter eierandel",
                                           sv: "Bidrag återbetalas först, sedan delas överskottet efter ägarandel",
                                           da: "Bidrag tilbagebetales først, derefter fordeles overskuddet efter ejerandel") }
    var dashboardAddAsset: String     { s(en: "Add asset",        nb: "Legg til eiendel", sv: "Lägg till tillgång", da: "Tilføj aktiv") }
    var dashboardSetupTitle: String   { s(en: "Set up your household", nb: "Sett opp husholdningen", sv: "Konfigurera ditt hushåll", da: "Konfigurer din husstand") }
    var dashboardSetupSub: String     { s(en: "Track shared assets, contributions, and get a fair settlement whenever you need it.",
                                           nb: "Registrer felles eiendeler og bidrag, og få et rettferdig oppgjør når dere trenger det.",
                                           sv: "Registrera gemensamma tillgångar och bidrag och få en rättvis uppgörelse vid behov.",
                                           da: "Registrer fælles aktiver og bidrag og få en retfærdig opgørelse når I har brug for det.") }
    var dashboardNoAssets: String     { s(en: "No assets yet",    nb: "Ingen eiendeler ennå", sv: "Inga tillgångar ännu", da: "Ingen aktiver endnu") }
    var dashboardNoAssetsSub: String  { s(en: "Add your home, car, or any shared asset to track contributions and see a fair settlement breakdown.",
                                           nb: "Legg til bolig, bil eller andre felles eiendeler for å registrere bidrag og se en rettferdig oppgjørsberegning.",
                                           sv: "Lägg till din bostad, bil eller andra gemensamma tillgångar för att spåra bidrag och se en rättvis fördelning.",
                                           da: "Tilføj din bolig, bil eller andre fælles aktiver for at registrere bidrag og se en retfærdig opgørelse.") }
    var dashboardItems: String        { s(en: "items",  nb: "elementer", sv: "poster",    da: "elementer") }
    var dashboardItem: String         { s(en: "item",   nb: "element",   sv: "post",      da: "element") }
    var dashboardLoan: String         { s(en: "Loan",   nb: "Lån",       sv: "Lån",       da: "Lån") }
    var dashboardEdit: String         { s(en: "Edit",   nb: "Rediger",   sv: "Redigera",  da: "Rediger") }
    var dashboardAgreementSigned: String { s(en: "Agreement signed ✓", nb: "Avtale signert ✓", sv: "Avtal undertecknat ✓", da: "Aftale underskrevet ✓") }
    var dashboardWaitingSignatures: String { s(en: "Waiting for signatures…", nb: "Venter på signaturer…", sv: "Väntar på underskrifter…", da: "Afventer underskrifter…") }
    var dashboardShowCalculation: String { s(en: "Settlement estimate", nb: "Oppgjørsestimat", sv: "Uppgörelsekalkyl", da: "Opgørelsesestimat") }
    var dashboardHideCalculation: String { s(en: "Hide settlement estimate", nb: "Skjul oppgjørsestimat", sv: "Dölj uppgörelsekalkyl", da: "Skjul opgørelsesestimat") }
    var dashboardSaleCostsSub: String { s(en: "Incl. sale costs & contribution returns", nb: "Inkl. salgskostnader og bidragstilbakebetaling", sv: "Inkl. försäljningskostnader och bidragsåterbetalning", da: "Inkl. salgsomkostninger og bidragstilbagebetaling") }

    // MARK: Asset card / detail

    var assetContribFirst: String   { s(en: "Contributions returned first · surplus split",
                                         nb: "Bidrag utbetales først · overskudd fordeles",
                                         sv: "Bidrag återbetalas först · överskott fördelas",
                                         da: "Bidrag tilbagebetales først · overskud fordeles") }
    var assetDistribution: String   { s(en: "DISTRIBUTION",    nb: "FORDELING",       sv: "FÖRDELNING",     da: "FORDELING") }
    var assetContribInterest: String { s(en: "① Contributions & interest returned", nb: "① Bidrag og renter tilbakebetalt", sv: "① Bidrag och ränta återbetalad", da: "① Bidrag og renter tilbagebetalt") }
    var assetRemainingSurplus: String { s(en: "② Remaining surplus", nb: "② Gjenstående overskudd", sv: "② Återstående överskott", da: "② Resterende overskud") }
    var assetTotalPayout: String    { s(en: "TOTAL PAYOUT",    nb: "TOTAL UTBETALING", sv: "TOTAL UTBETALNING", da: "TOTAL UDBETALING") }
    var assetContribInterestLine: String { s(en: "Contributions & interest:", nb: "Bidrag og renter:", sv: "Bidrag och ränta:", da: "Bidrag og renter:") }
    var assetRateLine: String       { s(en: "Rate:", nb: "Rente:", sv: "Ränta:", da: "Rente:") }
    var assetPerAgreement: String   { s(en: "Per agreement between parties", nb: "I henhold til avtale mellom partene", sv: "Enligt avtal mellan parterna", da: "I henhold til aftale mellem parterne") }
    var assetCurrentValue: String   { s(en: "Current value",   nb: "Gjeldende verdi", sv: "Aktuellt värde",  da: "Aktuel værdi") }
    var assetNetEquity: String      { s(en: "Net equity",      nb: "Netto egenkapital", sv: "Nettoeget kapital", da: "Netto egenkapital") }
    var assetNetProceeds: String    { s(en: "Net proceeds",    nb: "Netto proveny",   sv: "Nettointäkt",     da: "Nettoprovenu") }
    var assetTotalReturned: String  { s(en: "Total returned",  nb: "Totalt tilbakebetalt", sv: "Totalt återbetalt", da: "Totalt tilbagebetalt") }
    var assetNoContribs: String     { s(en: "No contributions recorded yet.", nb: "Ingen bidrag registrert ennå.", sv: "Inga bidrag registrerade ännu.", da: "Ingen bidrag registreret endnu.") }
    var assetContribHistory: String { s(en: "Contribution History", nb: "Bidragshistorikk", sv: "Bidragshistorik", da: "Bidragshistorik") }
    var assetAddContrib: String     { s(en: "Add Contribution",  nb: "Legg til bidrag",   sv: "Lägg till bidrag", da: "Tilføj bidrag") }
    var assetRecalculate: String    { s(en: "Recalculate",       nb: "Beregn på nytt",    sv: "Beräkna om",      da: "Genberegn") }
    var assetOwnership: String      { s(en: "OWNERSHIP",         nb: "EIERSKAP",          sv: "ÄGARANDEL",       da: "EJERSKAB") }
    var assetInterestEarned: String { s(en: "interest",          nb: "renter",            sv: "ränta",           da: "renter") }

    // MARK: Agreement tab

    var agreementTitle: String    { s(en: "Ownership Agreement", nb: "Eierskapsavtale",   sv: "Ägaravtal",      da: "Ejerskabsaftale") }
    var agreementGenerate: String { s(en: "Generate & sign agreement", nb: "Generer og signer avtale", sv: "Generera och signera avtal", da: "Generér og underskriv aftale") }
    var agreementUpdate: String   { s(en: "Update & resend agreement", nb: "Oppdater og send avtale på nytt", sv: "Uppdatera och skicka om avtal", da: "Opdatér og gensend aftale") }
    var agreementSigned: String   { s(en: "Signed by both parties", nb: "Signert av begge parter", sv: "Undertecknat av båda parter", da: "Underskrevet af begge parter") }
    var agreementPending: String  { s(en: "Pending signatures", nb: "Venter på signering", sv: "Väntar på underskrift", da: "Afventer underskrift") }
    var agreementNotSigned: String { s(en: "Not signed yet", nb: "Ikke signert ennå", sv: "Ej undertecknat", da: "Ikke underskrevet endnu") }
    var agreementUpdateNeeded: String { s(en: "Update needed", nb: "Oppdatering nødvendig", sv: "Uppdatering krävs", da: "Opdatering nødvendig") }
    var agreementSentWaiting: String { s(en: "Sent — waiting for signatures", nb: "Sendt — venter på signaturer", sv: "Skickat — väntar på underskrifter", da: "Sendt — afventer underskrifter") }
    var agreementCheckStatus: String { s(en: "Check signing status", nb: "Sjekk signeringsstatus", sv: "Kontrollera signeringsstatus", da: "Tjek signeringsstatus") }
    var agreementChecking: String { s(en: "Checking…", nb: "Sjekker…", sv: "Kontrollerar…", da: "Tjekker…") }
    var agreementLinksSentByEmail: String { s(en: "Signing links sent to both parties by email", nb: "Signeringslenker sendt til begge parter på e-post", sv: "Signeringslänkar skickade till båda parter via e-post", da: "Signeringslinks sendt til begge parter via e-mail") }
    var agreementNoAgreement: String { s(en: "No agreement yet", nb: "Ingen avtale ennå", sv: "Inget avtal ännu", da: "Ingen aftale endnu") }
    var agreementNoAgreementSub: String { s(en: "Generate and sign your cohabitation agreement", nb: "Generer og signer samboerkontrakten", sv: "Generera och underteckna samboavtalet", da: "Generér og underskriv samlejeaftalen") }
    var agreementWhatsIn: String  { s(en: "What's in your agreement", nb: "Hva er i avtalen din", sv: "Vad finns i ditt avtal", da: "Hvad er i din aftale") }
    var agreementViewDownload: String { s(en: "View & download agreement", nb: "Se og last ned avtale", sv: "Visa och ladda ner avtal", da: "Se og download aftale") }
    var agreementViewSigning: String { s(en: "View signing links", nb: "Se signeringslenker", sv: "Visa signeringslänkar", da: "Se signeringslinks") }
    var agreementNeedUpdate: String { s(en: "Need to update?", nb: "Trenger du å oppdatere?", sv: "Behöver du uppdatera?", da: "Skal du opdatere?") }
    var agreementNeedUpdateSub: String { s(en: "Generate a new agreement above — both parties will need to sign again.", nb: "Generer en ny avtale ovenfor — begge parter må signere på nytt.", sv: "Generera ett nytt avtal ovan — båda parter måste underteckna igen.", da: "Generér en ny aftale ovenfor — begge parter skal underskrive igen.") }
    var agreementNoFormal: String { s(en: "No agreement set up", nb: "Ingen avtale satt opp", sv: "Inget avtal konfigurerat", da: "Ingen aftale konfigureret") }
    var agreementNoFormalSub: String { s(en: "You chose to track only. You can upgrade to a formal agreement any time from Settings.", nb: "Du valgte kun sporing. Du kan oppgradere til en formell avtale når som helst fra Innstillinger.", sv: "Du valde att bara spåra. Du kan uppgradera till ett formellt avtal när som helst från Inställningar.", da: "Du valgte kun sporing. Du kan opgradere til en formel aftale til enhver tid fra Indstillinger.") }
    var agreementEmailsNeeded: String { s(en: "Email addresses needed for signing", nb: "E-postadresser nødvendig for signering", sv: "E-postadresser behövs för signering", da: "E-mailadresser nødvendige for signering") }
    var agreementEmailsNeededSub: String { s(en: "Both partners need an email to receive their signing link.", nb: "Begge parter trenger e-post for å motta signeringslenken.", sv: "Båda parter behöver en e-postadress för att ta emot sin signeringslänk.", da: "Begge parter skal bruge en e-mail for at modtage deres signeringslink.") }
    var agreementAddEmails: String { s(en: "Add signing emails", nb: "Legg til e-postadresser for signering", sv: "Lägg till e-postadresser för signering", da: "Tilføj e-mailadresser til signering") }
    var agreementEmailBothNeed: String { s(en: "Both partners need an email address to receive and sign the agreement via DocuSeal.", nb: "Begge parter trenger en e-postadresse for å motta og signere avtalen via DocuSeal.", sv: "Båda parter behöver en e-postadress för att ta emot och underteckna avtalet via DocuSeal.", da: "Begge parter skal have en e-mailadresse for at modtage og underskrive aftalen via DocuSeal.") }
    var agreementSaveAndContinue: String { s(en: "Save & continue", nb: "Lagre og fortsett", sv: "Spara och fortsätt", da: "Gem og fortsæt") }
    var agreementDissolutionIncluded: String { s(en: "Dissolution terms included", nb: "Oppløsningsvilkår inkludert", sv: "Upplösningsvillkor ingår", da: "Opløsningsvilkår inkluderet") }
    var agreementDissolutionSub: String { s(en: "Contributions returned first; remaining split by ownership share.", nb: "Bidrag tilbakebetales først; resten deles etter eierandel.", sv: "Bidrag återbetalas först; resten delas efter ägarandel.", da: "Bidrag tilbagebetales først; resten fordeles efter ejerandel.") }
    var agreementPartnerBEmail: String { s(en: "will receive a signing link by email.", nb: "mottar en signeringslenke på e-post.", sv: "får en signeringslänk via e-post.", da: "modtager et signeringslink via e-mail.") }
    var agreementContribsTracked: String { s(en: "contributions tracked", nb: "bidrag registrert", sv: "bidrag registrerade", da: "bidrag registreret") }
    var agreementContribTracked: String { s(en: "contribution tracked", nb: "bidrag registrert", sv: "bidrag registrerat", da: "bidrag registreret") }
    var agreementNoContribs: String { s(en: "No contributions recorded yet", nb: "Ingen bidrag registrert ennå", sv: "Inga bidrag registrerade ännu", da: "Ingen bidrag registreret endnu") }
    var agreementSharedAssets: String { s(en: "shared assets", nb: "felles eiendeler", sv: "gemensamma tillgångar", da: "fælles aktiver") }
    var agreementSharedAsset: String { s(en: "shared asset", nb: "felles eiendel", sv: "gemensam tillgång", da: "fælles aktiv") }
    var agreementNoAssetsYet: String { s(en: "No assets added yet", nb: "Ingen eiendeler lagt til ennå", sv: "Inga tillgångar tillagda ännu", da: "Ingen aktiver tilføjet endnu") }

    // MARK: Assets tab

    var assetsNoAssetsTitle: String { s(en: "No assets yet", nb: "Ingen eiendeler ennå", sv: "Inga tillgångar ännu", da: "Ingen aktiver endnu") }
    var assetsNoAssetsSub: String   { s(en: "Add your home, car, savings, or any shared asset to track contributions and equity.",
                                         nb: "Legg til bolig, bil, sparing eller andre felles eiendeler for å registrere bidrag og egenkapital.",
                                         sv: "Lägg till din bostad, bil, sparande eller andra gemensamma tillgångar för att spåra bidrag och eget kapital.",
                                         da: "Tilføj din bolig, bil, opsparing eller andre fælles aktiver for at registrere bidrag og egenkapital.") }
    var assetsAddFirst: String      { s(en: "Add first asset", nb: "Legg til første eiendel", sv: "Lägg till första tillgången", da: "Tilføj første aktiv") }

    // MARK: Calculators

    var calcOwnershipTitle: String { s(en: "Ownership split",   nb: "Eierfordelingskalkulator", sv: "Ägarandelsfördelning",  da: "Ejerandelskalkulator") }
    var calcOwnershipSub: String   { s(en: "Calculate equity based on deposits and payments.",
                                        nb: "Beregn egenkapital basert på innskudd og betalinger.",
                                        sv: "Beräkna eget kapital baserat på insättningar och betalningar.",
                                        da: "Beregn egenkapital baseret på indskud og betalinger.") }
    var calcExpenseTitle: String   { s(en: "Expense split",     nb: "Utgiftsfordeling",         sv: "Kostnadsfördelning",    da: "Udgiftsfordeling") }
    var calcExpenseSub: String     { s(en: "Fairly divide monthly household costs.",
                                        nb: "Fordel månedlige husholdningsutgifter rettferdig.",
                                        sv: "Fördela månadsliga hushållskostnader rättvist.",
                                        da: "Fordel månedlige husholdningsudgifter rimeligt.") }
    var calcRebalanceTitle: String { s(en: "Rebalance",         nb: "Rebalansering",            sv: "Ombalansering",         da: "Rebalancering") }
    var calcRebalanceSub: String   { s(en: "See what it takes to reach 50/50 ownership.",
                                        nb: "Se hva som skal til for å nå 50/50 eierskap.",
                                        sv: "Se vad som krävs för att nå 50/50 ägarandel.",
                                        da: "Se hvad der skal til for at nå 50/50 ejerskab.") }

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
