import UIKit
import Foundation

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

    static func generate(household: Household, date: Date = Date()) -> Output {
        let pageSize = CGSize(width: 595, height: 842)   // A4 @ 72 dpi
        let margin: CGFloat = 56
        let contentW = pageSize.width - margin * 2
        let layout = Layout()

        let pdfData = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize)
        ).pdfData { ctx in

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
            let rightTitle = "Shared Asset & Ownership Agreement"
            let rSize = (rightTitle as NSString).size(withAttributes: subtitleAttrs)
            rightTitle.draw(at: CGPoint(x: pageSize.width - margin - rSize.width, y: 20),
                            withAttributes: subtitleAttrs)
            y = headerH + 24

            // ── Parties & date ───────────────────────────────────────────────
            let dateStr = DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .none)
            let smallAttrs: Attrs = [.font: UIFont.systemFont(ofSize: 11),
                                     .foregroundColor: UIColor(white: 0.25, alpha: 1)]
            let tinyAttrs: Attrs  = [.font: UIFont.systemFont(ofSize: 9),
                                     .foregroundColor: UIColor(white: 0.5, alpha: 1)]
            "Between \(household.partnerAName) and \(household.partnerBName)  ·  Dated \(dateStr)"
                .draw(at: CGPoint(x: margin, y: y), withAttributes: smallAttrs)
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

            for section in buildSections(household: household) {
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
            "SIGNATURES".draw(at: CGPoint(x: margin, y: y), withAttributes: sigHeaderAttrs)
            y += 22

            // Record signature position BEFORE drawing (this is where DocuSeal fields go).
            // currentPage is 1-based after the first newPage(), so subtract 1 for 0-indexed.
            layout.sigY    = y
            layout.sigPage = layout.currentPage - 1   // 0-indexed

            let nameAttrs: Attrs = [.font: UIFont.systemFont(ofSize: 11, weight: .medium),
                                    .foregroundColor: UIColor(white: 0.18, alpha: 1)]
            let captionAttrs: Attrs = [.font: UIFont.systemFont(ofSize: 8.5),
                                       .foregroundColor: UIColor(white: 0.5, alpha: 1)]
            let midX   = pageSize.width / 2
            let lineY  = y + 44

            household.partnerAName.draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttrs)
            signLine(from: CGPoint(x: margin, y: lineY), to: CGPoint(x: midX - 24, y: lineY))
            "Signature".draw(at: CGPoint(x: margin, y: lineY + 5), withAttributes: captionAttrs)
            if !household.emailA.isEmpty {
                household.emailA.draw(at: CGPoint(x: margin, y: lineY + 15), withAttributes: captionAttrs)
            }

            household.partnerBName.draw(at: CGPoint(x: midX + 16, y: y), withAttributes: nameAttrs)
            signLine(from: CGPoint(x: midX + 16, y: lineY), to: CGPoint(x: pageSize.width - margin, y: lineY))
            "Signature".draw(at: CGPoint(x: midX + 16, y: lineY + 5), withAttributes: captionAttrs)
            if !household.emailB.isEmpty {
                household.emailB.draw(at: CGPoint(x: midX + 16, y: lineY + 15), withAttributes: captionAttrs)
            }

            // Footer — disclaimer + branding
            let lang = AppLanguage.from(country: household.country)
            AppStrings.shared.language = lang
            let footerText = AppStrings.shared.disclaimerFooter
            let footerAttrs: Attrs = [.font: UIFont.systemFont(ofSize: 7.5),
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

    private static func buildSections(household: Household) -> [(title: String, body: String)] {
        let rateStr = String(format: "%.0f%%", household.annualInterestRate * 100)
        var n = 1
        var sections: [(title: String, body: String)] = []

        sections.append(("\(n).  SCOPE", {
            let dissolution = household.includeDissolutionClause
                ? ", and establishes terms for asset distribution if the arrangement ends" : ""
            n += 1
            return "This agreement defines the ownership of shared assets recorded in the cohab application\(dissolution). Both parties agree to maintain accurate records of all jointly held assets and equity contributions."
        }()))

        sections.append(("\(n).  SHARED ASSETS", {
            n += 1
            let list = household.assets.isEmpty
                ? "No assets registered at signing. Assets will be added by mutual agreement."
                : household.assets.map {
                    "• \($0.label) — \($0.type.displayName), \(Int($0.ownershipShareA * 100))% / \(Int((1 - $0.ownershipShareA) * 100))%"
                  }.joined(separator: "\n")
            return "The parties jointly hold the following assets. Ownership percentages are as registered in the cohab application:\n\n\(list)"
        }()))

        sections.append(("\(n).  EQUITY CONTRIBUTIONS", {
            n += 1
            return "Contributions — including deposits, extra mortgage payments, renovations, and other capital inputs — are recorded digitally. Each contribution accrues interest at \(rateStr) per annum, compounded annually, from the date of contribution to final settlement."
        }()))

        if household.includeDissolutionClause {
            sections.append(("\(n).  DISSOLUTION", {
                n += 1
                return "In the event this arrangement ends:\n\n(a) Each party's contributions with accrued interest are returned first.\n\n(b) If proceeds are insufficient, available funds are split in proportion to total contributions.\n\n(c) Any surplus is divided by registered ownership percentage."
            }()))
        }

        sections.append(("\(n).  AMENDMENTS", {
            n += 1
            return "This agreement may be amended at any time by written consent of both parties."
        }()))

        sections.append(("\(n).  GOVERNING LAW", {
            return "This agreement is governed by the laws of the jurisdiction where the primary shared asset is located."
        }()))

        return sections
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
