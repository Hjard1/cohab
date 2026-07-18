import SwiftUI

struct AssetDetailView: View {
    let asset: Asset
    let household: Household

    @State private var showAddContribution = false
    @State private var showEdit = false
    @State private var showSettlement = false
    @State private var editingOwnership = false
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var strings = AppStrings.shared

    private var netEquity: Double { asset.currentValue - asset.remainingLoan }

    // Contribution-adjusted equity (no sale costs so totals sum to netEquity)
    private var equityResult: SettlementResult {
        SettlementEngine.settle(SettlementInput(
            salePrice: asset.currentValue,
            remainingLoan: asset.remainingLoan,
            salesCosts: 0,
            ownershipShareA: asset.ownershipShareA,
            annualRate: household.annualInterestRate,
            contributions: asset.contributions.map {
                Contribution(owner: $0.ownerKey == "A" ? .a : .b,
                             amount: $0.amount, date: $0.date, label: $0.label)
            },
            settlementDate: Date()
        ))
    }
    private var equityA: Double { equityResult.payout[.a] ?? 0 }
    private var equityB: Double { equityResult.payout[.b] ?? 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Themed visual header — icon + colour per asset type,
                // so a home, a car, and a sofa don't all look like the same row of text.
                heroHeader

                // Settlement value + split (primary info first)
                equityCard

                // Ownership chart (compact)
                ownershipChart

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
        .sheet(isPresented: $showSettlement) {
            SettlementView(asset: asset, household: household)
        }
    }

    // MARK: - Hero header

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [asset.type.color, asset.type.color.opacity(0.72)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // Oversized, low-opacity icon motif bleeding off the corner —
            // decorative texture, not competing with the readable text below.
            Image(systemName: asset.type.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 170, height: 170)
                .foregroundStyle(.white.opacity(0.14))
                .rotationEffect(.degrees(-10))
                .offset(x: 78, y: -36)

            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle().fill(.white.opacity(0.20)).frame(width: 52, height: 52)
                    Image(systemName: asset.type.icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.type.displayName.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(asset.label)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if !asset.address.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse").font(.caption2)
                            Text(asset.address).font(.caption).lineLimit(1)
                        }
                        .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .padding(20)
        }
        .frame(minHeight: 168)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: asset.type.color.opacity(0.25), radius: 12, y: 6)
    }

    // MARK: - Donut chart

    private var ownershipChart: some View {
        VStack(spacing: 20) {
            // Tappable donut
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 16)
                    .frame(width: 130, height: 130)

                Circle()
                    .trim(from: 0, to: asset.ownershipShareA)
                    .stroke(Color.cohGreen, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 3) {
                    Text(strings.assetOwnership)
                        .font(.caption2.bold()).tracking(1)
                        .foregroundStyle(.secondary)
                    Text("\(Int(asset.ownershipShareA * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.cohInk)
                    if !editingOwnership {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.cohGreen.opacity(0.6))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.4), value: asset.ownershipShareA)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    editingOwnership.toggle()
                }
            }

            // Partner split row
            HStack(spacing: 24) {
                partnerShare(name: household.partnerAName,
                             share: asset.ownershipShareA,
                             color: Color.cohGreen)
                Divider().frame(height: 32)
                partnerShare(name: household.partnerBName,
                             share: 1 - asset.ownershipShareA,
                             color: Color.cohBlue)
            }
            .padding(.horizontal, 40)

            // Inline ownership slider — appears on tap
            if editingOwnership {
                VStack(spacing: 10) {
                    Divider()
                    HStack {
                        Text(household.partnerAName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.cohGreen)
                        Spacer()
                        Text(household.partnerBName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.cohBlue)
                    }
                    Slider(value: Binding(
                        get: { asset.ownershipShareA },
                        set: { asset.ownershipShareA = $0 }
                    ), in: 0...1, step: 0.01)
                    .tint(Color.cohGreen)

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            editingOwnership = false
                        }
                    } label: {
                        Text(strings.save)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
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

    // MARK: - Equity card

    private var equityCard: some View {
        let shortfall = equityResult.shortfall
        return VStack(alignment: .leading, spacing: 14) {
            Text(strings.assetNetEquity)
                .font(.caption.bold()).tracking(0.5)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(household.currencySymbol)
                    .font(.title3.bold()).foregroundStyle(.secondary)
                Text("\(Int(netEquity).formatted())")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.cohInk)
            }

            Divider()

            HStack {
                equityRow(name: household.partnerAName, amount: equityA, color: Color.cohGreen)
                Spacer()
                equityRow(name: household.partnerBName, amount: equityB,
                          color: Color.cohBlue)
            }

            if !asset.contributions.isEmpty {
                Divider()
                Text(shortfall
                     ? strings.settlementShortfallInline
                     : strings.dashboardContribFirst)
                    .font(.caption2)
                    .foregroundStyle(shortfall ? Color.orange : Color(.tertiaryLabel))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func equityRow(name: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name)
                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            HStack(spacing: 3) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text("\(household.currencySymbol)\(Int(amount).formatted())")
                    .font(.subheadline.bold()).foregroundStyle(Color.cohInk)
            }
        }
    }

    // MARK: - Contribution history

    private var contributionHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(strings.assetContribHistory)
                .font(.headline).foregroundStyle(Color.cohInk)

            if asset.contributions.isEmpty {
                Text(strings.assetNoContribs)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(asset.contributions.sorted { $0.date > $1.date }) { contrib in
                        let contribColor: Color = contrib.ownerKey == "A" ? .cohGreen : .cohBlue
                        let contribName: String = contrib.ownerKey == "A" ? household.partnerAName : household.partnerBName
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(contribColor.opacity(0.12)).frame(width: 32, height: 32)
                                Text(String(contribName.prefix(1)).uppercased())
                                    .font(.caption.bold()).foregroundStyle(contribColor)
                            }
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
                                .foregroundStyle(contribColor)
                            Button {
                                let id = contrib.id
                                // Remote-first delete: the local row is removed
                                // only on success, otherwise the next sync would
                                // resurrect it (looking like "cannot delete").
                                Task { @MainActor in
                                    do {
                                        try await SupabaseService.deleteContribution(id)
                                        modelContext.delete(contrib)
                                    } catch {
                                        print("[Cohab] Delete contribution failed: \(error.localizedDescription)")
                                    }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color(.quaternaryLabel))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 12)

                        if contrib.id != asset.contributions.sorted(by: { $0.date > $1.date }).last?.id {
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
            Button { showSettlement = true } label: {
                Text(strings.settlementTitle)
                    .font(.headline).foregroundStyle(Color.cohInk)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.cohInk.opacity(0.2), lineWidth: 1.5)
                    )
            }
            Button { showAddContribution = true } label: {
                Text(strings.assetAddContrib)
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
