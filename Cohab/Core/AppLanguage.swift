import Foundation
import SwiftUI

// MARK: - Language enum

enum AppLanguage: String, CaseIterable {
    case en, nb, sv, da, fi, de, fr, es

    /// Derive language from ISO 3166 country code.
    static func from(country: String) -> AppLanguage {
        switch country {
        case "NO":          return .nb
        case "SE":          return .sv
        case "DK":          return .da
        case "FI":          return .fi
        case "DE":          return .de
        case "AT", "CH":    return .de
        case "FR":          return .fr
        case "ES":          return .es
        default:            return .en
        }
    }

    var localeIdentifier: String {
        switch self {
        case .en: return "en"
        case .nb: return "nb"
        case .sv: return "sv"
        case .da: return "da"
        case .fi: return "fi"
        case .de: return "de"
        case .fr: return "fr"
        case .es: return "es"
        }
    }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .nb: return "Norsk"
        case .sv: return "Svenska"
        case .da: return "Dansk"
        case .fi: return "Suomi"
        case .de: return "Deutsch"
        case .fr: return "Français"
        case .es: return "Español"
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
                                     da: "Vigtig information",
                                     fi: "Tärkeä ilmoitus",
                                     de: "Wichtiger Hinweis",
                                     fr: "Avis important",
                                     es: "Aviso importante") }

    var disclaimerBody: String { s(
        en: """
cohab is not a law firm and does not provide legal advice. \
This agreement is a template for general use between two parties.

• Digital signatures and cohabitation agreements may not be legally binding in all jurisdictions. \
Courts often look for clear intent to create legal relations — \
verify with a licensed attorney in your country before signing.

• This template may not cover every aspect of your situation. \
For significant legal matters — such as high-value property or complex ownership — \
consult a qualified attorney or legal counsel.

• The interest rate used in calculations is a guiding illustrative reference rate only \
and is not a guaranteed or legally binding rate.

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

• Renten som brukes i beregningene er en veiledende referanserente \
og er kun illustrativ.

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

• Räntan som används i beräkningarna är en vägledande illustrativ referensränta \
och är inte garanterad eller juridiskt bindande.

• Håll avtalet uppdaterat när gemensamma tillgångar eller bidrag förändras.

• Observera att enbart spårning av bidrag i appen inte åsidosätter Sambolagens regler om \
likadelning. För att appens fördelningsmodell ska gälla måste ett formellt samboavtal \
undertecknas där Sambolagen avtalas bort.

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

• Den rente der anvendes i beregningerne er en vejledende illustrativ referencerente \
og er ikke garanteret eller juridisk bindende.

• Hold aftalen opdateret, når fælles aktiver eller bidrag ændres.

Ved at fortsætte anerkender du, at cohab tilbyder værktøjer, ikke juridisk rådgivning, \
og fraskriver sig ethvert ansvar for et aftalets juridiske gyldighed i nogen jurisdiktion.
""",
        fi: """
cohab ei ole lakiasiaintoimisto eikä anna oikeudellisia neuvoja. \
Tämä sopimus on yleiskäyttöinen malli kahdelle osapuolelle.

• Sähköinen allekirjoitus ei välttämättä ole oikeudellisesti sitova kaikissa lainkäyttöalueilla. \
Tarkista digitaalisten sopimusten pätevyys maasi voimassa olevan lainsäädännön mukaan.

• Malli ei välttämättä kata kaikkia tilanteitasi. \
Ota yhteys pätevään lakimieheen tärkeissä oikeudellisissa asioissa.

• Laskelmissa käytetty korko on ohjeellinen viitekorko eikä ole takuukorko tai oikeudellisesti sitova.

• Pidä sopimus ajan tasalla yhteisten varojen tai maksujen muuttuessa.

Jatkamalla vahvistat, että cohab tarjoaa työkaluja, ei oikeudellisia neuvoja, \
eikä se ota vastuuta sopimuksen oikeudellisesta pätevyydestä missään lainkäyttöalueella.
""",
        de: """
cohab ist keine Anwaltskanzlei und erteilt keine Rechtsberatung. \
Diese Vereinbarung ist eine Vorlage für den allgemeinen Gebrauch zwischen zwei Parteien.

• Elektronische Signaturen sind nicht in allen Rechtsgebieten rechtlich bindend. \
Überprüfen Sie die Gültigkeit digitaler Verträge nach dem in Ihrem Land geltenden Recht.

• Die Vorlage deckt möglicherweise nicht alle Aspekte Ihrer Situation ab. \
Wenden Sie sich bei wichtigen rechtlichen Fragen an einen qualifizierten Anwalt.

• Der in den Berechnungen verwendete Zinssatz ist ein orientierender Referenzzins \
und ist nicht garantiert oder rechtlich verbindlich.

• Halten Sie die Vereinbarung aktuell, wenn sich gemeinsame Vermögenswerte oder Einlagen ändern.

Durch Fortfahren bestätigen Sie, dass cohab Werkzeuge und keine Rechtsberatung bietet \
und keine Haftung für die rechtliche Gültigkeit einer Vereinbarung übernimmt.
""",
        fr: """
cohab n'est pas un cabinet d'avocats et ne fournit pas de conseils juridiques. \
Cet accord est un modèle à usage général entre deux parties.

• La signature électronique n'est pas nécessairement juridiquement contraignante dans toutes les juridictions. \
Vérifiez la validité des contrats numériques selon la législation en vigueur dans votre pays.

• Le modèle peut ne pas couvrir tous les aspects de votre situation. \
Consultez un avocat qualifié pour les questions juridiques importantes.

• Le taux d'intérêt utilisé dans les calculs est un taux de référence indicatif \
et n'est pas garanti ni juridiquement contraignant.

• Tenez l'accord à jour lorsque les actifs communs ou les contributions changent.

En continuant, vous reconnaissez que cohab fournit des outils, non des conseils juridiques, \
et décline toute responsabilité quant à la validité juridique de tout accord.
""",
        es: """
cohab no es un despacho de abogados y no presta asesoramiento jurídico. \
Este acuerdo es una plantilla de uso general entre dos partes.

• La firma electrónica puede no ser jurídicamente vinculante en todas las jurisdicciones. \
Verifica la validez de los contratos digitales conforme a la legislación vigente en tu país.

• La plantilla puede no cubrir todos los aspectos de tu situación. \
Consulta a un abogado cualificado para asuntos jurídicos importantes.

• El tipo de interés utilizado en los cálculos es un tipo de referencia orientativo \
y no es garantizado ni jurídicamente vinculante.

• Mantén el acuerdo actualizado cuando cambien los activos comunes o las aportaciones.

Al continuar, reconoces que cohab proporciona herramientas, no asesoramiento jurídico, \
y no acepta ninguna responsabilidad por la validez jurídica de ningún acuerdo.
""") }

    var disclaimerAckLabel: String { s(
        en: "I understand — cohab provides tools, not legal advice",
        nb: "Jeg forstår — cohab er et verktøy, ikke juridisk rådgivning",
        sv: "Jag förstår — cohab är ett verktyg, inte juridisk rådgivning",
        da: "Jeg forstår — cohab er et værktøj, ikke juridisk rådgivning",
        fi: "Ymmärrän — cohab on työkalu, ei oikeudellinen neuvonta",
        de: "Ich verstehe — cohab ist ein Werkzeug, keine Rechtsberatung",
        fr: "Je comprends — cohab est un outil, pas un conseil juridique",
        es: "Entiendo — cohab es una herramienta, no asesoramiento legal") }

    var disclaimerFooter: String { s(
        en: "cohab is not a law firm. This is a template — not legal advice. Enforceability of cohabitation agreements varies by jurisdiction. Consult a licensed attorney for significant legal matters.",
        nb: "cohab er ikke et advokatfirma. Dette er en standardisert mal. Elektronisk signering er ikke bindende i alle jurisdiksjoner. Kontakt advokat ved viktige juridiske spørsmål.",
        sv: "cohab är inte en advokatbyrå. Detta är en standardiserad mall. Elektronisk signering är inte bindande i alla jurisdiktioner. Kontakta en advokat vid viktiga juridiska frågor.",
        da: "cohab er ikke et advokatfirma. Dette er en standardiseret skabelon. Elektronisk signering er ikke bindende i alle jurisdiktioner. Kontakt en advokat ved vigtige juridiske spørgsmål.",
        fi: "cohab ei ole lakiasiaintoimisto. Tämä on malli — ei oikeudellinen neuvo. Ota yhteys lakimieheen tärkeissä kiinteistöasioissa.",
        de: "cohab ist keine Anwaltskanzlei. Dies ist eine Vorlage — keine Rechtsberatung. Wenden Sie sich bei wichtigen Rechtsfragen an einen Anwalt.",
        fr: "cohab n'est pas un cabinet d'avocats. Il s'agit d'un modèle — pas d'un conseil juridique. Consultez un avocat pour les questions juridiques importantes.",
        es: "cohab no es un despacho de abogados. Esto es una plantilla — no asesoramiento jurídico. Consulta a un abogado para asuntos jurídicos importantes.") }

    // MARK: Onboarding

    var onboardingTagline: String { s(
        en: "Track ownership.\nTrust the numbers.",
        nb: "Registrer eierskap.\nStol på tallene.",
        sv: "Registrera ägandet.\nLita på siffrorna.",
        da: "Registrér ejerskab.\nStol på tallene.",
        fi: "Seuraa omistusta.\nLuota lukuihin.",
        de: "Eigentum verfolgen.\nDen Zahlen vertrauen.",
        fr: "Suivez la propriété.\nFaites confiance aux chiffres.",
        es: "Registra la propiedad.\nConfía en los números.") }

    var onboardingSubtitle: String { s(
        en: "A shared record of what you own together\n— and what's fair if anything changes.",
        nb: "Et felles register over det dere eier sammen\n— og hva som er rettferdig hvis noe endres.",
        sv: "En gemensam förteckning över vad ni äger tillsammans\n— och vad som är rättvist om något förändras.",
        da: "En fælles oversigt over hvad I ejer sammen\n— og hvad der er rimeligt, hvis noget ændres.",
        fi: "Yhteinen rekisteri siitä, mitä omistatte yhdessä\n— ja mikä on reilua, jos jotain muuttuu.",
        de: "Ein gemeinsames Verzeichnis dessen, was Sie zusammen besitzen\n— und was fair ist, wenn sich etwas ändert.",
        fr: "Un registre commun de ce que vous possédez ensemble\n— et ce qui est juste si quelque chose change.",
        es: "Un registro compartido de lo que poseen juntos\n— y lo que es justo si algo cambia.") }

    var onboardingGetStarted: String { s(en: "Get started", nb: "Kom i gang", sv: "Kom igång", da: "Kom i gang", fi: "Aloita", de: "Loslegen", fr: "Commencer", es: "Empezar") }
    var onboardingContinue: String   { s(en: "Continue",    nb: "Fortsett",   sv: "Fortsätt", da: "Fortsæt",   fi: "Jatka", de: "Weiter", fr: "Continuer", es: "Continuar") }
    var onboardingStartTracking: String { s(en: "Start tracking", nb: "Start registrering", sv: "Börja registrera", da: "Start registrering", fi: "Aloita seuranta", de: "Tracking starten", fr: "Commencer le suivi", es: "Comenzar seguimiento") }

    // MARK: Onboarding — new screens

    var onboardingHero: String { s(
        en: "Protect what matters.",
        nb: "Beskytt det som betyr noe.",
        sv: "Skydda det som är viktigt.",
        da: "Beskyt det, der betyder noget.",
        fi: "Suojaa se, mikä on tärkeää.",
        de: "Schützt, was euch wichtig ist.",
        fr: "Protégez ce qui compte.",
        es: "Protege lo que importa.") }

    var onboardingHeroSub: String { s(
        en: "Know who owns what, track every contribution, and avoid costly misunderstandings.",
        nb: "Vit hvem som eier hva, spor hvert bidrag og unngå kostbare misforståelser.",
        sv: "Veta vem som äger vad, spåra varje bidrag och undvik kostsamma missförståenden.",
        da: "Vid hvem der ejer hvad, spor hvert bidrag og undgå dyre misforståelser.",
        fi: "Tiedä kuka omistaa mitä, seuraa jokaista panosta ja vältä kalliit väärinkäsitykset.",
        de: "Wisst, wer was besitzt, verfolgt jeden Beitrag und vermeidet kostspielige Missverständnisse.",
        fr: "Sachez qui possède quoi, suivez chaque apport et évitez les malentendus coûteux.",
        es: "Sabed quién posee qué, registrad cada aportación y evitad malentendidos costosos.") }

    var onboardingAlreadyHaveAccount: String { s(
        en: "I already have an account",
        nb: "Jeg har allerede en konto",
        sv: "Jag har redan ett konto",
        da: "Jeg har allerede en konto",
        fi: "Minulla on jo tili",
        de: "Ich habe bereits ein Konto",
        fr: "J'ai déjà un compte",
        es: "Ya tengo una cuenta") }

    // Country step is always shown in English — language unknown before country is chosen.

    var onboardingWhoDoYouShare: String { s(
        en: "Who do you\nshare with?",
        nb: "Hvem deler\ndu med?",
        sv: "Vem delar\ndu med?",
        da: "Hvem deler\ndu med?",
        fi: "Kenen kanssa\njaatte?",
        de: "Mit wem teilen\nSie?",
        fr: "Avec qui\npartagez-vous?",
        es: "¿Con quién\ncompartes?") }

    var onboardingPartnerSub: String { s(
        en: "We'll use this to personalise your overview.",
        nb: "Vi bruker dette til å tilpasse oversikten.",
        sv: "Vi använder detta för att anpassa din översikt.",
        da: "Vi bruger dette til at tilpasse din oversigt.",
        fi: "Käytämme tätä yhteenvetosi mukauttamiseen.",
        de: "Wir verwenden dies, um Ihre Übersicht zu personalisieren.",
        fr: "Nous utilisons ceci pour personnaliser votre aperçu.",
        es: "Usaremos esto para personalizar tu resumen.") }

    // Partner invite step
    var onboardingAboutYou: String { s(
        en: "About you",
        nb: "Om deg",
        sv: "Om dig",
        da: "Om dig",
        fi: "Sinusta",
        de: "Über dich",
        fr: "À propos de toi",
        es: "Sobre ti") }

    var onboardingAddPartnerQuestion: String { s(
        en: "Add your partner?",
        nb: "Legg til samboeren din?",
        sv: "Lägg till din sambo?",
        da: "Tilføj din samboer?",
        fi: "Lisää kumppanis?",
        de: "Partner hinzufügen?",
        fr: "Ajouter ton/ta partenaire ?",
        es: "¿Añadir a tu pareja?") }

    var onboardingAddPartnerYes: String { s(
        en: "Yes, add partner",
        nb: "Ja, legg til samboer",
        sv: "Ja, lägg till sambo",
        da: "Ja, tilføj samboer",
        fi: "Kyllä, lisää kumppani",
        de: "Ja, Partner hinzufügen",
        fr: "Oui, ajouter",
        es: "Sí, añadir pareja") }

    var onboardingAddPartnerLater: String { s(
        en: "Later",
        nb: "Senere",
        sv: "Senare",
        da: "Senere",
        fi: "Myöhemmin",
        de: "Später",
        fr: "Plus tard",
        es: "Más tarde") }

    var onboardingAddingPartner: String { s(
        en: "Adding partner",
        nb: "Legger til samboer",
        sv: "Lägger till sambo",
        da: "Tilføjer samboer",
        fi: "Lisätään kumppani",
        de: "Partner wird hinzugefügt",
        fr: "Ajout du partenaire",
        es: "Añadiendo pareja") }

    var onboardingAddingLater: String { s(
        en: "Adding later",
        nb: "Legger til senere",
        sv: "Lägger till senare",
        da: "Tilføjer senere",
        fi: "Lisätään myöhemmin",
        de: "Wird später hinzugefügt",
        fr: "Ajout ultérieur",
        es: "Añadiendo más tarde") }

    var onboardingChange: String { s(
        en: "Change",
        nb: "Endre",
        sv: "Ändra",
        da: "Ændr",
        fi: "Muuta",
        de: "Ändern",
        fr: "Modifier",
        es: "Cambiar") }

    var onboardingYourName: String  { s(en: "YOUR NAME",     nb: "DITT NAVN",      sv: "DITT NAMN",    da: "DIT NAVN",    fi: "NIMESI",              de: "IHR NAME",           fr: "VOTRE NOM",            es: "SU NOMBRE") }
    var onboardingPartnerName: String { s(en: "PARTNER'S NAME", nb: "PARTNERS NAVN", sv: "PARTNERNS NAMN", da: "PARTNERS NAVN", fi: "KUMPPANIN NIMI",   de: "NAME DES PARTNERS",  fr: "NOM DU PARTENAIRE",    es: "NOMBRE DEL SOCIO") }
    var onboardingYourEmail: String { s(en: "YOUR EMAIL",    nb: "DIN E-POST",     sv: "DIN E-POST",   da: "DIN E-MAIL",  fi: "SÄHKÖPOSTISI",        de: "IHRE E-MAIL",        fr: "VOTRE E-MAIL",         es: "SU CORREO") }
    var onboardingPartnerEmail: String { s(en: "PARTNER'S EMAIL", nb: "PARTNERS E-POST", sv: "PARTNERNS E-POST", da: "PARTNERS E-MAIL", fi: "KUMPPANIN SÄHKÖPOSTI", de: "E-MAIL DES PARTNERS", fr: "E-MAIL DU PARTENAIRE", es: "CORREO DEL SOCIO") }

    var onboardingRelationship: String { s(en: "RELATIONSHIP", nb: "FORHOLD", sv: "RELATION", da: "FORHOLD", fi: "SUHDE", de: "BEZIEHUNG", fr: "RELATION", es: "RELACIÓN") }
    var onboardingCouple: String     { s(en: "Couple",            nb: "Par",               sv: "Par",             da: "Par",             fi: "Pari",                de: "Paar",               fr: "Couple",               es: "Pareja") }
    var onboardingHousemates: String { s(en: "Housemates",        nb: "Samboere",          sv: "Sambos",          da: "Samboere",        fi: "Asuntotoverit",       de: "Mitbewohner",        fr: "Colocataires",         es: "Compañeros de piso") }
    var onboardingBusiness: String   { s(en: "Business partners", nb: "Forretningspartnere", sv: "Affärspartners", da: "Forretningspartnere", fi: "Liikekumppanit",  de: "Geschäftspartner",   fr: "Partenaires commerciaux", es: "Socios comerciales") }

    var onboardingProtect: String { s(
        en: "Protect what you\nbuild together.",
        nb: "Beskytt det dere\nbygger sammen.",
        sv: "Skydda det ni\nbygger tillsammans.",
        da: "Beskyt det I\nbygger sammen.",
        fi: "Suojaa se, mitä\nrakennatte yhdessä.",
        de: "Schützen Sie, was\nSie gemeinsam aufbauen.",
        fr: "Protégez ce que\nvous construisez ensemble.",
        es: "Protege lo que\nconstruís juntos.") }

    var onboardingProtectSub: String { s(
        en: "A cohabitation agreement is a legal document that protects both partners if circumstances change.",
        nb: "En samboerkontrakt er et dokument som beskytter begge parter hvis situasjonen endrer seg.",
        sv: "Ett samboavtal är ett dokument som skyddar båda parter om situationen förändras.",
        da: "En samlivskontrakt er et dokument der beskytter begge parter hvis situationen ændrer sig.",
        fi: "Avoliittosopimus on oikeudellinen asiakirja, joka suojaa molempia osapuolia olosuhteiden muuttuessa.",
        de: "Ein Partnerschaftsvertrag ist ein rechtliches Dokument, das beide Partner schützt, wenn sich die Umstände ändern.",
        fr: "Un accord de cohabitation est un document juridique qui protège les deux partenaires en cas de changement de situation.",
        es: "Un acuerdo de convivencia es un documento jurídico que protege a ambas partes si las circunstancias cambian.") }

    var onboardingYesAgreement: String { s(
        en: "Yes, add an agreement",
        nb: "Ja, legg til en avtale",
        sv: "Ja, lägg till ett avtal",
        da: "Ja, tilføj en aftale",
        fi: "Kyllä, lisää sopimus",
        de: "Ja, Vereinbarung hinzufügen",
        fr: "Oui, ajouter un accord",
        es: "Sí, agregar un acuerdo") }

    var onboardingYesAgreementSub: String { s(
        en: "A simple document recording who owns what. You'll set it up after adding your assets.",
        nb: "Et enkelt dokument som registrerer hvem som eier hva. Du setter det opp etter å ha lagt til eiendeler.",
        sv: "Ett enkelt dokument som registrerar vem som äger vad. Du sätter upp det efter att ha lagt till tillgångar.",
        da: "Et enkelt dokument der registrerer hvem der ejer hvad. Du opsætter det efter at have tilføjet aktiver.",
        fi: "Yksinkertainen asiakirja, joka kirjaa kuka omistaa mitä. Luot sen varojen lisäämisen jälkeen.",
        de: "Ein einfaches Dokument, das festhält, wer was besitzt. Sie richten es nach dem Hinzufügen Ihrer Vermögenswerte ein.",
        fr: "Un document simple enregistrant qui possède quoi. Vous le configurerez après avoir ajouté vos actifs.",
        es: "Un documento sencillo que registra quién posee qué. Lo configurarás después de agregar tus activos.") }

    var onboardingSkipForNow: String { s(
        en: "Not right now",
        nb: "Ikke nå",
        sv: "Inte just nu",
        da: "Ikke lige nu",
        fi: "Ei juuri nyt",
        de: "Nicht jetzt",
        fr: "Pas maintenant",
        es: "Ahora no") }

    var onboardingSkipSub: String { s(
        en: "You can always add this later from the Agreement tab.",
        nb: "Du kan alltid legge dette til senere fra Avtale-fanen.",
        sv: "Du kan alltid lägga till detta senare från fliken Avtal.",
        da: "Du kan altid tilføje dette senere fra Aftale-fanen.",
        fi: "Voit aina lisätä tämän myöhemmin Sopimus-välilehdeltä.",
        de: "Sie können dies jederzeit später im Vereinbarungen-Tab hinzufügen.",
        fr: "Vous pouvez toujours l'ajouter plus tard depuis l'onglet Convention.",
        es: "Siempre puedes añadirlo más tarde desde la pestaña Contrato.") }

    var onboardingAgreementNote: String { s(
        en: "The agreement records ownership shares, contributions, and what happens to assets if you separate — nothing more. You confirm your own ownership; cohab doesn't verify identity.",
        nb: "Avtalen registrerer eierandeler, bidrag og hva som skjer med eiendeler ved brudd — ingenting mer. Du bekrefter ditt eget eierskap; cohab verifiserer ikke identitet.",
        sv: "Avtalet registrerar ägarandelar, bidrag och vad som händer med tillgångar vid separation — inget mer. Du bekräftar ditt eget ägande; cohab verifierar inte identitet.",
        da: "Aftalen registrerer ejerandele, bidrag og hvad der sker med aktiver ved separation — intet mere. Du bekræfter dit eget ejerskab; cohab verificerer ikke identitet.",
        fi: "Sopimus kirjaa omistusosuudet, panokset ja mitä tapahtuu varoille eron sattuessa — ei muuta. Vahvistat oman omistuksesi; cohab ei tarkista henkilöllisyyttä.",
        de: "Die Vereinbarung erfasst Eigentumsanteile, Beiträge und was mit Vermögenswerten bei Trennung passiert — nichts mehr. Sie bestätigen Ihr eigenes Eigentum; cohab überprüft keine Identität.",
        fr: "L'accord enregistre les quotes-parts de propriété, les contributions et ce qui arrive aux actifs en cas de séparation — rien de plus. Vous confirmez votre propre propriété ; cohab ne vérifie pas l'identité.",
        es: "El acuerdo registra las cuotas de propiedad, las aportaciones y lo que ocurre con los activos en caso de separación — nada más. Confirmas tu propia propiedad; cohab no verifica la identidad.") }

    var onboardingWhatDoYouShare: String { s(
        en: "What do you\nshare?",
        nb: "Hva eier\ndere sammen?",
        sv: "Vad äger\nni gemensamt?",
        da: "Hvad ejer\nI sammen?",
        fi: "Mitä\njaatte?",
        de: "Was teilen\nSie?",
        fr: "Que\npartagez-vous?",
        es: "¿Qué\ncompartís?") }

    var onboardingWhatSub: String { s(
        en: "Add the assets you own together.",
        nb: "Legg til eiendelene dere eier sammen.",
        sv: "Lägg till tillgångarna ni äger tillsammans.",
        da: "Tilføj de aktiver I ejer sammen.",
        fi: "Lisää varat, jotka omistatte yhdessä.",
        de: "Fügen Sie die Vermögenswerte hinzu, die Sie gemeinsam besitzen.",
        fr: "Ajoutez les actifs que vous possédez ensemble.",
        es: "Añade los activos que poseen juntos.") }

    var onboardingAllSet: String { s(
        en: "You're all set.",
        nb: "Dere er klare.",
        sv: "Ni är redo.",
        da: "I er klar.",
        fi: "Kaikki on valmista.",
        de: "Alles ist bereit.",
        fr: "Vous êtes prêts.",
        es: "Todo está listo.") }

    var onboardingDisclaimerAck: String { s(
        en: "I understand — cohab provides tools, not legal advice",
        nb: "Jeg forstår — cohab er et verktøy, ikke juridisk rådgivning",
        sv: "Jag förstår — cohab är ett verktyg, inte juridisk rådgivning",
        da: "Jeg forstår — cohab er et værktøj, ikke juridisk rådgivning",
        fi: "Ymmärrän — cohab on työkalu, ei oikeudellinen neuvonta",
        de: "Ich verstehe — cohab ist ein Werkzeug, keine Rechtsberatung",
        fr: "Je comprends — cohab est un outil, pas un conseil juridique",
        es: "Entiendo — cohab es una herramienta, no asesoramiento legal") }
    // MARK: Onboarding — ready screen

    var onboardingReadyTitle: String { s(
        en: "Everything you build\ntogether, protected.",
        nb: "Alt dere bygger\nsammen, trygt.",
        sv: "Allt ni bygger\ntillsammans, skyddat.",
        da: "Alt I bygger\nsammen, beskyttet.",
        fi: "Kaikki mitä rakennatte\nyhdessä, suojattuna.",
        de: "Alles, was ihr gemeinsam\naufbaut, geschützt.",
        fr: "Tout ce que vous\nconstruisez ensemble, protégé.",
        es: "Todo lo que construís\njuntos, protegido.") }

    var onboardingFeatureTrack: String { s(
        en: "Track contributions & ownership",
        nb: "Spor bidrag og eierskap",
        sv: "Spåra bidrag och ägarandel",
        da: "Spor bidrag og ejerskab",
        fi: "Seuraa panoksia ja omistusta",
        de: "Beiträge & Eigentum verfolgen",
        fr: "Suivre apports & propriété",
        es: "Registra aportaciones y propiedad") }

    var onboardingFeatureAgreement: String { s(
        en: "Cohabitation agreement ready when you need it",
        nb: "Samboerkontrakt klar når dere trenger den",
        sv: "Samboavtal klart när ni behöver det",
        da: "Samlivskontrakt klar når I har brug for den",
        fi: "Avoliittosopimus valmiina tarvittaessa",
        de: "Partnerschaftsvertrag bereit, wenn ihr ihn braucht",
        fr: "Convention de vie commune prête quand vous en avez besoin",
        es: "Acuerdo de convivencia listo cuando lo necesitéis") }

    // MARK: Onboarding — country step

    var onboardingCountryTitle: String { s(
        en: "Where do you\nlive?",
        nb: "Hvor bor dere?",
        sv: "Var bor ni?",
        da: "Hvor bor I?",
        fi: "Missä asutte?",
        de: "Wo wohnen Sie?",
        fr: "Où vivez-vous?",
        es: "¿Dónde vivís?") }

    var onboardingCountrySub: String { s(
        en: "Laws around cohabitation vary by country.",
        nb: "Lovgivning om samboerforhold varierer etter land.",
        sv: "Lagar kring samboförhållanden varierar mellan länder.",
        da: "Lovgivning om samlivsforhold varierer fra land til land.",
        fi: "Avoliittoa koskevat lait vaihtelevat maittain.",
        de: "Die Gesetze zum Zusammenleben variieren je nach Land.",
        fr: "Les lois sur la cohabitation varient selon les pays.",
        es: "Las leyes sobre convivencia varían según el país.") }

    // MARK: Onboarding — partners step placeholders

    var onboardingYourNamePlaceholder: String { s(
        en: "Enter your full name",
        nb: "Skriv inn fullt navn",
        sv: "Ange ditt fullständiga namn",
        da: "Skriv dit fulde navn",
        fi: "Kirjoita koko nimesi",
        de: "Vollständigen Namen eingeben",
        fr: "Entrez votre nom complet",
        es: "Introduce tu nombre completo") }

    var onboardingPartnerNamePlaceholder: String { s(
        en: "Enter full name",
        nb: "Skriv inn fullt navn",
        sv: "Ange fullständigt namn",
        da: "Skriv fulde navn",
        fi: "Kirjoita koko nimi",
        de: "Vollständigen Namen eingeben",
        fr: "Entrez le nom complet",
        es: "Introduce el nombre completo") }

    var onboardingEmailPlaceholder: String { s(
        en: "For signing the agreement",
        nb: "For signering av avtale",
        sv: "För att signera avtalet",
        da: "Til underskrivning af aftalen",
        fi: "Sopimuksen allekirjoittamista varten",
        de: "Zum Unterzeichnen der Vereinbarung",
        fr: "Pour signer l'accord",
        es: "Para firmar el acuerdo") }

    // MARK: Onboarding — asset step

    var onboardingAssetsHint: String { s(
        en: "You can add and edit assets at any time.",
        nb: "Du kan legge til og endre eiendeler når som helst.",
        sv: "Du kan lägga till och redigera tillgångar när som helst.",
        da: "Du kan tilføje og redigere aktiver til enhver tid.",
        fi: "Voit lisätä ja muokata varoja milloin tahansa.",
        de: "Sie können Vermögenswerte jederzeit hinzufügen und bearbeiten.",
        fr: "Vous pouvez ajouter et modifier des actifs à tout moment.",
        es: "Puedes añadir y editar activos en cualquier momento.") }

    // MARK: Onboarding — ready step

    var onboardingReadySubFormal: String { s(
        en: "Your agreement can be generated and signed from the Agreement tab.",
        nb: "Avtalen kan genereres og signeres fra Avtale-fanen.",
        sv: "Ditt avtal kan genereras och signeras från fliken Avtal.",
        da: "Din aftale kan genereres og underskrives fra Aftale-fanen.",
        fi: "Sopimuksesi voidaan luoda ja allekirjoittaa Sopimus-välilehdeltä.",
        de: "Ihre Vereinbarung kann über den Vereinbarungen-Tab erstellt und unterzeichnet werden.",
        fr: "Votre accord peut être généré et signé depuis l'onglet Accord.",
        es: "Tu acuerdo puede generarse y firmarse desde la pestaña Acuerdo.") }

    var onboardingReadySubMemory: String { s(
        en: "Start adding assets to track your ownership and contributions.",
        nb: "Legg til eiendeler for å spore eierskap og bidrag.",
        sv: "Börja lägga till tillgångar för att följa ägarskap och bidrag.",
        da: "Begynd at tilføje aktiver for at registrere ejerskab og bidrag.",
        fi: "Aloita varojen lisääminen seurataksesi omistusta ja panoksia.",
        de: "Beginnen Sie mit dem Hinzufügen von Vermögenswerten, um Eigentum und Beiträge zu verfolgen.",
        fr: "Commencez à ajouter des actifs pour suivre votre propriété et vos contributions.",
        es: "Empieza a añadir activos para hacer un seguimiento de tu propiedad y contribuciones.") }

    // MARK: Onboarding — summary card

    var onboardingSummaryFormal: String { s(
        en: "Formal agreement — legally binding",
        nb: "Formell avtale — juridisk bindende",
        sv: "Formellt avtal — juridiskt bindande",
        da: "Formel aftale — juridisk bindende",
        fi: "Virallinen sopimus — oikeudellisesti sitova",
        de: "Formeller Vertrag — rechtlich bindend",
        fr: "Accord formel — juridiquement contraignant",
        es: "Acuerdo formal — jurídicamente vinculante") }

    var onboardingSummaryMemory: String { s(
        en: "Track only — no formal agreement",
        nb: "Kun sporing — ingen formell avtale",
        sv: "Endast spårning — avtalar inte bort Sambolagen",
        da: "Kun registrering — ingen formel aftale",
        fi: "Vain seuranta — ei virallista sopimusta",
        de: "Nur verfolgen — kein formeller Vertrag",
        fr: "Suivi uniquement — pas d'accord formel",
        es: "Solo seguimiento — sin acuerdo formal") }

    // MARK: Onboarding — sign-in

    var onboardingGoogleSignInSync: String { s(
        en: "Sign in to sync with partner",
        nb: "Logg inn for å synkronisere",
        sv: "Logga in för att synka med partner",
        da: "Log ind for at synkronisere med partner",
        fi: "Kirjaudu sisään synkataksesi kumppanin kanssa",
        de: "Anmelden, um mit Partner zu synchronisieren",
        fr: "Se connecter pour synchroniser avec votre partenaire",
        es: "Iniciar sesión para sincronizar con tu pareja") }

    var onboardingSignInSyncNote: String { s(
        en: "Sign in to sync your household with your partner. You can also do this later.",
        nb: "Logg inn for å synkronisere husholdningen med partneren din. Du kan også gjøre dette senere.",
        sv: "Logga in för att synka ditt hushåll med din partner. Du kan också göra det senare.",
        da: "Log ind for at synkronisere din husstand med din partner. Du kan også gøre dette senere.",
        fi: "Kirjaudu sisään synkataksesi talouteesi kumppanisi kanssa. Voit myös tehdä tämän myöhemmin.",
        de: "Melden Sie sich an, um Ihren Haushalt mit Ihrem Partner zu synchronisieren. Sie können dies auch später tun.",
        fr: "Connectez-vous pour synchroniser votre foyer avec votre partenaire. Vous pouvez également le faire plus tard.",
        es: "Inicia sesión para sincronizar tu hogar con tu pareja. También puedes hacerlo más tarde.") }

    // MARK: Onboarding — welcome step

    var onboardingContinueWithGoogle: String { s(
        en: "Continue with Google",
        nb: "Fortsett med Google",
        sv: "Fortsätt med Google",
        da: "Fortsæt med Google",
        fi: "Jatka Googlella",
        de: "Mit Google fortfahren",
        fr: "Continuer avec Google",
        es: "Continuar con Google") }

    // MARK: Disclaimer sheet buttons

    var disclaimerIUnderstand: String { s(
        en: "I understand",
        nb: "Jeg forstår",
        sv: "Jag förstår",
        da: "Jeg forstår",
        fi: "Ymmärrän",
        de: "Ich verstehe",
        fr: "Je comprends",
        es: "Entiendo") }

    var disclaimerClose: String { s(
        en: "Close",
        nb: "Lukk",
        sv: "Stäng",
        da: "Luk",
        fi: "Sulje",
        de: "Schließen",
        fr: "Fermer",
        es: "Cerrar") }

    // MARK: Navigation tabs

    var tabHome: String       { s(en: "Overview",    nb: "Oversikt",      sv: "Översikt",      da: "Oversigt",      fi: "Yhteenveto",    de: "Übersicht",     fr: "Aperçu",         es: "Resumen") }
    var tabAssets: String     { s(en: "Assets",      nb: "Eiendeler",     sv: "Tillgångar",    da: "Aktiver",       fi: "Varat",         de: "Vermögenswerte", fr: "Actifs",        es: "Activos") }
    var tabAgreement: String  { s(en: "Agreement",   nb: "Avtale",        sv: "Avtal",         da: "Aftale",        fi: "Sopimus",       de: "Vertrag",        fr: "Convention",    es: "Contrato") }
    var tabCalculators: String { s(en: "Calculators", nb: "Kalkulatorer", sv: "Kalkylatorer",  da: "Kalkulatorer",  fi: "Laskin",        de: "Rechner",        fr: "Calculateurs",  es: "Calculadoras") }

    // MARK: Dashboard

    var dashboardAssets: String       { s(en: "Assets",    nb: "Eiendeler",  sv: "Tillgångar",  da: "Aktiver",     fi: "Varat",       de: "Vermögenswerte", fr: "Actifs",       es: "Activos") }
    var dashboardNetEquity: String    { s(en: "Net equity", nb: "Netto egenkapital", sv: "Nettoeget kapital", da: "Netto egenkapital", fi: "Netto oma pääoma", de: "Nettoeigenkapital", fr: "Fonds propres nets", es: "Patrimonio neto") }
    var dashboardContribFirst: String { s(en: "Contributions returned first, surplus split by ownership",
                                           nb: "Bidrag utbetales først, deretter fordeles overskuddet etter eierandel",
                                           sv: "Bidrag återbetalas först, sedan delas överskottet efter ägarandel",
                                           da: "Bidrag tilbagebetales først, derefter fordeles overskuddet efter ejerandel",
                                           fi: "Panokset palautetaan ensin, ylijäämä jaetaan omistusosuuden mukaan",
                                           de: "Einlagen werden zuerst zurückerstattet, Überschuss nach Eigentumsanteil",
                                           fr: "Apports restitués en premier, excédent réparti selon les quotes-parts",
                                           es: "Aportaciones devueltas primero, excedente distribuido por cuota") }
    var dashboardAddAsset: String     { s(en: "Add asset",  nb: "Legg til eiendel", sv: "Lägg till tillgång", da: "Tilføj aktiv", fi: "Lisää varallisuus", de: "Vermögenswert hinzufügen", fr: "Ajouter un actif", es: "Agregar activo") }
    var dashboardSetupTitle: String   { s(en: "Set up your household", nb: "Sett opp husholdningen", sv: "Konfigurera ditt hushåll", da: "Konfigurer din husstand", fi: "Määritä kotitalous", de: "Haushalt einrichten", fr: "Configurer votre foyer", es: "Configura tu hogar") }
    var dashboardSetupSub: String     { s(en: "Track shared assets, contributions, and get a fair settlement whenever you need it.",
                                           nb: "Registrer felles eiendeler og bidrag, og få et rettferdig oppgjør når dere trenger det.",
                                           sv: "Registrera gemensamma tillgångar och bidrag och få en rättvis uppgörelse vid behov.",
                                           da: "Registrer fælles aktiver og bidrag og få en retfærdig opgørelse når I har brug for det.",
                                           fi: "Seuraa yhteistä omaisuutta ja panoksia sekä saa oikeudenmukainen jako tarvittaessa.",
                                           de: "Verfolgen Sie gemeinsame Vermögenswerte und Einlagen und erhalten Sie bei Bedarf eine faire Aufteilung.",
                                           fr: "Suivez vos actifs communs et contributions, et obtenez un partage équitable quand vous en avez besoin.",
                                           es: "Registra los activos compartidos y obtén una distribución justa cuando la necesitéis.") }
    var dashboardNoAssets: String     { s(en: "No assets yet", nb: "Ingen eiendeler ennå", sv: "Inga tillgångar ännu", da: "Ingen aktiver endnu", fi: "Ei varoja vielä", de: "Noch keine Vermögenswerte", fr: "Aucun actif pour l'instant", es: "Aún no hay activos") }
    var dashboardNoAssetsSub: String  { s(en: "Add your home, car, or any shared asset to track contributions and see a fair settlement breakdown.",
                                           nb: "Legg til bolig, bil eller andre felles eiendeler for å registrere bidrag og se en rettferdig oppgjørsberegning.",
                                           sv: "Lägg till din bostad, bil eller andra gemensamma tillgångar för att spåra bidrag och se en rättvis fördelning.",
                                           da: "Tilføj din bolig, bil eller andre fælles aktiver for at registrere bidrag og se en retfærdig opgørelse.",
                                           fi: "Lisää koti, auto tai muu yhteinen varallisuus seurataksesi panoksia.",
                                           de: "Fügen Sie Ihr Zuhause, Auto oder andere gemeinsame Vermögenswerte hinzu.",
                                           fr: "Ajoutez votre logement, voiture ou tout actif commun pour suivre vos contributions.",
                                           es: "Añade tu vivienda, coche o cualquier activo compartido para registrar las aportaciones.") }
    var dashboardItems: String        { s(en: "items",  nb: "elementer", sv: "poster",    da: "elementer", fi: "kohdetta",  de: "Elemente",  fr: "éléments",  es: "elementos") }
    var dashboardItem: String         { s(en: "item",   nb: "element",   sv: "post",      da: "element",   fi: "kohde",     de: "Element",   fr: "élément",   es: "elemento") }
    var dashboardLoan: String         { s(en: "Loan",   nb: "Lån",       sv: "Lån",       da: "Lån",       fi: "Laina",     de: "Darlehen",  fr: "Prêt",      es: "Préstamo") }
    var dashboardEdit: String         { s(en: "Edit",   nb: "Rediger",   sv: "Redigera",  da: "Rediger",   fi: "Muokkaa",   de: "Bearbeiten", fr: "Modifier", es: "Editar") }
    var dashboardAgreementSigned: String { s(en: "Agreement signed ✓", nb: "Avtale signert ✓", sv: "Avtal undertecknat ✓", da: "Aftale underskrevet ✓", fi: "Sopimus allekirjoitettu ✓", de: "Vertrag unterzeichnet ✓", fr: "Convention signée ✓", es: "Contrato firmado ✓") }
    var dashboardWaitingSignatures: String { s(en: "Waiting for signatures…", nb: "Venter på signaturer…", sv: "Väntar på underskrifter…", da: "Afventer underskrifter…", fi: "Odotetaan allekirjoituksia…", de: "Warten auf Unterschriften…", fr: "En attente de signatures…", es: "Esperando firmas…") }
    var dashboardShowCalculation: String { s(en: "Settlement estimate", nb: "Oppgjørsestimat", sv: "Uppgörelsekalkyl", da: "Opgørelsesestimat", fi: "Selvitysarvio", de: "Aufteilungsschätzung", fr: "Estimation du partage", es: "Estimación del reparto") }
    var dashboardHideCalculation: String { s(en: "Hide settlement estimate", nb: "Skjul oppgjørsestimat", sv: "Dölj uppgörelsekalkyl", da: "Skjul opgørelsesestimat", fi: "Piilota selvitysarvio", de: "Schätzung ausblenden", fr: "Masquer l'estimation", es: "Ocultar estimación") }
    var dashboardSaleCostsSub: String { s(en: "Incl. sale costs & contribution returns", nb: "Inkl. salgskostnader og bidragstilbakebetaling", sv: "Inkl. försäljningskostnader och bidragsåterbetalning", da: "Inkl. salgsomkostninger og bidragstilbagebetaling", fi: "Sis. myyntikulut ja panosten palautus", de: "Inkl. Verkaufskosten und Einlagenrückzahlung", fr: "Incl. frais de vente et remboursement des apports", es: "Incl. costes de venta y devolución de aportaciones") }
    var dashboardLogFirstContrib: String { s(
        en: "Log your first contribution",
        nb: "Logg ditt første bidrag",
        sv: "Logga ditt första bidrag",
        da: "Log dit første bidrag",
        fi: "Kirjaa ensimmäinen panoksesi",
        de: "Erste Einlage erfassen",
        fr: "Enregistrer votre premier apport",
        es: "Registra tu primera aportación") }
    var dashboardLogFirstContribSub: String { s(
        en: "Deposits, renovations, extra mortgage payments — track who has put in what.",
        nb: "Innskudd, oppussing, ekstra nedbetalinger — registrer hvem som har bidratt med hva.",
        sv: "Insättningar, renoveringar, extra amorteringar — spåra vem som bidragit med vad.",
        da: "Indskud, renoveringer, ekstra afdrag — registrer hvem der har bidraget med hvad.",
        fi: "Talletukset, remontit, ylimääräiset lyhennykset — seuraa kuka on maksanut mitä.",
        de: "Einlagen, Renovierungen, Tilgungen — verfolgen, wer was gezahlt hat.",
        fr: "Dépôts, rénovations, remboursements — suivez qui a mis quoi.",
        es: "Depósitos, reformas, amortizaciones — registra quién ha aportado qué.") }
    var dashboardMakeOfficial: String { s(
        en: "Ready to make it official?",
        nb: "Klar til å gjøre det offisielt?",
        sv: "Redo att göra det officiellt?",
        da: "Klar til at gøre det officielt?",
        fi: "Valmis tekemään sen viralliseksi?",
        de: "Bereit, es offiziell zu machen?",
        fr: "Prêt à officialiser?",
        es: "¿Listo para hacerlo oficial?") }
    var dashboardMakeOfficialSub: String { s(
        en: "Generate and sign a shared ownership agreement from the Agreement tab.",
        nb: "Generer og signer en felles eiersskapsavtale fra Avtale-fanen.",
        sv: "Generera och signera ett gemensamt ägaravtal från Avtal-fliken.",
        da: "Generér og underskriv en fælles ejeraftale fra Aftale-fanen.",
        fi: "Luo ja allekirjoita yhteinen omistussopimus Sopimus-välilehdeltä.",
        de: "Erstellen und unterzeichnen Sie eine gemeinsame Eigentumsvereinbarung in der Registerkarte Vertrag.",
        fr: "Générez et signez un accord commun dans l'onglet Convention.",
        es: "Genera y firma un acuerdo conjunto en la pestaña Contrato.") }
    var calculatorsFreeToUse: String { s(
        en: "Free to use",
        nb: "Gratis å bruke",
        sv: "Gratis att använda",
        da: "Gratis at bruge",
        fi: "Ilmainen käyttää",
        de: "Kostenlos nutzbar",
        fr: "Gratuit",
        es: "Gratis") }
    var editAssetTitle: String { s(en: "Edit asset", nb: "Rediger eiendel", sv: "Redigera tillgång", da: "Rediger aktiv", fi: "Muokkaa varallisuutta", de: "Vermögenswert bearbeiten", fr: "Modifier l'actif", es: "Editar activo") }
    var addAssetNavTitle: String { s(en: "Add asset", nb: "Legg til eiendel", sv: "Lägg till tillgång", da: "Tilføj aktiv", fi: "Lisää varallisuus", de: "Vermögenswert hinzufügen", fr: "Ajouter un actif", es: "Agregar activo") }
    var addContribTitle: String { s(en: "Add contribution", nb: "Legg til bidrag", sv: "Lägg till bidrag", da: "Tilføj bidrag", fi: "Lisää maksu", de: "Beitrag hinzufügen", fr: "Ajouter une contribution", es: "Agregar aportación") }
    var noContribsYet: String { s(en: "No contributions yet", nb: "Ingen bidrag ennå", sv: "Inga bidrag ännu", da: "Ingen bidrag endnu", fi: "Ei maksuja vielä", de: "Noch keine Beiträge", fr: "Aucune contribution encore", es: "Sin aportaciones aún") }
    var deleteAsset: String { s(en: "Delete asset", nb: "Slett eiendel", sv: "Ta bort tillgång", da: "Slet aktiv", fi: "Poista varallisuus", de: "Vermögenswert löschen", fr: "Supprimer l'actif", es: "Eliminar activo") }
    var fieldName: String   { s(en: "Name",     nb: "Navn",      sv: "Namn",    da: "Navn",    fi: "Nimi",        de: "Name",     fr: "Nom",       es: "Nombre") }
    var optional: String   { s(en: "optional", nb: "valgfritt", sv: "valfritt", da: "valgfrit", fi: "valinnainen", de: "optional", fr: "optionnel", es: "opcional") }
    var cancel: String { s(en: "Cancel", nb: "Avbryt", sv: "Avbryt", da: "Annuller", fi: "Peruuta", de: "Abbrechen", fr: "Annuler", es: "Cancelar") }
    var save: String { s(en: "Save", nb: "Lagre", sv: "Spara", da: "Gem", fi: "Tallenna", de: "Speichern", fr: "Enregistrer", es: "Guardar") }
    var add: String { s(en: "Add", nb: "Legg til", sv: "Lägg till", da: "Tilføj", fi: "Lisää", de: "Hinzufügen", fr: "Ajouter", es: "Agregar") }
    var continueButton: String { s(en: "Continue", nb: "Fortsett", sv: "Fortsätt", da: "Fortsæt", fi: "Jatka", de: "Weiter", fr: "Continuer", es: "Continuar") }
    var stepWhatType: String   { s(en: "What type of asset?", nb: "Hva slags eiendel?", sv: "Vilken typ av tillgång?", da: "Hvilken type aktiv?", fi: "Minkä tyyppinen varallisuus?", de: "Welche Art von Vermögenswert?", fr: "Quel type d'actif?", es: "¿Qué tipo de activo?") }
    var stepNameIt: String     { s(en: "Name it", nb: "Gi den et navn", sv: "Namnge den", da: "Navngiv det", fi: "Anna nimi", de: "Benennen", fr: "Nommer", es: "Nombrar") }
    var stepWhatWorth: String  { s(en: "What's it worth?", nb: "Hva er den verdt?", sv: "Vad är den värd?", da: "Hvad er den værd?", fi: "Mikä on arvo?", de: "Was ist es wert?", fr: "Quelle est sa valeur?", es: "¿Cuánto vale?") }
    var stepWhoOwns: String    { s(en: "Who owns what?", nb: "Hvem eier hva?", sv: "Vem äger vad?", da: "Hvem ejer hvad?", fi: "Kuka omistaa?", de: "Wer besitzt was?", fr: "Qui possède quoi?", es: "¿Quién posee qué?") }
    var stepNameSub: String    { s(en: "Give your asset a name", nb: "Gi eiendelen et navn", sv: "Ge tillgången ett namn", da: "Giv aktivet et navn", fi: "Anna varallisuudelle nimi", de: "Benennen Sie Ihren Vermögenswert", fr: "Donnez un nom à votre actif", es: "Ponle nombre a tu activo") }
    var stepContribs: String   { s(en: "Who paid what?", nb: "Hvem betalte hva?", sv: "Vem betalade vad?", da: "Hvem betalte hvad?", fi: "Kuka maksoi?", de: "Wer hat was bezahlt?", fr: "Qui a payé quoi?", es: "¿Quién pagó qué?") }
    var stepContribsSub: String { s(
        en: "Log initial contributions now for accurate equity tracking. You can skip and add them later.",
        nb: "Registrer innskudd nå for nøyaktig egenkapitalsporing. Du kan hoppe over og legge til senere.",
        sv: "Registrera bidrag nu för exakt kapitalspårning. Du kan hoppa över och lägga till senare.",
        da: "Registrer bidrag nu for præcis egenkapitalsporing. Du kan springe over og tilføje dem senere.",
        fi: "Kirjaa alkumaksut nyt tarkkaa pääoman seurantaa varten. Voit ohittaa ja lisätä ne myöhemmin.",
        de: "Erfassen Sie die anfänglichen Beiträge jetzt für genaues Eigenkapital-Tracking. Sie können es überspringen und später hinzufügen.",
        fr: "Enregistrez les contributions initiales maintenant pour un suivi précis. Vous pouvez ignorer et ajouter plus tard.",
        es: "Registra las aportaciones iniciales ahora para un seguimiento preciso. Puedes omitirlo y añadir más tarde.") }
    var stepSkipContribs: String { s(en: "Skip — add later", nb: "Hopp over — legg til senere", sv: "Hoppa över — lägg till senare", da: "Spring over — tilføj senere", fi: "Ohita — lisää myöhemmin", de: "Überspringen — später hinzufügen", fr: "Ignorer — ajouter plus tard", es: "Omitir — agregar más tarde") }
    var stepPurchaseDate: String { s(en: "Purchase / start date", nb: "Kjøps- / startdato", sv: "Köp- / startdatum", da: "Købs- / startdato", fi: "Osto- / aloituspäivä", de: "Kauf- / Startdatum", fr: "Date d'achat / de début", es: "Fecha de compra / inicio") }
    var completeSetup: String   { s(en: "Complete setup",      nb: "Fyll inn detaljer",     sv: "Fyll i uppgifter",      da: "Udfyld oplysninger",    fi: "Täytä tiedot",          de: "Details ausfüllen",     fr: "Compléter la fiche",   es: "Completar datos") }
    var viewAllArrow: String    { s(en: "View all →",          nb: "Se alle →",             sv: "Visa alla →",           da: "Se alle →",             fi: "Näytä kaikki →",        de: "Alle anzeigen →",       fr: "Tout voir →",          es: "Ver todo →") }
    var noItemsYet: String      { s(en: "No items yet",        nb: "Ingen gjenstander ennå", sv: "Inga föremål ännu",   da: "Ingen genstande endnu", fi: "Ei esineitä vielä",     de: "Noch keine Gegenstände", fr: "Aucun article encore", es: "Sin artículos aún") }
    var furnItemSingular: String { s(en: "item",               nb: "gjenstand",             sv: "föremål",               da: "genstand",              fi: "esine",                 de: "Gegenstand",            fr: "objet",                es: "artículo") }
    var furnItemPlural: String  { s(en: "items",               nb: "gjenstander",           sv: "föremål",               da: "genstande",             fi: "esinettä",              de: "Gegenstände",           fr: "objets",               es: "artículos") }
    var monthlyExpenses: String { s(en: "Monthly expenses",    nb: "Månedlige utgifter",    sv: "Månatliga utgifter",    da: "Månedlige udgifter",    fi: "Kuukausittaiset kulut", de: "Monatliche Ausgaben",   fr: "Dépenses mensuelles",  es: "Gastos mensuales") }
    var perMonthSuffix: String  { s(en: "/mo",                 nb: "/mnd",                  sv: "/mån",                  da: "/mdr",                  fi: "/kk",                   de: "/Mon.",                 fr: "/mois",                es: "/mes") }
    var totalCombinedEquity: String { s(en: "Total combined equity", nb: "Samlet egenkapital", sv: "Total eget kapital", da: "Samlet egenkapital",   fi: "Yhteinen oma pääoma",   de: "Gesamteigenkapital",    fr: "Capitaux propres totaux", es: "Patrimonio total") }
    var noSaleCosts: String     { s(en: "No sale costs",       nb: "Ingen salgskostnader",  sv: "Utan försäljningskostnader", da: "Uden salgsomkostninger", fi: "Ilman myyntikuluja",  de: "Ohne Verkaufskosten",   fr: "Sans frais de vente",  es: "Sin costes de venta") }
    var asOf: String            { s(en: "As of",               nb: "Per dato",              sv: "Per datum",             da: "Per dato",              fi: "Tähän päivään",         de: "Stand",                 fr: "En date du",           es: "A fecha de") }
    var perAsset: String        { s(en: "PER ASSET",           nb: "PER EIENDEL",           sv: "PER TILLGÅNG",          da: "PER AKTIV",             fi: "PER VARALLISUUS",       de: "PRO VERMÖGENSWERT",     fr: "PAR ACTIF",            es: "POR ACTIVO") }
    var inviteTitle: String     { s(en: "Invite",              nb: "Inviter",               sv: "Bjud in",               da: "Inviter",               fi: "Kutsu",                 de: "Einladen",              fr: "Inviter",              es: "Invitar") }
    var inviteExplain: String   { s(en: "Share this link. They open it on their iPhone, download cohab, and your household will sync automatically.", nb: "Del denne lenken. De åpner den på sin iPhone, laster ned cohab, og husholdningen synkroniseres automatisk.", sv: "Dela den här länken. De öppnar den på sin iPhone, laddar ner cohab och hushållet synkroniseras automatiskt.", da: "Del dette link. De åbner det på deres iPhone, downloader cohab, og husstanden synkroniseres automatisk.", fi: "Jaa tämä linkki. He avaavat sen iPhonellaan, lataavat cohabin ja talouhenne synkronoidaan automaattisesti.", de: "Teilen Sie diesen Link. Sie öffnen ihn auf ihrem iPhone, laden cohab herunter, und Ihr Haushalt wird automatisch synchronisiert.", fr: "Partagez ce lien. Ils l'ouvrent sur leur iPhone, téléchargent cohab et votre foyer se synchronise automatiquement.", es: "Comparte este enlace. Lo abren en su iPhone, descargan cohab y vuestro hogar se sincroniza automáticamente.") }
    var inviteGenerate: String  { s(en: "Generate invite link", nb: "Generer invitasjonslenke", sv: "Generera inbjudningslänk", da: "Generer invitationslink", fi: "Luo kutsulinkin", de: "Einladungslink generieren", fr: "Générer un lien d'invitation", es: "Generar enlace de invitación") }
    var inviteGenerating: String { s(en: "Generating…",        nb: "Genererer…",            sv: "Genererar…",            da: "Genererer…",            fi: "Luodaan…",              de: "Wird generiert…",       fr: "Génération…",          es: "Generando…") }
    var inviteShare: String     { s(en: "Share invite link",   nb: "Del invitasjonslenke",  sv: "Dela inbjudningslänk",  da: "Del invitationslink",   fi: "Jaa kutsulinkki",       de: "Einladungslink teilen", fr: "Partager le lien",     es: "Compartir enlace") }
    var inviteManual: String    { s(en: "Or share the code manually", nb: "Eller del koden manuelt", sv: "Eller dela koden manuellt", da: "Eller del koden manuelt", fi: "Tai jaa koodi manuaalisesti", de: "Oder Code manuell teilen", fr: "Ou partager le code manuellement", es: "O compartir el código manualmente") }
    var inviteNewLink: String   { s(en: "Generate a new link", nb: "Generer ny lenke",      sv: "Generera ny länk",      da: "Generer nyt link",      fi: "Luo uusi linkki",       de: "Neuen Link generieren", fr: "Générer un nouveau lien", es: "Generar nuevo enlace") }
    var inviteExpiry: String    { s(en: "Link expires in 7 days. A new link can be generated at any time.", nb: "Lenken utløper om 7 dager. En ny lenke kan genereres når som helst.", sv: "Länken upphör om 7 dagar. En ny länk kan genereras när som helst.", da: "Linket udløber om 7 dage. Et nyt link kan genereres til enhver tid.", fi: "Linkki vanhenee 7 päivässä. Uuden linkin voi luoda milloin tahansa.", de: "Der Link läuft in 7 Tagen ab. Ein neuer Link kann jederzeit generiert werden.", fr: "Le lien expire dans 7 jours. Un nouveau lien peut être généré à tout moment.", es: "El enlace caduca en 7 días. Se puede generar un nuevo enlace en cualquier momento.") }
    var done: String            { s(en: "Done",                nb: "Ferdig",                sv: "Klar",                  da: "Færdig",                fi: "Valmis",                de: "Fertig",                fr: "Terminé",              es: "Listo") }

    // MARK: Edit asset
    var sectionType: String          { s(en: "TYPE",               nb: "TYPE",                sv: "TYP",              da: "TYPE",            fi: "TYYPPI",              de: "TYP",                fr: "TYPE",                 es: "TIPO") }
    var sectionDetails: String       { s(en: "DETAILS",            nb: "DETALJER",            sv: "DETALJER",         da: "DETALJER",        fi: "TIEDOT",              de: "DETAILS",            fr: "DÉTAILS",              es: "DETALLES") }
    var sectionValue: String         { s(en: "VALUE",              nb: "VERDI",               sv: "VÄRDE",            da: "VÆRDI",           fi: "ARVO",                de: "WERT",               fr: "VALEUR",               es: "VALOR") }
    var sectionValueLoan: String     { s(en: "VALUE & LOAN",       nb: "VERDI OG LÅN",        sv: "VÄRDE OCH LÅN",   da: "VÆRDI OG LÅN",   fi: "ARVO JA LAINA",       de: "WERT & DARLEHEN",    fr: "VALEUR & PRÊT",        es: "VALOR Y PRÉSTAMO") }
    var sectionContribs: String      { s(en: "EQUITY CONTRIBUTIONS", nb: "EGENKAPITALBIDRAG", sv: "EGET KAPITAL",    da: "EGENKAPITALBIDRAG", fi: "PÄÄOMAMAKSUT",      de: "EIGENKAPITALBEITRÄGE", fr: "APPORTS EN CAPITAL", es: "APORTACIONES DE CAPITAL") }
    var addContribButton: String     { s(en: "Add contribution",   nb: "Legg til bidrag",      sv: "Lägg till bidrag", da: "Tilføj bidrag",  fi: "Lisää maksu",         de: "Beitrag hinzufügen", fr: "Ajouter une contribution", es: "Agregar aportación") }
    // MARK: Agreement — advanced clauses
    var agreementAdvancedTitle: String    { s(en: "Optional advanced clauses", nb: "Valgfrie tilleggsklausuler",    sv: "Valfria tilläggsklausuler",     da: "Valgfrie tillægsklausuler",   fi: "Valinnaiset lisälausekkeet",   de: "Optionale Zusatzklauseln",     fr: "Clauses complémentaires",     es: "Cláusulas adicionales opcionales") }
    var agreementAdvancedSub: String      { s(en: "Adds extra legal protection",   nb: "Legger til ekstra juridisk beskyttelse", sv: "Lägger till extra rättsskydd", da: "Tilføjer ekstra retsbeskyttelse", fi: "Lisää oikeudellista suojaa", de: "Bietet zusätzlichen Rechtsschutz", fr: "Renforce la protection juridique", es: "Añade protección jurídica adicional") }
    var agreementClauseSeparate: String   { s(en: "Separate property",            nb: "Særeie og eneeie",            sv: "Enskild egendom",               da: "Særeje",                      fi: "Oma omaisuus",                 de: "Eigenes Vermögen",             fr: "Biens propres",               es: "Bienes privativos") }
    var agreementClauseSeparateSub: String { s(en: "Pre-existing assets remain sole property", nb: "Eiendeler man hadde fra før forblir eget", sv: "Egendom som inte är samboegendom förblir enskild", da: "Forudgående aktiver forbliver egne", fi: "Aiemmat varat pysyvät omana", de: "Frühere Vermögenswerte bleiben persönlich", fr: "Les biens antérieurs restent des biens propres", es: "Los bienes previos mantienen su carácter privativo") }
    var agreementClauseBuyout: String     { s(en: "Buyout rights & 6-month deadline", nb: "Overtakelse ved opphør",  sv: "Inlösenrätt",                   da: "Overtagelsesret",             fi: "Lunastusoikeus",               de: "Vorkaufsrecht",                fr: "Droit de préemption",         es: "Derecho de adquisición preferente") }
    var agreementClauseBuyoutSub: String  { s(en: "Right of first refusal, valuation, timeline", nb: "Fortrinnsrett, takst og frist", sv: "Inlösenrätt, värdering, tidsfrist", da: "Fortrinsstilling, vurdering, frist", fi: "Lunastusoikeus, arvostus, määräaika", de: "Vorkaufsrecht, Bewertung, Frist", fr: "Droit de préemption, évaluation, délai", es: "Derecho preferente, valoración, plazo") }
    var agreementClauseDisposal: String   { s(en: "Joint disposal consent",       nb: "Samtykke ved salg",           sv: "Samtyckeskrav",                 da: "Dispositionssamtykke",        fi: "Luovutussuostumus",            de: "Verfügungszustimmung",         fr: "Consentement aux cessions",   es: "Consentimiento para disposición") }
    var agreementClauseDisposalSub: String { s(en: "Both must consent to selling or mortgaging", nb: "Begge må godkjenne salg eller pantsettelse", sv: "Båda måste godkänna försäljning", da: "Begge skal godkende salg eller pantsætning", fi: "Molempien suostumus myyntiin tai panttaukseen", de: "Beide müssen Verkauf oder Verpfändung zustimmen", fr: "Les deux doivent consentir à toute cession", es: "Ambos deben consentir venta o hipoteca") }
    var agreementClauseDispute: String    { s(en: "Dispute resolution",           nb: "Tvisteløsning",               sv: "Tvistelösning",                 da: "Tvistløsning",                fi: "Riidanratkaisu",               de: "Streitbeilegung",              fr: "Résolution des différends",   es: "Resolución de disputas") }
    var agreementClauseDisputeSub: String { s(en: "Mediation before legal proceedings", nb: "Mekling før rettslige skritt", sv: "Medling före rättsliga åtgärder", da: "Mægling før retssager",     fi: "Sovittelu ennen oikeustoimia", de: "Mediation vor Gerichtsverfahren", fr: "Médiation avant procédures judiciaires", es: "Mediación antes de acciones legales") }
    var agreementClauseDebt: String       { s(en: "Personal debt responsibility",             nb: "Personlig gjeldsansvar",            sv: "Personligt skuldansvar",            da: "Personligt gældsansvar",           fi: "Henkilökohtainen velkavastuu",       de: "Persönliche Schuldenhaftung",        fr: "Responsabilité personnelle des dettes", es: "Responsabilidad personal por deudas") }
    var agreementClauseDebtSub: String    { s(en: "Each party responsible for their own debts", nb: "Hver part ansvarlig for egen gjeld", sv: "Varje part ansvarar för sina skulder", da: "Hver part ansvarlig for sin gæld", fi: "Kumpikin osapuoli vastaa omista veloistaan", de: "Jede Partei haftet für ihre eigenen Schulden", fr: "Chaque partie responsable de ses propres dettes", es: "Cada parte responsable de sus propias deudas") }

    var deleteAssetMessage: String   { s(en: "All contributions linked to this asset will also be deleted.",
                                          nb: "Alle bidrag knyttet til denne eiendelen slettes også.",
                                          sv: "Alla bidrag kopplade till denna tillgång tas också bort.",
                                          da: "Alle bidrag knyttet til dette aktiv slettes også.",
                                          fi: "Kaikki tähän varallisuuteen liittyvät maksut poistetaan myös.",
                                          de: "Alle mit diesem Vermögenswert verknüpften Beiträge werden ebenfalls gelöscht.",
                                          fr: "Toutes les contributions liées à cet actif seront également supprimées.",
                                          es: "Todas las aportaciones vinculadas a este activo también se eliminarán.") }

    // MARK: Asset card / detail

    var assetContribFirst: String   { s(en: "Contributions returned first · surplus split",
                                         nb: "Bidrag utbetales først · overskudd fordeles",
                                         sv: "Bidrag återbetalas först · överskott fördelas",
                                         da: "Bidrag tilbagebetales først · overskud fordeles",
                                         fi: "Maksut palautetaan ensin · ylijäämä jaetaan",
                                         de: "Beiträge zuerst zurück · Überschuss geteilt",
                                         fr: "Contributions remboursées en premier · excédent partagé",
                                         es: "Aportaciones devueltas primero · excedente repartido") }
    var assetDistribution: String   { s(en: "DISTRIBUTION",    nb: "FORDELING",       sv: "FÖRDELNING",     da: "FORDELING",     fi: "JAKO",            de: "VERTEILUNG",     fr: "RÉPARTITION",      es: "DISTRIBUCIÓN") }
    var assetContribInterest: String { s(en: "① Contributions & interest returned", nb: "① Bidrag og renter tilbakebetalt", sv: "① Bidrag och ränta återbetalad", da: "① Bidrag og renter tilbagebetalt", fi: "① Maksut ja korko palautettu", de: "① Beiträge und Zinsen zurückgezahlt", fr: "① Contributions et intérêts remboursés", es: "① Aportaciones e intereses devueltos") }
    var assetRemainingSurplus: String { s(en: "② Remaining surplus", nb: "② Gjenstående overskudd", sv: "② Återstående överskott", da: "② Resterende overskud", fi: "② Jäljellä oleva ylijäämä", de: "② Verbleibender Überschuss", fr: "② Excédent restant", es: "② Excedente restante") }
    var assetTotalPayout: String    { s(en: "TOTAL PAYOUT",    nb: "TOTAL UTBETALING", sv: "TOTAL UTBETALNING", da: "TOTAL UDBETALING", fi: "KOKONAISMAKSU", de: "GESAMTAUSZAHLUNG", fr: "PAIEMENT TOTAL",    es: "PAGO TOTAL") }
    var assetContribInterestLine: String { s(en: "Contributions & interest:", nb: "Bidrag og renter:", sv: "Bidrag och ränta:", da: "Bidrag og renter:", fi: "Maksut ja korko:", de: "Beiträge und Zinsen:", fr: "Contributions et intérêts:", es: "Aportaciones e intereses:") }
    var assetRateLine: String       { s(en: "Rate:", nb: "Rente:", sv: "Ränta:", da: "Rente:", fi: "Korko:", de: "Zinssatz:", fr: "Taux:", es: "Tasa:") }
    var assetPerAgreement: String   { s(en: "Per agreement between parties", nb: "I henhold til avtale mellom partene", sv: "Enligt avtal mellan parterna", da: "I henhold til aftale mellem parterne", fi: "Osapuolten sopimuksen mukaan", de: "Gemäß Vereinbarung zwischen den Parteien", fr: "Selon accord entre les parties", es: "Según acuerdo entre las partes") }
    var assetCurrentValue: String   { s(en: "Current value",   nb: "Gjeldende verdi", sv: "Aktuellt värde",  da: "Aktuel værdi",       fi: "Nykyinen arvo",       de: "Aktueller Wert",     fr: "Valeur actuelle",      es: "Valor actual") }
    var assetNetEquity: String      { s(en: "Net equity",      nb: "Netto egenkapital", sv: "Nettoeget kapital", da: "Netto egenkapital", fi: "Netto oma pääoma",  de: "Nettoeigenkapital",  fr: "Fonds propres nets",   es: "Patrimonio neto") }
    var assetNetProceeds: String    { s(en: "Net proceeds",    nb: "Netto proveny",   sv: "Nettointäkt",     da: "Nettoprovenu",        fi: "Nettotulot",          de: "Nettoerlös",         fr: "Produit net",          es: "Ingresos netos") }
    var assetTotalReturned: String  { s(en: "Total returned",  nb: "Totalt tilbakebetalt", sv: "Totalt återbetalt", da: "Totalt tilbagebetalt", fi: "Yhteensä palautettu", de: "Gesamt zurückgezahlt", fr: "Total remboursé",   es: "Total devuelto") }
    var assetNoContribs: String     { s(en: "No contributions recorded yet.", nb: "Ingen bidrag registrert ennå.", sv: "Inga bidrag registrerade ännu.", da: "Ingen bidrag registreret endnu.", fi: "Ei maksuja kirjattu vielä.", de: "Noch keine Beiträge erfasst.", fr: "Aucune contribution enregistrée.", es: "Sin aportaciones registradas aún.") }
    var assetContribHistory: String { s(en: "Contribution History", nb: "Bidragshistorikk", sv: "Bidragshistorik", da: "Bidragshistorik", fi: "Maksuhistoria", de: "Beitragsverlauf", fr: "Historique des contributions", es: "Historial de aportaciones") }
    var assetAddContrib: String     { s(en: "Add Contribution",  nb: "Legg til bidrag",   sv: "Lägg till bidrag", da: "Tilføj bidrag",   fi: "Lisää maksu",         de: "Beitrag hinzufügen", fr: "Ajouter une contribution", es: "Agregar aportación") }
    var assetRecalculate: String    { s(en: "Recalculate",       nb: "Beregn på nytt",    sv: "Beräkna om",      da: "Genberegn",          fi: "Laske uudelleen",     de: "Neu berechnen",      fr: "Recalculer",           es: "Recalcular") }
    var assetOwnership: String      { s(en: "OWNERSHIP",         nb: "EIERSKAP",          sv: "ÄGARANDEL",       da: "EJERSKAB",           fi: "OMISTUS",             de: "EIGENTUMSANTEIL",    fr: "PROPRIÉTÉ",            es: "PROPIEDAD") }
    var assetInterestEarned: String { s(en: "interest",          nb: "renter",            sv: "ränta",           da: "renter",             fi: "korko",               de: "Zinsen",             fr: "intérêts",             es: "intereses") }

    // MARK: Agreement tab

    var agreementTitle: String    { s(en: "Cohabitation Agreement", nb: "Samboerkontrakt", sv: "Samboavtal",     da: "Samlivskontrakt",  fi: "Avoliittosopimus", de: "Partnerschaftsvertrag", fr: "Convention de vie commune", es: "Contrato de convivencia") }
    var agreementGenerate: String { s(en: "Generate & sign agreement", nb: "Generer og signer avtale", sv: "Generera och signera avtal", da: "Generér og underskriv aftale", fi: "Luo ja allekirjoita sopimus", de: "Vertrag erstellen und unterzeichnen", fr: "Créer et signer la convention", es: "Crear y firmar el contrato") }
    var agreementUpdate: String   { s(en: "Update & resend agreement", nb: "Oppdater og send avtale på nytt", sv: "Uppdatera och skicka om avtal", da: "Opdatér og gensend aftale", fi: "Päivitä ja lähetä sopimus uudelleen", de: "Vereinbarung aktualisieren und neu senden", fr: "Mettre à jour et renvoyer l'accord", es: "Actualizar y reenviar el acuerdo") }
    var agreementSigned: String   { s(en: "Signed by both parties", nb: "Signert av begge parter", sv: "Undertecknat av båda parter", da: "Underskrevet af begge parter", fi: "Molemmat osapuolet allekirjoittaneet", de: "Beide Parteien haben unterzeichnet", fr: "Signé par les deux parties", es: "Firmado por ambas partes") }
    var agreementPending: String  { s(en: "Pending signatures", nb: "Venter på signering", sv: "Väntar på underskrift", da: "Afventer underskrift", fi: "Odottaa allekirjoituksia", de: "Unterschriften ausstehend", fr: "En attente de signatures", es: "Pendiente de firmas") }
    var agreementNotSigned: String { s(en: "Not signed yet", nb: "Ikke signert ennå", sv: "Ej undertecknat", da: "Ikke underskrevet endnu", fi: "Ei vielä allekirjoitettu", de: "Noch nicht unterzeichnet", fr: "Pas encore signé", es: "Aún no firmado") }
    var agreementUpdateNeeded: String { s(en: "Update needed", nb: "Oppdatering nødvendig", sv: "Uppdatering krävs", da: "Opdatering nødvendig", fi: "Päivitys tarvitaan", de: "Aktualisierung erforderlich", fr: "Mise à jour nécessaire", es: "Actualización necesaria") }
    var agreementSentWaiting: String { s(en: "Sent — waiting for signatures", nb: "Sendt — venter på signaturer", sv: "Skickat — väntar på underskrifter", da: "Sendt — afventer underskrifter", fi: "Lähetetty — odotetaan allekirjoituksia", de: "Gesendet — Unterschriften ausstehend", fr: "Envoyé — en attente de signatures", es: "Enviado — esperando firmas") }
    var agreementCheckStatus: String { s(en: "Check signing status", nb: "Sjekk signeringsstatus", sv: "Kontrollera signeringsstatus", da: "Tjek signeringsstatus", fi: "Tarkista allekirjoitusstatus", de: "Unterschriftsstatus prüfen", fr: "Vérifier le statut de signature", es: "Verificar estado de firma") }
    var agreementChecking: String { s(en: "Checking…", nb: "Sjekker…", sv: "Kontrollerar…", da: "Tjekker…", fi: "Tarkistetaan…", de: "Wird geprüft…", fr: "Vérification…", es: "Verificando…") }
    var agreementLinksSentByEmail: String { s(en: "Signing links sent to both parties by email", nb: "Signeringslenker sendt til begge parter på e-post", sv: "Signeringslänkar skickade till båda parter via e-post", da: "Signeringslinks sendt til begge parter via e-mail", fi: "Allekirjoituslinkit lähetetty molemmille osapuolille sähköpostitse", de: "Signierlinks an beide Parteien per E-Mail gesendet", fr: "Liens de signature envoyés aux deux parties par e-mail", es: "Enlaces de firma enviados a ambas partes por correo") }
    var agreementNoAgreement: String { s(en: "No agreement yet", nb: "Ingen avtale ennå", sv: "Inget avtal ännu", da: "Ingen aftale endnu", fi: "Ei sopimusta vielä", de: "Noch keine Vereinbarung", fr: "Pas encore d'accord", es: "Aún no hay acuerdo") }
    var agreementNoAgreementSub: String { s(en: "Generate and sign your cohabitation agreement", nb: "Generer og signer samboerkontrakten", sv: "Generera och underteckna samboavtalet", da: "Generér og underskriv samlivskontrakten", fi: "Luo ja allekirjoita avoliittosopimus", de: "Vereinbarung erstellen und unterzeichnen", fr: "Générez et signez votre accord de vie commune", es: "Genera y firma tu acuerdo de convivencia") }
    var agreementWhatsIn: String  { s(en: "What's in your agreement", nb: "Hva er i avtalen din", sv: "Vad finns i ditt avtal", da: "Hvad er i din aftale", fi: "Mitä sopimuksessasi on", de: "Was ist in Ihrer Vereinbarung", fr: "Ce que contient votre accord", es: "Qué incluye tu acuerdo") }
    var agreementViewDownload: String { s(en: "View & download agreement", nb: "Se og last ned avtale", sv: "Visa och ladda ner avtal", da: "Se og download aftale", fi: "Näytä ja lataa sopimus", de: "Vereinbarung anzeigen und herunterladen", fr: "Voir et télécharger l'accord", es: "Ver y descargar el acuerdo") }
    var agreementViewSigning: String { s(en: "View signing links", nb: "Se signeringslenker", sv: "Visa signeringslänkar", da: "Se signeringslinks", fi: "Näytä allekirjoituslinkit", de: "Signierlinks anzeigen", fr: "Voir les liens de signature", es: "Ver enlaces de firma") }
    var agreementNeedUpdate: String { s(en: "Need to update?", nb: "Trenger du å oppdatere?", sv: "Behöver du uppdatera?", da: "Skal du opdatere?", fi: "Tarvitsetko päivityksen?", de: "Aktualisierung erforderlich?", fr: "Besoin de mettre à jour?", es: "¿Necesitas actualizar?") }
    var agreementNeedUpdateSub: String { s(en: "Generate a new agreement above — both parties will need to sign again.", nb: "Generer en ny avtale ovenfor — begge parter må signere på nytt.", sv: "Generera ett nytt avtal ovan — båda parter måste underteckna igen.", da: "Generér en ny aftale ovenfor — begge parter skal underskrive igen.", fi: "Luo uusi sopimus yllä — molempien osapuolten on allekirjoitettava uudelleen.", de: "Oben eine neue Vereinbarung erstellen — beide Parteien müssen erneut unterzeichnen.", fr: "Générez un nouvel accord ci-dessus — les deux parties devront signer à nouveau.", es: "Genera un nuevo acuerdo arriba — ambas partes deberán firmar de nuevo.") }
    var agreementNoFormal: String { s(en: "No agreement set up", nb: "Ingen avtale satt opp", sv: "Inget avtal konfigurerat", da: "Ingen aftale konfigureret", fi: "Ei sopimusta määritetty", de: "Keine Vereinbarung eingerichtet", fr: "Aucun accord configuré", es: "Sin acuerdo configurado") }
    var agreementNoFormalSub: String { s(en: "You chose to track only. You can upgrade to a formal agreement any time from Settings.", nb: "Du valgte kun sporing. Du kan oppgradere til en formell avtale når som helst fra Innstillinger.", sv: "Du valde att bara spåra. Du kan uppgradera till ett formellt avtal när som helst från Inställningar.", da: "Du valgte kun sporing. Du kan opgradere til en formel aftale til enhver tid fra Indstillinger.", fi: "Valitsit vain seurannan. Voit päivittää viralliseen sopimukseen milloin tahansa Asetuksista.", de: "Sie haben nur die Verfolgung gewählt. Sie können jederzeit über Einstellungen auf eine formelle Vereinbarung upgraden.", fr: "Vous avez choisi le suivi uniquement. Vous pouvez passer à un accord formel à tout moment depuis les Paramètres.", es: "Elegiste solo el seguimiento. Puedes cambiar a un acuerdo formal en cualquier momento desde Configuración.") }
    var agreementEmailsNeeded: String { s(en: "Email addresses needed for signing", nb: "E-postadresser nødvendig for signering", sv: "E-postadresser behövs för signering", da: "E-mailadresser nødvendige for signering", fi: "Sähköpostiosoitteet tarvitaan allekirjoittamiseen", de: "E-Mail-Adressen für die Unterzeichnung erforderlich", fr: "Adresses e-mail nécessaires pour la signature", es: "Se necesitan correos electrónicos para firmar") }
    var agreementEmailsNeededSub: String { s(en: "Both partners need an email to receive their signing link.", nb: "Begge parter trenger e-post for å motta signeringslenken.", sv: "Båda parter behöver en e-postadress för att ta emot sin signeringslänk.", da: "Begge parter skal bruge en e-mail for at modtage deres signeringslink.", fi: "Molemmilla osapuolilla on oltava sähköposti allekirjoituslinkin vastaanottamiseen.", de: "Beide Partner benötigen eine E-Mail, um ihren Signierlink zu erhalten.", fr: "Les deux partenaires ont besoin d'un e-mail pour recevoir leur lien de signature.", es: "Ambos socios necesitan un correo para recibir su enlace de firma.") }
    var agreementAddEmails: String { s(en: "Add signing emails", nb: "Legg til e-postadresser for signering", sv: "Lägg till e-postadresser för signering", da: "Tilføj e-mailadresser til signering", fi: "Lisää allekirjoitussähköpostit", de: "Signing-E-Mails hinzufügen", fr: "Ajouter les e-mails de signature", es: "Añadir correos de firma") }
    var agreementEmailBothNeed: String { s(en: "Both partners need an email address to receive and sign the agreement via DocuSeal.", nb: "Begge parter trenger en e-postadresse for å motta og signere avtalen via DocuSeal.", sv: "Båda parter behöver en e-postadress för att ta emot och underteckna avtalet via DocuSeal.", da: "Begge parter skal have en e-mailadresse for at modtage og underskrive aftalen via DocuSeal.", fi: "Molemmilla osapuolilla on oltava sähköpostiosoite sopimuksen vastaanottamiseen ja allekirjoittamiseen DocuSealin kautta.", de: "Beide Partner benötigen eine E-Mail-Adresse, um die Vereinbarung über DocuSeal zu erhalten und zu unterzeichnen.", fr: "Les deux partenaires ont besoin d'une adresse e-mail pour recevoir et signer l'accord via DocuSeal.", es: "Ambos socios necesitan una dirección de correo para recibir y firmar el acuerdo a través de DocuSeal.") }
    var agreementSaveAndContinue: String { s(en: "Save & continue", nb: "Lagre og fortsett", sv: "Spara och fortsätt", da: "Gem og fortsæt", fi: "Tallenna ja jatka", de: "Speichern & fortfahren", fr: "Enregistrer et continuer", es: "Guardar y continuar") }
    var agreementDissolutionIncluded: String { s(en: "Dissolution terms included", nb: "Oppløsningsvilkår inkludert", sv: "Upplösningsvillkor ingår", da: "Opløsningsvilkår inkluderet", fi: "Purkamisehdot sisällytetty", de: "Auflösungsbedingungen enthalten", fr: "Conditions de dissolution incluses", es: "Condiciones de disolución incluidas") }
    var agreementDissolutionSub: String { s(en: "Contributions returned first; remaining split by ownership share.", nb: "Bidrag tilbakebetales først; resten deles etter eierandel.", sv: "Bidrag återbetalas först; resten delas efter ägarandel.", da: "Bidrag tilbagebetales først; resten fordeles efter ejerandel.", fi: "Maksut palautetaan ensin; loput jaetaan omistusosuuden mukaan.", de: "Beiträge werden zuerst zurückgezahlt; der Rest wird nach Eigentumsanteil aufgeteilt.", fr: "Contributions remboursées en premier; le reste réparti par quote-part.", es: "Aportaciones devueltas primero; el resto repartido por cuota de propiedad.") }
    var agreementPartnerBEmail: String { s(en: "will receive a signing link by email.", nb: "mottar en signeringslenke på e-post.", sv: "får en signeringslänk via e-post.", da: "modtager et signeringslink via e-mail.", fi: "saa allekirjoituslinkin sähköpostitse.", de: "erhält einen Signierlink per E-Mail.", fr: "recevra un lien de signature par e-mail.", es: "recibirá un enlace de firma por correo.") }
    var agreementContribsTracked: String { s(en: "contributions tracked", nb: "bidrag registrert", sv: "bidrag registrerade", da: "bidrag registreret", fi: "maksuja seurattu", de: "Beiträge verfolgt", fr: "contributions suivies", es: "aportaciones registradas") }
    var agreementContribTracked: String { s(en: "contribution tracked", nb: "bidrag registrert", sv: "bidrag registrerat", da: "bidrag registreret", fi: "maksu seurattu", de: "Beitrag verfolgt", fr: "contribution suivie", es: "aportación registrada") }
    var agreementNoContribs: String { s(en: "No contributions recorded yet", nb: "Ingen bidrag registrert ennå", sv: "Inga bidrag registrerade ännu", da: "Ingen bidrag registreret endnu", fi: "Ei maksuja kirjattu vielä", de: "Noch keine Beiträge erfasst", fr: "Aucune contribution enregistrée", es: "Sin aportaciones registradas") }
    var agreementSharedAssets: String { s(en: "shared assets", nb: "felles eiendeler", sv: "gemensamma tillgångar", da: "fælles aktiver", fi: "yhteistä varallisuutta", de: "gemeinsame Vermögenswerte", fr: "actifs communs", es: "activos compartidos") }
    var agreementSharedAsset: String { s(en: "shared asset", nb: "felles eiendel", sv: "gemensam tillgång", da: "fælles aktiv", fi: "yhteinen varallisuus", de: "gemeinsamer Vermögenswert", fr: "actif commun", es: "activo compartido") }
    var agreementNoAssetsYet: String { s(en: "No assets added yet", nb: "Ingen eiendeler lagt til ennå", sv: "Inga tillgångar tillagda ännu", da: "Ingen aktiver tilføjet endnu", fi: "Ei varoja lisätty vielä", de: "Noch keine Vermögenswerte hinzugefügt", fr: "Aucun actif ajouté encore", es: "Aún no se han añadido activos") }

    // MARK: Agreement — additional UI strings

    var agreementAddSigningEmails: String { s(
        en: "Add signing emails",
        nb: "Legg til signeringsadresser",
        sv: "Lägg till e-postadresser för signering",
        da: "Tilføj e-mailadresser til signering",
        fi: "Lisää allekirjoitussähköpostit",
        de: "Signing-E-Mails hinzufügen",
        fr: "Ajouter les e-mails de signature",
        es: "Añadir correos de firma") }

    var agreementYourAgreement: String { s(
        en: "Your agreement",
        nb: "Din avtale",
        sv: "Ditt avtal",
        da: "Din aftale",
        fi: "Sopimuksesi",
        de: "Ihre Vereinbarung",
        fr: "Votre accord",
        es: "Tu acuerdo") }

    var agreementSignedPrefix: String { s(
        en: "Signed · ",
        nb: "Signert · ",
        sv: "Undertecknat · ",
        da: "Underskrevet · ",
        fi: "Allekirjoitettu · ",
        de: "Unterzeichnet · ",
        fr: "Signé · ",
        es: "Firmado · ") }

    var agreementBetweenPartners: String { s(
        en: "Between",
        nb: "Mellom",
        sv: "Mellan",
        da: "Mellem",
        fi: "Välillä",
        de: "Zwischen",
        fr: "Entre",
        es: "Entre") }

    var agreementAndConnector: String { s(
        en: " & ",
        nb: " og ",
        sv: " och ",
        da: " og ",
        fi: " ja ",
        de: " und ",
        fr: " et ",
        es: " y ") }

    var agreementCheckedAt: String { s(
        en: "Checked ",
        nb: "Sjekket ",
        sv: "Kontrollerat ",
        da: "Tjekket ",
        fi: "Tarkistettu ",
        de: "Geprüft ",
        fr: "Vérifié ",
        es: "Comprobado ") }

    var agreementPreviewFullContract: String { s(
        en: "Preview full contract text",
        nb: "Se full kontraktstekst",
        sv: "Förhandsgranska fullständig kontraktstext",
        da: "Forhåndsvis fuld kontrakttekst",
        fi: "Esikatsele koko sopimusasiakirja",
        de: "Vollständigen Vertragstext anzeigen",
        fr: "Aperçu du texte complet du contrat",
        es: "Vista previa del texto completo del contrato") }

    var agreementGenerateFresh: String { s(
        en: "Generate a fresh agreement",
        nb: "Generer ny avtale fra bunnen av",
        sv: "Generera ett nytt avtal från grunden",
        da: "Generér en ny aftale fra bunden",
        fi: "Luo uusi sopimus alusta",
        de: "Neue Vereinbarung erstellen",
        fr: "Générer un nouvel accord",
        es: "Generar un nuevo acuerdo") }

    var agreementCancelSigningTitle: String { s(
        en: "Cancel current signing?",
        nb: "Avbryt nåværende signering?",
        sv: "Avbryta nuvarande signering?",
        da: "Annuller nuværende signering?",
        fi: "Peruuta nykyinen allekirjoitus?",
        de: "Aktuelle Unterzeichnung abbrechen?",
        fr: "Annuler la signature en cours ?",
        es: "¿Cancelar la firma actual?") }

    var agreementYesGenerateNew: String { s(
        en: "Yes, generate new",
        nb: "Ja, generer ny",
        sv: "Ja, generera ny",
        da: "Ja, generér ny",
        fi: "Kyllä, luo uusi",
        de: "Ja, neu erstellen",
        fr: "Oui, générer nouveau",
        es: "Sí, generar nuevo") }

    var agreementCancelSigningMessage: String { s(
        en: "Any signing links already sent will no longer be used. A new PDF will be generated from current data.",
        nb: "Signeringslenker som allerede er sendt vil ikke lenger være gyldige. En ny PDF genereres fra nåværende data.",
        sv: "Eventuella signeringslänkar som redan skickats kommer inte längre att användas. En ny PDF genereras från aktuell data.",
        da: "Allerede afsendte signeringslinks vil ikke længere blive brugt. En ny PDF genereres ud fra aktuelle data.",
        fi: "Jo lähetettyjä allekirjoituslinkkejä ei enää käytetä. Uusi PDF luodaan nykyisistä tiedoista.",
        de: "Bereits gesendete Signierlinks werden nicht mehr verwendet. Eine neue PDF wird aus den aktuellen Daten erstellt.",
        fr: "Les liens de signature déjà envoyés ne seront plus utilisés. Un nouveau PDF sera généré à partir des données actuelles.",
        es: "Los enlaces de firma ya enviados dejarán de usarse. Se generará un nuevo PDF con los datos actuales.") }

    /// Suffix appended to a partner name to form an email field label.
    /// e.g. "Anna's email" / "Annas e-post"
    var agreementPartnerEmailSuffix: String { s(
        en: "'s email",
        nb: "s e-post",
        sv: "s e-post",
        da: "s e-mail",
        fi: ":n sähköposti",
        de: "s E-Mail",
        fr: " — e-mail",
        es: " — correo") }

    // MARK: Settlement — additional UI strings

    var settlementTotalEquity: String { s(
        en: "TOTAL EQUITY",
        nb: "TOTAL EGENKAPITAL",
        sv: "TOTALT EGET KAPITAL",
        da: "TOTAL EGENKAPITAL",
        fi: "OMA PÄÄOMA YHTEENSÄ",
        de: "GESAMTEIGENKAPITAL",
        fr: "CAPITAUX PROPRES TOTAUX",
        es: "PATRIMONIO TOTAL") }

    // MARK: Agreement — waterfall explanation

    var agreementHowItWorksTitle: String { s(
        en: "How this agreement protects you",
        nb: "Slik beskytter avtalen dere",
        sv: "Hur avtalet skyddar er",
        da: "Sådan beskytter aftalen jer",
        fi: "Miten sopimus suojaa teitä",
        de: "So schützt Sie der Vertrag",
        fr: "Comment cet accord vous protège",
        es: "Cómo le protege este acuerdo") }

    var agreementWaterfallStep1Title: String { s(
        en: "Contributions returned first",
        nb: "Bidrag tilbakebetales først",
        sv: "Bidrag återbetalas först",
        da: "Bidrag tilbagebetales først",
        fi: "Maksut palautetaan ensin",
        de: "Beiträge werden zuerst zurückgezahlt",
        fr: "Contributions remboursées en premier",
        es: "Aportaciones devueltas primero") }

    var agreementWaterfallStep1Body: String { s(
        en: "Everything you've put in — equity contributions to your home, deposits, renovations, extra mortgage payments — is returned to you with interest before anything is split.",
        nb: "Alt du har bidratt med — egenkapitalbidrag til boligen, innskudd, oppussing, ekstra nedbetalinger — tilbakebetales til deg med renter før noe deles.",
        sv: "Allt du har bidragit med — eget kapital till bostaden, insättningar, renoveringar, extra amorteringar — återbetalas med ränta innan något delas.",
        da: "Alt du har bidraget med — egenkapitalbidrag til boligen, indskud, renoveringer, ekstra afdrag — tilbagebetales med renter inden noget deles.",
        fi: "Kaikki, mitä olet maksanut — pääomamaksut kotiisi, talletukset, remontit, ylimääräiset lyhennykset — palautetaan sinulle korkoineen ennen mitään jakoa.",
        de: "Alles, was Sie eingebracht haben — Eigenkapitalbeiträge, Einlagen, Renovierungen, extra Hypothekenzahlungen — wird mit Zinsen zurückgezahlt, bevor etwas aufgeteilt wird.",
        fr: "Tout ce que vous avez apporté — contributions en capital, dépôts, rénovations, remboursements supplémentaires — vous est rendu avec intérêts avant tout partage.",
        es: "Todo lo que ha aportado — contribuciones de capital, depósitos, reformas, pagos hipotecarios extra — le es devuelto con intereses antes de cualquier reparto.") }

    var agreementWaterfallStep2Title: String { s(
        en: "Remaining surplus split by ownership",
        nb: "Gjenværende overskudd fordeles etter eierandel",
        sv: "Återstående överskott delas efter ägarandel",
        da: "Resterende overskud fordeles efter ejerandel",
        fi: "Jäljellä oleva ylijäämä jaetaan omistuksen mukaan",
        de: "Verbleibender Überschuss nach Eigentumsanteil aufgeteilt",
        fr: "L'excédent restant réparti selon la propriété",
        es: "El excedente restante repartido por cuota de propiedad") }

    var agreementWaterfallStep2Body: String { s(
        en: "Only what's left after contributions are repaid is split according to your registered ownership percentages.",
        nb: "Kun det som er igjen etter at bidrag er tilbakebetalt, fordeles etter registrert eierbrøk.",
        sv: "Bara det som återstår efter att bidrag återbetalats fördelas efter registrerade ägarandelar.",
        da: "Kun det resterende efter bidrag er tilbagebetalt fordeles efter registrerede ejerandele.",
        fi: "Vain se, mitä jää jäljelle maksujen palautuksen jälkeen, jaetaan rekisteröityjen omistusprosenttien mukaan.",
        de: "Nur das, was nach der Rückzahlung der Beiträge übrig bleibt, wird gemäß den registrierten Eigentumsanteilen aufgeteilt.",
        fr: "Seul ce qui reste après remboursement des contributions est réparti selon vos pourcentages de propriété enregistrés.",
        es: "Solo lo que queda después de devolver las aportaciones se reparte según sus porcentajes de propiedad registrados.") }

    var agreementWaterfallStep3Title: String { s(
        en: "If sold at a loss: proportional split",
        nb: "Ved tap: forholdsmessig fordeling",
        sv: "Vid förlust: proportionell fördelning",
        da: "Ved tab: forholdsmæssig fordeling",
        fi: "Jos myydään tappiolla: suhteellinen jako",
        de: "Bei Verlustverkauf: proportionale Aufteilung",
        fr: "En cas de vente à perte: répartition proportionnelle",
        es: "Si se vende con pérdida: reparto proporcional") }

    var agreementWaterfallStep3Body: String { s(
        en: "If net proceeds are less than total contributions, the available funds are shared proportionally to what each person put in.",
        nb: "Hvis nettoproveny er lavere enn de totale bidragene, fordeles tilgjengelige midler forholdsmessig etter hva hver part bidro med.",
        sv: "Om nettointäkterna är lägre än totala bidrag fördelas tillgängliga medel proportionellt efter vad varje part bidrog med.",
        da: "Hvis nettoprovenuet er lavere end de samlede bidrag, fordeles tilgængelige midler forholdsmæssigt efter hvad hver part bidrog med.",
        fi: "Jos nettotulot ovat pienempiä kuin kokonaismaksut, käytettävissä olevat varat jaetaan suhteessa kunkin osapuolen maksamaan summaan.",
        de: "Wenn die Nettoerlöse unter den Gesamtbeiträgen liegen, werden die verfügbaren Mittel proportional zu dem aufgeteilt, was jede Person eingebracht hat.",
        fr: "Si le produit net est inférieur aux contributions totales, les fonds disponibles sont partagés proportionnellement à ce que chacun a apporté.",
        es: "Si los ingresos netos son inferiores a las aportaciones totales, los fondos disponibles se reparten proporcionalmente a lo que cada persona aportó.") }

    // MARK: Settlement tab

    var tabEquity: String        { s(en: "Equity", nb: "Egenkapital", sv: "Eget kapital", da: "Egenkapital", fi: "Oma pääoma", de: "Eigenkapital", fr: "Capitaux propres", es: "Patrimonio") }
    var settlementTabSub: String { s(
        en: "Your equity stake in each shared asset today",
        nb: "Din egenkapitalandel i hver felles eiendel i dag",
        sv: "Din andel av eget kapital i varje gemensam tillgång idag",
        da: "Din egenkapitalandel i hvert fælles aktiv i dag",
        fi: "Osuutesi omasta pääomasta kussakin yhteisessä omaisuudessa tänään",
        de: "Ihr Eigenkapitalanteil an jedem gemeinsamen Vermögenswert heute",
        fr: "Votre quote-part dans chaque actif commun aujourd'hui",
        es: "Su cuota de patrimonio en cada activo compartido hoy") }
    var settlementNoAssets: String { s(
        en: "Add shared assets to track your equity.",
        nb: "Legg til felles eiendeler for å følge egenkapitalen din.",
        sv: "Lägg till gemensamma tillgångar för att följa ditt egna kapital.",
        da: "Tilføj fælles aktiver for at følge din egenkapital.",
        fi: "Lisää yhteisiä varoja seurataksesi pääomaasi.",
        de: "Fügen Sie gemeinsame Vermögenswerte hinzu, um Ihr Eigenkapital zu verfolgen.",
        fr: "Ajoutez des actifs communs pour suivre votre patrimoine.",
        es: "Añade activos compartidos para seguir tu patrimonio.") }
    var settlementRun: String    { s(en: "Calculate", nb: "Beregn", sv: "Beräkna", da: "Beregn", fi: "Laske", de: "Berechnen", fr: "Calculer", es: "Calcular") }
    var settlementToday: String  { s(en: "Today — no sale costs", nb: "I dag — uten salgskostnader", sv: "Idag — utan försäljningskostnader", da: "I dag — uden salgsomkostninger", fi: "Tänään — ilman myyntikuluja", de: "Heute — ohne Verkaufskosten", fr: "Aujourd'hui — sans frais de vente", es: "Hoy — sin costes de venta") }

    // MARK: Assets tab

    var assetsNoAssetsTitle: String { s(en: "No assets yet", nb: "Ingen eiendeler ennå", sv: "Inga tillgångar ännu", da: "Ingen aktiver endnu", fi: "Ei varoja vielä", de: "Noch keine Vermögenswerte", fr: "Aucun actif pour l'instant", es: "Aún no hay activos") }
    var assetsNoAssetsSub: String   { s(en: "Add your home, car, savings, or any shared asset to track contributions and equity.",
                                         nb: "Legg til bolig, bil, sparing eller andre felles eiendeler for å registrere bidrag og egenkapital.",
                                         sv: "Lägg till din bostad, bil, sparande eller andra gemensamma tillgångar för att spåra bidrag och eget kapital.",
                                         da: "Tilføj din bolig, bil, opsparing eller andre fælles aktiver for at registrere bidrag og egenkapital.",
                                         fi: "Lisää koti, auto, säästöt tai muu yhteinen varallisuus seurataksesi maksuja ja pääomaa.",
                                         de: "Fügen Sie Ihr Zuhause, Auto, Ersparnisse oder andere gemeinsame Vermögenswerte hinzu.",
                                         fr: "Ajoutez votre logement, voiture, épargne ou tout actif commun pour suivre les contributions et le patrimoine.",
                                         es: "Añade tu vivienda, coche, ahorros o cualquier activo compartido para registrar aportaciones y patrimonio.") }
    var assetsAddFirst: String      { s(en: "Add first asset", nb: "Legg til første eiendel", sv: "Lägg till första tillgången", da: "Tilføj første aktiv", fi: "Lisää ensimmäinen varallisuus", de: "Ersten Vermögenswert hinzufügen", fr: "Ajouter le premier actif", es: "Agregar primer activo") }

    // MARK: Calculators

    var calcOwnershipTitle: String { s(en: "Ownership split",   nb: "Eierfordelingskalkulator", sv: "Ägarandelsfördelning",  da: "Ejerandelskalkulator",   fi: "Omistusosuuslaskuri",      de: "Eigentumsaufteilung",     fr: "Répartition de propriété",  es: "Distribución de propiedad") }
    var calcOwnershipSub: String   { s(en: "Calculate equity based on deposits and payments.", nb: "Beregn egenkapital basert på innskudd og betalinger.", sv: "Beräkna eget kapital baserat på insättningar och betalningar.", da: "Beregn egenkapital baseret på indskud og betalinger.", fi: "Laske oma pääoma maksujen perusteella.", de: "Eigenkapital basierend auf Einlagen berechnen.", fr: "Calculer les capitaux propres à partir des apports.", es: "Calcula el patrimonio basándote en depósitos y pagos.") }
    var calcExpenseTitle: String   { s(en: "Expense split",     nb: "Utgiftsfordeling",         sv: "Kostnadsfördelning",    da: "Udgiftsfordeling",       fi: "Kulujen jako",             de: "Kostenaufteilung",        fr: "Répartition des dépenses",  es: "División de gastos") }
    var calcExpenseSub: String     { s(en: "Fairly divide monthly household costs.", nb: "Fordel månedlige husholdningsutgifter rettferdig.", sv: "Fördela månadsliga hushållskostnader rättvist.", da: "Fordel månedlige husholdningsudgifter rimeligt.", fi: "Jaa kuukausittaiset kotitalouskulut oikeudenmukaisesti.", de: "Monatliche Haushaltskosten fair aufteilen.", fr: "Répartir équitablement les charges mensuelles.", es: "Divide equitativamente los gastos mensuales del hogar.") }
    var calcRebalanceTitle: String { s(en: "Rebalance",         nb: "Rebalansering",            sv: "Ombalansering",         da: "Rebalancering",          fi: "Uudelleentasapainotus",    de: "Anteilsausgleich",        fr: "Rééquilibrage",             es: "Reequilibrio") }
    var calcRebalanceSub: String   { s(en: "See what it takes to reach 50/50 ownership.", nb: "Se hva som skal til for å nå 50/50 eierskap.", sv: "Se vad som krävs för att nå 50/50 ägarandel.", da: "Se hvad der skal til for at nå 50/50 ejerskab.", fi: "Näe mitä tarvitaan 50/50 omistukseen.", de: "Sehen Sie, was zum 50/50-Eigentum nötig ist.", fr: "Voyez ce qu'il faut pour atteindre 50/50.", es: "Descubre qué se necesita para llegar al 50/50.") }
    var calcSavingsTitle: String   { s(en: "Savings planner",   nb: "Sparekalkulator",          sv: "Sparekalkylator",       da: "Sparekalkulator",        fi: "Säästösuunnittelija",      de: "Sparrechner",             fr: "Calculateur d'épargne",     es: "Calculadora de ahorro") }
    var calcSavingsSub: String     { s(en: "Compare mortgage paydown vs. investing — see which grows your wealth faster.", nb: "Sammenlign nedbetaling av boliglån med fondssparing.", sv: "Jämför amortering med fondsparande — se vad som lönar sig.", da: "Sammenlign afdrag og investering — se hvad der vokser hurtigst.", fi: "Vertaa asuntolainan lyhentämistä sijoittamiseen.", de: "Tilgung vs. Investieren — was vermehrt Ihr Vermögen schneller?", fr: "Comparez remboursement et investissement — lequel croît plus vite?", es: "Compara amortización e inversión — ¿cuál hace crecer más tu patrimonio?") }

    // MARK: Savings calculator

    var savingsMonthlySavingsHeader: String { s(
        en: "MONTHLY SAVINGS",
        nb: "MÅNEDLIG SPARING",
        sv: "MÅNADSSPARANDE",
        da: "MÅNEDLIG OPSPARING",
        fi: "KUUKAUSISÄÄSTÖ",
        de: "MONATLICHES SPAREN",
        fr: "ÉPARGNE MENSUELLE",
        es: "AHORRO MENSUAL") }

    var savingsMonthlySavingsPrompt: String { s(
        en: "How much do you want to save each month?",
        nb: "Hvor mye vil dere spare per måned?",
        sv: "Hur mycket vill ni spara per månad?",
        da: "Hvor meget vil I spare om måneden?",
        fi: "Kuinka paljon haluatte säästää kuukaudessa?",
        de: "Wie viel möchten Sie monatlich sparen?",
        fr: "Combien souhaitez-vous épargner chaque mois ?",
        es: "¿Cuánto queréis ahorrar al mes?") }

    var savingsPerYear: String { s(
        en: " per year",
        nb: " per år",
        sv: " per år",
        da: " om året",
        fi: " vuodessa",
        de: " pro Jahr",
        fr: " par an",
        es: " al año") }

    var savingsAllocationHeader: String { s(
        en: "ALLOCATION",
        nb: "FORDELING",
        sv: "FÖRDELNING",
        da: "FORDELING",
        fi: "JAKO",
        de: "AUFTEILUNG",
        fr: "RÉPARTITION",
        es: "DISTRIBUCIÓN") }

    var savingsMoreToMortgage: String { s(
        en: "← More to mortgage",
        nb: "← Mer til boliglån",
        sv: "← Mer till bolånet",
        da: "← Mere til boliglån",
        fi: "← Enemmän lainaan",
        de: "← Mehr zum Kredit",
        fr: "← Plus vers le crédit",
        es: "← Más a la hipoteca") }

    var savingsMoreToInvesting: String { s(
        en: "More to investing →",
        nb: "Mer til fond →",
        sv: "Mer till fonder →",
        da: "Mere til investering →",
        fi: "Enemmän sijoituksiin →",
        de: "Mehr investieren →",
        fr: "Plus vers l'investissement →",
        es: "Más a invertir →") }

    var savingsTimeHorizonHeader: String { s(
        en: "TIME HORIZON",
        nb: "TIDSHORISONT",
        sv: "TIDSHORISONT",
        da: "TIDSHORISONT",
        fi: "AIKAJÄNNE",
        de: "ZEITHORIZONT",
        fr: "HORIZON TEMPOREL",
        es: "HORIZONTE TEMPORAL") }

    var savingsSaveFor: String { s(
        en: "Save for",
        nb: "Spare i",
        sv: "Spara i",
        da: "Spar i",
        fi: "Säästä",
        de: "Sparen für",
        fr: "Épargner pendant",
        es: "Ahorrar durante") }

    var savingsYears: String { s(
        en: "years",
        nb: "år",
        sv: "år",
        da: "år",
        fi: "vuotta",
        de: "Jahre",
        fr: "ans",
        es: "años") }

    var savingsAdjustRates: String { s(
        en: "Adjust rates",
        nb: "Juster rente og avkastning",
        sv: "Justera räntor",
        da: "Juster renter",
        fi: "Muokkaa korkoja",
        de: "Zinsen anpassen",
        fr: "Ajuster les taux",
        es: "Ajustar tasas") }

    var savingsMortgageRate: String { s(
        en: "Mortgage rate",
        nb: "Lånerente",
        sv: "Bolåneränta",
        da: "Boliglånsrente",
        fi: "Lainakorko",
        de: "Kreditzins",
        fr: "Taux hypothécaire",
        es: "Tipo hipotecario") }

    var savingsExpectedReturn: String { s(
        en: "Expected return",
        nb: "Fondsavkastning",
        sv: "Förväntad avkastning",
        da: "Forventet afkast",
        fi: "Odotettu tuotto",
        de: "Erwartete Rendite",
        fr: "Rendement attendu",
        es: "Rentabilidad esperada") }

    /// Format: String(format: strings.savingsAfterYears, X) → "After 10 years" / "Om 10 år"
    var savingsAfterYears: String { s(
        en: "After %d years",
        nb: "Om %d år",
        sv: "Om %d år",
        da: "Om %d år",
        fi: "%d vuoden kuluttua",
        de: "Nach %d Jahren",
        fr: "Dans %d ans",
        es: "En %d años") }

    var savingsTotalAccumulated: String { s(
        en: "total accumulated",
        nb: "totalt spart",
        sv: "totalt sparat",
        da: "totalt opsparet",
        fi: "yhteensä kertynyt",
        de: "insgesamt angespart",
        fr: "total accumulé",
        es: "total acumulado") }

    var savingsMortgageLabel: String { s(
        en: "Mortgage",
        nb: "Boliglån",
        sv: "Bolån",
        da: "Boliglån",
        fi: "Asuntolaina",
        de: "Kredit",
        fr: "Crédit immobilier",
        es: "Hipoteca") }

    var savingsInvestingLabel: String { s(
        en: "Investing",
        nb: "Fondssparing",
        sv: "Fondsparande",
        da: "Investering",
        fi: "Sijoittaminen",
        de: "Investieren",
        fr: "Investissement",
        es: "Inversión") }

    var savingsInterestSaved: String { s(
        en: "interest saved",
        nb: "renter spart",
        sv: "räntebesparing",
        da: "renter sparet",
        fi: "korkoa säästetty",
        de: "Zinsen gespart",
        fr: "intérêts économisés",
        es: "intereses ahorrados") }

    var savingsReturns: String { s(
        en: "returns",
        nb: "avkastning",
        sv: "avkastning",
        da: "afkast",
        fi: "tuotto",
        de: "Rendite",
        fr: "rendements",
        es: "rentabilidad") }

    var savingsPaidIn: String { s(
        en: " paid in",
        nb: " innbetalt",
        sv: " inbetalt",
        da: " indbetalt",
        fi: " maksettu",
        de: " eingezahlt",
        fr: " versé",
        es: " aportado") }

    var savingsMortgagePrioritisedNote: String { s(
        en: "Mortgage is prioritised. Extra payments give a guaranteed return equal to your interest rate.",
        nb: "Boliglånet er prioritert. Nedbetaling gir garantert avkastning tilsvarende lånerenten.",
        sv: "Bolånet prioriteras. Extra amorteringar ger garanterad avkastning motsvarande räntan.",
        da: "Boliglånet prioriteres. Ekstra afdrag giver garanteret afkast svarende til lånerenten.",
        fi: "Laina on ensisijainen. Lisälyhennykset tuottavat takuutuoton lainakoron verran.",
        de: "Kredit wird priorisiert. Extra-Zahlungen liefern eine garantierte Rendite in Höhe des Zinssatzes.",
        fr: "Le crédit est prioritaire. Les remboursements supplémentaires offrent un rendement garanti égal au taux.",
        es: "La hipoteca tiene prioridad. Los pagos extra dan un retorno garantizado igual al tipo de interés.") }

    var savingsInvestingPrioritisedNote: String { s(
        en: "Investing is prioritised. Long-term funds have historically outperformed mortgage rates.",
        nb: "Fond er prioritert. Langsiktig sparing i fond gir historisk sett høyere avkastning enn boligrenten.",
        sv: "Fondsparande prioriteras. Långsiktig fondsparande har historiskt gett högre avkastning än bolåneräntan.",
        da: "Investering prioriteres. Langsigtet fondsopsparing har historisk givet højere afkast end boliglånsrenten.",
        fi: "Sijoittaminen on ensisijainen. Pitkäaikainen rahastosijoittaminen on historiallisesti tuottanut enemmän kuin lainakorko.",
        de: "Investieren wird priorisiert. Langfristige Fonds haben historisch besser abgeschnitten als Hypothekenzinsen.",
        fr: "L'investissement est prioritaire. Les fonds à long terme ont historiquement surpassé les taux hypothécaires.",
        es: "La inversión tiene prioridad. Los fondos a largo plazo han superado históricamente los tipos hipotecarios.") }

    var savingsProjectionsDisclaimer: String { s(
        en: "Projections are illustrative. Actual returns will vary.",
        nb: "Beregningene er veiledende. Faktisk avkastning varierer.",
        sv: "Beräkningarna är vägledande. Faktisk avkastning varierar.",
        da: "Beregningerne er vejledende. Faktisk afkast varierer.",
        fi: "Laskelmat ovat suuntaa-antavia. Todellinen tuotto vaihtelee.",
        de: "Prognosen sind illustrativ. Die tatsächliche Rendite kann abweichen.",
        fr: "Les projections sont indicatives. Les rendements réels peuvent varier.",
        es: "Las proyecciones son orientativas. La rentabilidad real puede variar.") }

    // MARK: Expense split

    var expenseSaveToOverview: String { s(
        en: "Save to Overview",
        nb: "Lagre til Oversikt",
        sv: "Spara till Översikt",
        da: "Gem til Oversigt",
        fi: "Tallenna Yhteenvetoon",
        de: "In Übersicht speichern",
        fr: "Enregistrer dans Vue d'ensemble",
        es: "Guardar en Resumen") }

    var expenseSavedToOverview: String { s(
        en: "Saved to Overview",
        nb: "Lagret til Oversikt",
        sv: "Sparat till Översikt",
        da: "Gemt til Oversigt",
        fi: "Tallennettu Yhteenvetoon",
        de: "In Übersicht gespeichert",
        fr: "Enregistré dans Vue d'ensemble",
        es: "Guardado en Resumen") }

    var expenseMonthlyTotal: String { s(
        en: "Monthly total",
        nb: "Månedlig totalt",
        sv: "Månatlig totalt",
        da: "Månedlig total",
        fi: "Kuukausittainen yhteensä",
        de: "Monatliche Gesamtsumme",
        fr: "Total mensuel",
        es: "Total mensual") }

    // MARK: Settlement

    var settlementTitle: String { s(en: "Settlement", nb: "Oppgjør", sv: "Uppgörelse", da: "Opgørelse", fi: "Selvitys", de: "Aufteilung", fr: "Partage", es: "Reparto") }

    var settlementValueToday: String { s(
        en: "Value today",
        nb: "Verdi i dag",
        sv: "Värde idag",
        da: "Værdi i dag",
        fi: "Arvo tänään",
        de: "Heutiger Wert",
        fr: "Valeur aujourd'hui",
        es: "Valor hoy") }

    var settlementBalance: String { s(
        en: "Balance",
        nb: "Saldo",
        sv: "Saldo",
        da: "Saldo",
        fi: "Saldo",
        de: "Kontostand",
        fr: "Solde",
        es: "Saldo") }

    var settlementNet: String { s(
        en: "Net",
        nb: "Netto",
        sv: "Netto",
        da: "Netto",
        fi: "Netto",
        de: "Netto",
        fr: "Net",
        es: "Neto") }

    var settlementSectionIfSold: String { s(
        en: "If sold today",
        nb: "Hvis solgt i dag",
        sv: "Om sålt idag",
        da: "Hvis solgt i dag",
        fi: "Jos myytäisiin tänään",
        de: "Bei Verkauf heute",
        fr: "Si vendu aujourd'hui",
        es: "Si se vendiera hoy") }

    var settlementSalePrice: String { s(
        en: "Sale price",
        nb: "Salgspris",
        sv: "Försäljningspris",
        da: "Salgspris",
        fi: "Myyntihinta",
        de: "Verkaufspreis",
        fr: "Prix de vente",
        es: "Precio de venta") }

    var settlementLoan: String { s(
        en: "Remaining loan",
        nb: "Gjenstående lån",
        sv: "Återstående lån",
        da: "Resterende lån",
        fi: "Jäljellä oleva laina",
        de: "Restdarlehen",
        fr: "Prêt restant",
        es: "Préstamo restante") }

    var settlementSaleCosts: String { s(
        en: "Sale costs",
        nb: "Salgskostnader",
        sv: "Försäljningskostnader",
        da: "Salgsomkostninger",
        fi: "Myyntikulut",
        de: "Verkaufskosten",
        fr: "Frais de vente",
        es: "Costes de venta") }

    var settlementNetProceeds: String { s(
        en: "Net proceeds",
        nb: "Netto proveny",
        sv: "Nettointäkt",
        da: "Nettoprovenu",
        fi: "Nettotulot",
        de: "Nettoerlös",
        fr: "Produit net",
        es: "Ingresos netos") }

    var settlementWaterfall: String { s(
        en: "How it's distributed",
        nb: "Slik fordeles det",
        sv: "Så här fördelas det",
        da: "Sådan fordeles det",
        fi: "Näin se jaetaan",
        de: "So wird es verteilt",
        fr: "Comment c'est distribué",
        es: "Cómo se distribuye") }

    var settlementStep1Label: String { s(
        en: "① Contributions returned first (with interest)",
        nb: "① Bidrag tilbakebetales først (med renter)",
        sv: "① Bidrag återbetalas först (med ränta)",
        da: "① Bidrag tilbagebetales først (med renter)",
        fi: "① Maksut palautetaan ensin (korkoineen)",
        de: "① Beiträge werden zuerst zurückgezahlt (mit Zinsen)",
        fr: "① Contributions remboursées en premier (avec intérêts)",
        es: "① Aportaciones devueltas primero (con intereses)") }

    var settlementStep2Label: String { s(
        en: "② Surplus split by ownership",
        nb: "② Overskudd fordeles etter eierandel",
        sv: "② Överskott delas efter ägarandel",
        da: "② Overskud fordeles efter ejerandel",
        fi: "② Ylijäämä jaetaan omistuksen mukaan",
        de: "② Überschuss nach Eigentumsanteil aufgeteilt",
        fr: "② Excédent réparti selon la propriété",
        es: "② Excedente repartido por cuota de propiedad") }

    var settlementShortfallStep2: String { s(
        en: "② Proportional split (shortfall)",
        nb: "② Forholdsmessig fordeling (tap)",
        sv: "② Proportionell fördelning (underskott)",
        da: "② Forholdsmæssig fordeling (tab)",
        fi: "② Suhteellinen jako (tappio)",
        de: "② Proportionale Aufteilung (Defizit)",
        fr: "② Répartition proportionnelle (déficit)",
        es: "② Reparto proporcional (déficit)") }

    var settlementShortfallTitle: String { s(
        en: "Shortfall scenario",
        nb: "Tapssituasjon",
        sv: "Underskottsscenario",
        da: "Tabssituation",
        fi: "Alijäämätilanne",
        de: "Defizit-Szenario",
        fr: "Scénario de déficit",
        es: "Escenario de déficit") }

    var settlementShortfallBody: String { s(
        en: "Net proceeds are below total contributions. Available funds are split proportionally to each partner's contribution — no surplus to distribute.",
        nb: "Netto proveny er lavere enn de totale bidragene. Tilgjengelige midler fordeles forholdsmessig etter hver parts bidrag — det er ingen overskudd å fordele.",
        sv: "Nettointäkterna understiger totala bidrag. Tillgängliga medel fördelas proportionellt efter varje parts bidrag — inget överskott att fördela.",
        da: "Nettoprovenuet er lavere end de samlede bidrag. Tilgængelige midler fordeles forholdsmæssigt efter hver parts bidrag — intet overskud at fordele.",
        fi: "Nettotulot jäävät alle kokonaismaksujen. Käytettävissä olevat varat jaetaan suhteessa kunkin osapuolen maksuihin — ei ylijäämää jaettavaksi.",
        de: "Nettoerlöse liegen unter den Gesamtbeiträgen. Verfügbare Mittel werden proportional zu den Beiträgen der einzelnen Partner aufgeteilt — kein Überschuss.",
        fr: "Le produit net est inférieur aux contributions totales. Les fonds disponibles sont répartis proportionnellement aux contributions de chaque partenaire — pas d'excédent.",
        es: "Los ingresos netos están por debajo de las aportaciones totales. Los fondos disponibles se reparten proporcionalmente a las aportaciones de cada socio — sin excedente.") }

    var settlementShortfallInline: String { s(
        en: "If sold at a loss: funds split proportionally to contributions",
        nb: "Ved tap: midler fordeles forholdsmessig etter bidrag",
        sv: "Vid förlust: medel fördelas proportionellt efter bidrag",
        da: "Ved tab: midler fordeles forholdsmæssigt efter bidrag",
        fi: "Jos myydään tappiolla: varat jaetaan suhteessa maksuihin",
        de: "Bei Verlust: Mittel proportional zu Beiträgen aufgeteilt",
        fr: "En cas de perte: fonds répartis proportionnellement aux contributions",
        es: "Si se vende con pérdida: fondos repartidos proporcionalmente a las aportaciones") }

    var settlementTotalPayout: String { s(
        en: "Final payout",
        nb: "Endelig utbetaling",
        sv: "Slutlig utbetalning",
        da: "Endelig udbetaling",
        fi: "Lopullinen maksu",
        de: "Endauszahlung",
        fr: "Paiement final",
        es: "Pago final") }

    var settlementTransferTitle: String { s(
        en: "Equalisation transfer",
        nb: "Utjevningstransaksjon",
        sv: "Utjämningstransaktion",
        da: "Udligningsoverførsel",
        fi: "Tasausmaksu",
        de: "Ausgleichsübertragung",
        fr: "Transfert d'égalisation",
        es: "Transferencia de compensación") }

    var settlementTransferNote: String { s(
        en: "The bank pays by registered ownership title. Since equity contributions differ from ownership shares, a transfer between partners is needed to settle fairly.",
        nb: "Banken utbetaler etter tinglyst eierbrøk. Siden egenkapitalbidragene avviker fra eierandelen, kreves en overføring mellom partene for et rettferdig oppgjør.",
        sv: "Banken betalar efter registrerade ägarandelar. Eftersom kapitalinsatserna skiljer sig från ägarandelarna behövs en överföring mellan parterna för rättvis uppgörelse.",
        da: "Banken udbetaler efter registreret ejerandel. Da egenkapitalbidragene afviger fra ejerandelene, kræves en overførsel mellem parterne for retfærdig opgørelse.",
        fi: "Pankki maksaa rekisteröidyn omistusasteen mukaan. Koska pääomamaksut poikkeavat omistusosuuksista, tarvitaan osapuolten välinen siirto reilua selvitystä varten.",
        de: "Die Bank zahlt nach dem eingetragenen Eigentumsanteil. Da die Eigenkapitalbeiträge von den Eigentumsanteilen abweichen, ist eine Überweisung zwischen den Partnern für eine faire Abwicklung erforderlich.",
        fr: "La banque paie selon la quote-part enregistrée. Comme les contributions en capital diffèrent des quotes-parts, un transfert entre partenaires est nécessaire pour un règlement équitable.",
        es: "El banco paga según la cuota de propiedad registrada. Como las aportaciones de capital difieren de las cuotas de propiedad, se necesita una transferencia entre socios para un reparto justo.") }

    /// Format: String(format: strings.settlementInterestEarned, "£500") → "incl. £500 interest"
    var settlementInterestEarned: String { s(
        en: "incl. %@ interest",
        nb: "inkl. %@ renter",
        sv: "inkl. %@ ränta",
        da: "inkl. %@ renter",
        fi: "sis. %@ korko",
        de: "inkl. %@ Zinsen",
        fr: "incl. %@ intérêts",
        es: "incl. %@ intereses") }

    /// Format: String(format: strings.settlementRateNote, "5.0%") → "Interest rate: 5.0%/yr · compounded annually"
    var settlementRateNote: String { s(
        en: "Interest rate: %@/yr · compounded annually",
        nb: "Rentesats: %@/år · kapitaliseres årlig",
        sv: "Ränta: %@/år · kapitaliseras årligen",
        da: "Rentesats: %@/år · kapitaliseres årligt",
        fi: "Korko: %@/v · korotetaan vuosittain",
        de: "Zinssatz: %@/Jahr · jährlich kapitalisiert",
        fr: "Taux d'intérêt: %@/an · composé annuellement",
        es: "Tipo de interés: %@/año · capitalizado anualmente") }

    var settlementNoContributions: String { s(
        en: "No contributions recorded — distribution is by ownership share only.",
        nb: "Ingen bidrag registrert — fordeling skjer kun etter eierandel.",
        sv: "Inga bidrag registrerade — fördelning sker enbart efter ägarandel.",
        da: "Ingen bidrag registreret — fordeling sker kun efter ejerandel.",
        fi: "Ei maksuja kirjattu — jako tapahtuu vain omistusosuuden mukaan.",
        de: "Keine Beiträge erfasst — Verteilung nur nach Eigentumsanteil.",
        fr: "Aucune contribution enregistrée — répartition uniquement par quote-part.",
        es: "Sin aportaciones registradas — distribución solo por cuota de propiedad.") }

    // MARK: Paywall

    var paywallTitle: String { s(
        en: "Formal Agreement",
        nb: "Formell avtale",
        sv: "Formellt avtal",
        da: "Formel aftale",
        fi: "Virallinen sopimus",
        de: "Formelle Vereinbarung",
        fr: "Accord formel",
        es: "Acuerdo formal") }

    var paywallSubtitle: String { s(
        en: "Create a legally-styled ownership record, signed by both partners.",
        nb: "Lag et formelt eierskapsbevis som signeres av begge parter.",
        sv: "Skapa ett formellt ägarintyg som undertecknas av båda parter.",
        da: "Lav en formel ejerskabsregistrering, underskrevet af begge parter.",
        fi: "Luo muodollinen omistusrekisteri, jonka molemmat osapuolet allekirjoittavat.",
        de: "Erstellen Sie ein formelles Eigentumsdokument, das von beiden Partnern unterzeichnet wird.",
        fr: "Créez un acte de propriété formel, signé par les deux partenaires.",
        es: "Cree un registro formal de propiedad, firmado por ambos socios.") }

    var paywallFeature1: String { s(
        en: "PDF ownership agreement generated from your data",
        nb: "PDF-eierskapsavtale generert fra dine data",
        sv: "PDF-ägaravtal genererat från dina uppgifter",
        da: "PDF-ejerskabsaftale genereret fra dine data",
        fi: "PDF-omistussopimus luotu tiedoistasi",
        de: "PDF-Eigentumsvereinbarung aus Ihren Daten erstellt",
        fr: "Accord de propriété PDF généré à partir de vos données",
        es: "Acuerdo de propiedad PDF generado a partir de sus datos") }

    var paywallFeature2: String { s(
        en: "E-sign via DocuSeal — both partners receive a signing link by email",
        nb: "E-signering via DocuSeal — begge parter mottar signeringslenke på e-post",
        sv: "E-signering via DocuSeal — båda parter får en signeringslänk via e-post",
        da: "E-signering via DocuSeal — begge parter modtager signeringslink via e-mail",
        fi: "Sähköinen allekirjoitus DocuSealin kautta — molemmat osapuolet saavat allekirjoituslinkin sähköpostitse",
        de: "E-Signatur über DocuSeal — beide Partner erhalten einen Signierlink per E-Mail",
        fr: "Signature électronique via DocuSeal — les deux partenaires reçoivent un lien de signature par e-mail",
        es: "Firma electrónica a través de DocuSeal — ambos socios reciben un enlace de firma por correo") }

    var paywallFeature3: String { s(
        en: "Auto-detect changes and prompt for re-signing when assets or contributions change",
        nb: "Automatisk varsling om ny signering ved endringer i eiendeler eller bidrag",
        sv: "Automatisk uppmaning till omunderteckning när tillgångar eller bidrag ändras",
        da: "Automatisk opfordring til ny underskrift når aktiver eller bidrag ændres",
        fi: "Automaattinen uudelleenallekirjoituspyyntö, kun varat tai maksut muuttuvat",
        de: "Automatische Aufforderung zur erneuten Unterzeichnung bei Änderungen",
        fr: "Invitation automatique à signer à nouveau en cas de changement",
        es: "Aviso automático para volver a firmar cuando cambian los activos o aportaciones") }

    var paywallCTA: String { s(
        en: "Unlock formal agreement",
        nb: "Lås opp formell avtale",
        sv: "Lås upp formellt avtal",
        da: "Lås op for formel aftale",
        fi: "Avaa virallinen sopimus",
        de: "Formelle Vereinbarung freischalten",
        fr: "Débloquer l'accord formel",
        es: "Desbloquear acuerdo formal") }

    var paywallRestore: String { s(
        en: "Restore purchase",
        nb: "Gjenopprett kjøp",
        sv: "Återställ köp",
        da: "Gendan køb",
        fi: "Palauta ostos",
        de: "Kauf wiederherstellen",
        fr: "Restaurer l'achat",
        es: "Restaurar compra") }

    var paywallNote: String { s(
        en: "Not a substitute for legal advice. Consult a licensed attorney for significant property matters.",
        nb: "Erstatter ikke juridisk rådgivning. Kontakt advokat ved viktige eiendomsspørsmål.",
        sv: "Ersätter inte juridisk rådgivning. Kontakta en jurist vid viktiga fastighetsfrågor.",
        da: "Erstatter ikke juridisk rådgivning. Kontakt en advokat ved vigtige ejendomsspørgsmål.",
        fi: "Ei korvaa oikeudellisia neuvoja. Ota yhteys lakimieheen tärkeissä kiinteistöasioissa.",
        de: "Kein Ersatz für Rechtsberatung. Wenden Sie sich bei wichtigen Immobilienfragen an einen Anwalt.",
        fr: "Ne remplace pas un conseil juridique. Consultez un avocat pour les questions immobilières importantes.",
        es: "No sustituye el asesoramiento jurídico. Consulta a un abogado para asuntos inmobiliarios importantes.") }

    var paywallOneTime: String { s(
        en: "One-time purchase · No subscription",
        nb: "Engangsbetaling · Ingen abonnement",
        sv: "Engångsbetalning · Ingen prenumeration",
        da: "Engangsbetaling · Intet abonnement",
        fi: "Kertamaksu · Ei tilausta",
        de: "Einmalzahlung · Kein Abonnement",
        fr: "Achat unique · Sans abonnement",
        es: "Pago único · Sin suscripción") }

    var paywallLoading: String { s(en: "Loading…", nb: "Laster…", sv: "Laddar…", da: "Indlæser…", fi: "Ladataan…", de: "Wird geladen…", fr: "Chargement…", es: "Cargando…") }

    // MARK: Budget card

    var budgetByIncome: String    { s(en: "By income",       nb: "Etter inntekt",     sv: "Efter inkomst",      da: "Efter indkomst",    fi: "Tulojen mukaan",      de: "Nach Einkommen",     fr: "Par revenu",           es: "Por ingresos") }
    var budgetEqualLeft: String   { s(en: "Equal left over", nb: "Likt til overs",    sv: "Lika kvar",          da: "Lige til overs",    fi: "Tasan jäljellä",      de: "Gleich übrig",       fr: "Égal restant",         es: "Igual restante") }

    // MARK: Add asset — misc

    var sharedLabel: String       { s(en: "Shared",          nb: "Felles",            sv: "Gemensamt",          da: "Fælles",            fi: "Yhteinen",            de: "Geteilt",            fr: "Partagé",              es: "Compartido") }
    var settingUp: String         { s(en: "Setting up",      nb: "Sett opp",          sv: "Konfigurerar",       da: "Opsætter",          fi: "Määritetään",         de: "Einrichten",         fr: "Configuration",        es: "Configurando") }

    // MARK: Add asset — deposit label

    var depositDeposit: String    { s(en: "Deposit paid",    nb: "Innskudd betalt",   sv: "Insats betald",      da: "Indskud betalt",    fi: "Talletus maksettu",   de: "Anzahlung bezahlt",  fr: "Apport versé",         es: "Depósito pagado") }
    var depositPurchase: String   { s(en: "Purchase payment",nb: "Kjøpsbetaling",     sv: "Köpbetalning",       da: "Købbetaling",       fi: "Ostomaksu",           de: "Kaufzahlung",        fr: "Paiement d'achat",     es: "Pago de compra") }
    var depositGeneric: String    { s(en: "Contribution",    nb: "Bidrag",            sv: "Bidrag",             da: "Bidrag",            fi: "Maksu",               de: "Beitrag",            fr: "Contribution",         es: "Contribución") }

    // MARK: Add asset — contributions hint

    var contribInterestHint: String { s(
        en: "Contributions earn %@ p.a. interest and affect the equity calculation.",
        nb: "Bidragene forrentes med %@ p.a. og påvirker oppgjørsberegningen.",
        sv: "Bidragen ger %@ p.a. ränta och påverkar kapitalberäkningen.",
        da: "Bidragene forrentes med %@ p.a. og påvirker opgørelsesberegningen.",
        fi: "Maksuille kertyy %@ p.a. korkoa ja ne vaikuttavat oman pääoman laskentaan.",
        de: "Beiträge verzinsen sich mit %@ p.a. und beeinflussen die Eigenkapitalberechnung.",
        fr: "Les contributions rapportent %@ p.a. d'intérêts et affectent le calcul des capitaux propres.",
        es: "Las contribuciones devengan %@ anual de interés y afectan al cálculo del patrimonio.") }

    // MARK: Edit asset

    var fieldOptional: String     { s(en: "(optional)",      nb: "(valgfritt)",       sv: "(valfritt)",         da: "(valgfrit)",        fi: "(valinnainen)",       de: "(optional)",         fr: "(facultatif)",         es: "(opcional)") }

    // MARK: Contribution row

    var removeContrib: String     { s(en: "Remove contribution?", nb: "Fjerne bidrag?",   sv: "Ta bort bidrag?",    da: "Fjern bidrag?",     fi: "Poista maksu?",       de: "Beitrag entfernen?", fr: "Retirer la contribution?", es: "¿Eliminar contribución?") }
    var removeContribButton: String { s(en: "Remove",         nb: "Fjern bidrag",      sv: "Ta bort",            da: "Fjern",             fi: "Poista",              de: "Entfernen",          fr: "Retirer",              es: "Eliminar") }

    // MARK: Add contribution view — section headers

    var addContribWho: String     { s(en: "WHO CONTRIBUTED?",nb: "HVEM BIDRO?",       sv: "VEM BIDROG?",        da: "HVEM BIDROG?",      fi: "KUKA MAKSOI?",        de: "WER BEIGETRAGEN?",   fr: "QUI A CONTRIBUÉ?",     es: "¿QUIÉN CONTRIBUYÓ?") }
    var addContribAmountDate: String { s(en: "AMOUNT & DATE",nb: "BELØP OG DATO",     sv: "BELOPP OCH DATUM",   da: "BELØB OG DATO",     fi: "SUMMA JA PÄIVÄ",      de: "BETRAG & DATUM",     fr: "MONTANT & DATE",       es: "IMPORTE Y FECHA") }
    var addContribCategory: String { s(en: "CATEGORY",       nb: "KATEGORI",          sv: "KATEGORI",           da: "KATEGORI",          fi: "KATEGORIA",           de: "KATEGORIE",          fr: "CATÉGORIE",            es: "CATEGORÍA") }
    var addContribNote: String    { s(en: "NOTE (OPTIONAL)", nb: "MERKNAD (VALGFRITT)",sv: "ANTECKNING (VALFRITT)", da: "BEMÆRKNING (VALGFRIT)", fi: "HUOMIO (VALINNAINEN)", de: "HINWEIS (OPTIONAL)", fr: "NOTE (FACULTATIF)",   es: "NOTA (OPCIONAL)") }
    var addContribNotePlaceholder: String { s(en: "e.g. Kitchen renovation", nb: "F.eks. kjøkkenrenovering", sv: "T.ex. köksrenovering", da: "F.eks. køkkenrenovering", fi: "Esim. keittiöremontti", de: "z.B. Küchenrenovierung", fr: "p.ex. Rénovation cuisine", es: "p.ej. Renovación cocina") }

    // MARK: Add contribution view — categories

    var catDeposit: String        { s(en: "Deposit",         nb: "Innskudd",          sv: "Insättning",         da: "Indskud",           fi: "Talletus",            de: "Einlage",            fr: "Apport",               es: "Depósito") }
    var catExtraRepayment: String { s(en: "Extra repayment", nb: "Ekstra nedbetaling",sv: "Extra amortering",   da: "Ekstra afdrag",     fi: "Ylimääräinen maksu",  de: "Sondertilgung",      fr: "Remboursement extra",  es: "Pago extra") }
    var catRenovation: String     { s(en: "Renovation",      nb: "Oppussing",         sv: "Renovering",         da: "Renovering",        fi: "Remontti",            de: "Renovierung",        fr: "Rénovation",           es: "Renovación") }
    var catInheritance: String    { s(en: "Inheritance / gift", nb: "Arv / gave",     sv: "Arv / gåva",        da: "Arv / gave",        fi: "Perintö / lahja",     de: "Erbschaft / Schenkung", fr: "Héritage / don",    es: "Herencia / regalo") }
    var catOther: String          { s(en: "Other",           nb: "Annet",             sv: "Annat",              da: "Andet",             fi: "Muu",                 de: "Sonstiges",          fr: "Autre",                es: "Otro") }

    // MARK: Furniture list

    var furnSectionHeader: String   { s(en: "ITEMS",                        nb: "GJENSTANDER",               sv: "FÖREMÅL",                      da: "GENSTANDE",          fi: "ESINEET",             de: "GEGENSTÄNDE",        fr: "OBJETS",               es: "ARTÍCULOS") }
    var furnTotalValue: String      { s(en: "Estimated total value",         nb: "Estimert totalverdi",        sv: "Uppskattat totalvärde",         da: "Anslået totalværdi",  fi: "Arvioitu kokonaisarvo", de: "Geschätzter Gesamtwert", fr: "Valeur totale estimée", es: "Valor total estimado") }
    var furnNoItemsYet: String      { s(en: "No items yet",                  nb: "Ingen møbler ennå",          sv: "Inga föremål ännu",             da: "Ingen genstande endnu", fi: "Ei esineitä vielä",  de: "Noch keine Artikel",  fr: "Aucun article encore", es: "Sin artículos aún") }
    var furnNoItemsBody: String     { s(en: "Add furniture, appliances, and other items you own together.",
                                        nb: "Legg til møbler, hvitevarer og andre gjenstander dere eier sammen.",
                                        sv: "Lägg till möbler, vitvaror och andra föremål ni äger tillsammans.",
                                        da: "Tilføj møbler, hvidevarer og andre genstande I ejer sammen.",
                                        fi: "Lisää huonekaluja, kodinkoneita ja muita yhdessä omistamia esineitä.",
                                        de: "Fügen Sie Möbel, Geräte und andere gemeinsame Gegenstände hinzu.",
                                        fr: "Ajoutez des meubles, appareils et autres articles que vous possédez ensemble.",
                                        es: "Añade muebles, electrodomésticos y otros artículos que poseéis juntos.") }
    var furnAddItem: String         { s(en: "Add item",                      nb: "Legg til gjenstand",         sv: "Lägg till föremål",             da: "Tilføj genstand",     fi: "Lisää esine",         de: "Artikel hinzufügen",  fr: "Ajouter un article",   es: "Agregar artículo") }
    var furnEditItem: String        { s(en: "Edit item",                     nb: "Rediger gjenstand",          sv: "Redigera föremål",              da: "Rediger genstand",    fi: "Muokkaa esinettä",    de: "Artikel bearbeiten",  fr: "Modifier l'article",  es: "Editar artículo") }
    var furnItemSection: String     { s(en: "Item",                          nb: "Gjenstand",                  sv: "Föremål",                       da: "Genstand",            fi: "Esine",               de: "Artikel",             fr: "Article",              es: "Artículo") }
    var furnWhoOwns: String         { s(en: "Who owns it?",                  nb: "Hvem eier den?",             sv: "Vem äger den?",                 da: "Hvem ejer den?",      fi: "Kuka omistaa sen?",   de: "Wer besitzt es?",     fr: "Qui le possède?",      es: "¿Quién lo posee?") }
    var furnNamePlaceholder: String { s(en: "Name (e.g. IKEA sofa)",         nb: "Navn (f.eks. IKEA-sofa)",    sv: "Namn (t.ex. IKEA-soffa)",       da: "Navn (f.eks. IKEA-sofa)", fi: "Nimi (esim. IKEA-sohva)", de: "Name (z.B. IKEA-Sofa)", fr: "Nom (p.ex. canapé IKEA)", es: "Nombre (p.ej. sofá IKEA)") }
    var furnNameShort: String       { s(en: "Name",                          nb: "Navn",                       sv: "Namn",                          da: "Navn",                fi: "Nimi",                de: "Name",                fr: "Nom",                  es: "Nombre") }
    var furnValueOptional: String   { s(en: "Estimated value (optional)",    nb: "Estimert verdi (valgfritt)", sv: "Uppskattat värde (valfritt)",    da: "Anslået værdi (valgfrit)", fi: "Arvioitu arvo (valinnainen)", de: "Geschätzter Wert (optional)", fr: "Valeur estimée (facultatif)", es: "Valor estimado (opcional)") }
    var furnShared: String          { s(en: "Shared",                        nb: "Felles",                     sv: "Gemensam",                      da: "Fælles",              fi: "Yhteinen",            de: "Geteilt",             fr: "Partagé",              es: "Compartido") }

    // MARK: Contract preview

    var contractPreviewTitle: String    { s(en: "Preview",                   nb: "Forhåndsvisning",            sv: "Förhandsvisning",               da: "Forhåndsvisning",     fi: "Esikatselu",          de: "Vorschau",            fr: "Aperçu",               es: "Vista previa") }
    var contractClausesIncluded: String { s(en: "clauses included",          nb: "paragrafer inkludert",       sv: "klausuler inkluderade",         da: "klausuler inkluderet", fi: "lausekketta sisällytetty", de: "Klauseln enthalten", fr: "clauses incluses",    es: "cláusulas incluidas") }
    var contractDatedAtSigning: String  { s(en: "Dated at signing",          nb: "Datert ved signering",       sv: "Daterat vid signering",         da: "Dateret ved underskrift", fi: "Päivätty allekirjoitettaessa", de: "Bei Unterzeichnung datiert", fr: "Daté à la signature", es: "Fechado en la firma") }
    var contractHeaderTitle: String     { s(en: "Cohabitation Agreement",    nb: "Avtale om felles eierskap",  sv: "Samboavtal",                    da: "Samlivskontrakt",      fi: "Avoliittosopimus",    de: "Partnerschaftsvertrag", fr: "Convention de cohabitation", es: "Contrato de convivencia") }
    /// Use String(format: strings.contractBetween, nameA, nameB)
    var contractBetween: String         { s(en: "Between %@ and %@",         nb: "Mellom %@ og %@",            sv: "Mellan %@ och %@",              da: "Mellem %@ og %@",     fi: "Välillä %@ ja %@",    de: "Zwischen %@ und %@",  fr: "Entre %@ et %@",       es: "Entre %@ y %@") }

    // MARK: Agreement intro

    var back: String { s(en: "Back", nb: "Tilbake", sv: "Tillbaka", da: "Tilbage", fi: "Takaisin", de: "Zurück", fr: "Retour", es: "Atrás") }

    var introWhatTitle: String { s(
        en: "What is a Cohabitation Agreement?",
        nb: "Hva er en samboerkontrakt?",
        sv: "Vad är ett samboavtal?",
        da: "Hvad er en samlivskontrakt?",
        fi: "Mikä on avoliittosopimus?",
        de: "Was ist ein Partnerschaftsvertrag?",
        fr: "Qu'est-ce qu'une Convention de vie commune ?",
        es: "¿Qué es un acuerdo de convivencia?") }

    var introWhatBody: String { s(
        en: "A cohabitation agreement is a legal document that records what you own together, what each of you has contributed financially — and what happens to those assets if the relationship ends.",
        nb: "En samboerkontrakt er et juridisk dokument som beskriver hva dere eier i fellesskap, hva hver av dere har bidratt med — og hva som skjer med verdiene dersom dere går fra hverandre.",
        sv: "Ett samboavtal är ett juridiskt dokument som registrerar vad ni äger tillsammans, vad var och en av er har bidragit med ekonomiskt — och vad som händer med tillgångarna om förhållandet tar slut.",
        da: "En samlivskontrakt er et juridisk dokument der registrerer hvad I ejer sammen, hvad hver af jer har bidraget med — og hvad der sker med aktiverne hvis forholdet ophører.",
        fi: "Avoliittosopimus on oikeudellinen asiakirja, joka kirjaa mitä omistatte yhdessä, mitä kumpikin on maksanut — ja mitä tapahtuu varoille, jos suhde päättyy.",
        de: "Ein Partnerschaftsvertrag ist ein rechtliches Dokument, das festhält, was Sie gemeinsam besitzen, was jeder finanziell beigetragen hat — und was mit dem Vermögen passiert, wenn die Beziehung endet.",
        fr: "Un accord de cohabitation est un document juridique qui enregistre ce que vous possédez ensemble, ce que chacun a apporté financièrement — et ce qui arrive aux actifs si la relation prend fin.",
        es: "Un acuerdo de convivencia es un documento jurídico que registra lo que poseen juntos, lo que cada uno ha aportado económicamente — y lo que ocurre con los activos si la relación termina.") }

    var introLegalClarity: String { s(en: "Legal clarity", nb: "Rettssikkerhet", sv: "Juridisk klarhet", da: "Juridisk klarhed", fi: "Oikeudellinen selkeys", de: "Rechtliche Klarheit", fr: "Clarté juridique", es: "Claridad jurídica") }
    var introLegalClarityBody: String { s(
        en: "Both partners know exactly where they stand.",
        nb: "Begge vet hva de har krav på.",
        sv: "Båda vet exakt var de står.",
        da: "Begge ved præcis hvad de har krav på.",
        fi: "Molemmat osapuolet tietävät tarkalleen missä seisovat.",
        de: "Beide Partner wissen genau, woran sie sind.",
        fr: "Les deux partenaires savent exactement où ils en sont.",
        es: "Ambos socios saben exactamente dónde están.") }

    var introProtectionRow: String { s(en: "Protection", nb: "Beskyttelse", sv: "Skydd", da: "Beskyttelse", fi: "Suoja", de: "Schutz", fr: "Protection", es: "Protección") }
    var introProtectionBody: String { s(
        en: "Your contributions are documented and protected.",
        nb: "Bidragene dine er dokumentert og sikret.",
        sv: "Dina bidrag är dokumenterade och skyddade.",
        da: "Dine bidrag er dokumenterede og sikrede.",
        fi: "Maksusi on dokumentoitu ja suojattu.",
        de: "Ihre Beiträge sind dokumentiert und geschützt.",
        fr: "Vos contributions sont documentées et protégées.",
        es: "Sus aportaciones están documentadas y protegidas.") }

    var introAlwaysCurrent: String { s(en: "Always current", nb: "Alltid oppdatert", sv: "Alltid aktuellt", da: "Altid opdateret", fi: "Aina ajan tasalla", de: "Immer aktuell", fr: "Toujours à jour", es: "Siempre actualizado") }
    var introAlwaysCurrentBody: String { s(
        en: "Update whenever assets or contributions change.",
        nb: "Oppdater kontrakten når eiendeler eller bidrag endres.",
        sv: "Uppdatera när tillgångar eller bidrag förändras.",
        da: "Opdatér når aktiver eller bidrag ændres.",
        fi: "Päivitä kun varat tai maksut muuttuvat.",
        de: "Aktualisieren, wenn sich Vermögenswerte oder Beiträge ändern.",
        fr: "Mettez à jour dès que les actifs ou contributions changent.",
        es: "Actualice cuando cambien los activos o las aportaciones.") }

    var introWhatsIncluded: String { s(en: "What's included?", nb: "Hva er inkludert?", sv: "Vad ingår?", da: "Hvad er inkluderet?", fi: "Mitä sisältyy?", de: "Was ist enthalten?", fr: "Qu'est-ce qui est inclus?", es: "¿Qué se incluye?") }
    var introWhatsIncludedSub: String { s(
        en: "The agreement covers three core areas. You can customise each one.",
        nb: "Kontrakten dekker tre kjerneområder. Du kan tilpasse hver av dem.",
        sv: "Avtalet täcker tre kärnområden. Du kan anpassa vart och ett.",
        da: "Aftalen dækker tre kerneområder. Du kan tilpasse hvert af dem.",
        fi: "Sopimus kattaa kolme ydinosa-aluetta. Voit mukauttaa kutakin.",
        de: "Die Vereinbarung deckt drei Kernbereiche ab. Sie können jeden anpassen.",
        fr: "L'accord couvre trois domaines essentiels. Vous pouvez personnaliser chacun.",
        es: "El acuerdo cubre tres áreas esenciales. Puede personalizar cada una.") }

    var introSharedAssets: String { s(en: "Shared assets", nb: "Felles eiendeler", sv: "Gemensamma tillgångar", da: "Fælles aktiver", fi: "Yhteinen omaisuus", de: "Gemeinsame Vermögenswerte", fr: "Actifs communs", es: "Activos compartidos") }
    var introSharedAssetsBody: String { s(
        en: "Home, car, cabin, savings — everything you own together with value and ownership split.",
        nb: "Bolig, bil, hytte, sparing — alt dere eier i fellesskap med verdi og eierbrøk.",
        sv: "Bostad, bil, stuga, sparande — allt ni äger tillsammans med värde och ägarandel.",
        da: "Bolig, bil, sommerhus, opsparing — alt I ejer sammen med værdi og ejerandel.",
        fi: "Koti, auto, mökki, säästöt — kaikki mitä omistatte yhdessä arvo ja omistusosuus.",
        de: "Wohnung, Auto, Hütte, Ersparnisse — alles gemeinsam mit Wert und Eigentumsanteil.",
        fr: "Logement, voiture, chalet, épargne — tout ce que vous possédez ensemble avec valeur et quote-part.",
        es: "Vivienda, coche, cabaña, ahorros — todo lo que poseen juntos con valor y cuota de propiedad.") }

    var introFinancialContribs: String { s(en: "Financial contributions", nb: "Innbetalte bidrag", sv: "Ekonomiska bidrag", da: "Finansielle bidrag", fi: "Taloudelliset maksut", de: "Finanzielle Beiträge", fr: "Contributions financières", es: "Aportaciones financieras") }
    var introFinancialContribsBody: String { s(
        en: "Deposits, renovations, extra payments — what each of you has put in.",
        nb: "Innskudd, oppussing, ekstra nedbetalinger — hva hver av dere har betalt inn.",
        sv: "Insättningar, renoveringar, extra betalningar — vad var och en av er har bidragit med.",
        da: "Indskud, renoveringer, ekstra betalinger — hvad hver af jer har betalt.",
        fi: "Talletukset, remontit, ylimääräiset maksut — mitä kukin on maksanut.",
        de: "Einlagen, Renovierungen, Extrazahlungen — was jeder von Ihnen eingebracht hat.",
        fr: "Dépôts, rénovations, paiements supplémentaires — ce que chacun a apporté.",
        es: "Depósitos, reformas, pagos extra — lo que cada uno ha aportado.") }

    var introDissolutionTerms: String { s(en: "Dissolution terms", nb: "Oppgjørsvilkår", sv: "Upplösningsvillkor", da: "Opløsningsvilkår", fi: "Purkamisehdot", de: "Auflösungsbedingungen", fr: "Conditions de dissolution", es: "Condiciones de disolución") }
    var introDissolutionTermsBody: String { s(
        en: "How assets are divided if the relationship ends.",
        nb: "Hva som skjer med verdiene dersom dere avslutter samboerforholdet.",
        sv: "Hur tillgångarna fördelas om förhållandet tar slut.",
        da: "Hvad der sker med aktiverne hvis forholdet ophører.",
        fi: "Miten varat jaetaan, jos suhde päättyy.",
        de: "Wie Vermögenswerte aufgeteilt werden, wenn die Beziehung endet.",
        fr: "Comment les actifs sont répartis si la relation prend fin.",
        es: "Cómo se dividen los activos si la relación termina.") }

    var introHowSettlementWorks: String { s(en: "How settlement works", nb: "Slik fungerer oppgjøret", sv: "Hur uppgörelsen fungerar", da: "Sådan fungerer opgørelsen", fi: "Miten selvitys toimii", de: "Wie die Abrechnung funktioniert", fr: "Comment fonctionne le règlement", es: "Cómo funciona el reparto") }
    var introHowSettlementSub: String { s(
        en: "If you sell or divide a shared asset, this order applies.",
        nb: "Dersom dere selger et felles aktiv, gjelder denne rekkefølgen.",
        sv: "Om ni säljer eller delar en gemensam tillgång gäller denna ordning.",
        da: "Hvis I sælger eller deler et fælles aktiv, gælder denne rækkefølge.",
        fi: "Jos myyt tai jaat yhteisen omaisuuden, tätä järjestystä sovelletaan.",
        de: "Beim Verkauf oder der Aufteilung eines gemeinsamen Vermögenswerts gilt diese Reihenfolge.",
        fr: "Si vous vendez ou divisez un actif commun, cet ordre s'applique.",
        es: "Si vendéis o dividís un activo compartido, se aplica este orden.") }

    var introSigningNote: String { s(
        en: "Both partners sign digitally via email. Links are sent automatically after generation.",
        nb: "Begge parter signerer digitalt via e-post. Lenker sendes automatisk etter generering.",
        sv: "Båda parter signerar digitalt via e-post. Länkar skickas automatiskt efter generering.",
        da: "Begge parter underskriver digitalt via e-mail. Links sendes automatisk efter generering.",
        fi: "Molemmat osapuolet allekirjoittavat digitaalisesti sähköpostitse. Linkit lähetetään automaattisesti luomisen jälkeen.",
        de: "Beide Partner unterzeichnen digital per E-Mail. Links werden nach der Erstellung automatisch gesendet.",
        fr: "Les deux partenaires signent numériquement par e-mail. Les liens sont envoyés automatiquement après génération.",
        es: "Ambos socios firman digitalmente por correo. Los enlaces se envían automáticamente tras la generación.") }

    // MARK: Helper

    private func s(en: String, nb: String, sv: String = "", da: String = "", fi: String = "", de: String = "", fr: String = "", es: String = "") -> String {
        switch language {
        case .en: return en
        case .nb: return nb
        case .sv: return sv.isEmpty ? en : sv
        case .da: return da.isEmpty ? en : da
        case .fi: return fi.isEmpty ? en : fi
        case .de: return de.isEmpty ? en : de
        case .fr: return fr.isEmpty ? en : fr
        case .es: return es.isEmpty ? en : es
        }
    }
}
