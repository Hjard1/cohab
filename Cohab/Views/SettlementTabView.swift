import SwiftUI
import SwiftData

// MARK: - Equity / Settlement tab
//
// Redesigned "Egenkapital" overview. Only layout/styling changed — the
// calculation logic (SettlementEngine inputs) is identical to before.

struct SettlementTabView: View {
    @Query private var households: [Household]
    @ObservedObject private var strings = AppStrings.shared
    /// nil = show all asset types
    @State private var filter: AssetType?

    private var household: Household? { households.first }

    private static let typeOrder: [AssetType] = [.home, .cabin, .car, .savings, .investment, .furniture, .pet, .other]

    private func sortedAssets(_ assets: [Asset]) -> [Asset] {
        assets.sorted { (Self.typeOrder.firstIndex(of: $0.type) ?? 99) < (Self.typeOrder.firstIndex(of: $1.type) ?? 99) }
    }

    /// Same default assumptions as the per-asset detail view (SettlementView):
    /// sale at current value, loan repaid, sale costs = salesCostFraction.
    private func computeTotals(_ h: Household) -> (a: Double, b: Double) {
        h.assets.reduce((a: 0.0, b: 0.0)) { acc, asset in
            let r = SettlementEngine.settle(SettlementInput(
                salePrice: asset.currentValue, remainingLoan: asset.remainingLoan,
                salesCosts: asset.currentValue * asset.salesCostFraction,
                ownershipShareA: asset.ownershipShareA,
                annualRate: h.annualInterestRate,
                contributions: asset.contributions.map {
                    Contribution(owner: $0.ownerKey == "A" ? .a : .b,
                                 amount: $0.amount, date: $0.date, label: $0.label)
                },
                settlementDate: Date()
            ))
            return (a: acc.a + (r.payout[.a] ?? 0),
                    b: acc.b + (r.payout[.b] ?? 0))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cohBg.ignoresSafeArea()

                if let h = household, !h.assets.isEmpty {
                    content(h)
                } else {
                    emptyState
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Content

    private func content(_ h: Household) -> some View {
        let totals = computeTotals(h)
        let assets = sortedAssets(h.assets)
        let presentTypes = Self.typeOrder.filter { t in assets.contains { $0.type == t } }
        let shown = assets.filter { filter == nil || $0.type == filter }

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                reportHeader(h)

                EquitySummaryCard(household: h, totalA: totals.a, totalB: totals.b)
                    .padding(.horizontal, 20)

                // Type filters — only when the data actually spans types
                if presentTypes.count > 1 {
                    filterChips(presentTypes)
                        .padding(.top, 20)
                }

                Text(strings.equityPerAsset)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.cohInk)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                VStack(spacing: 10) {
                    ForEach(shown) { asset in
                        NavigationLink(destination: SettlementView(asset: asset, household: h)) {
                            AssetEquityRow(asset: asset, household: h)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Text(strings.settlementEstimateNote)
                    .font(.caption)
                    .foregroundStyle(Color.cohTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
            }
            // Generous bottom inset: the last row must scroll fully clear
            // of the floating tab bar.
            .padding(.bottom, 120)
        }
    }

    // MARK: Header

    private func reportHeader(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.equityOverviewTitle)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(Color.cohInk)
                    Text("\(h.partnerAName) & \(h.partnerBName)")
                        .font(.subheadline).foregroundStyle(Color.cohSecondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption).foregroundStyle(Color.cohGreen)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(strings.equityUpdated)
                            .font(.caption).foregroundStyle(Color.cohTertiary)
                        Text(Date(), style: .date)
                            .font(.caption.monospacedDigit()).foregroundStyle(Color.cohSecondary)
                    }
                }
                .padding(10)
                .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }
            Text(strings.equityTabSub)
                .font(.subheadline)
                .foregroundStyle(Color.cohSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: Filter chips

    private func filterChips(_ types: [AssetType]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: strings.filterAll, selected: filter == nil) { filter = nil }
                ForEach(types, id: \.self) { t in
                    chip(label: t.displayName, selected: filter == t) { filter = t }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chip(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? .white : Color.cohInk)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)   // minimum touch target
                .background(
                    selected
                        ? Color.cohGreen
                        : Color.cohCard,
                    in: Capsule()
                )
                .overlay(
                    Capsule().strokeBorder(selected ? Color.clear : Color(.separator).opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(Color.cohGreen.opacity(0.08)).frame(width: 100, height: 100)
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 44)).foregroundStyle(Color.cohGreen)
            }
            VStack(spacing: 8) {
                Text(strings.equityOverviewTitle).font(.title2.bold())
                Text(strings.settlementNoAssets)
                    .font(.subheadline).foregroundStyle(Color.cohSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cohBg.ignoresSafeArea())
    }
}

// MARK: - Equity summary card

struct EquitySummaryCard: View {
    let household: Household
    let totalA: Double
    let totalB: Double
    @ObservedObject private var strings = AppStrings.shared

    private var combined: Double { totalA + totalB }
    private var shareA: Double { combined > 0 ? totalA / combined : 0.5 }

