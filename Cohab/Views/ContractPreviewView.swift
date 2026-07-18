import SwiftUI

/// Shows the full contract text (all active clauses) so users can review
/// exactly what will appear in the signed PDF before generating it.
struct ContractPreviewView: View {
    let household: Household
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var pm: PurchaseManager
    @ObservedObject private var strings = AppStrings.shared
    @State private var showPaywall = false

    private var sections: [(title: String, body: String)] {
        ContractGenerator.previewSections(household: household)
    }

    // Number of sections shown clearly before blur kicks in — everything
    // unlocks once the user has formal access.
    private var visibleSections: Int { pm.hasFormalAccess ? sections.count : 1 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Document header — always fully visible
                    docHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                    // Sections — first N clear, rest blurred
                    ZStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(sections.enumerated()), id: \.offset) { idx, section in
                                sectionView(section)
                                    .blur(radius: idx >= visibleSections ? 6 : 0)
                                    .allowsHitTesting(idx < visibleSections)
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
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
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

    private func sectionView(_ section: (title: String, body: String)) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section title
            Text(section.title)
                .font(.caption.bold())
                .tracking(0.5)
                .foregroundStyle(Color.cohGreen)
                .padding(.top, 4)

            // Body text
            Text(section.body)
                .font(.subheadline)
                .foregroundStyle(Color.cohInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .padding(.top, 8)
        }
        .padding(.vertical, 12)
    }
}
