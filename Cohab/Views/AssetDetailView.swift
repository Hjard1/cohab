import SwiftUI

struct AssetDetailView: View {
    let asset: Asset
    let household: Household

    @State private var showAddContribution = false
    @State private var showEdit = false
    @Environment(\.modelContext) private var modelContext

    private var result: SettlementResult {
        SettlementEngine.settle(SettlementInput(
            salePrice: asset.currentValue,
            remainingLoan: asset.remainingLoan,
            salesCosts: asset.estimatedSalesCost,
            ownershipShareA: asset.ownershipShareA,
            annualRate: household.annualInterestRate,
            contributions: asset.contributions.map {
                Contribution(owner: $0.ownerKey == "A" ? .a : .b,
                             amount: $0.amount, date: $0.date, label: $0.label)
            },
            settlementDate: Date()
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Donut chart
                ownershipChart

                // Settlement value card
                settlementCard

                // Contribution history
                contributionHistory

                Spacer(minLength: 20)
            }
            .padding(20)
            .padding(.bottom, 88)
        }
        .background(Color.cohBg.ignoresSafeArea())
        .navigationTitle(asset.address.isEmpty ? asset.label : asset.address)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEdit = true } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.cohGreen)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomButtons }
        .sheet(isPresented: $showAddContribution) {
            AddContributionView(asset: asset, household: household)
        }
        .sheet(isPresented: $showEdit) {
            EditAssetView(asset: asset, household: household)
        }
    }

    // MARK: - Donut chart

    private var ownershipChart: some View {
        VStack(spacing: 20) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 20)
                    .frame(width: 180, height: 180)

                // Ownership arc
                Circle()
                    .trim(from: 0, to: asset.ownershipShareA)
                    .stroke(Color.cohGreen, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                // Centre label
                VStack(spacing: 4) {
                    Text("OWNERSHIP")
                        .font(.caption2.bold()).tracking(1)
                        .foregroundStyle(.secondary)
                    Text("\(Int(asset.ownershipShareA * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.cohInk)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: asset.ownershipShareA)

            // Partner split row
            HStack(spacing: 24) {
                partnerShare(name: household.partnerAName,
                             share: asset.ownershipShareA,
                             color: Color.cohGreen)
                Divider().frame(height: 32)
                partnerShare(name: household.partnerBName,
                             share: 1 - asset.ownershipShareA,
                             color: Color(red: 0.20, green: 0.49, blue: 0.96))
            }
            .padding(.horizontal, 40)
        }
        .padding(24)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func partnerShare(name: String, share: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Text("\(Int(share * 100))%")
                .font(.title3.bold()).foregroundStyle(Color.cohInk)
        }
    }

    // MARK: - Settlement card

    private var settlementCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settlement value")
                .font(.caption.bold()).tracking(0.5)
                .foregroundStyle(.secondary)
            Text("\(household.currencySymbol)\(Int(result.payout[.a] ?? 0).formatted())")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.cohInk)
            Text("If sold today at current market value")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Contribution history

    private var contributionHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Contribution History")
                .font(.headline).foregroundStyle(Color.cohInk)

            if asset.contributions.isEmpty {
                Text("No contributions recorded yet.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(asset.contributions.sorted { $0.date > $1.date }) { contrib in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(contrib.label.isEmpty ? contrib.category.capitalized : contrib.label)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.cohInk)
                                Text(contrib.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(household.currencySymbol)\(Int(contrib.amount).formatted())")
                                .font(.subheadline.bold())
                                .foregroundStyle(contrib.ownerKey == "A" ? Color.cohGreen
                                                 : Color(red: 0.20, green: 0.49, blue: 0.96))
                        }
                        .padding(.vertical, 12)

                        if contrib.id != asset.contributions.sorted { $0.date > $1.date }.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 18)
                .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            }
        }
    }

    // MARK: - Bottom buttons

    private var bottomButtons: some View {
        HStack(spacing: 14) {
            Button { showEdit = true } label: {
                Text("Recalculate")
                    .font(.headline).foregroundStyle(Color.cohInk)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.cohInk.opacity(0.2), lineWidth: 1.5)
                    )
            }
            Button { showAddContribution = true } label: {
                Text("Add Contribution")
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.cohBg.ignoresSafeArea(edges: .bottom))
    }
}