    var body: some View {
        // Keep the displayed partner amounts consistent with the displayed
        // total: B is derived from the rounded total minus rounded A.
        let displayTotal = Int(combined)
        let displayA = Int(totalA)
        let displayB = displayTotal - displayA

        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(strings.totalCombinedEquity)
                    .font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
                Text(household.moneyText(Double(displayTotal)))
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.cohInk)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(strings.equityEstimatedSaleToday)
                    .font(.caption).foregroundStyle(Color.cohTertiary)
            }
            .accessibilityElement(children: .combine)

            EquityDistributionBar(shareA: shareA)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(household.partnerAName) \(shareA.formatted(.percent.precision(.fractionLength(1)))), "
                    + "\(household.partnerBName) \((1 - shareA).formatted(.percent.precision(.fractionLength(1))))"
                )

            HStack(alignment: .top) {
                PartnerEquitySummary(name: household.partnerAName, color: .cohGreen,
                                     share: shareA, amount: displayA, household: household)
                Spacer()
                PartnerEquitySummary(name: household.partnerBName, color: .cohBlue,
                                     share: 1 - shareA, amount: displayB, household: household,
                                     alignment: .trailing)
            }
        }
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
    }
}

// MARK: - Partner equity summary

struct PartnerEquitySummary: View {
    let name: String
    let color: Color
    let share: Double
    let amount: Int
    let household: Household
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 3) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(name)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohInk)
                    .lineLimit(1)
                Text(share.formatted(.percent.precision(.fractionLength(1))))
                    .font(.subheadline).foregroundStyle(Color.cohSecondary)
            }
            Text(household.moneyText(Double(amount)))
                .font(.caption.monospacedDigit()).foregroundStyle(Color.cohSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Equity distribution bar

struct EquityDistributionBar: View {
    /// Partner A's fraction of the total (0–1). A = green, B = blue.
    let shareA: Double

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.cohGreen)
                    .frame(width: max(geo.size.width * min(max(shareA, 0), 1) - 1.5, 8))
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.cohBlue)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Asset equity row

struct AssetEquityRow: View {
    let asset: Asset
    let household: Household
    @ObservedObject private var strings = AppStrings.shared

    // Same default assumptions as SettlementView (sale at current value,
    // loan repaid, sale costs = salesCostFraction) so the row and the
    // detail view always agree.
    private var result: SettlementResult {
        SettlementEngine.settle(SettlementInput(
            salePrice: asset.currentValue, remainingLoan: asset.remainingLoan,
            salesCosts: asset.currentValue * asset.salesCostFraction,
            ownershipShareA: asset.ownershipShareA,
            annualRate: household.annualInterestRate,
            contributions: asset.contributions.map {
                Contribution(owner: $0.ownerKey == "A" ? .a : .b,
                             amount: $0.amount, date: $0.date, label: $0.label)
            },
            settlementDate: Date()
        ))
    }

    private var shareA: Double { asset.ownershipShareA }
    /// Amount tint follows the majority owner (green = A, blue = B).
    private var accent: Color { shareA >= 0.5 ? .cohGreen : .cohBlue }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(asset.type.color.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: asset.type.icon)
                    .font(.subheadline).foregroundStyle(asset.type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(asset.label)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohInk)
                Text("\(asset.type.displayName) · \(strings.equityYourOwnership) \(Int((shareA * 100).rounded())) %")
                    .font(.caption).foregroundStyle(Color.cohSecondary)
                Text("\(strings.equityCombinedNetValue): \(household.moneyText(asset.netEquity))")
                    .font(.caption).foregroundStyle(Color.cohTertiary)
            }

            Spacer(minLength: 8)

            // The app user is partner A — this is THEIR calculated equity
            // from this asset, not a shared total.
            VStack(alignment: .trailing, spacing: 2) {
                Text(household.moneyText(result.payout[.a] ?? 0))
                    .font(.subheadline.bold().monospacedDigit()).foregroundStyle(accent)
                Text(strings.equityYourCalculated)
                    .font(.caption2).foregroundStyle(Color.cohTertiary)
                    .multilineTextAlignment(.trailing)
            }

            Image(systemName: "chevron.right")
                .font(.caption.bold()).foregroundStyle(Color.cohTertiary)
        }
        .padding(14)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Household.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let h = Household(partnerAName: "Fredrik", partnerBName: "Nora",
                      country: "NO", currency: "NOK")
    h.assets = [
        Asset(assetType: "home", label: "Gruvemyra", address: "Gruvemyra 79",
              currentValue: 6_960_000, remainingLoan: 4_500_000, ownershipShareA: 0.6),
        Asset(assetType: "cabin", label: "Isfjorden",
              currentValue: 7_840_000, remainingLoan: 4_000_000, ownershipShareA: 0.5),
        Asset(assetType: "car", label: "Volvo EX30",
              currentValue: 600_000, remainingLoan: 300_000, ownershipShareA: 0.5),
        Asset(assetType: "savings", label: "Felles sparing",
              currentValue: 150_000, remainingLoan: 0, ownershipShareA: 0.5),
    ]
    container.mainContext.insert(h)
    return SettlementTabView().modelContainer(container)
}
