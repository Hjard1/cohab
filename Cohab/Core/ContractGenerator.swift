import UIKit
import Foundation

/// Marks sections whose body can be partially revealed as a teaser
/// (first asset / first contribution) in the unpaid in-app preview.
enum ContractSectionKind {
    case plain
    case assets
    case contributions
}

enum ContractGenerator {

    struct Output {
        let pdfData: Data
        /// Fractional Y (0–1) of the signature line, measured from top of page.
        let sigYFraction: Double
        /// 0-indexed page number (DocuSeal: page 0 = first page).
        let sigPage: Int
    }

    // Reference type so mutations inside the @escaping pdfData closure are visible outside.
    private final class Layout {
        var sigY: CGFloat = 700
        var sigPage: Int = 0      // 0-indexed
        var currentPage: Int = 0  // 0-indexed, incremented on ctx.beginPage()
    }

    static func generate(household: Household, date: Date = Date(), templates: [String: ContractTemplate] = [:]) -> Output {
        let pageSize = CGSize(width: 595, height: 842)   // A4 @ 72 dpi
        let margin: CGFloat = 56
        let contentW = pageSize.width - margin * 2
        let layout = Layout()

        let pdfData = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize)
        ).pdfData { ctx in

            let isNO = isNorwegian(household)
            let isUSA = isUS(household)
            let isDe = isGerman(household)
            let isFr = isFrench(household)
            let isEs = isSpanish(household)
            let docLocale: Locale
            if isNO { docLocale = Locale(identifier: "nb_NO") }
            else if isSwedish(household) { docLocale = Locale(identifier: "sv_SE") }
            else if isDanish(household)  { docLocale = Locale(identifier: "da_DK") }
            else if isFinnish(household) { docLocale = Locale(identifier: "fi_FI") }
            else if isDe { docLocale = Locale(identifier: "de_DE") }
            else if isFr { docLocale = Locale(identifier: "fr_FR") }
            else if isEs { docLocale = Locale(identifier: "es_ES") }
            else if isUSA { docLocale = Locale(identifier: "en_US") }
            else { docLocale = Locale(identifier: "en_GB") }

            func newPage() {
                ctx.beginPage()
                layout.currentPage += 1
            }

            newPage()
            var y: CGFloat = 0

            // ── Header band ──────────────────────────────────────────────────
            let headerH: CGFloat = 52
            UIColor(red: 0.10, green: 0.68, blue: 0.45, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageSize.width, height: headerH)).fill()

            let brandAttrs: Attrs = [.font: UIFont.systemFont(ofSize: 14, weight: .bold),
                                     .foregroundColor: UIColor.white, .kern: 3.0]
            let subtitleAttrs: Attrs = [.font: UIFont.systemFont(ofSize: 10),
                                        .foregroundColor: UIColor.white.withAlphaComponent(0.85)]
            "cohab".draw(at: CGPoint(x: margin, y: 18), withAttributes: brandAttrs)
            let rightTitle: String
            if isNO          { rightTitle = "Samboerkontrakt" }
            else if isSwedish(household) { rightTitle = "Samboavtal" }
            else if isDanish(household)  { rightTitle = "Samlivskontrakt" }
            else if isFinnish(household) { rightTitle = "Avoliittosopimus" }
            else if isGerman(household)  { rightTitle = "Partnerschaftsvertrag" }
            else if isFrench(household)  { rightTitle = "Convention de vie commune" }
            else if isSpanish(household) { rightTitle = "Contrato de convivencia" }
            else             { rightTitle = "Cohabitation Agreement" }
            let rSize = (rightTitle as NSString).size(withAttributes: subtitleAttrs)
            rightTitle.draw(at: CGPoint(x: pageSize.width - margin - rSize.width, y: 20),
                            withAttributes: subtitleAttrs)
            y = headerH + 24

            // ── Parties & date ───────────────────────────────────────────────
            let df = DateFormatter()
            df.dateStyle = .long; df.timeStyle = .none; df.locale = docLocale
            let dateStr = df.string(from: date)
            let smallAttrs: Attrs = [.font: UIFont.systemFont(ofSize: 11),
                                     .foregroundColor: UIColor(white: 0.25, alpha: 1)]
            let tinyAttrs: Attrs  = [.font: UIFont.systemFont(ofSize: 9),
                                     .foregroundColor: UIColor(white: 0.5, alpha: 1)]
            let partiesLine: String
            if isNO {
                partiesLine = "Mellom \(household.partnerAName) og \(household.partnerBName)  ·  Datert \(dateStr)"
            } else if isSwedish(household) {
                partiesLine = "Mellan \(household.partnerAName) och \(household.partnerBName)  ·  Daterad \(dateStr)"
            } else if isFinnish(household) {
                partiesLine = "Välillä \(household.partnerAName) ja \(household.partnerBName)  ·  Päivätty \(dateStr)"
            } else if isDe {
                partiesLine = "Zwischen \(household.partnerAName) und \(household.partnerBName)  ·  Datiert \(dateStr)"
            } else if isFr {
                partiesLine = "Entre \(household.partnerAName) et \(household.partnerBName)  ·  Daté du \(dateStr)"
            } else if isEs {
                partiesLine = "Entre \(household.partnerAName) y \(household.partnerBName)  ·  Fechado \(dateStr)"
            } else {
                partiesLine = "Between \(household.partnerAName) and \(household.partnerBName)  ·  Dated \(dateStr)"
            }
            partiesLine.draw(at: CGPoint(x: margin, y: y), withAttributes: smallAttrs)
            y += 18
            if !household.emailA.isEmpty || !household.emailB.isEmpty {
                "\(household.partnerAName): \(household.emailA)   \(household.partnerBName): \(household.emailB)"
                    .draw(at: CGPoint(x: margin, y: y), withAttributes: tinyAttrs)
                y += 14
            }
            y += 6
            hRule(at: y, margin: margin, pageW: pageSize.width)
            y += 14

            // ── Sections ─────────────────────────────────────────────────────
            let sectionTitleAttrs: Attrs = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor(red: 0.10, green: 0.68, blue: 0.45, alpha: 1)]
            let bodyStyle = NSMutableParagraphStyle()
            bodyStyle.lineSpacing = 2.5
            let bodyAttrs: Attrs = [
                .font: UIFont.systemFont(ofSize: 10.5),
                .foregroundColor: UIColor(white: 0.18, alpha: 1),
                .paragraphStyle: bodyStyle]

            for section in buildSections(household: household, templates: templates) {
                if y > pageSize.height - 160 { newPage(); y = 40 }
                section.title.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitleAttrs)
                y += 16
                let attributed = NSAttributedString(string: section.body, attributes: bodyAttrs)
                let h = attributed.boundingRect(
                    with: CGSize(width: contentW, height: 4000),
                    options: .usesLineFragmentOrigin, context: nil).height
                attributed.draw(in: CGRect(x: margin, y: y, width: contentW, height: h))
                y += h + 20
            }

            // ── Signature block ──────────────────────────────────────────────
            // Leave at least 140 pt for signatures; start new page if needed.
            if y > pageSize.height - 140 { newPage(); y = 40 }
            y += 10
            hRule(at: y, margin: margin, pageW: pageSize.width)
            y += 16

            let sigHeaderAttrs: Attrs = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor(red: 0.10, green: 0.68, blue: 0.45, alpha: 1),
                .kern: 1.0]
            let sigHeader: String
            if isNO { sigHeader = "UNDERSKRIFTER" }
            else if isSwedish(household) { sigHeader = "UNDERSKRIFTER" }
            else if isFinnish(household) { sigHeader = "ALLEKIRJOITUKSET" }
            else if isDe { sigHeader = "UNTERSCHRIFTEN" }
            else if isEs { sigHeader = "FIRMAS" }
            else { sigHeader = "SIGNATURES" }
            sigHeader.draw(at: CGPoint(x: margin, y: y), withAttributes: sigHeaderAttrs)
            y += 22

            // Record signature position BEFORE drawing (this is where DocuSeal fields go).
            // DocuSeal expects 0-indexed pages (0 = first page).
            layout.sigY    = y
            layout.sigPage = layout.currentPage   // 0-indexed

            let nameAttrs: Attrs = [.font: UIFont.systemFont(ofSize: 11, weight: .medium),
                                    .foregroundColor: UIColor(white: 0.18, alpha: 1)]
            let captionAttrs: Attrs = [.font: UIFont.systemFont(ofSize: 8.5),
                                       .foregroundColor: UIColor(white: 0.5, alpha: 1)]
            let midX   = pageSize.width / 2
            let lineY  = y + 44
            let signatureLabel: String
            if isNO { signatureLabel = "Underskrift" }
            else if isSwedish(household) { signatureLabel = "Underskrift" }
            else if isFinnish(household) { signatureLabel = "Allekirjoitus" }
            else if isDe { signatureLabel = "Unterschrift" }
            else if isEs { signatureLabel = "Firma" }
            else { signatureLabel = "Signature" }

            household.partnerAName.draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttrs)
            signLine(from: CGPoint(x: margin, y: lineY), to: CGPoint(x: midX - 24, y: lineY))
            signatureLabel.draw(at: CGPoint(x: margin, y: lineY + 5), withAttributes: captionAttrs)
            if !household.emailA.isEmpty {
                household.emailA.draw(at: CGPoint(x: margin, y: lineY + 15), withAttributes: captionAttrs)
            }

            household.partnerBName.draw(at: CGPoint(x: midX + 16, y: y), withAttributes: nameAttrs)
            signLine(from: CGPoint(x: midX + 16, y: lineY), to: CGPoint(x: pageSize.width - margin, y: lineY))
            signatureLabel.draw(at: CGPoint(x: midX + 16, y: lineY + 5), withAttributes: captionAttrs)
            if !household.emailB.isEmpty {
                household.emailB.draw(at: CGPoint(x: midX + 16, y: lineY + 15), withAttributes: captionAttrs)
            }

            // Footer — disclaimer + branding
            // Language-explicit lookup — mutating AppStrings.shared.language
            // mid-render would crash SwiftUI (see buildSections note).
            let footerText = AppStrings.pick(AppLanguage.from(country: household.country),
                en: "cohab is not a law firm. This is a template — not legal advice. Enforceability of cohabitation agreements varies by jurisdiction. Consult a licensed attorney for significant legal matters.",
                nb: "cohab er ikke et advokatfirma. Dette er en standardisert mal. Elektronisk signering er ikke bindende i alle jurisdiksjoner. Kontakt advokat ved viktige juridiske spørsmål.",
                sv: "cohab är inte en advokatbyrå. Detta är en standardiserad mall. Elektronisk signering är inte bindande i alla jurisdiktioner. Kontakta en advokat vid viktiga juridiska frågor.",
                da: "cohab er ikke et advokatfirma. Dette er en standardiseret skabelon. Elektronisk signering er ikke bindende i alle jurisdiktioner. Kontakt en advokat ved vigtige juridiske spørgsmål.",
                fi: "cohab ei ole lakiasiaintoimisto. Tämä on malli — ei oikeudellinen neuvo. Ota yhteys lakimieheen tärkeissä kiinteistöasioissa.",
                de: "cohab ist keine Anwaltskanzlei. Dies ist eine Vorlage — keine Rechtsberatung. Wenden Sie sich bei wichtigen Rechtsfragen an einen Anwalt.",
                fr: "cohab n'est pas un cabinet d'avocats. Il s'agit d'un modèle — pas d'un conseil juridique. Consultez un avocat pour les questions juridiques importantes.",
                es: "cohab no es un despacho de abogados. Esto es una plantilla — no asesoramiento jurídico. Consulta a un abogado para asuntos jurídicos importantes.")
            let _: Attrs = [.font: UIFont.systemFont(ofSize: 7.5),
                                      .foregroundColor: UIColor(white: 0.55, alpha: 1)]
            let footerStyle = NSMutableParagraphStyle()
            footerStyle.lineSpacing = 1.5
            let footerAttrsFull: Attrs = [.font: UIFont.systemFont(ofSize: 7.5),
                                          .foregroundColor: UIColor(white: 0.55, alpha: 1),
                                          .paragraphStyle: footerStyle]
            let footerStr = NSAttributedString(string: footerText, attributes: footerAttrsFull)
            let footerBound = footerStr.boundingRect(
                with: CGSize(width: contentW, height: 40),
                options: .usesLineFragmentOrigin, context: nil)
            let footerY = pageSize.height - 12 - footerBound.height
            footerStr.draw(in: CGRect(x: margin, y: footerY, width: contentW, height: footerBound.height))

            // cohab branding (right-aligned)
            let brandFooter = "Generated by cohab"
            let brandAttrsF: Attrs = [.font: UIFont.systemFont(ofSize: 7.5),
                                       .foregroundColor: UIColor(red: 0.10, green: 0.68, blue: 0.45, alpha: 1)]
            let brandSize = (brandFooter as NSString).size(withAttributes: brandAttrsF)
            brandFooter.draw(
                at: CGPoint(x: pageSize.width - margin - brandSize.width, y: pageSize.height - 14),
                withAttributes: brandAttrsF)
        }

        // Convert UIKit sigY (from top) to fraction — DocuSeal accepts absolute pts
        // but divides internally by page height. We pass the fraction directly to
        // avoid any conversion ambiguity (confirmed via API inspection).
        let sigYFraction = Double(layout.sigY) / 842.0

        return Output(pdfData: pdfData, sigYFraction: sigYFraction, sigPage: layout.sigPage)
    }

    // MARK: - Sections

    // MARK: - Language helpers

    private static func isNorwegian(_ h: Household) -> Bool { h.country == "NO" }
    private static func isSwedish(_ h: Household) -> Bool { h.country == "SE" }
    private static func isDanish(_ h: Household) -> Bool { h.country == "DK" }
    private static func isFinnish(_ h: Household) -> Bool { h.country == "FI" }
    private static func isGerman(_ h: Household) -> Bool { ["DE","AT"].contains(h.country) }
    private static func isFrench(_ h: Household) -> Bool { h.country == "FR" }
    private static func isSpanish(_ h: Household) -> Bool { h.country == "ES" }
    private static func isUS(_ h: Household) -> Bool { h.country == "US" }
    private static func isGB(_ h: Household) -> Bool { h.country == "GB" }
    private static func isAU(_ h: Household) -> Bool { h.country == "AU" }
    private static func isCA(_ h: Household) -> Bool { h.country == "CA" }
    private static func isNZ(_ h: Household) -> Bool { h.country == "NZ" }
    private static func isIE(_ h: Household) -> Bool { h.country == "IE" }

    // Returns the name of the relevant land/property registry for a given country
    private static func landRegistry(_ h: Household) -> String {
        switch h.country {
        case "GB": return "HM Land Registry"
        case "SE": return "Lantmäteriet"
        case "DA", "DK": return "Tinglysning"
        case "FI": return "Maanmittauslaitos"
        case "DE", "AT", "CH": return "Grundbuch"
        case "FR": return "acte notarié"
        case "ES": return "Registro de la Propiedad"
        case "AU": return "Land Titles Office"
        case "CA": return "Land Titles Office"
        case "NZ": return "Land Information New Zealand (LINZ)"
        case "IE": return "Property Registration Authority"
        case "NL": return "Kadaster"
        case "IS": return "Þinglýsing"
        default: return "land registry"
        }
    }

    /// Formats an annual rate (0.045) as a clean percentage string ("4.5%"),
    /// trimming trailing zeros — never rounding to a whole number, so the signed
    /// contract states exactly the rate the settlement engine uses.
    private static func formatRate(_ rate: Double, norwegian: Bool = false, swedish: Bool = false) -> String {
        let pct = rate * 100
        var s = String(format: "%.2f", pct)
        if s.contains(".") {
            while s.hasSuffix("0") { s.removeLast() }
            if s.hasSuffix(".") { s.removeLast() }
        }
        // Norwegian/Swedish convention: decimal comma and a space before the percent sign.
        if norwegian || swedish { return s.replacingOccurrences(of: ".", with: ",") + " %" }
        return s + "%"
    }

    // "1st", "2nd", "3rd", "4th"... for English day-of-month phrasing.
    private static func ordinalSuffix(_ n: Int) -> String {
        switch (n % 100, n % 10) {
        case (11, _), (12, _), (13, _): return "th"
        case (_, 1): return "st"
        case (_, 2): return "nd"
        case (_, 3): return "rd"
        default: return "th"
        }
    }

    // Returns text for a given field. Only NO is fully localised from Samboappen source.
    private static func t(_ h: Household, no: String, sv: String = "", da: String = "", fi: String = "", de: String = "", fr: String = "", es: String = "", en: String) -> String {
        if isNorwegian(h) { return no }
        if isSwedish(h)   { return sv.isEmpty ? en : sv }
        if isDanish(h)    { return da.isEmpty ? en : da }
        if isFinnish(h)   { return fi.isEmpty ? en : fi }
        if isGerman(h)    { return de.isEmpty ? en : de }
        if isFrench(h)    { return fr.isEmpty ? en : fr }
        if isSpanish(h)   { return es.isEmpty ? en : es }
        return en
    }

    /// Language code ("nb", "sv", "da", "fi", "de", "fr", "es", "en") the
    /// document renders in — the same selection logic buildSections uses
    /// (docLang = AppLanguage.from(country:)), so callers fetch templates
    /// for exactly the language the document is generated in.
    static func docLanguageCode(household: Household) -> String {
        AppLanguage.from(country: household.country).rawValue
    }

    /// Template body with each {{token}} replaced; falls back to the bundled
    /// string when the clause key is absent from the fetched map.
    private static func tpl(_ templates: [String: ContractTemplate], _ key: String,
                            tokens: [String: String] = [:], fallback: () -> String) -> String {
        guard let body = templates[key]?.body, !body.isEmpty else { return fallback() }
        var result = body
        for (token, value) in tokens {
            result = result.replacingOccurrences(of: "{{\(token)}}", with: value)
        }
        return result
    }

    /// Template title when present and non-empty, else nil — callers fall
    /// back to the bundled inline title.
    private static func tplTitle(_ templates: [String: ContractTemplate], _ key: String) -> String? {
        guard let title = templates[key]?.title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else { return nil }
        return title
    }

    /// Public access to clause sections for in-app preview.
    static func previewSections(household: Household, templates: [String: ContractTemplate] = [:]) -> [(title: String, body: String, kind: ContractSectionKind)] {
        buildSections(household: household, templates: templates)
    }

    private static func buildSections(household: Household, templates: [String: ContractTemplate] = [:]) -> [(title: String, body: String, kind: ContractSectionKind)] {
        // Document-language lookups go through explicit-language helpers
        // (AppStrings.pick / secondaryLabel(in:)) — mutating the shared
        // AppStrings language here would crash SwiftUI previews.
        let docLang = AppLanguage.from(country: household.country)
        let isRental = household.agreementType == "rental"
        let isNO = isNorwegian(household)
        let isSV = isSwedish(household)
        let isDA = isDanish(household)
        let isFI = isFinnish(household)
        let isDe = isGerman(household)
        let isFr = isFrench(household)
        let isEs = isSpanish(household)
        // Print the exact rate (e.g. "4,5 %"), not a rounded integer — the signed
        // document must state the same rate the settlement engine actually uses.
        let rateStr = formatRate(household.annualInterestRate, norwegian: isNO, swedish: isSV)
        let docLocale: Locale
        if isNO { docLocale = Locale(identifier: "nb_NO") }
        else if isSV { docLocale = Locale(identifier: "sv_SE") }
        else if isDA { docLocale = Locale(identifier: "da_DK") }
        else if isFI { docLocale = Locale(identifier: "fi_FI") }
        else if isDe { docLocale = Locale(identifier: "de_DE") }
        else if isFr { docLocale = Locale(identifier: "fr_FR") }
        else if isEs { docLocale = Locale(identifier: "es_ES") }
        else if isUS(household) { docLocale = Locale(identifier: "en_US") }
        else { docLocale = Locale(identifier: "en_GB") }
        /// Money formatted in the document's own locale ("kr 2 500 000" for
        /// Norwegian), independent of the device locale.
        let money: (Double) -> String = { v in
            "\(household.currencySymbol)\(Int(v).formatted(.number.locale(docLocale)))"
        }
        // Disambiguated asset names, shared by the assets and contributions sections.
        let assetNames = assetDisplayNames(household: household)
        var n = 1
        var sections: [(title: String, body: String, kind: ContractSectionKind)] = []

        // § 1 SCOPE
        sections.append(("\(n).  \(tplTitle(templates, "purpose") ?? t(household, no: "AVTALENS FORMÅL", sv: "AVTALETS ÄNDAMÅL", da: "AFTALENS FORMÅL", fi: "SOPIMUKSEN TARKOITUS", de: "VERTRAGSZWECK", fr: "OBJET DE LA CONVENTION", es: "OBJETO DEL CONTRATO", en: "PURPOSE"))", {
            n += 1
            let reg = landRegistry(household)
            // Optional dissolution sentence — separately template-overridable.
            let dissolution: String
            if household.includeDissolutionClause {
                dissolution = tpl(templates, "purpose_dissolution") {
                    t(household,
                      no: " Den fastsetter også hvordan verdier fordeles dersom samlivet opphører.",
                      sv: " Det fastställer också hur tillgångar fördelas om samboförhållandet upphör.",
                      da: " Det fastslår også, hvordan aktiver fordeles, hvis samlivsforholdet ophører.",
                      fi: " Se määrittelee myös, miten varat jaetaan, jos avoliitto päättyy.",
                      de: " Er legt außerdem fest, wie das Vermögen bei Auflösung der Partnerschaft aufgeteilt wird.",
                      fr: " Elle définit également la répartition des actifs en cas de dissolution de l'union.",
                      es: " También establece cómo se dividen los activos si la relación termina.",
                      en: " It also sets out how assets are divided if the arrangement ends.")
                }
            } else {
                dissolution = ""
            }
            // English US-specific variant — no template; kept purely inline.
            if isUS(household) {
                return "This agreement confirms the ownership shares the parties have agreed between themselves in their shared assets, and documents what each has contributed financially.\(dissolution) This agreement does not by itself create, vary or transfer any interest in real property; for shares in real estate to bind third parties, they should also be reflected in the recorded deed. The parties intend this agreement to be legally binding. Both parties agree to keep records up to date."
            }
            return tpl(templates, "purpose", tokens: ["registry": reg, "dissolution": dissolution]) {
                if isNO {
                    return "Denne avtalen bekrefter partenes registrerte eierbrøk i felles eiendeler og dokumenterer hva hver av dem har betalt inn.\(dissolution) Avtalen oppretter ingen nye eiendomsrettigheter — den gjentar og bekrefter det som allerede er tinglyst. Partene forplikter seg til å holde oversikten oppdatert."
                } else if isSV {
                    return "Detta avtal bekräftar parternas registrerade ägarandel i gemensamma tillgångar och dokumenterar vad var och en har betalat in.\(dissolution) Avtalet skapar inga nya äganderätter — det återger och bekräftar de ägarandelar parterna har uppgett. Parterna förbinder sig att vid behov uppdatera uppgifterna genom ett nytt eller ändrat avtal som undertecknas av båda."
                } else if isDA {
                    return "Denne aftale bekræfter parternes tinglyste ejerandel i fælles aktiver og dokumenterer, hvad den enkelte har indbetalt.\(dissolution) Aftalen skaber ingen nye ejendomsrettigheder — den gentager og bekræfter det, der allerede er registreret via \(reg). Parterne forpligter sig til at holde oplysningerne opdaterede."
                } else if isFI {
                    return "Tämä sopimus vahvistaa osapuolten rekisteröidyn omistusosuuden yhteisiin varoihin ja dokumentoi kummankin maksamat panokset.\(dissolution) Sopimus ei luo uusia omistusoikeuksia — se toistaa ja vahvistaa \(reg):ssa rekisteröidyn omistuksen. Osapuolet sitoutuvat pitämään tiedot ajan tasalla."
                } else if isDe {
                    return "Dieser Vertrag bestätigt die im \(reg) eingetragenen Eigentumsanteile der Parteien am gemeinsamen Vermögen und dokumentiert die jeweiligen Einzahlungen.\(dissolution) Er begründet keine neuen Eigentumsrechte — er gibt die bestehende Eintragung wieder. Die Parteien verpflichten sich, die Angaben stets aktuell zu halten."
                } else if isFr {
                    return "La présente convention confirme les quotes-parts de propriété existantes des parties dans les actifs communs, telles qu'établies par \(reg), et documente les apports financiers de chacune.\(dissolution) Elle ne crée ni ne transfère aucun droit de propriété — elle en atteste l'existence. Les parties s'engagent à tenir les informations à jour."
                } else if isEs {
                    return "Este contrato confirma las cuotas de propiedad registradas de las partes en los activos compartidos, según constan en el \(reg), y documenta las aportaciones económicas de cada una.\(dissolution) No crea ni transfiere ningún derecho de propiedad — se limita a confirmar el registro existente. Las partes se comprometen a mantener la información actualizada."
                } else {
                    // English (non-US)
                    return "This agreement confirms the ownership shares the parties have agreed between themselves in their shared assets, and documents what each has contributed financially.\(dissolution) This agreement does not by itself create, vary or transfer any interest in property; for shares in a home to bind third parties, they should also be recorded in a declaration of trust. The parties intend this agreement to be legally binding. Both parties agree to keep records up to date."
                }
            }
        }(), .plain))

        // § SAMBOLAGEN — Swedish only. Without an explicit written opt-out, the
        // Cohabitation Act's equal-division rules (bodelning) would apply to the
        // shared home and household goods regardless of registered shares — which
        // would override this agreement's distribution model. 9 § sambolagen
        // allows the parties to agree otherwise in writing; this signed document
        // is that agreement.
        if isSV {
            sections.append(("\(n).  \(tplTitle(templates, "sambolagen") ?? "SAMBOLAGEN (2003:376)")", {
                n += 1
                return tpl(templates, "sambolagen") {
                    "Parterna är överens om att bodelning enligt sambolagen (2003:376) inte ska ske. För de tillgångar som anges i detta avtal gäller dessutom den ekonomiska fördelningsmodell som parterna har kommit överens om nedan."
                }
            }(), .plain))
        }

        // § SEPARATE PROPERTY — Samboappen § 2 (optional advanced; presumes co-owned property)
        if household.includeSeparatePropertyClause && !isRental {
            sections.append(("\(n).  \(tplTitle(templates, "separate_property") ?? t(household, no: "SÆREIE OG ENEEIE", sv: "ENSKILD EGENDOM", da: "SÆREJE", fi: "OMA OMAISUUS", de: "EIGENES VERMÖGEN", fr: "PROPRIÉTÉ PERSONNELLE", es: "PROPIEDAD INDIVIDUAL", en: "SEPARATE PROPERTY"))", {
                n += 1
                return tpl(templates, "separate_property") {
                    if isNO {
                        return "Det hver av oss tok med inn i samboerforholdet, er den enkeltes eneeie. Midler eller gjenstander hver av oss mottar som gave eller arv, er også den enkeltes eneeie.\n\nEiendeler anskaffet underveis i samlivet tilhører den part som anskaffet dem. Partene oppfordres til å registrere eiendeler i cohab — både personlig eneeie og felles eie. Den sist signerte versjonen av denne avtalen har forrang ved eventuell uenighet."
                    } else if isSV {
                        return "Det var och en av oss hade med oss in i samboförhållandet är den enskildes egendom. Tillgångar som mottagits som gåva eller arv under samboförhållandet är också den enskildes egendom.\n\nTillgångar som förvärvats gemensamt ägs i de andelar som registrerats i cohab. Parterna uppmanas att hålla uppgifterna uppdaterade. Den senast undertecknade versionen av detta avtal har företräde vid eventuell oenighet."
                    } else if isDA {
                        return "Hvad vi hver især bragte med ind i samlivsforholdet, er den enkeltes ejendom. Aktiver modtaget som gave eller arv under samlivsforholdet er ligeledes den enkeltes ejendom.\n\nAktiver erhvervet i fællesskab ejes i de andele, der er registreret i cohab. Parterne opfordres til at holde oplysningerne opdaterede. Den sidst underskrevne version af denne aftale har forrang ved eventuell uenighed."
                    } else if isFI {
                        return "Kumpikin osapuoli omistaa yksin sen omaisuuden, jonka hän toi avoliittoon, sekä lahjaksi tai perinnöksi saamansa omaisuuden.\n\nYhdessä hankittu omaisuus kuuluu osapuolille cohab-sovellukseen rekisteröityjen omistusosuuksien mukaisesti. Osapuolia kannustetaan pitämään tiedot ajan tasalla. Viimeksi allekirjoitettu versio tästä sopimuksesta on ensisijainen ristiriitatilanteessa."
                    } else if isDe {
                        return "Jeder Vertragspartner behält das Alleineigentum an dem Vermögen, das er in die Partnerschaft eingebracht hat, sowie an Vermögen, das er als Geschenk oder Erbschaft erhalten hat.\n\nGemeinsam erworbenes Vermögen wird in den in cohab eingetragenen Anteilen gehalten. Die Parteien sind angehalten, die Angaben aktuell zu halten. Die zuletzt unterzeichnete Version dieses Vertrags hat bei Unstimmigkeiten Vorrang."
                    } else if isFr {
                        return "Chaque partie conserve la propriété exclusive des biens qu'elle a apportés à l'union libre, ainsi que des biens reçus en donation ou par succession.\n\nLes biens acquis en commun sont détenus selon les quotes-parts enregistrées dans cohab. Les parties sont encouragées à maintenir les informations à jour. La version du présent accord signée en dernier lieu prévaut en cas de divergence."
                    } else if isEs {
                        return "Cada parte conserva la propiedad exclusiva de los bienes que aportó a la convivencia, así como de los bienes recibidos como donación o herencia.\n\nLos bienes adquiridos conjuntamente se poseen en las proporciones registradas en cohab. Las partes se comprometen a mantener los datos actualizados. La versión firmada más recientemente prevalece en caso de discrepancia."
                    } else {
                        return "Assets that each party brought into this arrangement, and any assets received as a gift or inheritance during the arrangement, remain the sole property of the party who brought or received them.\n\nAssets acquired jointly during the arrangement are held in the proportions recorded in cohab. Both parties are encouraged to keep records up to date; the most recently signed version of this agreement takes precedence in the event of any discrepancy."
                    }
                }
            }(), .plain))
        }

        // § SHARED ASSETS
        sections.append(("\(n).  \(tplTitle(templates, "assets_intro") ?? t(household, no: "FELLES EIENDELER OG EIERSKAP", sv: "REGISTRERADE TILLGÅNGAR OCH ÄGARANDELAR", da: "FÆLLES AKTIVER OG EJERSKAB", fi: "YHTEISET VARAT JA OMISTUS", de: "GEMEINSAMES VERMÖGEN UND EIGENTUMSANTEILE", fr: "ACTIFS COMMUNS ET PROPRIÉTÉ", es: "ACTIVOS COMPARTIDOS Y PROPIEDAD", en: "SHARED ASSETS AND OWNERSHIP"))", {
            n += 1
            let sym = household.currencySymbol
            let valuationClause = tpl(templates, "assets_valuation") {
                if isNO {
                    return "Ved uenighet om markedsverdien av en felles eiendel er partene enige om å innhente én uavhengig takst fra godkjent takstmann hver, og bruke gjennomsnittet av de to."
                } else if isSV {
                    return "Vid oenighet om marknadsvärdet på en gemensam tillgång är parterna överens om att var och en inhämtar ett oberoende värderingsintyg från en auktoriserad värderingsman och att använda genomsnittet av de två."
                } else if isDA {
                    return "Ved uenighed om markedsværdien af et fælles aktiv er parterne enige om, at hver part indhenter én uafhængig vurdering fra en autoriseret vurderingsmand og anvender gennemsnittet af de to."
                } else if isFI {
                    return "Mikäli yhteisen omaisuuden markkina-arvosta syntyy erimielisyys, osapuolet hankkivat kukin yhden riippumattoman arvion valtuutetulta arvioijalta ja käyttävät arvojen keskiarvoa."
                } else if isDe {
                    return "Bei Uneinigkeit über den Marktwert eines gemeinsamen Vermögenswerts holt jede Partei ein unabhängiges Gutachten eines zugelassenen Sachverständigen ein; der Durchschnitt beider Gutachten ist maßgeblich."
                } else if isFr {
                    return "En cas de désaccord sur la valeur marchande d'un actif commun, chaque partie mandate un expert indépendant agréé; la moyenne des deux estimations s'applique."
                } else if isEs {
                    return "En caso de desacuerdo sobre el valor de mercado de un activo, cada parte obtendrá una tasación independiente de un tasador homologado; se aplicará la media de ambas."
                } else {
                    return "In the event of a dispute on the market value of a shared asset, the parties agree to each obtain one independent professional valuation and use the average of the two."
                }
            }
            if household.assets.isEmpty {
                // The DB row holds only the "no assets" sentence; the valuation
                // clause (its own clause key) is appended by code — same as the
                // non-empty path below.
                let emptyText = tpl(templates, "assets_empty") {
                    if isNO {
                        return "Ingen eiendeler er registrert ved signering. Eiendeler vil legges til etter felles avtale."
                    } else if isSV {
                        return "Inga tillgångar är registrerade vid undertecknandet. Tillgångar läggs till efter ömsesidig överenskommelse."
                    } else if isDA {
                        return "Ingen aktiver er registreret ved underskrivelsen. Aktiver tilføjes efter fælles aftale."
                    } else if isFI {
                        return "Varoja ei ole rekisteröity allekirjoitushetkellä. Varat lisätään yhteisellä sopimuksella."
                    } else if isDe {
                        return "Zum Zeitpunkt der Unterzeichnung sind keine Vermögenswerte eingetragen. Vermögenswerte werden einvernehmlich ergänzt."
                    } else if isFr {
                        return "Aucun actif n'est enregistré à la date de signature. Les actifs seront ajoutés d'un commun accord."
                    } else if isEs {
                        return "No hay activos registrados en la fecha de firma. Los activos se añadirán de mutuo acuerdo."
                    } else {
                        return "No assets registered at signing. Assets will be added by mutual agreement."
                    }
                }
                return "\(emptyText)\n\n\(valuationClause)"
            }
            let intro = tpl(templates, "assets_intro") {
                if isNO {
                    return "Partene eier i fellesskap følgende eiendeler registrert i cohab ved signeringstidspunktet:"
                } else if isSV {
                    return "Parterna har registrerat följande tillgångar och bekräftar de angivna ägarandelarna:"
                } else if isDA {
                    return "Parterne ejer i fællesskab følgende aktiver registreret i cohab på tidspunktet for underskrivelsen:"
                } else if isFI {
                    return "Osapuolet omistavat yhdessä seuraavat cohab-sovellukseen allekirjoitushetkellä rekisteröidyt varat:"
                } else if isDe {
                    return "Die Parteien besitzen gemeinsam folgende in cohab zum Zeitpunkt der Unterzeichnung eingetragene Vermögenswerte:"
                } else if isFr {
                    return "Les parties détiennent en commun les actifs suivants enregistrés dans cohab à la date de signature:"
                } else if isEs {
                    return "Las partes poseen conjuntamente los siguientes activos registrados en cohab en la fecha de firma:"
                } else {
                    return "The parties jointly hold the following assets as registered in cohab at the time of signing:"
                }
            }
            // Each asset is presented as its own block: identification +
            // ownership split only. Values and loans are irrelevant for
            // ownership and contributions, so they are deliberately omitted.
            let typeLabel = t(household, no: "Type", sv: "Typ", da: "Type",
                              fi: "Tyyppi", de: "Typ", fr: "Type",
                              es: "Tipo", en: "Type")
            // Norwegian/Swedish convention: space before the percent sign.
            let pctSuffix = (isNO || isSV) ? " %" : "%"
            let list = household.assets.map { a -> String in
                let category = assetCategory(a, isNO: isNO, isSV: isSV)
                // Same (disambiguated) name as in the contributions section.
                var line = assetNames[a.id] ?? a.label
                line += "\n\(typeLabel): \(category)"
                // Name the asset by its registered detail when one exists. The
                // label follows the asset type (address for property, plate
                // number for vehicles, account for savings, …) in the
                // document's own language — essential to identify the asset.
                let addr = a.address.trimmingCharacters(in: .whitespacesAndNewlines)
                if !addr.isEmpty {
                    line += "\n\(a.type.secondaryLabel(in: docLang)): \(addr)"
                }
                // Use explicit flag; fall back to type-based for legacy assets without the field
                // nil = not explicitly set → fall back to type-based default
                let isRegisteredProperty = a.isOwnershipRegistered ?? (a.type == .home || a.type == .cabin)
                let reg = landRegistry(household)
                let regLabel: String
                if isNO {
                    regLabel = isRegisteredProperty ? "Eierbrøk (tinglyst)" : "Eierbrøk"
                } else if isSV {
                    // A car's registered keeper is Transportstyrelsen. For all
                    // other assets we use the always-correct generic wording —
                    // we cannot distinguish fastighet (lagfart hos Lantmäteriet)
                    // from bostadsrätt (registered in the förening's ledger),
                    // so naming one registry would risk a wrong factual claim.
                    if a.type == .car {
                        regLabel = "Registrerad ägare enligt Transportstyrelsen"
                    } else {
                        regLabel = "Ägarandel enligt parternas uppgifter och tillämplig ägarhandling eller registrering"
                    }
                } else if isDA {
                    regLabel = "Ejerandel\(isRegisteredProperty ? " (tinglyst)" : "")"
                } else if isFI {
                    regLabel = "Omistusosuus\(isRegisteredProperty ? " (\(reg))" : "")"
                } else if isDe {
                    regLabel = "Eigentumsanteil\(isRegisteredProperty ? " (lt. \(reg))" : "")"
                } else if isFr {
                    regLabel = "Quote-part\(isRegisteredProperty ? " (selon \(reg))" : "")"
                } else if isEs {
                    regLabel = "Cuota de propiedad\(isRegisteredProperty ? " (\(reg))" : "")"
                } else {
                    // HM Land Registry (and most registries) never record
                    // percentage shares — claiming they do is factually wrong.
                    regLabel = isRegisteredProperty ? "Ownership share (as agreed between the parties)" : "Ownership share"
                }
                line += "\n\(regLabel): \(household.partnerAName) \(Int(a.ownershipShareA * 100))\(pctSuffix) · \(household.partnerBName) \(Int((1 - a.ownershipShareA) * 100))\(pctSuffix)"
                // Itemised assets (furniture): record per-item ownership rather
                // than collapsing to a single aggregate %, so the allocation the
                // user entered survives into the signed document.
                if !a.furnitureItems.isEmpty {
                    let sharedWord = t(household, no: "felles", sv: "gemensamt", da: "fælles",
                                       fi: "yhteinen", de: "gemeinsam", fr: "commun",
                                       es: "común", en: "shared")
                    func ownerName(_ key: String) -> String {
                        switch key {
                        case "A": return household.partnerAName
                        case "B": return household.partnerBName
                        default:  return sharedWord
                        }
                    }
                    for item in a.furnitureItems {
                        let valuePart = item.currentValue > 0 ? " (\(sym)\(Int(item.currentValue).formatted(.number.locale(docLocale))))" : ""
                        line += "\n    – \(item.label)\(valuePart): \(ownerName(item.ownerKey))"
                    }
                }
                return line
            }.joined(separator: "\n\n")
            return "\(intro)\n\n\(list)\n\n\(valuationClause)"
        }(), .assets))

        // § RENTAL ARRANGEMENT — added when the household is renting rather than co-owning a home
        if isRental {
            sections.append(("\(n).  \(tplTitle(templates, "rental") ?? t(household, no: "LEIEAVTALE OG HUSLEIE", sv: "HYRESAVTAL", da: "LEJEAFTALE", fi: "VUOKRASOPIMUS", de: "MIETVEREINBARUNG", fr: "ACCORD DE LOCATION", es: "ACUERDO DE ALQUILER", en: "RENTAL ARRANGEMENT"))", {
                n += 1
                let sym = household.currencySymbol
                let hasRentDetails = household.rentAmount > 0
                let amountStr = "\(sym)\(Int(household.rentAmount).formatted(.number.locale(docLocale)))"
                let day = household.rentPaymentDay
                // Payer phrase template key for the household's rentPayerKey.
                let payerClauseKey: String
                switch household.rentPayerKey {
                case "a": payerClauseKey = "rental_payer_a"
                case "b": payerClauseKey = "rental_payer_b"
                default:  payerClauseKey = "rental_payer_landlord"
                }
                let nameTokens = ["name_a": household.partnerAName, "name_b": household.partnerBName]

                // The specific "who pays what, when" sentence — falls back to
                // generic "as agreed between the parties" language until the
                // household fills in rental details (see rentalDetailsCard).
                let rentSentence: String
                if isNO {
                    if hasRentDetails {
                        let payer = tpl(templates, payerClauseKey, tokens: nameTokens) {
                            switch household.rentPayerKey {
                            case "a": return "\(household.partnerAName) betaler husleie til \(household.partnerBName)"
                            case "b": return "\(household.partnerBName) betaler husleie til \(household.partnerAName)"
                            default:  return "Partene betaler husleie til utleier"
                            }
                        }
                        rentSentence = tpl(templates, "rental_sentence_full", tokens: ["payer": payer, "amount": amountStr, "day": "\(day)."]) {
                            "\(payer), \(amountStr) per måned, forfaller den \(day). i hver måned. Øvrige boutgifter (blant annet strøm, internett og felles husholdningsutgifter) fordeles som avtalt mellom partene og dokumenteres i cohab."
                        }
                    } else {
                        rentSentence = tpl(templates, "rental_sentence_generic") {
                            "Husleie og fordeling av øvrige boutgifter (blant annet strøm, internett og felles husholdningsutgifter) er som avtalt mellom partene og dokumenteres i cohab."
                        }
                    }
                    return tpl(templates, "rental", tokens: ["rent_sentence": rentSentence]) {
                        "Partene bor sammen i en bolig de leier, eller hvor én av partene leier ut til den andre. \(rentSentence) Dersom bofellesskapet opphører, faller den enkeltes betalingsplikt automatisk bort fra opphørsdatoen."
                    }
                } else if isSV {
                    if hasRentDetails {
                        let payer = tpl(templates, payerClauseKey, tokens: nameTokens) {
                            switch household.rentPayerKey {
                            case "a": return "\(household.partnerAName) betalar hyra till \(household.partnerBName)"
                            case "b": return "\(household.partnerBName) betalar hyra till \(household.partnerAName)"
                            default:  return "Parterna betalar hyra till hyresvärden"
                            }
                        }
                        rentSentence = tpl(templates, "rental_sentence_full", tokens: ["payer": payer, "amount": amountStr, "day": "\(day):e"]) {
                            "\(payer), \(amountStr) per månad, förfaller den \(day):e varje månad. Övriga boendekostnader (t.ex. el, internet och gemensamma hushållsutgifter) fördelas som avtalats mellan parterna och dokumenteras i cohab."
                        }
                    } else {
                        rentSentence = tpl(templates, "rental_sentence_generic") {
                            "Hyra och fördelning av övriga boendekostnader (t.ex. el, internet och gemensamma hushållsutgifter) är som avtalats mellan parterna och dokumenteras i cohab."
                        }
                    }
                    return tpl(templates, "rental", tokens: ["rent_sentence": rentSentence]) {
                        "Parterna bor tillsammans i en bostad de hyr, eller där en av parterna hyr ut till den andra. \(rentSentence) Om samboförhållandet upphör upphör betalningsskyldigheten automatiskt från och med upphörandedatumet."
                    }
                } else if isDA {
                    if hasRentDetails {
                        let payer = tpl(templates, payerClauseKey, tokens: nameTokens) {
                            switch household.rentPayerKey {
                            case "a": return "\(household.partnerAName) betaler husleje til \(household.partnerBName)"
                            case "b": return "\(household.partnerBName) betaler husleje til \(household.partnerAName)"
                            default:  return "Parterne betaler husleje til udlejeren"
                            }
                        }
                        rentSentence = tpl(templates, "rental_sentence_full", tokens: ["payer": payer, "amount": amountStr, "day": "\(day)."]) {
                            "\(payer), \(amountStr) om måneden, forfalder den \(day). i hver måned. Øvrige boligudgifter (f.eks. el, internet og fælles husholdningsudgifter) fordeles som aftalt mellem parterne og dokumenteres i cohab."
                        }
                    } else {
                        rentSentence = tpl(templates, "rental_sentence_generic") {
                            "Husleje og fordeling af øvrige boligudgifter (f.eks. el, internet og fælles husholdningsudgifter) er som aftalt mellem parterne og dokumenteres i cohab."
                        }
                    }
                    return tpl(templates, "rental", tokens: ["rent_sentence": rentSentence]) {
                        "Parterne bor sammen i en bolig, de lejer, eller hvor en af parterne udlejer til den anden. \(rentSentence) Hvis bofællesskabet ophører, bortfalder betalingsforpligtelsen automatisk fra ophørsdatoen."
                    }
                } else if isFI {
                    if hasRentDetails {
                        let payer = tpl(templates, payerClauseKey, tokens: nameTokens) {
                            switch household.rentPayerKey {
                            case "a": return "\(household.partnerAName) maksaa vuokraa \(household.partnerBName)lle"
                            case "b": return "\(household.partnerBName) maksaa vuokraa \(household.partnerAName)lle"
                            default:  return "Osapuolet maksavat vuokraa vuokranantajalle"
                            }
                        }
                        rentSentence = tpl(templates, "rental_sentence_full", tokens: ["payer": payer, "amount": amountStr, "day": "\(day)."]) {
                            "\(payer), \(amountStr) kuukaudessa, eräpäivä kunkin kuukauden \(day). päivä. Muut asumiskustannukset (esim. sähkö, internet ja yhteiset kotitalousmenot) jaetaan osapuolten sopimuksen mukaisesti ja kirjataan cohab-sovellukseen."
                        }
                    } else {
                        rentSentence = tpl(templates, "rental_sentence_generic") {
                            "Vuokra ja muiden asumiskustannusten (esim. sähkö, internet ja yhteiset kotitalousmenot) jakautuminen on osapuolten sopimuksen mukainen ja kirjataan cohab-sovellukseen."
                        }
                    }
                    return tpl(templates, "rental", tokens: ["rent_sentence": rentSentence]) {
                        "Osapuolet asuvat yhdessä vuokra-asunnossa, tai toinen osapuoli vuokraa asunnon toiselle. \(rentSentence) Jos asuminen yhdessä päättyy, maksuvelvollisuus lakkaa automaattisesti päättymispäivästä."
                    }
                } else if isDe {
                    if hasRentDetails {
                        let payer = tpl(templates, payerClauseKey, tokens: nameTokens) {
                            switch household.rentPayerKey {
                            case "a": return "\(household.partnerAName) zahlt Miete an \(household.partnerBName)"
                            case "b": return "\(household.partnerBName) zahlt Miete an \(household.partnerAName)"
                            default:  return "Die Parteien zahlen Miete an den Vermieter"
                            }
                        }
                        rentSentence = tpl(templates, "rental_sentence_full", tokens: ["payer": payer, "amount": amountStr, "day": "\(day)."]) {
                            "\(payer), \(amountStr) pro Monat, fällig am \(day). jeden Monats. Weitere Wohnkosten (z. B. Strom, Internet und gemeinsame Haushaltsausgaben) werden nach Vereinbarung der Parteien aufgeteilt und in cohab dokumentiert."
                        }
                    } else {
                        rentSentence = tpl(templates, "rental_sentence_generic") {
                            "Miete und die Aufteilung weiterer Wohnkosten (z. B. Strom, Internet und gemeinsame Haushaltsausgaben) richten sich nach der Vereinbarung der Parteien und werden in cohab dokumentiert."
                        }
                    }
                    return tpl(templates, "rental", tokens: ["rent_sentence": rentSentence]) {
                        "Die Parteien leben gemeinsam in einer gemieteten Wohnung, oder eine Partei vermietet an die andere. \(rentSentence) Endet die gemeinsame Haushaltsführung, entfällt die Zahlungspflicht automatisch ab dem Beendigungsdatum."
                    }
                } else if isFr {
                    if hasRentDetails {
                        let payer = tpl(templates, payerClauseKey, tokens: nameTokens) {
                            switch household.rentPayerKey {
                            case "a": return "\(household.partnerAName) verse le loyer à \(household.partnerBName)"
                            case "b": return "\(household.partnerBName) verse le loyer à \(household.partnerAName)"
                            default:  return "Les parties versent le loyer au propriétaire"
                            }
                        }
                        rentSentence = tpl(templates, "rental_sentence_full", tokens: ["payer": payer, "amount": amountStr, "day": "\(day)"]) {
                            "\(payer), \(amountStr) par mois, exigible le \(day) de chaque mois. Les autres frais de logement (électricité, internet, dépenses courantes du foyer, etc.) sont répartis tels que convenus entre les parties et documentés dans cohab."
                        }
                    } else {
                        rentSentence = tpl(templates, "rental_sentence_generic") {
                            "Le loyer et la répartition des autres frais de logement (électricité, internet, dépenses courantes du foyer, etc.) sont tels que convenus entre les parties et documentés dans cohab."
                        }
                    }
                    return tpl(templates, "rental", tokens: ["rent_sentence": rentSentence]) {
                        "Les parties partagent un logement qu'elles louent, ou l'une loue à l'autre. \(rentSentence) Si la cohabitation prend fin, l'obligation de paiement cesse automatiquement à la date de fin."
                    }
                } else if isEs {
                    if hasRentDetails {
                        let payer = tpl(templates, payerClauseKey, tokens: nameTokens) {
                            switch household.rentPayerKey {
                            case "a": return "\(household.partnerAName) paga el alquiler a \(household.partnerBName)"
                            case "b": return "\(household.partnerBName) paga el alquiler a \(household.partnerAName)"
                            default:  return "Las partes pagan el alquiler al arrendador"
                            }
                        }
                        rentSentence = tpl(templates, "rental_sentence_full", tokens: ["payer": payer, "amount": amountStr, "day": "\(day)"]) {
                            "\(payer), \(amountStr) al mes, con vencimiento el día \(day) de cada mes. Los demás gastos de la vivienda (electricidad, internet, gastos domésticos comunes, etc.) se reparten según lo acordado entre las partes y se documentan en cohab."
                        }
                    } else {
                        rentSentence = tpl(templates, "rental_sentence_generic") {
                            "El alquiler y el reparto de otros gastos de la vivienda (electricidad, internet, gastos domésticos comunes, etc.) son los acordados entre las partes y se documentan en cohab."
                        }
                    }
                    return tpl(templates, "rental", tokens: ["rent_sentence": rentSentence]) {
                        "Las partes conviven en una vivienda que alquilan, o una de ellas alquila a la otra. \(rentSentence) Si la convivencia termina, la obligación de pago cesa automáticamente desde la fecha de finalización."
                    }
                } else {
                    if hasRentDetails {
                        let payer = tpl(templates, payerClauseKey, tokens: nameTokens) {
                            switch household.rentPayerKey {
                            case "a": return "\(household.partnerAName) pays rent to \(household.partnerBName)"
                            case "b": return "\(household.partnerBName) pays rent to \(household.partnerAName)"
                            default:  return "The parties pay rent to their landlord"
                            }
                        }
                        rentSentence = tpl(templates, "rental_sentence_full", tokens: ["payer": payer, "amount": amountStr, "day": "\(day)\(ordinalSuffix(day))"]) {
                            "\(payer), \(amountStr) per month, due on the \(day)\(ordinalSuffix(day)) of each month. Other household costs (e.g. utilities, internet, and shared household expenses) are split as agreed between the parties and documented in cohab."
                        }
                    } else {
                        rentSentence = tpl(templates, "rental_sentence_generic") {
                            "Rent and the split of other household costs (e.g. utilities, internet, and shared household expenses) are as agreed between the parties and documented in cohab."
                        }
                    }
                    return tpl(templates, "rental", tokens: ["rent_sentence": rentSentence]) {
                        "The parties share a home that they rent, or one party rents to the other. \(rentSentence) If the arrangement ends, the obligation to pay rent ends automatically from the date the arrangement ends."
                    }
                }
            }(), .plain))
        }

        // § RECORDED CONTRIBUTIONS
        // The section title lives on both contributions_* rows in the DB —
        // there is no separate "contributions" key.
        sections.append(("\(n).  \(tplTitle(templates, "contributions_empty") ?? tplTitle(templates, "contributions_interest_note") ?? t(household, no: "REGISTRERTE BIDRAG", sv: "REGISTRERADE BIDRAG", da: "REGISTREREDE BIDRAG", fi: "REKISTERÖIDYT PANOKSET", de: "ERFASSTE EINZAHLUNGEN", fr: "APPORTS ENREGISTRÉS", es: "APORTACIONES REGISTRADAS", en: "RECORDED CONTRIBUTIONS"))", {
            n += 1
            let assetsWithContribs = household.assets.filter { !$0.contributions.isEmpty }
            if assetsWithContribs.isEmpty {
                return tpl(templates, "contributions_empty", tokens: ["rate": rateStr]) {
                    if isNO {
                        return "Ingen innbetalinger er registrert ved signering. Innskudd, ekstra nedbetalinger og oppussing kan registreres når som helst og forrentes med \(rateStr) per år. Registrerte bidrag endrer ikke eierbrøken."
                    } else if isSV {
                        return "Inga ekonomiska bidrag har registrerats vid undertecknandet. Insättningar, extra amorteringar och renoveringar kan registreras när som helst och räknas upp med \(rateStr) per år. Registrerade bidrag ändrar inte parternas ägarandelar."
                    } else if isDA {
                        return "Ingen finansielle bidrag er registreret ved underskrivelsen. Indskud, ekstra afdrag og renoveringer kan registreres til enhver tid og forrentes med \(rateStr) per år. Registrerede bidrag ændrer ikke ejerandelen."
                    } else if isFI {
                        return "Taloudellisia panoksia ei ole rekisteröity allekirjoitushetkellä. Talletukset, ylimääräiset lyhennykset ja remontit voidaan rekisteröidä milloin tahansa ja niille lasketaan korkoa \(rateStr) vuodessa. Rekisteröidyt panokset eivät muuta omistusosuuksia."
                    } else if isDe {
                        return "Zum Zeitpunkt der Unterzeichnung sind keine Einzahlungen erfasst. Einlagen, zusätzliche Tilgungen und Renovierungen können jederzeit ergänzt werden und werden mit \(rateStr) p.a. verzinst. Erfasste Einzahlungen ändern nicht die Eigentumsanteile."
                    } else if isFr {
                        return "Aucun apport financier n'est enregistré à la date de signature. Les dépôts, remboursements supplémentaires et travaux peuvent être ajoutés à tout moment et sont rémunérés à \(rateStr) par an. Les apports enregistrés ne modifient pas les quotes-parts."
                    } else if isEs {
                        return "No se han registrado aportaciones en la fecha de firma. Los depósitos, amortizaciones extraordinarias y reformas pueden registrarse en cualquier momento y generan intereses al \(rateStr) anual. Las aportaciones registradas no modifican las cuotas de propiedad."
                    } else {
                        return "No contributions recorded at signing. Deposits, extra mortgage payments, and renovations may be added at any time and will accrue interest at \(rateStr) per annum. Recorded contributions do not change the ownership shares."
                    }
                }
            }

            let fmtDate: (Date) -> String = { d in
                let f = DateFormatter()
                f.dateStyle = .medium; f.timeStyle = .none; f.locale = docLocale
                return f.string(from: d)
            }
            let interestNote = tpl(templates, "contributions_interest_note", tokens: ["rate": rateStr]) {
                if isNO {
                    return "Alle beløp forrentes med \(rateStr) per år fra innbetalingsdato, kapitalisert årlig. For deler av et år beregnes renten proporsjonalt per dag, og den løper frem til utbetalingsdagen. Registrerte bidrag endrer ikke eierbrøken.\nMed bidrag menes engangsinnbetalinger registrert i cohab (f.eks. innskudd, ekstra nedbetaling eller oppussing) — løpende boutgifter omfattes ikke.\n"
                } else if isSV {
                    return "Samtliga belopp räknas upp med \(rateStr) per år från inbetalningsdatumet, sammansatt årligen. För del av år beräknas räntan proportionerligt per dag. Räntan löper fram till utbetalningsdagen. Registrerade bidrag ändrar inte parternas ägarandelar.\nMed bidrag avses engångsinbetalningar som registrerats i cohab (till exempel kontantinsats, extra amortering eller renovering). Löpande boendekostnader som mat, el och hyra omfattas inte.\n"
                } else if isDA {
                    return "Alle beløb forrentes med \(rateStr) per år fra indbetalingsdatoen, kapitaliseret årligt. For dele af et år beregnes renten forholdsmæssigt pr. dag, og den løber indtil udbetalingsdatoen. Registrerede bidrag ændrer ikke ejerandelen.\nMed bidrag menes engangsindbetalinger registreret i cohab (f.eks. indskud, ekstra afdrag eller renovering) — løbende boligudgifter omfattes ikke.\n"
                } else if isFI {
                    return "Kaikille summille lasketaan korkoa \(rateStr) vuodessa maksupäivästä lähtien, vuotuisella koronkorolla. Osittaiselta vuodelta korko lasketaan suhteellisesti päivittäin, ja sitä kertyy maksupäivään asti. Rekisteröidyt panokset eivät muuta omistusosuuksia.\nPanoksella tarkoitetaan cohab-sovellukseen rekisteröityjä kertamaksuja (esim. käsiraha, ylimääräinen lyhennys tai remontti) — juoksevat asumiskulut eivät kuulu mukaan.\n"
                } else if isDe {
                    return "Alle Beträge werden ab dem Einzahlungsdatum mit \(rateStr) p.a. verzinst, jährlich kapitalisiert. Für Teile eines Jahres werden die Zinsen anteilig pro Tag berechnet und laufen bis zum Auszahlungstag. Erfasste Einzahlungen ändern nicht die Eigentumsanteile.\nAls Einzahlungen gelten einmalige, in cohab erfasste Zahlungen (z. B. Anzahlung, zusätzliche Tilgung oder Renovierung) — laufende Wohnkosten sind ausgeschlossen.\n"
                } else if isFr {
                    return "Tous les montants sont rémunérés à \(rateStr) par an à compter de la date de versement, avec capitalisation annuelle. Pour une fraction d'année, les intérêts sont calculés au prorata par jour et courent jusqu'à la date de versement final. Les apports enregistrés ne modifient pas les quotes-parts.\nPar apports, on entend les versements ponctuels enregistrés dans cohab (ex. apport initial, remboursement supplémentaire ou travaux) — les dépenses courantes du logement sont exclues.\n"
                } else if isEs {
                    return "Todos los importes generan intereses al \(rateStr) anual desde la fecha de pago, con capitalización anual. Para fracciones de año, el interés se calcula proporcionalmente por día y devenga hasta la fecha de pago. Las aportaciones registradas no modifican las cuotas de propiedad.\nPor aportaciones se entienden pagos únicos registrados en cohab (p. ej. entrada, amortización extraordinaria o reformas) — los gastos corrientes de la vivienda quedan excluidos.\n"
                } else {
                    return "All amounts accrue interest at \(rateStr) per annum from the date of payment, compounded annually. For part of a year, interest accrues proportionally per day and runs until the payout date. Recorded contributions do not change the ownership shares.\nContributions mean one-off payments recorded in cohab (e.g. deposit, extra mortgage payment or renovation) — ongoing household costs are not included.\n"
                }
            }

            // Purchase equity (deposits/down payments) and later contributions
            // are presented as one combined "contributions" figure — simpler
            // to read, and the split is visible in the app for those who care.
            func ownerName(_ key: String) -> String {
                key == "A" ? household.partnerAName : household.partnerBName
            }
            let now = Date()
            // Same-day interest is noise (a few kroner) — amounts registered the
            // day the contract is created count at face value.
            func accruedValue(_ c: ContributionRecord) -> Double {
                if Calendar.current.isDate(c.date, inSameDayAs: now) { return c.amount }
                return SettlementEngine.accrue(c.amount, rate: household.annualInterestRate,
                                               from: c.date, to: now)
            }

            let contribShort = t(household, no: "bidrag", sv: "bidrag",
                                 da: "bidrag", fi: "panokset",
                                 de: "Einzahlungen", fr: "apports",
                                 es: "aportaciones", en: "contributions")
            let interestShort = t(household, no: "renter", sv: "ränta", da: "renter",
                                  fi: "korkoa", de: "Zinsen", fr: "intérêts",
                                  es: "intereses", en: "interest")
            let totalShort = t(household, no: "samlet", sv: "totalt", da: "i alt",
                               fi: "yhteensä", de: "gesamt", fr: "total",
                               es: "total", en: "total")
            // One summary line per partner: total paid in, accrued interest
            // separately, and the combined registered value.
            func summaryLine(_ key: String, principal: Double, accrued: Double) -> String {
                let interest = accrued - principal
                return "  \(ownerName(key)): \(contribShort) \(money(principal)) · \(interestShort) \(money(interest)) · \(totalShort) \(money(accrued))"
            }

            // Per asset: each contribution is listed (party, type, date,
            // amount) because the signed document must show the payment dates
            // the interest runs from — followed by a one-line summary per
            // partner.
            var blocks: [String] = []
            var totPrincipal: [String: Double] = ["A": 0, "B": 0]
            var totAcc: [String: Double] = ["A": 0, "B": 0]
            for asset in assetsWithContribs {
                let contribs = asset.contributions
                var lines = [assetNames[asset.id] ?? asset.label]
                for c in contribs.sorted(by: { $0.date < $1.date }) {
                    lines.append("  \(ownerName(c.ownerKey)) · \(AppStrings.contribCategory(c.category, lang: docLang)) · \(fmtDate(c.date)) · \(money(c.amount))")
                }
                for key in ["A", "B"] {
                    let all = contribs.filter { $0.ownerKey == key }
                    guard !all.isEmpty else { continue }
                    let principal = all.reduce(0.0) { $0 + $1.amount }
                    let acc = all.reduce(0.0) { $0 + accruedValue($1) }
                    lines.append(summaryLine(key, principal: principal, accrued: acc))
                    totPrincipal[key, default: 0] += principal
                    totAcc[key, default: 0] += acc
                }
                blocks.append(lines.joined(separator: "\n"))
            }

            // Per-person totals across all assets, at the very bottom.
            let asOf = fmtDate(now)
            let combinedHeading = tpl(templates, "contributions_combined_heading", tokens: ["date": asOf]) {
                t(household,
                no: "Samlet for alle eiendeler per \(asOf)",
                sv: "Totalt för alla tillgångar per \(asOf)",
                da: "Samlet for alle aktiver pr. \(asOf)",
                fi: "Yhteensä kaikista varoista \(asOf)",
                de: "Gesamt über alle Vermögenswerte zum \(asOf)",
                fr: "Total pour tous les actifs au \(asOf)",
                es: "Total de todos los activos al \(asOf)",
                en: "Combined totals across all assets as of \(asOf)")
            }
            let note = tpl(templates, "contributions_note") {
                t(household,
                no: "Endelig utbetaling avhenger av tilgjengelig verdi ved oppgjør (se fordelingsrekkefølgen).",
                sv: "Slutlig utbetalning beror på tillgängligt värde vid uppgörelsen (se fördelningsordningen).",
                da: "Den endelige udbetaling afhænger af den tilgængelige værdi ved opgørelsen (se fordelingsrækkefølgen).",
                fi: "Lopullinen maksu riippuu selvityshetkellä käytettävissä olevasta arvosta (ks. jakojärjestys).",
                de: "Die endgültige Auszahlung hängt vom bei der Abwicklung verfügbaren Wert ab (siehe Verteilungsreihenfolge).",
                fr: "Le versement final dépend de la valeur disponible lors du règlement (voir l'ordre de répartition).",
                es: "El pago final depende del valor disponible en la liquidación (véase el orden de reparto).",
                en: "Final payout depends on the value available at settlement (see the distribution order).")
            }
            var lines = [interestNote, blocks.joined(separator: "\n\n"), "", combinedHeading]
            for key in ["A", "B"] {
                guard (totAcc[key] ?? 0) > 0 else { continue }
                lines.append(summaryLine(key, principal: totPrincipal[key] ?? 0, accrued: totAcc[key] ?? 0))
            }
            lines.append("")
            lines.append(note)
            return lines.joined(separator: "\n")
        }(), .contributions))

        // § DISSOLUTION — Samboappen § 8 (core, always included if toggled)
        if household.includeDissolutionClause {
            sections.append(("\(n).  \(tplTitle(templates, "dissolution") ?? t(household, no: "FORDELING VED OPPHØR", sv: "EKONOMISK REGLERING VID FÖRSÄLJNING, UTKÖP ELLER SEPARATION", da: "FORDELING VED OPHØR", fi: "OMAISUUDEN JAKO EROTESSA", de: "VERMÖGENSAUFTEILUNG BEI TRENNUNG", fr: "RÉPARTITION EN CAS DE SÉPARATION", es: "DISTRIBUCIÓN AL SEPARARSE", en: "SETTLEMENT ON SEPARATION"))", {
                n += 1
                return tpl(templates, "dissolution", tokens: ["rate": rateStr]) {
                if isNO {
                    return "Dersom samboerforholdet opphører, gjelder følgende rekkefølge:\n\n(a) Innbetalinger tilbakebetales først. Det hver part har betalt inn — med opptjente renter (\(rateStr) per år) — utbetales til vedkommende før resterende verdi fordeles.\n\n(b) Ved underskudd. Er tilgjengelig verdi lavere enn de samlede innbetalingene, deles det som finnes forholdsmessig etter hva hver part har betalt inn.\n\n(c) Overskudd. Eventuell restverdi etter at innbetalinger er dekket, fordeles etter registrert eierbrøk.\n\nDenne avtalen er ikke et testament og regulerer ikke arv. Dersom samboerforholdet opphører ved dødsfall, gjelder arvelovens regler — partene oppfordres til å opprette testament."
                } else if isSV {
                    return "Bestämmelserna nedan är parternas ekonomiska överenskommelse om de registrerade tillgångarna — inte ett föravtal om bodelning enligt 10 § sambolagen. De gäller vid separation, vid försäljning av en gemensam tillgång och vid inlösen. Vid inlösen räknas tillgångens marknadsvärde enligt avtalets värderingsregler i stället för en försäljningsintäkt.\n\nMed tillgängliga intäkter avses försäljnings- eller inlösenvärdet minus lån som belastar tillgången och kostnader för försäljningen. Bankens och andra borgenärers rättigheter påverkas inte.\n\n(a) Återbetalning först. Varje parts inbetalningar återbetalas med upplupen ränta (\(rateStr) per år fram till utbetalningsdagen) innan resten fördelas.\n\n(b) Underskott. Räcker inte intäkterna till alla inbetalningar fördelas de proportionellt efter vad var och en betalat in.\n\n(c) Överskott. Det som återstår fördelas enligt ägarandelarna.\n\n(d) Restskuld. Om intäkterna inte ens täcker lån och kostnader bär parterna restskulden internt efter ägarandel.\n\nDetta avtal är inte ett testamente och reglerar inte arv. Om samboförhållandet upphör genom en parts död gäller landets arvsregler — parterna uppmanas att upprätta testamente."
                } else if isDA {
                    return "Hvis samlivsforholdet ophører, hvis et fælles aktiv sælges, eller hvis en part overtager den andens andel, gælder følgende som parternes egen aftale om de registrerede aktiver. Ved overtagelse anvendes aktivets markedsværdi, fastsat efter aftalens vurderingsregler, i stedet for en salgspris.\n\nMed tilgængelig værdi menes salgs- eller overtagelsesværdien fratrukket lån, der belaster aktivet, samt rimelige salgsomkostninger. Aftalen påvirker ikke pengeinstitutters eller andre kreditorers rettigheder.\n\n(a) Indbetalinger tilbagebetales først. Hvad den enkelte part har indbetalt — med påløbne renter (\(rateStr) per år indtil udbetalingsdagen) — tilbagebetales til den pågældende, inden det resterende fordeles.\n\n(b) Underskud. Hvis den tilgængelige værdi er lavere end de samlede indbetalinger, fordeles den forholdsmæssigt efter, hvad hver part har indbetalt.\n\n(c) Overskud. Et eventuelt restbeløb efter tilbagebetaling af indbetalinger fordeles efter parternes registrerede ejerandele.\n\n(d) Restgæld. Hvis værdien ikke engang dækker lån og salgsomkostninger, bærer parterne restgælden internt i forhold til deres ejerandele.\n\nDenne aftale er ikke et testamente og regulerer ikke arv. Hvis samlivsforholdet ophører ved en parts død, gælder arvelovens regler — parterne opfordres til at oprette testamente."
                } else if isFI {
                    return "Jos avoliitto päättyy, noudatetaan seuraavaa järjestystä:\n\n(a) Panokset palautetaan ensin. Kunkin osapuolen maksamat summat — kertyneineen korkoineen (\(rateStr) vuodessa) — palautetaan hänelle ennen jäljelle jäävän omaisuuden jakamista.\n\n(b) Alijäämä. Jos käytettävissä olevat varat ovat pienempiä kuin panokset yhteensä, jaetaan ne suhteessa kunkin suorittamiin maksuihin.\n\n(c) Ylijäämä. Mahdollinen jäljelle jäävä arvo jaetaan osapuolten rekisteröityjen omistusosuuksien mukaisesti.\n\nTämä sopimus ei ole testamentti eikä sääntele perintöä. Jos avoliitto päättyy osapuolen kuolemaan, sovelletaan perintölainsäädäntöä — osapuolia kehotetaan tekemään testamentit."
                } else if isDe {
                    return "Im Fall der Auflösung der Partnerschaft gilt folgende Reihenfolge:\n\n(a) Einzahlungen werden zuerst zurückerstattet. Die geleisteten Einzahlungen jeder Partei — zuzüglich aufgelaufener Zinsen (\(rateStr) p.a.) — werden zurückerstattet, bevor der verbleibende Wert aufgeteilt wird.\n\n(b) Unterdeckung. Reichen die verfügbaren Erlöse zur vollständigen Rückerstattung nicht aus, werden die verfügbaren Mittel anteilig verteilt.\n\n(c) Überschuss. Verbleibt nach der Rückerstattung der Einzahlungen ein Restwert, wird dieser gemäß den eingetragenen Eigentumsanteilen aufgeteilt.\n\nDieser Vertrag ist kein Testament und regelt nicht die Erbfolge. Endet die Partnerschaft durch den Tod einer Partei, gilt das gesetzliche Erbrecht — den Parteien wird empfohlen, Testamente zu errichten."
                } else if isFr {
                    return "En cas de dissolution de l'union, l'ordre suivant s'applique:\n\n(a) Restitution des apports en premier. Les sommes versées par chaque partie — augmentées des intérêts courus (\(rateStr) par an) — sont restituées avant tout partage du solde.\n\n(b) Insuffisance. Si les fonds disponibles sont inférieurs aux apports totaux, ils sont répartis proportionnellement aux versements de chaque partie.\n\n(c) Excédent. L'éventuel solde restant après restitution des apports est réparti selon les quotes-parts enregistrées.\n\nLe présent accord n'est pas un testament et ne régit pas la succession. Si l'union prend fin par le décès d'une partie, le droit des successions s'applique — les parties sont invitées à rédiger des testaments."
                } else if isEs {
                    return "Si la convivencia termina, se aplicará el siguiente orden:\n\n(a) Las aportaciones se devuelven primero. Lo que cada parte ha aportado — con los intereses acumulados (\(rateStr) anual) — se devuelve antes de distribuir el valor restante.\n\n(b) Déficit. Si los fondos disponibles son inferiores a las aportaciones totales, se distribuyen proporcionalmente a lo aportado por cada parte.\n\n(c) Excedente. El saldo eventual tras la devolución de aportaciones se distribuye conforme a las cuotas de propiedad registradas.\n\nEste acuerdo no es un testamento y no regula la herencia. Si la convivencia termina por el fallecimiento de una parte, se aplica la legislación sucesoria — se recomienda a las partes otorgar testamento."
                } else {
                    return "The following provisions are the parties' own contractual arrangement for the recorded assets. They apply if the arrangement ends (including on the death of either party), if a shared asset is sold, and on a buyout. On a buyout, the asset's market value — determined under this agreement's valuation rules — is used in place of sale proceeds.\n\nAvailable proceeds means the sale or buyout value of an asset, less any loan secured on the asset and the reasonable costs of sale. This agreement does not affect the rights of any lender or other creditor.\n\n(a) Contributions returned first. What each party has paid in — with accrued interest at \(rateStr) per annum until the payout date — is returned to that party before any remaining value is divided.\n\n(b) Shortfall. If the available proceeds are less than the total contributions, the available amount is shared in proportion to what each party has paid in.\n\n(c) Surplus. Any remaining value after contributions have been repaid is divided according to each party's recorded ownership share.\n\n(d) Residual debt. If the proceeds do not even cover the loan and the costs of sale, the parties bear the remaining debt between themselves in proportion to their ownership shares.\n\nThis agreement is not a will and does not govern inheritance. On the death of a party it binds that party's estate as a contract to the extent permitted by applicable law; inheritance law otherwise applies, and the parties are encouraged to make wills."
                }
                }
            }(), .plain))
        }

        // § BUYOUT RIGHTS — Samboappen § 7 (advanced optional; presumes co-owned property)
        if household.includeBuyoutRightsClause && !isRental {
            sections.append(("\(n).  \(tplTitle(templates, "buyout") ?? t(household, no: "OVERTAKELSE VED OPPHØR", sv: "INLÖSENRÄTT", da: "OVERTAGELSESRET", fi: "LUNASTUSOIKEUS", de: "VORKAUFSRECHT", fr: "DROIT DE PRÉEMPTION", es: "DERECHO DE ADQUISICIÓN PREFERENTE", en: "BUYOUT RIGHTS AND TAKEOVER"))", {
                n += 1
                return tpl(templates, "buyout", tokens: ["rate": rateStr]) {
                if isNO {
                    return "Dersom samboerforholdet opphører:\n\n(a) Fortrinnsrett: Den parten med størst tinglyst eierandel har fortrinnsrett til å overta boligen. Ved lik eierandel (50/50) skal partene forsøke å bli enige skriftlig; dersom dette ikke lykkes innen 30 dager, avgjøres fortrinnsretten ved mekling eller, dersom mekling ikke fører frem, ved loddtrekning.\n\n(b) Verdifastsettelse: Overtakelsessummen fastsettes som gjennomsnittet av to uavhengige takster — én innhentet av hver part fra godkjent takstmann.\n\n(c) Frist: Overtakelse eller åpent salg skal gjennomføres innen 6 måneder fra den dato en av partene skriftlig varsler om opphør, eller fra den dato samlivet faktisk opphørte dersom dette kan dokumenteres.\n\n(d) Forsinkelsesrente: Ved oversittelse av fristen beregnes forsinkelsesrente i henhold til forsinkelsesrenteloven."
                } else if isSV {
                    return "Om samboförhållandet upphör och parterna äger en gemensam bostad:\n\n(a) Inlösenrätt. Den part med störst registrerad ägarandel har rätt att lösa in den andras andel. Vid lika ägarandel (50/50) ska parterna i första hand nå skriftlig överenskommelse. Lyckas detta inte inom 30 dagar avgörs inlösenrätten genom medling eller, om det misslyckas, lottdragning.\n\n(b) Värdering. Inlösenpriset fastställs som genomsnittet av två oberoende värderingsintyg, ett inhämtat av varje part.\n\n(c) Tidsfrist. Inlösen eller försäljning på öppna marknaden ska slutföras inom 6 månader från skriftlig uppsägning eller den dokumenterade dag samboförhållandet faktiskt upphörde.\n\n(d) Dröjsmålsränta. Överskrids fristen ska den dröjande parten betala ränta enligt tillämplig lag."
                } else if isDA {
                    return "Hvis samlivsforholdet ophører, og parterne ejer en fælles bolig:\n\n(a) Overtagelsesret. Den part med den største registrerede ejerandel har ret til at overtage den andens andel. Ved ens ejerandel (50/50) skal parterne i første omgang forsøge at nå en skriftlig aftale. Lykkes dette ikke inden 30 dage, afgøres overtagelsesretten ved mægling eller, hvis dette mislykkes, af en af parterne i fællesskab udpeget neutral tredjepart.\n\n(b) Vurdering. Overtagelsesprisen fastsættes som gennemsnittet af to uafhængige vurderinger, én indhentet af hver part.\n\n(c) Tidsfrist. Overtagelse eller salg på det åbne marked skal gennemføres inden 6 måneder fra skriftlig opsigelse eller den dokumenterede dato, samlivsforholdet faktisk ophørte.\n\n(d) Morarenter. Overskrides fristen, betaler den forsinkede part morarenter i henhold til renteloven."
                } else if isFI {
                    return "Jos avoliitto päättyy ja osapuolet omistavat yhteisen asunnon:\n\n(a) Lunastusoikeus. Suurimman omistusosuuden omaavalla osapuolella on oikeus lunastaa toisen osuus. Tasan (50/50) jaetun omistuksen tapauksessa pyritään ensin kirjalliseen sopimukseen. Ellei sopimukseen päästä 30 päivässä, lunastusoikeus ratkaistaan sovittelulla tai arvonnalla.\n\n(b) Arvostus. Lunastushinta on kahden riippumattoman arvion keskiarvo, yksi kummankin hankkimana.\n\n(c) Määräaika. Lunastus tai myynti on saatettava päätökseen 6 kuukauden kuluessa kirjallisesta irtisanomisesta tai dokumentoidusta päivämäärästä, jolloin avoliitto tosiasiallisesti päättyi.\n\n(d) Viivästyskorko. Määräajan ylittyessä viivästyvä osapuoli maksaa korkoa sovellettavan lain mukaisesti."
                } else if isDe {
                    return "Bei Auflösung der Partnerschaft und gemeinsamem Immobilieneigentum gilt:\n\n(a) Vorkaufsrecht. Die Partei mit dem größeren eingetragenen Eigentumsanteil hat das Recht, den Anteil der anderen Partei zu übernehmen. Bei gleichen Anteilen (50/50) bemühen sich die Parteien zunächst um eine schriftliche Einigung. Scheitert dies binnen 30 Tagen, wird das Vorkaufsrecht durch Mediation oder, falls diese scheitert, durch Los entschieden.\n\n(b) Bewertung. Der Übernahmepreis entspricht dem Durchschnitt zweier unabhängiger Gutachten, je eines pro Partei.\n\n(c) Frist. Die Übernahme oder der Verkauf am freien Markt muss innerhalb von 6 Monaten nach schriftlicher Kündigung abgeschlossen sein.\n\n(d) Verzugszinsen. Bei Fristüberschreitung schuldet die säumige Partei Zinsen gemäß geltendem Recht."
                } else if isFr {
                    return "En cas de dissolution de l'union et de copropriété immobilière:\n\n(a) Droit de préemption. La partie détenant la quote-part la plus élevée a le droit de racheter la part de l'autre. En cas d'égalité (50/50), les parties s'efforcent d'abord de parvenir à un accord écrit; à défaut dans les 30 jours, le droit de préemption est déterminé par médiation ou, si celle-ci échoue, par tirage au sort.\n\n(b) Évaluation. Le prix de rachat correspond à la moyenne de deux expertises indépendantes, une par partie.\n\n(c) Délai. Le rachat ou la vente sur le marché libre doit être achevé dans les 6 mois suivant la notification écrite.\n\n(d) Intérêts de retard. En cas de dépassement du délai, la partie défaillante doit des intérêts conformément à la loi applicable."
                } else if isEs {
                    return "Si la convivencia termina y las partes son copropietarias de un inmueble:\n\n(a) Derecho preferente. La parte con mayor cuota registrada tiene derecho a adquirir la parte de la otra. En caso de igualdad (50/50), se intentará primero un acuerdo escrito; si no se alcanza en 30 días, el derecho se determina por mediación o, si fracasa, por sorteo.\n\n(b) Valoración. El precio de adquisición es la media de dos tasaciones independientes, una por parte.\n\n(c) Plazo. La adquisición o venta en mercado abierto debe completarse en 6 meses desde la notificación escrita.\n\n(d) Intereses de demora. Si se supera el plazo, la parte incumplidora pagará intereses conforme a la ley aplicable."
                } else {
                    return "If this arrangement ends and the parties hold a jointly owned property:\n\n(a) Right of first refusal: The party with the greater recorded ownership share has the right to buy out the other. Where ownership is equal (50/50), the parties shall first attempt written agreement; if no agreement is reached within 30 days, the right is determined by mediation or, failing that, by a mutually agreed neutral third party.\n\n(b) Valuation: The buyout price shall be the average of two independent professional valuations, one obtained by each party.\n\n(c) Timeline: Buyout or open-market sale shall be completed within 6 months of written notice of termination, or the documented date the arrangement ended.\n\n(d) Interest on delay: If the deadline is missed, the delaying party shall pay interest at \(rateStr) per annum on the outstanding amount."
                }
                }
            }(), .plain))
        }

        // § DISPOSAL CONSENT — Samboappen § 10 (advanced optional)
        if household.includeDisposalConsentClause {
            sections.append(("\(n).  \(tplTitle(templates, "disposal_consent") ?? t(household, no: "SAMTYKKE VED SALG OG UTLEIE", sv: "SAMTYCKESKRAV", da: "DISPOSITIONSSAMTYKKE", fi: "LUOVUTUSSUOSTUMUS", de: "VERFÜGUNGSZUSTIMMUNG", fr: "CONSENTEMENT AUX CESSIONS", es: "CONSENTIMIENTO PARA DISPOSICIÓN", en: "JOINT DISPOSAL CONSENT"))", {
                n += 1
                return tpl(templates, "disposal_consent") {
                if isNO {
                    return "Skriftlig samtykke fra begge parter kreves ved salg, utleie, pantsettelse eller annen disposisjon av felles eiendeler. Disposisjoner foretatt uten slikt samtykke kan kreves omgjort av den parten som ikke har gitt samtykke."
                } else if isSV {
                    return "Ingen av parterna får sälja, hyra ut, pantsätta eller på annat sätt disponera gemensamma tillgångar utan den andra partens skriftliga samtycke. Transaktioner genomförda utan sådant samtycke kan ogiltigförklaras av den part som inte lämnat samtycke."
                } else if isDA {
                    return "Ingen af parterne må sælge, udleje, pantsætte eller på anden måde disponere over fælles aktiver uden den anden parts skriftlige samtykke. Transaktioner gennemført uden sådant samtykke kan gøres ugyldige af den part, der ikke har givet samtykke."
                } else if isFI {
                    return "Kumpikaan osapuoli ei saa myydä, vuokrata, pantata tai muutoin luovuttaa yhteistä omaisuutta ilman toisen kirjallista suostumusta. Ilman suostumusta tehdyt luovutukset voidaan julistaa pätemättömiksi."
                } else if isDe {
                    return "Keine Partei darf gemeinsame Vermögenswerte ohne schriftliche Zustimmung der anderen verkaufen, vermieten, verpfänden oder anderweitig veräußern. Ohne Zustimmung vorgenommene Verfügungen können von der nicht zustimmenden Partei angefochten werden."
                } else if isFr {
                    return "Aucune partie ne peut vendre, louer, hypothéquer ou autrement disposer des actifs communs sans le consentement écrit préalable de l'autre. Toute opération effectuée sans ce consentement peut être annulée à la demande de la partie lésée."
                } else if isEs {
                    return "Ninguna parte podrá vender, arrendar, hipotecar o disponer de los activos compartidos sin el consentimiento escrito previo de la otra. Las operaciones realizadas sin dicho consentimiento podrán ser impugnadas por la parte que no lo haya otorgado."
                } else {
                    return "Neither party may sell, lease, mortgage, pledge, or otherwise dispose of any jointly held asset without the prior written consent of both parties. Any transaction entered into without such consent shall be voidable at the non-consenting party's election."
                }
                }
            }(), .plain))
        }

        // § DISPUTE RESOLUTION — Samboappen § 9 (advanced optional)
        if household.includeDisputeResolutionClause {
            sections.append(("\(n).  \(tplTitle(templates, "dispute") ?? t(household, no: "TVISTELØSNING", sv: "TVISTELÖSNING", da: "TVISTLØSNING", fi: "RIIDANRATKAISU", de: "STREITBEILEGUNG", fr: "RÉSOLUTION DES DIFFÉRENDS", es: "RESOLUCIÓN DE DISPUTAS", en: "DISPUTE RESOLUTION"))", {
                n += 1
                return tpl(templates, "dispute") {
                if isNO {
                    return "Eventuelle tvister skal først søkes løst gjennom mekling. Dersom mekling ikke fører frem innen 60 dager fra første meklingsmøte, kan saken bringes inn for ordinære domstoler i den jurisdiksjonen der den primære felles eiendelen befinner seg."
                } else if isSV {
                    return "Tvister som uppstår till följd av detta avtal ska i första hand lösas genom medling. Om medlingen inte löser tvisten inom 60 dagar kan endera parten väcka talan vid allmän domstol."
                } else if isDA {
                    return "Tvister vedrørende denne aftale skal i første omgang søges løst ved mægling. Fører mæglingen ikke til en løsning inden 60 dage, kan enhver af parterne indbringe sagen for de ordinære domstole."
                } else if isFI {
                    return "Sopimuksesta johtuvat riidat pyritään ensisijaisesti ratkaisemaan sovittelulla. Jos sovittelu ei tuota ratkaisua 60 päivässä, kumpi tahansa osapuoli voi saattaa asian toimivaltaisen käräjäoikeuden käsiteltäväksi."
                } else if isDe {
                    return "Streitigkeiten aus oder im Zusammenhang mit diesem Vertrag werden zunächst durch Mediation beigelegt. Führt die Mediation binnen 60 Tagen zu keiner Lösung, können die Parteien die zuständigen ordentlichen Gerichte anrufen."
                } else if isFr {
                    return "Tout différend découlant de la présente convention sera d'abord soumis à médiation. Si aucune solution n'est trouvée dans les 60 jours, l'une ou l'autre partie peut saisir les juridictions judiciaires compétentes."
                } else if isEs {
                    return "Cualquier disputa derivada de este contrato se someterá primero a mediación. Si no se resuelve en 60 días, cualquiera de las partes podrá acudir a los tribunales competentes."
                } else {
                    return "Any dispute arising from or relating to this agreement shall first be referred to mediation. If mediation does not resolve the dispute within 60 days, either party may bring proceedings before the courts of the jurisdiction in which the primary shared asset is located."
                }
                }
            }(), .plain))
        }

        // § PERSONAL DEBT RESPONSIBILITY (optional; mortgage/loan-oriented, presumes co-owned property)
        if household.includeDebtClause && !isRental {
            sections.append(("\(n).  \(tplTitle(templates, "debt") ?? t(household, no: "PERSONLIG GJELDSANSVAR", sv: "PERSONLIGT SKULDANSVAR", da: "PERSONLIGT GÆLDSANSVAR", fi: "HENKILÖKOHTAINEN VELKAVASTUU", de: "PERSÖNLICHE SCHULDENHAFTUNG", fr: "RESPONSABILITÉ PERSONNELLE DES DETTES", es: "RESPONSABILIDAD PERSONAL POR DEUDAS", en: "PERSONAL DEBT RESPONSIBILITY"))", {
                n += 1
                return tpl(templates, "debt") {
                if isNO {
                    return "Gjeld og andre finansielle forpliktelser som en part har pådratt seg — enten før eller under samboerforholdet — er utelukkende den partens eget ansvar. Den andre parten er ikke ansvarlig for slik gjeld overfor kreditorer eller tredjeparter, med mindre begge parter uttrykkelig har avtalt delt ansvar skriftlig."
                } else if isSV {
                    return "Skulder och andra finansiella förpliktelser som en part ådragit sig — oavsett om det skedde före eller under samboförhållandet — är uteslutande den partens eget ansvar. Den andra parten är inte ansvarig för sådana skulder gentemot fordringsägare eller tredje parter, såvida inte båda parter uttryckligen har avtalat om delat ansvar skriftligen."
                } else if isDA {
                    return "Gæld og andre finansielle forpligtelser, som en part har pådraget sig — hvad enten det er sket før eller under samlivsforholdet — er udelukkende den pågældendes eget ansvar. Den anden part er ikke ansvarlig for sådan gæld over for kreditorer eller tredjeparter, medmindre begge parter udtrykkeligt har aftalt delt ansvar skriftligt."
                } else if isFI {
                    return "Velat ja muut taloudelliset velvoitteet, jotka osapuoli on ottanut — ennen avoliittoa tai sen aikana — ovat yksinomaan kyseisen osapuolen omaa vastuuta. Toinen osapuoli ei ole vastuussa tällaisista veloista velkojille tai kolmansille osapuolille, ellei molemmat osapuolet ole nimenomaisesti sopineet yhteisvastuusta kirjallisesti."
                } else if isDe {
                    return "Schulden und andere finanzielle Verpflichtungen, die eine Partei eingegangen ist — ob vor oder während dieser Partnerschaft — liegen ausschließlich in der Verantwortung dieser Partei. Die andere Partei haftet nicht für solche Schulden gegenüber Gläubigern oder Dritten, es sei denn, beide Parteien haben ausdrücklich eine gemeinsame Haftung schriftlich vereinbart."
                } else if isFr {
                    return "Les dettes et autres obligations financières contractées par une partie — avant ou pendant cette union — relèvent exclusivement de la responsabilité de cette partie. L'autre partie n'est pas responsable de ces dettes envers les créanciers ou les tiers, sauf si les deux parties ont expressément convenu d'une responsabilité partagée par écrit."
                } else if isEs {
                    return "Las deudas y otras obligaciones financieras contraídas por una parte — antes o durante esta convivencia — son responsabilidad exclusiva de dicha parte. La otra parte no es responsable de dichas deudas ante acreedores o terceros, salvo que ambas partes hayan acordado expresamente una responsabilidad compartida por escrito."
                } else {
                    return "Debts and other financial obligations incurred by a party — whether before or during this arrangement — are solely that party's responsibility. The other party is not liable for such debts to creditors or third parties, unless both parties have expressly agreed to shared liability in writing."
                }
                }
            }(), .plain))
        }

        // § AMENDMENTS — Samboappen § 11
        sections.append(("\(n).  \(tplTitle(templates, "amendments") ?? t(household, no: "ENDRINGER AV AVTALEN", sv: "ÄNDRINGAR", da: "ÆNDRINGER", fi: "MUUTOKSET", de: "ÄNDERUNGEN", fr: "MODIFICATIONS", es: "MODIFICACIONES", en: "AMENDMENTS"))", {
            n += 1
            return tpl(templates, "amendments") {
            if isNO {
                return "Denne avtalen kan ved enighet endres. Alle endringer må dokumenteres og signeres av begge parter for å være gyldige.\n\nDenne avtalen gjelder så lenge partene er samboere. Den opphører automatisk dersom partene inngår ekteskap eller samboerforholdet opphører. Alle forpliktelser eller krav som har oppstått før opphør, skal fortsatt gjøres opp i henhold til avtalen."
            } else if isSV {
                return "Detta avtal kan ändras när som helst med båda parters skriftliga samtycke. Alla ändringar ska dokumenteras och undertecknas av båda parter för att vara giltiga.\n\nDetta avtal gäller så länge parterna gemensamt innehar de registrerade tillgångarna. Alla skyldigheter eller anspråk som uppkommit före avtalets upphörande ska regleras i enlighet med avtalet."
            } else if isDA {
                return "Denne aftale kan ændres til enhver tid med begge parters skriftlige samtykke. Alle ændringer skal dokumenteres og underskrives af begge parter for at være gyldige.\n\nDenne aftale gælder, så længe parterne i fællesskab ejer de registrerede aktiver. Alle forpligtelser eller krav opstået inden aftalens ophør reguleres i overensstemmelse med aftalen."
            } else if isFI {
                return "Tätä sopimusta voidaan muuttaa milloin tahansa molempien osapuolten kirjallisella suostumuksella. Kaikki muutokset on dokumentoitava ja molempien allekirjoitettava.\n\nSopimus on voimassa niin kauan kuin osapuolet omistavat yhdessä rekisteröidyt varat. Kaikki ennen sopimuksen päättymistä syntyneet velvoitteet ratkaistaan sopimuksen mukaisesti."
            } else if isDe {
                return "Dieser Vertrag kann jederzeit mit schriftlicher Zustimmung beider Parteien geändert werden. Alle Änderungen sind zu dokumentieren und von beiden zu unterzeichnen.\n\nDer Vertrag gilt, solange die Parteien gemeinsam die eingetragenen Vermögenswerte halten. Alle vor Vertragsende entstandenen Verpflichtungen werden vertragsgemäß abgewickelt."
            } else if isFr {
                return "La présente convention peut être modifiée à tout moment avec le consentement écrit des deux parties. Toute modification doit être documentée et signée par les deux parties.\n\nLa convention reste en vigueur tant que les parties détiennent en commun les actifs enregistrés. Toutes les obligations nées avant son terme sont réglées conformément à ses stipulations."
            } else if isEs {
                return "Este contrato puede modificarse en cualquier momento con el consentimiento escrito de ambas partes. Toda modificación debe documentarse y firmarse.\n\nEl contrato estará vigente mientras las partes posean conjuntamente los activos registrados. Todas las obligaciones surgidas antes de su terminación se regularán conforme a él."
            } else {
                return "This agreement may be amended at any time by the written consent of both parties. All amendments must be documented and signed by both parties to be valid.\n\nThis agreement remains in force for as long as the parties jointly hold the assets recorded herein. All obligations or claims arising before termination shall continue to be settled in accordance with this agreement."
            }
            }
        }(), .plain))

        // § GOVERNING LAW
        sections.append(("\(n).  \(tplTitle(templates, "governing_law") ?? t(household, no: "LOVVALG", sv: "TILLÄMPLIG LAG", da: "LOVVALG", fi: "SOVELLETTAVA LAKI", de: "ANWENDBARES RECHT", fr: "LOI APPLICABLE", es: "LEY APLICABLE", en: "GOVERNING LAW"))", {
            // English US-specific variant — no template; kept purely inline.
            if isUS(household) {
                return "This agreement is governed by the laws of the state where the parties reside or where their primary shared asset is located. Cohabitation agreements vary in enforceability by state — any provision found unenforceable shall be severed without affecting the remainder. Both parties are encouraged to seek independent legal advice before signing."
            }
            return tpl(templates, "governing_law") {
            if isNO {
                return "Denne avtalen reguleres av norsk lov. Tvister som ikke løses mellom partene, bringes inn for de ordinære domstoler."
            } else if isSwedish(household) {
                return "Detta avtal regleras av svensk rätt. Tvister som inte kan lösas mellan parterna hänskjuts till allmän domstol."
            } else if isDanish(household) {
                return "Denne aftale er underlagt dansk ret. Tvister, der ikke løses i mindelighed, indbringes for de ordinære domstole."
            } else if isFinnish(household) {
                return "Tähän sopimukseen sovelletaan Suomen lakia. Osapuolten väliset riidat, joita ei voida ratkaista sovinnollisesti, saatetaan toimivaltaisen käräjäoikeuden käsiteltäväksi."
            } else if isDe {
                return "Dieser Vertrag unterliegt deutschem Recht. Streitigkeiten, die nicht gütlich beigelegt werden können, werden vor den zuständigen ordentlichen Gerichten ausgetragen."
            } else if isFr {
                return "La présente convention est régie par le droit français. Tout différend qui ne peut être résolu à l'amiable est soumis aux juridictions judiciaires compétentes."
            } else if isEs {
                return "Este contrato se rige por la legislación española. Las disputas que no puedan resolverse amistosamente se someterán a los tribunales competentes de la jurisdicción donde se encuentre el activo principal compartido."
            } else {
                return "This agreement is governed by the law of England and Wales. Any disputes that cannot be resolved between the parties shall be referred to the courts of England and Wales."
            }
            }
        }(), .plain))

        return sections
    }

    // MARK: - Contribution label helper

    /// Display names for the contract's asset sections. When several assets
    /// share the same label, the address (or the asset type when no address is
    /// registered) is appended so the same name can identify the asset in both
    /// the assets overview and the contributions section.
    private static func assetDisplayNames(household: Household) -> [UUID: String] {
        func key(_ a: Asset) -> String {
            a.label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        var counts: [String: Int] = [:]
        for a in household.assets { counts[key(a), default: 0] += 1 }
        var names: [UUID: String] = [:]
        for a in household.assets where (counts[key(a)] ?? 0) > 1 {
            let addr = a.address.trimmingCharacters(in: .whitespacesAndNewlines)
            if !addr.isEmpty {
                names[a.id] = "\(a.label) (\(addr))"
            } else {
                names[a.id] = "\(a.label) (\(assetCategory(a, isNO: isNorwegian(household), isSV: isSwedish(household))))"
            }
        }
        return names
    }

    private static func assetCategory(_ asset: Asset, isNO: Bool, isSV: Bool = false) -> String {
        if isSV {
            switch AssetType(rawValue: asset.assetType) ?? .other {
            case .home:       return "Bostad"
            case .cabin:      return "Fritidsboende"
            case .car:        return "Motorfordon"
            case .savings:    return "Sparkonto"
            case .investment: return "Investeringsportfölj"
            case .furniture:  return "Möbler och inventarier"
            case .pet:        return "Sällskapsdjur"
            case .other:      return "Övrig tillgång"
            }
        }
        switch AssetType(rawValue: asset.assetType) ?? .other {
        case .home:       return isNO ? "Bolig"                    : "Residential property"
        case .cabin:      return isNO ? "Fritidseiendom"           : "Leisure/holiday property"
        case .car:        return isNO ? "Motorvogn"                : "Motor vehicle"
        case .savings:    return isNO ? "Sparekonto"               : "Savings account"
        case .investment: return isNO ? "Investeringsportefølje"   : "Investment portfolio"
        case .furniture:  return isNO ? "Møbler og inventar"       : "Furniture and furnishings"
        case .pet:        return isNO ? "Kjæledyr"                 : "Pet"
        case .other:      return isNO ? "Øvrig eiendel"            : "Other asset"
        }
    }

    // MARK: - Drawing helpers

    private typealias Attrs = [NSAttributedString.Key: Any]

    private static func hRule(at y: CGFloat, margin: CGFloat, pageW: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageW - margin, y: y))
        UIColor(white: 0.8, alpha: 1).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private static func signLine(from: CGPoint, to: CGPoint) {
        let path = UIBezierPath()
        path.move(to: from); path.addLine(to: to)
        UIColor(white: 0.5, alpha: 1).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
}
