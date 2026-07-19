import SwiftUI
import SwiftData

// MARK: - Equity / Settlement tab

struct SettlementTabView: View {
    @Query private var households: [Household]
    @ObservedObject private var strings = AppStrings.shared

    private var household: Household? { households.first }

    private func sortedAssets(_ assets: [Asset]) -> [Asset] {
        let order: [AssetType] = [.home, .cabin, .car, .other, .savings, .investment]
        return assets.sorted { (order.firstIndex(of: $0.type) ?? 99) < (order.firstIndex(of: $1.type) ?? 99) }
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
                    let totals = computeTotals(h)
                    ScrollView {
                        VStack(spacing: 0) {
                            reportHeader(h)
                            summaryCard(h, totals: totals)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                            assetBreakdown(h)
                            Text(strings.settlementEstimateNote)
                                .font(.caption)
                                .foregroundStyle(Color.cohTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.top, 20)
                        }
                        .padding(.bottom, 40)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Report header

    private func reportHeader(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.tabEquity)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color.cohInk)
                    Text("\(h.partnerAName) & \(h.partnerBName)")
                        .font(.subheadline).foregroundStyle(Color.cohSecondary)
                }
                Spacer()
                // Report date
                VStack(alignment: .trailing, spacing: 2) {
                    Text(strings.asOf)
                        .font(.caption).foregroundStyle(Color.cohTertiary)
                    Text(Date(), style: .date)
                        .font(.caption.monospacedDigit()).foregroundStyle(Color.cohSecondary)
                }
            }
            Text(strings.settlementTabSub)
                .font(.subheadline)
                .foregroundStyle(Color.cohSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: Summary card (top — main report view)

    private func summaryCard(_ h: Household, totals: (a: Double, b: Double)) -> some View {
        let sym = h.currencySymbol
        let combined = totals.a + totals.b

        return VStack(spacing: 0) {
            // Top: label
            HStack {
                Text(strings.settlementTotalEquity)
                    .font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
                Spacer()
                Text(strings.settlementIfSoldToday)
                    .font(.caption).foregroundStyle(Color.cohTertiary)
            }
            .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 14)

            // Partner columns
            HStack(spacing: 12) {
                partnerEquityColumn(h.partnerAName, amount: totals.a, color: .cohGreen, sym: sym)
                partnerEquityColumn(h.partnerBName, amount: totals.b, color: Color.cohBlue, sym: sym)
            }
            .padding(.horizontal, 16).padding(.bottom, 16)

            // Combined total row
            HStack {
                Text(strings.totalCombinedEquity)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohInk)
                Spacer()
                Text(sym + Int(combined).formatted())
                    .font(.title2.bold().monospacedDigit()).foregroundStyle(Color.cohGreen)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(Color.cohGreen.opacity(0.07))
        }
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private func partnerEquityColumn(_ name: String, amount: Double, color: Color, sym: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.caption.weight(.semibold)).foregroundStyle(color)
            Text(sym + Int(amount).formatted())
                .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.cohInk)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Asset breakdown

    private func assetBreakdown(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.perAsset)
                .font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(sortedAssets(h.assets)) { asset in
                    NavigationLink(destination: SettlementView(asset: asset, household: h)) {
                        SettlementRowCard(asset: asset, household: h, strings: strings)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
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
                Text(strings.tabEquity).font(.title2.bold())
                Text(strings.settlementNoAssets)
                    .font(.subheadline).foregroundStyle(Color.cohSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cohBg.ignoresSafeArea())
    }
}

// MARK: - Settlement row card

struct SettlementRowCard: View {
    let asset: Asset
    let household: Household
    let strings: AppStrings

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

    private var payoutA: Double { result.payout[.a] ?? 0 }
    private var payoutB: Double { result.payout[.b] ?? 0 }
    private var sym: String { household.currencySymbol }

    var body: some View {
        HStack(spacing: 14) {
            // Ownership square: split green/blue by ownership share —
            // half each at 50/50, fully one colour for sole ownership.
            ZStack {
                GeometryReader { g in
                    HStack(spacing: 0) {
                        Color.cohGreen
                            .frame(width: g.size.width * asset.ownershipShareA)
                        Color.cohBlue
                            .frame(width: g.size.width * (1 - asset.ownershipShareA))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(width: 42, height: 42)
                Image(systemName: asset.type.icon)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(asset.label)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohInk)
                // What each partner is entitled to — the coloured dots map to
                // the ownership square (green = partner A, blue = partner B).
                HStack(spacing: 8) {
                    partnerLine(amount: payoutA, color: .cohGreen)
                    Text("·").font(.caption).foregroundStyle(Color.cohTertiary)
                    partnerLine(amount: payoutB, color: Color.cohBlue)
                }
                .minimumScaleFactor(0.75)
                .lineLimit(1)
            }

            Spacer()

            // One headline number per asset: net proceeds if sold today.
            VStack(alignment: .trailing, spacing: 2) {
                Text(sym + Int(result.netProceeds).formatted())
                    .font(.subheadline.bold().monospacedDigit()).foregroundStyle(Color.cohInk)
                Text(strings.settlementNetProceeds)
                    .font(.caption).foregroundStyle(Color.cohTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.bold()).foregroundStyle(Color.cohTertiary)
        }
        .padding(14)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }

    private func partnerLine(amount: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(Int(amount).formatted())
                .font(.caption.monospacedDigit()).foregroundStyle(Color.cohSecondary)
        }
    }
}
