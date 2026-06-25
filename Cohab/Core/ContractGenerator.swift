import UIKit
import Foundation

/// Generates an A4 PDF for the shared asset & ownership agreement.
/// Returns the raw PDF bytes and the Y coordinate where the signature
/// block starts — passed to DocuSeal for signature field placement.
enum ContractGenerator {

    struct Output {
        let pdfData: Data
        let sigY: CGFloat      // top of signature block, in A4 points (origin top-left)
    }

    static func generate(household: Household, date: Date = Date()) -> Output {
        let pageSize = CGSize(width: 595, height: 842)   // A4 at 72 dpi
        let margin: CGFloat = 56
        let contentW = pageSize.width - margin * 2

        var sigY: CGFloat = 700

        let pdfData = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize)
        ).pdfData { ctx in
            ctx.beginPage()

            var y: CGFloat = 0

            // ── Header band ──────────────────────────────────────────────────
            let headerH: CGFloat = 52
            let headerRect = CGRect(x: 0, y: 0, width: pageSize.width, height: headerH)
            UIColor(red: 0.10, green: 0.68, blue: 0.45, alpha: 1).setFill()
            UIBezierPath(rect: headerRect).fill()

            let brandAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.white,
                .kern: 3.0
            ]
            "cohab".draw(at: CGPoint(x: margin, y: 18), withAttributes: brandAttrs)

            let titleRightAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.white.withAlphaComponent(0.85)
            ]
            let rightTitle = "Shared Asset & Ownership Agreement"
            let rightTitleSize = (rightTitle as NSString).size(withAttributes: titleRightAttrs)
            rightTitle.draw(
                at: CGPoint(x: pageSize.width - margin - rightTitleSize.width, y: 20),
                withAttributes: titleRightAttrs
            )
            y = headerH + 24

            // ── Parties & date ───────────────────────────────────────────────
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateStr = dateFormatter.string(from: date)

            let partiesAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor(white: 0.25, alpha: 1)
            ]
            let parties = "Between \(household.partnerAName) and \(household.partnerBName)  ·  Dated \(dateStr)"
            parties.draw(at: CGPoint(x: margin, y: y), withAttributes: partiesAttrs)
            y += 18

            if !household.emailA.isEmpty || !household.emailB.isEmpty {
                let emails = "\(household.partnerAName): \(household.emailA)   \(household.partnerBName): \(household.emailB)"
                let emailAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9),
                    .foregroundColor: UIColor(white: 0.5, alpha: 1)
                ]
                emails.draw(at: CGPoint(x: margin, y: y), withAttributes: emailAttrs)
                y += 14
            }
            y += 6

            // Divider
            y = drawHRule(at: y, margin: margin, width: pageSize.width, ctx: ctx)
            y += 14

            // ── Numbered sections ────────────────────────────────────────────
            let sections = buildSections(household: household)

            let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor(red: 0.10, green: 0.68, blue: 0.45, alpha: 1)
            ]
            let bodyStyle = NSMutableParagraphStyle()
            bodyStyle.lineSpacing = 2.5
            bodyStyle.paragraphSpacing = 0
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10.5),
                .foregroundColor: UIColor(white: 0.18, alpha: 1),
                .paragraphStyle: bodyStyle
            ]

            for section in sections {
                // Page break if needed (leave 140pt for signature block)
                if y > pageSize.height - 160 {
                    ctx.beginPage()
                    y = 40
                }

                section.title.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitleAttrs)
                y += 16

                let attributed = NSAttributedString(string: section.body, attributes: bodyAttrs)
                let drawn = drawAttributedText(attributed, at: CGPoint(x: margin, y: y),
                                               width: contentW, pageH: pageSize.height,
                                               ctx: ctx)
                y += drawn + 20
            }

            // ── Signature block ──────────────────────────────────────────────
            if y > pageSize.height - 120 {
                ctx.beginPage()
                y = 40
            }
            y += 8
            y = drawHRule(at: y, margin: margin, width: pageSize.width, ctx: ctx)
            y += 16

            let sigHeaderAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor(red: 0.10, green: 0.68, blue: 0.45, alpha: 1),
                .kern: 1.0
            ]
            "SIGNATURES".draw(at: CGPoint(x: margin, y: y), withAttributes: sigHeaderAttrs)
            y += 22

            sigY = y   // ← returned to caller for DocuSeal field placement

            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor(white: 0.18, alpha: 1)
            ]
            let captionAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8.5),
                .foregroundColor: UIColor(white: 0.5, alpha: 1)
            ]

            let midX = pageSize.width / 2
            let lineY = y + 44

            // Left: Partner A
            household.partnerAName.draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttrs)
            drawSignLine(from: CGPoint(x: margin, y: lineY), to: CGPoint(x: midX - 24, y: lineY))
            "Signature".draw(at: CGPoint(x: margin, y: lineY + 5), withAttributes: captionAttrs)
            if !household.emailA.isEmpty {
                household.emailA.draw(at: CGPoint(x: margin, y: lineY + 15), withAttributes: captionAttrs)
            }

            // Right: Partner B
            household.partnerBName.draw(at: CGPoint(x: midX + 16, y: y), withAttributes: nameAttrs)
            drawSignLine(from: CGPoint(x: midX + 16, y: lineY), to: CGPoint(x: pageSize.width - margin, y: lineY))
            "Signature".draw(at: CGPoint(x: midX + 16, y: lineY + 5), withAttributes: captionAttrs)
            if !household.emailB.isEmpty {
                household.emailB.draw(at: CGPoint(x: midX + 16, y: lineY + 15), withAttributes: captionAttrs)
            }

            // Footer
            let footerY = pageSize.height - 24
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor(white: 0.65, alpha: 1)
            ]
            "Generated by cohab · cohab.app".draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttrs)
        }

        return Output(pdfData: pdfData, sigY: sigY)
    }

    // MARK: - Contract sections

    private static func buildSections(household: Household) -> [(title: String, body: String)] {
        let rateStr = String(format: "%.0f%%", household.annualInterestRate * 100)
        var n = 1
        var sections: [(title: String, body: String)] = []

        sections.append(("\(n).  SCOPE", {
            let dissolution = household.includeDissolutionClause
                ? ", and establishes terms for the distribution of assets in the event the arrangement ends"
                : ""
            n += 1
            return "This agreement defines the ownership of shared assets recorded in the cohab application\(dissolution). Both parties agree to maintain accurate records of all jointly held assets and equity contributions."
        }()))

        sections.append(("\(n).  SHARED ASSETS", {
            n += 1
            let assetList = household.assets.isEmpty
                ? "No assets are registered at the time of signing. Assets shall be added to the cohab application by mutual agreement."
                : household.assets.map { "• \($0.label) — \($0.type.displayName), \(Int($0.ownershipShareA * 100))% / \(Int((1 - $0.ownershipShareA) * 100))%" }.joined(separator: "\n")
            return "The parties jointly hold the assets listed below. Ownership percentages reflect each party's registered share at the time of signing and are maintained in the cohab application.\n\n\(assetList)"
        }()))

        sections.append(("\(n).  EQUITY CONTRIBUTIONS", {
            n += 1
            return "Equity contributions — including initial deposits, additional mortgage payments, renovations, and other capital inputs — are recorded digitally in the cohab application. Each contribution accrues interest at \(rateStr) per annum, compounded annually, from the date of contribution to the date of final settlement."
        }()))

        if household.includeDissolutionClause {
            sections.append(("\(n).  DISSOLUTION", {
                n += 1
                return "In the event this arrangement ends, shared assets shall be distributed as follows:\n\n(a) Each party's recorded equity contributions, together with accrued interest at the agreed annual rate, are returned first.\n\n(b) If net proceeds are insufficient to return all contributions in full, the available amount is distributed in proportion to each party's total contributions.\n\n(c) Any surplus after the full return of contributions is distributed in proportion to each party's registered ownership percentage."
            }()))
        }

        sections.append(("\(n).  AMENDMENTS", {
            n += 1
            return "This agreement may be amended at any time by the written consent of both parties. Amendments shall be recorded as a signed addendum and maintained alongside this agreement."
        }()))

        sections.append(("\(n).  GOVERNING LAW", {
            return "This agreement shall be governed by the laws applicable in the jurisdiction where the parties' primary shared asset is located."
        }()))

        return sections
    }

    // MARK: - Drawing helpers

    @discardableResult
    private static func drawHRule(at y: CGFloat, margin: CGFloat, width: CGFloat, ctx: UIGraphicsPDFRendererContext) -> CGFloat {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: width - margin, y: y))
        UIColor(white: 0.8, alpha: 1).setStroke()
        path.lineWidth = 0.5
        path.stroke()
        return y
    }

    private static func drawSignLine(from: CGPoint, to: CGPoint) {
        let path = UIBezierPath()
        path.move(to: from)
        path.addLine(to: to)
        UIColor(white: 0.5, alpha: 1).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    /// Draws attributed text with line wrapping and returns the rendered height.
    /// Handles page breaks by starting a new page when text overflows.
    private static func drawAttributedText(
        _ text: NSAttributedString,
        at point: CGPoint,
        width: CGFloat,
        pageH: CGFloat,
        ctx: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        let maxH: CGFloat = 4000
        let boundingRect = text.boundingRect(
            with: CGSize(width: width, height: maxH),
            options: .usesLineFragmentOrigin,
            context: nil
        )
        let drawRect = CGRect(x: point.x, y: point.y, width: width, height: boundingRect.height)
        text.draw(in: drawRect)
        return boundingRect.height
    }
}
