import SwiftUI

/// Shows the full contract text (all active clauses) so users can review
/// exactly what will appear in the signed PDF before generating it.
struct ContractPreviewView: View {
    let household: Household
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var pm: PurchaseManager
    @ObservedObject private var strings = AppStrings.shared
    @State private var showPaywall = false
    /// DB-published clause templates for the document language; empty map
    /// renders the bundled fallback strings (offline / not yet loaded).
    @State private var templates: [String: ContractTemplate] = [:]

    private var sections: [(title: String, body: String, kind: ContractSectionKind)] {
        ContractGenerator.previewSections(household: household, templates: templates)
    }

    /// How much of a section is shown before purchase.
    private enum SectionVisibility {
        case full
        case blurred
        /// The contract text itself teases one asset / one contribution.
        case teaser(visible: String, hidden: String)
    }

    private func visibility(for section: (title: String, body: String, kind: ContractSectionKind), idx: Int) -> SectionVisibility {
        if pm.hasFormalAccess || idx == 0 { return .full }
        switch section.kind {
        case .assets:
            // Body is intro + one block per asset + closing clauses, separated
            // by blank lines — reveal the intro and the first asset only.
            let comps = section.body.components(separatedBy: "\n\n")
            guard comps.count > 2 else { return .full }
            return .teaser(visible: comps.prefix(2).joined(separator: "\n\n") + "\n\n",
                           hidden: comps.dropFirst(2).joined(separator: "\n\n"))
        case .contributions:
            // Contribution rows are indented with two spaces — reveal
            // everything up to and including the first row.
            let lines = section.body.components(separatedBy: "\n")
            guard let firstRow = lines.firstIndex(where: { $0.hasPrefix("  ") }) else { return .full }
            return .teaser(visible: lines[...firstRow].joined(separator: "\n") + "\n",
                           hidden: lines[(firstRow + 1)...].joined(separator: "\n"))
        case .plain:
            return .blurred
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Document header — always fully visible
                    docHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                    // Sections — first clear, assets/contributions teased,
                    // rest blurred until purchase
                    ZStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(sections.enumerated()), id: \.offset) { idx, section in
                                sectionView(section, idx: idx)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, pm.hasFormalAccess ? 0 : 160)

                        // Gradient + unlock CTA over blurred content
                        if !pm.hasFormalAccess {
                            VStack(spacing: 0) {
                                LinearGradient(
                                    colors: [Color.cohBg.opacity(0), Color.cohBg],
                                    startPoint: .top, endPoint: .bottom
                                )
                                .frame(height: 120)

                                VStack(spacing: 12) {
                                    Button { showPaywall = true } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "lock.fill")
                                                .font(.subheadline)
                                                .foregroundStyle(Color.cohGreen)
                                            Text(strings.agreementGenerate)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(Color.cohInk)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
                                        .shadow(color: .black.opacity(0.06), radius: 12, y: 3)
                                        .padding(.horizontal, 24)
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(sections.count) \(strings.contractClausesIncluded)")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.cohSecondary)
                                }
                                .padding(.bottom, 24)
                                .background(Color.cohBg)
                            }
                        }
                    }
                }
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle(strings.contractPreviewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.cancel) { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            templates = await ContractTemplateStore.templates(
                for: ContractGenerator.docLanguageCode(household: household))
        }
    }

    // MARK: Document header

    private var docHeader: some View {
        VStack(spacing: 16) {
            // Branded header band (mirrors the PDF)
            HStack {
                Text("cohab")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(Color.cohGreen)
                Spacer()
                Text(strings.contractHeaderTitle)
                    .font(.caption)
                    .foregroundStyle(Color.cohSecondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color.cohGreen.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))

            // Parties
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: strings.contractBetween, household.partnerAName, household.partnerBName))
                    .font(.subheadline.weight(.medium)).foregroundStyle(Color.cohInk)
                Text(strings.contractDatedAtSigning)
                    .font(.caption).foregroundStyle(Color.cohSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)

            // Clause count
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.cohGreen).font(.caption)
                Text("\(sections.count) \(strings.contractClausesIncluded)")
                    .font(.caption.weight(.medium)).foregroundStyle(Color.cohSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Section view

    private func sectionView(_ section: (title: String, body: String, kind: ContractSectionKind), idx: Int) -> some View {
        let vis = visibility(for: section, idx: idx)
        return VStack(alignment: .leading, spacing: 12) {
            // Section title — editorial heading, clearly separated from the
            // body text so the document is scannable.
            Text(section.title)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(Color.cohInk)
                .fixedSize(horizontal: false, vertical: true)

            // Body text
            switch vis {
            case .full:
                bodyText(section.body)
            case .blurred:
                bodyText(section.body)
                    .blur(radius: 6)
            case .teaser(let visible, let hidden):
                VStack(alignment: .leading, spacing: 0) {
                    bodyText(visible)
                    bodyText(hidden)
                        .blur(radius: 6)
                }
            }

            Divider()
                .padding(.top, 10)
        }
        .padding(.vertical, 18)
    }

    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Color.cohInk)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}
