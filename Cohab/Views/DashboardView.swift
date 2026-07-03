import SwiftUI
import SwiftData

// MARK: - Dashboard

struct DashboardView: View {
    @Query private var households: [Household]
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var strings = AppStrings.shared
    @State private var showSetup = false
    @State private var showAddAsset = false
    @State private var editingAsset: Asset?
    @State private var setupAsset: Asset?   // blank asset to set up via wizard
    @State private var showAgreementSheet = false
    @State private var agreementSubmission: DocuSealSubmission?
    @State private var isGeneratingAgreement = false
    @State private var agreementError: String?
    @State private var availableRate: CentralBankRate?
    @State private var showRateSaved = false

    private var household: Household? { households.first }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.cohBg.ignoresSafeArea()

                if let h = household {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Serif screen header — consistent with Agreement, Assets, Calculators
                            VStack(alignment: .leading, spacing: 4) {
                                Text(strings.tabHome)
                                    .font(.system(size: 28, weight: .bold, design: .serif))
                                    .foregroundStyle(Color.cohInk)
                                Text("\(h.partnerAName) & \(h.partnerBName)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 16)

                            equityHeader(h)
                                .padding(.horizontal, 20)
                            if let rate = availableRate,
                               abs(rate.rate - h.annualInterestRate) > 0.001 {
                                rateUpdateBanner(household: h, rate: rate)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 12)
                            }
                            if h.hasBudget {
                                budgetCard(h)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 12)
                            }
                            assetsList(h)
                                .padding(.top, 24)
                            if h.isFormalMode {
                                agreementStatusRow(h)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 12)
                            }
                            Spacer(minLength: 100)
                        }
                    }
                    .task {
                        availableRate = await InterestRateService.fetch(currency: h.currency)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        if h.agreementStatus == "pending" {
                            Task { await DocuSealService.checkSigned(household: h) }
                        }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        // FAB anchored above tab bar — never overlaps scroll content
                        HStack {
                            Spacer()
                            addButton
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 8)
                    }

                } else {
                    emptyState
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .sheet(isPresented: $showSetup) {
            HouseholdSetupView(household: household)
        }
        .sheet(isPresented: $showAddAsset) {
            if let h = household { AddAssetView(household: h) }
        }
        .sheet(item: $editingAsset) { asset in
            if let h = household { EditAssetView(asset: asset, household: h) }
        }
        .sheet(item: $setupAsset) { asset in
            if let h = household { AddAssetView(household: h, existingAsset: asset) }
        }
        .sheet(isPresented: $showAgreementSheet) {
            if let h = household {
                AgreementSheetView(
                    household: h,
                    submission: $agreementSubmission,
                    isGenerating: $isGeneratingAgreement,
                    error: $agreementError
                )
            }
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSetup = true } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(Color.cohTertiary)
                    .font(.body)
            }
        }
    }

    // MARK: Ownership header

    private func equityHeader(_ h: Household) -> some View {
        let sorted = sortedAssets(h.assets)
        return VStack(spacing: 14) {
            // Partner figures with first asset centred between them
            HStack(alignment: .bottom) {
                partnerFigure(name: h.partnerAName, avatar: h.avatarA, color: .cohGreen, align: .leading)
                Spacer()
                if let first = sorted.first {
                    assetFigure(first, onTap: {
                        if first.currentValue == 0 { setupAsset = first }
                        else { editingAsset = first }
                    })
                }
                Spacer()
                partnerFigure(name: h.partnerBName, avatar: h.avatarB, color: .cohBlue, align: .trailing)
            }

            if h.assets.isEmpty {
                Text(strings.dashboardNoAssets)
                    .font(.caption).foregroundStyle(Color.cohTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, asset in
                        if idx > 0 {
                            Color.cohIconBg.frame(height: 1).opacity(0.7)
                        }
                        Button {
                            if asset.currentValue == 0 { setupAsset = asset }
                            else { editingAsset = asset }
                        } label: {
                            assetBalanceRow(asset: asset, symbol: h.currencySymbol,
                                            nameA: h.partnerAName, nameB: h.partnerBName,
                                            showHeader: idx > 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private func assetFigure(_ asset: Asset, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cohIconBg)
                        .frame(width: 56, height: 56)
                    Image(systemName: asset.type.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.cohIconFg)
                }
                Text(asset.label.isEmpty ? asset.type.displayName : asset.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.cohInk)
                    .lineLimit(1)
                    .frame(width: 72)
            }
        }
        .buttonStyle(.plain)
    }

    private func partnerFigure(name: String, avatar: String, color: Color, align: HorizontalAlignment) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.10))
                    .frame(width: 64, height: 64)
                Image(systemName: avatar)
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(color)
            }
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.cohInk)
                .lineLimit(1)
        }
        .frame(maxWidth: 80, alignment: align == .leading ? .leading : .trailing)
    }

    private func sortedAssets(_ assets: [Asset]) -> [Asset] {
        let order: [AssetType] = [.home, .cabin, .car, .other, .savings, .investment]
        return assets.sorted {
            (order.firstIndex(of: $0.type) ?? 99) < (order.firstIndex(of: $1.type) ?? 99)
        }
    }

    /// Unified asset balance row — same layout for all asset types.
    /// Shows: centred icon+name (secondary assets), split bar with %, per-partner amounts.
    private func assetBalanceRow(asset: Asset, symbol: String,
                                  nameA: String, nameB: String,
                                  showHeader: Bool = true) -> some View {
        let shareA = asset.ownershipShareA
        let shareB = 1 - shareA
        let hasValue = asset.currentValue > 0

        return VStack(spacing: 6) {
            // Icon + name — secondary assets only (first asset is the centred figure)
            if showHeader {
                VStack(spacing: 3) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cohIconBg)
                            .frame(width: 38, height: 38)
                        Image(systemName: asset.type.icon)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.cohIconFg)
                    }
                    Text(asset.label.isEmpty ? asset.type.displayName : asset.label)
                        .font(.caption2).foregroundStyle(Color.cohTertiary)
                        .lineLimit(1).frame(width: 68)
                }
            }

            // Split bar: A% ——bar—— B%
            HStack(spacing: 0) {
                Text("\(Int((shareA * 100).rounded()))%")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(shareA > 0.005 ? Color.cohGreen : Color.cohTertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.cohBlue.opacity(0.18))
                        Capsule().fill(Color.cohGreen)
                            .frame(width: geo.size.width * CGFloat(shareA))
                    }
                }
                .frame(width: 72, height: 5)

                Text("\(Int((shareB * 100).rounded()))%")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(shareB > 0.005 ? Color.cohBlue : Color.cohTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
            }

            // Per-partner amounts — shown for all types when value > 0
            if hasValue {
                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(Color.cohGreen).frame(width: 5, height: 5)
                        Text(symbol + Int(asset.currentValue * shareA).formatted())
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(shareA > 0.005 ? Color.cohSecondary : Color.cohTertiary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text(symbol + Int(asset.currentValue * shareB).formatted())
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(shareB > 0.005 ? Color.cohSecondary : Color.cohTertiary)
                        Circle().fill(Color.cohBlue).frame(width: 5, height: 5)
                    }
                }
            }
        }
    }


    // MARK: Budget card

    private func budgetCard(_ h: Household) -> some View {
        let sym = h.currencySymbol
        let paysA = h.budgetTotalExpenses * h.budgetSplitA
        let paysB = h.budgetTotalExpenses * (1 - h.budgetSplitA)
        let modeLabel: String = {
            switch h.budgetFairnessMode {
            case "byIncome":   return strings.budgetByIncome
            case "equalLeft":  return strings.budgetEqualLeft
            default:           return ""
            }
        }()

        return VStack(spacing: 12) {
            HStack {
                Label(strings.monthlyExpenses,
                      systemImage: "dollarsign.circle.fill")
                    .font(.caption.bold()).foregroundStyle(Color.cohGreen)
                Spacer()
                if !modeLabel.isEmpty {
                    Text(modeLabel)
                        .font(.caption2).foregroundStyle(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color(.systemGray6), in: Capsule())
                }
            }
            HStack(spacing: 8) {
                budgetPill(h.partnerAName, pays: paysA, sym: sym, color: .cohGreen)
                budgetPill(h.partnerBName, pays: paysB, sym: sym, color: Color.cohBlue)
            }
        }
        .padding(16)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func budgetPill(_ name: String, pays: Double, sym: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).font(.caption2.weight(.semibold)).foregroundStyle(color)
            Text(sym + Int(pays).formatted() + strings.perMonthSuffix)
                .font(.subheadline.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
    }

    private func totalNetEquity(_ h: Household) -> (Double, Double) {
        h.assets.reduce((0.0, 0.0)) { acc, asset in
            let r = SettlementEngine.settle(SettlementInput(
                salePrice: asset.currentValue,
                remainingLoan: asset.remainingLoan,
                salesCosts: 0,
                ownershipShareA: asset.ownershipShareA,
                annualRate: h.annualInterestRate,
                contributions: asset.contributions.map {
                    Contribution(owner: $0.ownerKey == "A" ? .a : .b,
                                 amount: $0.amount, date: $0.date, label: $0.label)
                },
                settlementDate: Date()
            ))
            return (acc.0 + (r.payout[.a] ?? 0),
                    acc.1 + (r.payout[.b] ?? 0))
        }
    }

    private func agreementStatusRow(_ h: Household) -> some View {
        Group {
            switch h.agreementStatus {
            case "signed" where !h.agreementNeedsUpdate:
                Label("Agreement signed ✓", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.bold()).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 12))
            case "pending":
                Label("Waiting for signatures…", systemImage: "clock.fill")
                    .font(.subheadline.bold()).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 12))
            default:
                EmptyView()
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.cohGreen.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "house.and.flag.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.cohGreen)
            }

            VStack(spacing: 8) {
                Text(strings.dashboardSetupTitle)
                    .font(.title2.bold())
                Text(strings.dashboardSetupSub)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button { showSetup = true } label: {
                Text(strings.onboardingGetStarted)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 48)
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: Household header

    private func householdHeader(_ h: Household) -> some View {
        HStack(spacing: 0) {
            partnerPill(h.partnerAName, color: .cohGreen)
            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.cohTertiary)
                Text(h.currency)
                    .font(.caption.bold())
                    .foregroundStyle(Color.cohSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6), in: Capsule())

            Spacer()
            partnerPill(h.partnerBName, color: Color.cohBlue)
        }
        .padding(.horizontal, 24)
    }

    private func partnerPill(_ name: String, color: Color) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Text(String(name.prefix(1)).uppercased())
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
            }
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    // MARK: Assets list

    private func assetsList(_ h: Household) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(strings.dashboardAssets)
                    .font(.system(.subheadline, design: .default).weight(.semibold))
                    .foregroundStyle(Color.cohInk)
                Spacer()
                Text("\(h.assets.count) \(h.assets.count == 1 ? strings.dashboardItem : strings.dashboardItems)")
                    .font(.caption)
                    .foregroundStyle(Color.cohTertiary)
            }
            .padding(.horizontal, 20)

            if h.assets.isEmpty {
                noAssetsPrompt { showAddAsset = true }
                    .padding(.top, 16)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(sortedAssets(h.assets)) { asset in
                        AssetCard(asset: asset, household: h,
                                  onEdit: { editingAsset = asset },
                                  onSetup: { setupAsset = asset })
                    }
                    nextActionCard(for: h)
                }
                .padding(.top, 16)
            }
        }
    }

    @ViewBuilder
    private func nextActionCard(for h: Household) -> some View {
        let hasAnyContribs = h.assets.contains { !$0.contributions.isEmpty }
        let needsAgreement = h.isFormalMode && h.agreementStatus == "none"

        if !hasAnyContribs {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cohGreen.opacity(0.10))
                        .frame(width: 38, height: 38)
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline).foregroundStyle(Color.cohGreen)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(strings.dashboardLogFirstContrib)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.cohInk)
                    Text(strings.dashboardLogFirstContribSub)
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundStyle(Color.cohTertiary)
            }
            .padding(16)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            .padding(.horizontal, 20)
            .onTapGesture { editingAsset = sortedAssets(h.assets).first }
        } else if needsAgreement {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.54, green: 0.31, blue: 0.96).opacity(0.10))
                        .frame(width: 38, height: 38)
                    Image(systemName: "doc.text.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.54, green: 0.31, blue: 0.96))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(strings.dashboardMakeOfficial)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.cohInk)
                    Text(strings.dashboardMakeOfficialSub)
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            .padding(.horizontal, 20)
        }
    }

    private func noAssetsPrompt(action: @escaping () -> Void) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "plus.square.dashed")
                .font(.system(size: 36))
                .foregroundStyle(Color.cohTertiary)
            Text(strings.dashboardNoAssets)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(strings.dashboardNoAssetsSub)
                .font(.subheadline)
                .foregroundStyle(Color.cohTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: Floating add button

    private var addButton: some View {
        Button { showAddAsset = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(Color.cohInk, in: Circle())
                .shadow(color: .black.opacity(0.22), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Asset card

struct AssetCard: View {
    let asset: Asset
    let household: Household
    let onEdit: () -> Void
    let onSetup: () -> Void

    @ObservedObject private var strings = AppStrings.shared
    @State private var showFurnitureList = false

    private var isBlank: Bool { asset.currentValue == 0 && !asset.type.isSimpleAsset }
    private var nb: Bool { strings.language == .nb }
    private var sym: String { household.currencySymbol }

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

    var body: some View {
        Button {
            if isBlank { onSetup() }
            else if asset.type == .furniture { showFurnitureList = true }
            else { onEdit() }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                assetHeader
                Color(.separator).frame(height: 0.5).padding(.vertical, 14)
                if isBlank {
                    setupPrompt
                } else if asset.type == .furniture {
                    furnitureRow
                } else {
                    equityRow
                }
            }
            .padding(20)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showFurnitureList) {
            FurnitureListView(asset: asset, household: household)
        }
    }

    // MARK: Furniture row

    private var furnitureRow: some View {
        Button { showFurnitureList = true } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    let count = asset.furnitureItems.count
                    Text(count == 0
                         ? strings.noItemsYet
                         : "\(count) \(count == 1 ? strings.furnItemSingular : strings.furnItemPlural)")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohInk)
                    if count > 0 {
                        let total = asset.furnitureItems.reduce(0.0) { $0 + $1.currentValue }
                        if total > 0 {
                            Text(sym + Int(total).formatted())
                                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                Text(strings.viewAllArrow)
                    .font(.caption.weight(.semibold)).foregroundStyle(Color.cohGreen)
            }
        }
        .buttonStyle(.plain)
    }

    private var setupPrompt: some View {
        Button(action: onSetup) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.right.circle.fill").foregroundStyle(Color.cohGreen)
                Text(strings.completeSetup)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohGreen)
                Spacer()
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(Color.cohTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Header

    private var assetHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.cohIconBg)
                    .frame(width: 50, height: 50)
                Image(systemName: asset.type.icon)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.cohIconFg)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(asset.label).font(.headline)
                if !asset.address.isEmpty {
                    Text(asset.address).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(household.currencySymbol + fmt(asset.currentValue))
                    .font(.subheadline.bold().monospacedDigit())
                if asset.remainingLoan > 0 {
                    Text(strings.dashboardLoan + ": −" + fmt(asset.remainingLoan))
                        .font(.caption2.monospacedDigit()).foregroundStyle(.orange)
                }
                Button(action: isBlank ? onSetup : onEdit) {
                    Image(systemName: isBlank ? "arrow.right.circle.fill" : "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(isBlank ? Color.cohGreen : Color.cohTertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Equity row

    private var equityRow: some View {
        let payoutA = equityResult.payout[.a] ?? 0
        let payoutB = equityResult.payout[.b] ?? 0
        return VStack(spacing: 8) {
            HStack(alignment: .top) {
                equityColumn(household.partnerAName, equity: payoutA, color: .cohGreen)
                Spacer()
                equityColumn(household.partnerBName, equity: payoutB, color: Color.cohBlue)
            }
        }
    }

    private func equityColumn(_ name: String, equity: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.caption.weight(.medium)).foregroundStyle(color)
            Text(household.currencySymbol + fmt(equity))
                .font(.title3.bold().monospacedDigit())
        }
    }

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

// MARK: - Rate update banner

extension DashboardView {
    func rateUpdateBanner(household: Household, rate: CentralBankRate) -> some View {
        let newPct     = rate.rate * 100
        let currentPct = household.annualInterestRate * 100
        let delta      = newPct - currentPct
        let isUp       = delta > 0
        let deltaText  = String(format: "%+.2f%%", delta)
        let arrow      = isUp ? "arrow.up.right" : "arrow.down.right"
        let deltaColor = isUp ? Color.orange : Color(red: 0.10, green: 0.60, blue: 0.38)

        return HStack(spacing: 12) {
            // Left: icon
            Image(systemName: "building.columns")
                .font(.subheadline)
                .foregroundStyle(Color.cohSecondary)
                .frame(width: 32, height: 32)
                .background(Color.cohIconBg, in: RoundedRectangle(cornerRadius: 8))

            // Centre: title + delta
            VStack(alignment: .leading, spacing: 3) {
                Text("\(rate.source) rate update")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.cohInk)
                HStack(spacing: 4) {
                    Text(String(format: "%.2f%%", currentPct))
                        .foregroundStyle(Color.cohTertiary)
                    Image(systemName: arrow)
                        .foregroundStyle(deltaColor)
                    Text(String(format: "%.2f%%", newPct))
                        .foregroundStyle(Color.cohSecondary)
                    Text("(\(deltaText))")
                        .foregroundStyle(deltaColor)
                }
                .font(.caption2.monospacedDigit())
            }

            Spacer()

            // Right: actions
            if showRateSaved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.cohSecondary)
                    .font(.subheadline)
            } else {
                HStack(spacing: 8) {
                    Button("Update") {
                        household.annualInterestRate = rate.rate
                        showRateSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            availableRate = nil
                            showRateSaved = false
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.cohInk, in: Capsule())

                    Button { availableRate = nil } label: {
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.cohTertiary)
                    }
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.cohIconBg, lineWidth: 1)
        )
    }
}

// MARK: - Agreement card

extension DashboardView {
    func agreementCard(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // ── Header ───────────────────────────────────────────────
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.checkmark.fill")
                        .foregroundStyle(Color.cohGreen)
                    Text(AppStrings.shared.agreementTitle)
                        .font(.headline)
                }
                Spacer()
                statusBadge(h.agreementStatus, needsUpdate: h.agreementNeedsUpdate)
            }

            Color(.separator).frame(height: 0.5)

            // ── Scope description ─────────────────────────────────────
            Text(h.includeDissolutionClause
                 ? "Covers: ownership, contributions & dissolution clause"
                 : "Covers: ownership & contributions")
                .font(.caption)
                .foregroundStyle(.secondary)

            // ── Update notice ─────────────────────────────────────────
            if h.agreementNeedsUpdate && h.agreementStatus != "none" {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                    Text(h.changesSinceSigning + " since last agreement.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }

            // ── Signed state ──────────────────────────────────────────
            if h.agreementStatus == "signed" && !h.agreementNeedsUpdate {
                Label("Signed by both parties", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.cohGreen)
            }

            // ── Action button ─────────────────────────────────────────
            if h.agreementStatus != "signed" || h.agreementNeedsUpdate {
                let buttonLabel = buttonText(for: h)
                Button {
                    agreementSubmission = nil
                    agreementError = nil
                    showAgreementSheet = true
                } label: {
                    HStack(spacing: 8) {
                        if isGeneratingAgreement {
                            ProgressView().scaleEffect(0.8)
                        }
                        Text(buttonLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        h.agreementNeedsUpdate ? Color.orange : Color.cohGreen,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .disabled(isGeneratingAgreement)
            }
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
    }

    private func buttonText(for h: Household) -> String {
        if h.agreementNeedsUpdate    { return "Update & resend agreement" }
        if h.agreementStatus == "pending" { return "View signing links" }
        return "Generate & sign agreement"
    }

    private func statusBadge(_ status: String, needsUpdate: Bool) -> some View {
        let (label, color): (String, Color) = {
            if needsUpdate && status != "none" { return ("Update needed", .orange) }
            switch status {
            case "pending": return ("Pending signatures", .orange)
            case "signed":  return ("Signed ✓", .cohGreen)
            default:        return ("Not signed yet", Color(.systemGray))
            }
        }()
        return Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.1), in: Capsule())
    }
}

// MARK: - Agreement sheet

struct AgreementSheetView: View {
    let household: Household
    @Binding var submission: DocuSealSubmission?
    @Binding var isGenerating: Bool
    @Binding var error: String?
    @Environment(\.dismiss) private var dismiss
    @State private var hasStarted = false
    @State private var isSigned = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cohBg.ignoresSafeArea()

                if isSigned {
                    signedConfirmation
                } else if isGenerating {
                    generatingView
                } else if let err = error {
                    errorView(err)
                } else if let sub = submission {
                    signingView(sub)
                } else {
                    EmptyView()
                }
            }
            .navigationTitle(isSigned ? "Agreement Signed" : "Sign Agreement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true

            // Recovery: rebuild the in-memory submission from the URL we stored at creation time.
            // Without this, returning to the sheet after a crash/restart shows a blank page.
            if submission == nil, !household.docusealViewUrl.isEmpty,
               household.agreementStatus == "pending" {
                submission = DocuSealSubmission(
                    submissionId: household.docusealSlug,
                    slug: household.docusealSlug,
                    signingUrlA: household.docusealViewUrl,
                    signingUrlB: ""
                )
                Task {
                    let signed = await DocuSealService.checkSigned(household: household)
                    if signed { withAnimation { isSigned = true } }
                }
                return
            }

            if submission == nil { generate() }
        }
        // Poll every 6s — uses try await so the loop exits cleanly on dismiss
        .task(id: submission?.slug) {
            guard let slug = submission?.slug, !slug.isEmpty else { return }
            do {
                while !isSigned {
                    try await Task.sleep(for: .seconds(6))
                    let signed = await DocuSealService.checkSigned(household: household)
                    if signed {
                        withAnimation { isSigned = true }
                        return
                    }
                }
            } catch {
                // Task cancelled — sheet was dismissed, nothing to do
            }
        }
    }

    // MARK: Signed confirmation

    private var signedConfirmation: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(Color.cohGreen.opacity(0.1)).frame(width: 90, height: 90)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44)).foregroundStyle(Color.cohGreen)
            }
            VStack(spacing: 8) {
                Text("Agreement signed")
                    .font(.title2.bold())
                Text("Both \(household.partnerAName) and \(household.partnerBName) have signed. Your agreement is now complete.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent).tint(Color.cohGreen)
        }
    }

    // MARK: Loading

    private var generatingView: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.3)
            Text("Preparing agreement…")
                .font(.subheadline).foregroundStyle(.secondary)
            Text("Generating PDF and creating signing session in DocuSeal.")
                .font(.caption).foregroundStyle(Color.cohTertiary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
    }

    // MARK: Error

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill").font(.system(size: 44)).foregroundStyle(.red)
            Text("Something went wrong").font(.headline)
            Text(msg).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Button("Try again") { error = nil; generate() }
                .buttonStyle(.borderedProminent).tint(.cohGreen)
        }
    }

    // MARK: Signing form (in-app WKWebView)

    private func signingView(_ sub: DocuSealSubmission) -> some View {
        VStack(spacing: 0) {
            // Embedded DocuSeal signing form — only for the current user (Partner A)
            DocuSealSigningView(signingURL: sub.signingUrlA)
                .ignoresSafeArea(edges: .bottom)

            // Partner B must sign from their own device via email
            HStack(spacing: 6) {
                Image(systemName: "envelope").font(.caption2).foregroundStyle(.secondary)
                Text("\(household.partnerBName) will receive a signing link by email.")
                    .font(.caption2).foregroundStyle(Color.cohTertiary)
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: Generate

    private func generate() {
        isGenerating = true
        Task {
            do {
                let result = try await DocuSealService.submit(household: household)
                await MainActor.run { submission = result; isGenerating = false }
            } catch {
                await MainActor.run { self.error = error.localizedDescription; isGenerating = false }
            }
        }
    }
}

// MARK: - Household setup sheet

struct HouseholdSetupView: View {
    let household: Household?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @ObservedObject private var strings = AppStrings.shared
    @Environment(HouseholdStore.self) private var store

    @State private var nameA = ""
    @State private var nameB = ""
    @State private var avatarA = "person.fill"
    @State private var avatarB = "person.fill"
    @State private var currency = "GBP"
    @State private var rateText = "5.0"
    @State private var showDeleteConfirm = false
    @State private var showSignOutConfirm = false
    @State private var showInvite = false

    let currencies = ["GBP", "USD", "EUR", "AUD", "CAD", "NOK", "SEK"]
    let avatarOptions: [(icon: String, label: String)] = [
        ("person.fill",             s(en: "Person",  nb: "Person")),
        ("person.crop.circle.fill", s(en: "Profile", nb: "Profil")),
        ("star.fill",               s(en: "Star",    nb: "Stjerne")),
        ("heart.fill",              s(en: "Heart",   nb: "Hjerte")),
    ]

    private static func s(en: String, nb: String) -> String {
        AppStrings.shared.language == .nb ? nb : en
    }
    private var canSave: Bool {
        !nameA.trimmingCharacters(in: .whitespaces).isEmpty &&
        !nameB.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: avatarA)
                            .foregroundStyle(Color.cohGreen).frame(width: 24)
                        TextField(strings.onboardingYourName, text: $nameA)
                    }
                    HStack {
                        Image(systemName: avatarB)
                            .foregroundStyle(Color.cohBlue).frame(width: 24)
                        TextField(strings.onboardingPartnerName, text: $nameB)
                    }
                } header: { Text(strings.onboardingWhoDoYouShare) }

                Section {
                    avatarPickerRow(
                        label: nameA.isEmpty ? s(en: "Your figure", nb: "Din figur") : nameA,
                        color: .cohGreen,
                        selection: $avatarA
                    )
                    avatarPickerRow(
                        label: nameB.isEmpty ? s(en: "Partner's figure", nb: "Partners figur") : nameB,
                        color: .cohBlue,
                        selection: $avatarB
                    )
                } header: { Text(s(en: "Figures", nb: "Figurer")) }

                Section {
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { Text($0) }
                    }
                    HStack {
                        Text(s(en: "Interest rate", nb: "Rente"))
                        Spacer()
                        TextField("5.0", text: $rateText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%").foregroundStyle(.secondary)
                    }
                } header: { Text(s(en: "Settings", nb: "Innstillinger")) }

                Section {
                    Text(s(en: "The interest rate determines how much each contribution grows over time. 5% is a sensible default.",
                           nb: "Renten bestemmer hvor mye hvert bidrag vokser over tid. 5 % er et fornuftig utgangspunkt."))
                        .font(.caption).foregroundStyle(.secondary)
                }

                if household != nil {
                    Section {
                        Button { showInvite = true } label: {
                            Label(s(en: "Invite \(household?.partnerBName ?? "partner")",
                                    nb: "Inviter \(household?.partnerBName ?? "partner")"),
                                  systemImage: "person.badge.plus")
                                .foregroundStyle(Color.cohGreen)
                        }
                    } header: {
                        Text(s(en: "Partner access", nb: "Partnertilgang"))
                    } footer: {
                        Text(s(en: "Share a link so your partner can join this household on their iPhone.",
                               nb: "Del en lenke slik at partneren din kan koble seg til på sin iPhone."))
                    }

                    Section {
                        Button(role: .destructive) { signOut() } label: {
                            Label(s(en: "Sign out", nb: "Logg ut"), systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }

                    Section {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label(s(en: "Delete all data", nb: "Slett alle data"),
                                  systemImage: "trash")
                        }
                    } footer: {
                        Text(s(en: "Permanently deletes all assets, contributions, and your agreement. This cannot be undone.",
                               nb: "Sletter alle eiendeler, bidrag og avtalen din permanent. Dette kan ikke angres."))
                    }
                }
            }
            .navigationTitle(household == nil ? s(en: "Set up household", nb: "Sett opp husholdning") : s(en: "Settings", nb: "Innstillinger"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(s(en: "Cancel", nb: "Avbryt")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(s(en: "Save", nb: "Lagre")) { save() }.bold().disabled(!canSave)
                }
            }
            .confirmationDialog(s(en: "Delete all data?", nb: "Slette alle data?"),
                                isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button(s(en: "Delete everything", nb: "Slett alt"), role: .destructive) { deleteAll() }
                Button(s(en: "Cancel", nb: "Avbryt"), role: .cancel) {}
            } message: {
                Text(s(en: "All assets, contributions, and your agreement will be permanently deleted.",
                       nb: "Alle eiendeler, bidrag og avtalen din slettes permanent."))
            }
        }
        .onAppear {
            guard let h = household else { return }
            nameA = h.partnerAName; nameB = h.partnerBName
            avatarA = h.avatarA; avatarB = h.avatarB
            currency = h.currency
            rateText = String(format: "%.1f", h.annualInterestRate * 100)
        }
        .sheet(isPresented: $showInvite) {
            if let h = household { InvitePartnerView(household: h) }
        }
    }

    private func save() {
        let rate = (Double(rateText.replacingOccurrences(of: ",", with: ".")) ?? 5.0) / 100
        let a = nameA.trimmingCharacters(in: .whitespaces)
        let b = nameB.trimmingCharacters(in: .whitespaces)
        if let h = household {
            h.partnerAName = a; h.partnerBName = b
            h.avatarA = avatarA; h.avatarB = avatarB
            h.currency = currency; h.annualInterestRate = rate

            // Mirror to Supabase if household is synced
            if let householdId = store.household?.id {
                let capturedA    = a
                let capturedB    = b
                let capturedCur  = currency
                let capturedRate = rate
                Task {
                    try? await SupabaseService.updateHousehold(
                        householdId: householdId,
                        partnerALabel: capturedA, partnerBLabel: capturedB,
                        currency: capturedCur, annualInterestRate: capturedRate)
                }
            }
        } else {
            let h = Household(partnerAName: a, partnerBName: b, currency: currency, annualInterestRate: rate)
            h.avatarA = avatarA; h.avatarB = avatarB
            modelContext.insert(h)
        }
        dismiss()
    }

    private func avatarPickerRow(label: String, color: Color, selection: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline).foregroundStyle(Color.cohInk).lineLimit(1)
            Spacer()
            HStack(spacing: 8) {
                ForEach(avatarOptions, id: \.icon) { opt in
                    Button {
                        selection.wrappedValue = opt.icon
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selection.wrappedValue == opt.icon
                                      ? color.opacity(0.15) : Color(.systemGray6))
                                .frame(width: 36, height: 36)
                            Image(systemName: opt.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(selection.wrappedValue == opt.icon ? color : Color.cohTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func signOut() {
        // Delete local household so ContentView's !households.isEmpty check also clears
        if let h = household { modelContext.delete(h) }
        try? modelContext.save()
        Task { try? await supabase.auth.signOut() }
        dismiss()
        onboardingComplete = false
    }

    private func deleteAll() {
        if let h = household { modelContext.delete(h) }
        try? modelContext.save()
        dismiss()
        onboardingComplete = false
    }

    private func s(en: String, nb: String) -> String {
        strings.language == .nb ? nb : en
    }
}

// MARK: - Add asset sheet (wizard)

struct AddAssetView: View {
    let household: Household
    let existingAsset: Asset?   // non-nil = first-time setup of a blank asset
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HouseholdStore.self) private var store

    @State private var step: Int
    @State private var selectedType: AssetType
    @State private var label: String
    @State private var address: String
    @State private var valueText: String
    @State private var loanText: String
    @State private var shareAText: String
    @State private var ownerMode: OwnerMode
    @State private var direction: Int = 1
    @State private var depositAText = ""
    @State private var depositBText = ""
    @State private var contributionDate = Date()

    enum OwnerMode { case personA, shared, personB, custom }

    init(household: Household, existingAsset: Asset? = nil) {
        self.household = household
        self.existingAsset = existingAsset

        if let a = existingAsset {
            // Setup mode: skip type step (step 1), pre-fill from existing blank asset
            let type = AssetType(rawValue: a.assetType) ?? .home
            _step         = State(wrappedValue: 2)
            _selectedType = State(wrappedValue: type)
            _label        = State(wrappedValue: a.label == type.displayName ? "" : a.label)
            _address      = State(wrappedValue: a.address)
            _valueText    = State(wrappedValue: a.currentValue > 0 ? String(Int(a.currentValue)) : "")
            _loanText     = State(wrappedValue: a.remainingLoan > 0 ? String(Int(a.remainingLoan)) : "")
            let pct       = Int(a.ownershipShareA * 100)
            _shareAText   = State(wrappedValue: String(pct))
            let mode: OwnerMode = pct == 100 ? .personA : pct == 0 ? .personB : pct == 50 ? .shared : .custom
            _ownerMode    = State(wrappedValue: mode)
        } else {
            _step         = State(wrappedValue: 1)
            _selectedType = State(wrappedValue: .home)
            _label        = State(wrappedValue: "")
            _address      = State(wrappedValue: "")
            _valueText    = State(wrappedValue: "")
            _loanText     = State(wrappedValue: "")
            _shareAText   = State(wrappedValue: "50")
            _ownerMode    = State(wrappedValue: .shared)
        }
    }

    private let totalSteps = 5
    private var strings: AppStrings { AppStrings.shared }
    private var minStep: Int { existingAsset != nil ? 2 : 1 }

    // Steps that are actually shown for this asset type
    private var effectiveSteps: [Int] {
        switch selectedType {
        case .pet:                  return existingAsset != nil ? [2, 4] : [1, 2, 4]
        case .furniture:            return existingAsset != nil ? [2, 3, 4] : [1, 2, 3, 4]
        case .savings, .investment: return existingAsset != nil ? [2, 3, 4] : [1, 2, 3, 4]
        default:                    return existingAsset != nil ? [2, 3, 4, 5] : [1, 2, 3, 4, 5]
        }
    }

    private func nextStep(from current: Int) -> Int {
        guard let idx = effectiveSteps.firstIndex(of: current), idx + 1 < effectiveSteps.count else {
            return totalSteps + 1   // signal to save
        }
        return effectiveSteps[idx + 1]
    }

    private func prevStep(from current: Int) -> Int {
        guard let idx = effectiveSteps.firstIndex(of: current), idx > 0 else { return minStep }
        return effectiveSteps[idx - 1]
    }

    private var isLastStep: Bool { step == effectiveSteps.last }

    private var canAdvance: Bool {
        switch step {
        case 2: return !label.trimmingCharacters(in: .whitespaces).isEmpty
        case 3: return selectedType == .pet || (Double(valueText.replacingOccurrences(of: ",", with: "")) ?? 0) > 0
        default: return true
        }
    }

    // Step 5 label adapts to asset type
    private var depositLabel: String {
        switch selectedType {
        case .home, .cabin: return strings.depositDeposit
        case .car:           return strings.depositPurchase
        default:             return strings.depositGeneric
        }
    }
    private var depositCategory: String {
        selectedType == .other ? "other" : "deposit"
    }

    private var stepTitle: String {
        switch step {
        case 1: return strings.stepWhatType
        case 2: return strings.stepNameIt
        case 3: return strings.stepWhatWorth
        case 4: return ownershipStepTitle
        case 5: return contributionsStepTitle
        default: return ""
        }
    }

    private var ownershipStepTitle: String {
        let lang = strings.language
        switch selectedType {
        case .home:
            switch lang { case .nb: return "Hvem eier boligen?"; case .sv: return "Vem äger bostaden?"; case .da: return "Hvem ejer boligen?"; case .fi: return "Kuka omistaa asunnon?"; case .de: return "Wem gehört die Immobilie?"; case .fr: return "Qui possède le logement?"; case .es: return "¿Quién es propietario de la vivienda?"; default: return "Who owns the home?" }
        case .cabin:
            switch lang { case .nb: return "Hvem eier hytten?"; case .sv: return "Vem äger stugan?"; case .da: return "Hvem ejer hytten?"; case .fi: return "Kuka omistaa mökin?"; case .de: return "Wem gehört das Ferienhaus?"; case .fr: return "Qui possède la résidence secondaire?"; case .es: return "¿Quién posee la casa de campo?"; default: return "Who owns the cabin?" }
        case .car:
            switch lang { case .nb: return "Hvem eier bilen?"; case .sv: return "Vem äger bilen?"; case .da: return "Hvem ejer bilen?"; case .fi: return "Kuka omistaa auton?"; case .de: return "Wem gehört das Auto?"; case .fr: return "Qui possède la voiture?"; case .es: return "¿Quién posee el coche?"; default: return "Who owns the car?" }
        case .savings:
            switch lang { case .nb: return "Hvem har sparingen?"; case .sv: return "Vem har sparandet?"; case .da: return "Hvem ejer opsparingen?"; case .fi: return "Kenellä on säästöt?"; case .de: return "Wem gehören die Ersparnisse?"; case .fr: return "Qui détient l'épargne?"; case .es: return "¿Quién tiene los ahorros?"; default: return "Who holds the savings?" }
        case .investment:
            switch lang { case .nb: return "Hvem har investeringen?"; case .sv: return "Vem äger investeringen?"; case .da: return "Hvem ejer investeringen?"; case .fi: return "Kenellä on sijoitus?"; case .de: return "Wem gehört die Kapitalanlage?"; case .fr: return "Qui détient l'investissement?"; case .es: return "¿Quién tiene la inversión?"; default: return "Who holds the investment?" }
        case .furniture:
            switch lang { case .nb: return "Hvem eier møblene?"; case .sv: return "Vem äger möblerna?"; case .da: return "Hvem ejer møblerne?"; case .fi: return "Kuka omistaa huonekalut?"; case .de: return "Wem gehören die Möbel?"; case .fr: return "Qui possède les meubles?"; case .es: return "¿Quién posee los muebles?"; default: return "Who owns the furniture?" }
        case .pet:
            switch lang { case .nb: return "Hvem eier kjæledyret?"; case .sv: return "Vem äger husdjuret?"; case .da: return "Hvem ejer kæledyret?"; case .fi: return "Kuka omistaa lemmikin?"; case .de: return "Wem gehört das Haustier?"; case .fr: return "Qui possède l'animal?"; case .es: return "¿Quién posee la mascota?"; default: return "Who owns the pet?" }
        case .other:
            switch lang { case .nb: return "Hvem eier den?"; case .sv: return "Vem äger den?"; case .da: return "Hvem ejer det?"; case .fi: return "Kuka omistaa sen?"; case .de: return "Wem gehört es?"; case .fr: return "Qui le possède?"; case .es: return "¿Quién lo posee?"; default: return "Who owns it?" }
        }
    }

    private var contributionsStepTitle: String {
        let lang = strings.language
        switch selectedType {
        case .home, .cabin:
            switch lang { case .nb: return "Hvem betalte innskuddet?"; case .sv: return "Vem betalade insatsen?"; case .da: return "Hvem betalte indskuddet?"; case .fi: return "Kuka maksoi talletuksen?"; case .de: return "Wer hat die Einlage gezahlt?"; case .fr: return "Qui a payé l'apport?"; case .es: return "¿Quién pagó el depósito?"; default: return "Who paid the deposit?" }
        case .car:
            switch lang { case .nb: return "Hvem betalte for bilen?"; case .sv: return "Vem betalade för bilen?"; case .da: return "Hvem betalte for bilen?"; case .fi: return "Kuka maksoi auton?"; case .de: return "Wer hat das Auto bezahlt?"; case .fr: return "Qui a payé la voiture?"; case .es: return "¿Quién pagó el coche?"; default: return "Who paid for the car?" }
        case .savings:
            switch lang { case .nb: return "Hva har dere spart?"; case .sv: return "Vad har ni sparat?"; case .da: return "Hvad har I sparet?"; case .fi: return "Mitä olette säästäneet?"; case .de: return "Was haben Sie gespart?"; case .fr: return "Qu'avez-vous épargné?"; case .es: return "¿Cuánto han ahorrado?"; default: return "What have you each saved?" }
        case .investment:
            switch lang { case .nb: return "Hva har dere investert?"; case .sv: return "Vad har ni investerat?"; case .da: return "Hvad har I investeret?"; case .fi: return "Mitä olette sijoittaneet?"; case .de: return "Was haben Sie investiert?"; case .fr: return "Qu'avez-vous investi?"; case .es: return "¿Cuánto han invertido?"; default: return "What have you each invested?" }
        case .furniture:
            switch lang { case .nb: return "Hva betalte dere for møblene?"; case .sv: return "Vad betalade ni för möblerna?"; case .da: return "Hvad betalte I for møblerne?"; case .fi: return "Mitä maksoit huonekaluista?"; case .de: return "Was haben Sie für die Möbel bezahlt?"; case .fr: return "Qu'avez-vous payé pour les meubles?"; case .es: return "¿Cuánto pagaron por los muebles?"; default: return "What did you pay for the furniture?" }
        case .pet:
            switch lang { case .nb: return "Hva kostet kjæledyret?"; case .sv: return "Vad kostade husdjuret?"; case .da: return "Hvad kostede kæledyret?"; case .fi: return "Mitä lemmikki maksoi?"; case .de: return "Was hat das Haustier gekostet?"; case .fr: return "Combien a coûté l'animal?"; case .es: return "¿Cuánto costó la mascota?"; default: return "How much did the pet cost?" }
        case .other:
            switch lang { case .nb: return "Hvem bidro med hva?"; case .sv: return "Vem bidrog med vad?"; case .da: return "Hvem bidrog med hvad?"; case .fi: return "Kuka maksoi mitä?"; case .de: return "Wer hat was beigetragen?"; case .fr: return "Qui a contribué quoi?"; case .es: return "¿Quién aportó qué?"; default: return "What have you each contributed?" }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .padding(.bottom, 28)

                stepContent
                    .id(step)
                    .transition(direction > 0
                        ? .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                      removal:   .move(edge: .leading).combined(with: .opacity))
                        : .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                      removal:   .move(edge: .trailing).combined(with: .opacity))
                    )

                Spacer(minLength: 0)
                bottomBar
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .animation(.spring(duration: 0.32), value: step)
        }
        .onChange(of: ownerMode) { _, m in applyOwnerMode(m) }
        .onChange(of: selectedType) { _, _ in ownerMode = .shared; shareAText = "50" }
    }

    // MARK: Progress bar (reflects only effective steps for this type)

    private var progressBar: some View {
        let steps = effectiveSteps
        let currentIdx = (steps.firstIndex(of: step) ?? -1) + 1
        return HStack(spacing: 6) {
            ForEach(0..<steps.count, id: \.self) { i in
                Capsule()
                    .fill(i < currentIdx ? Color.cohGreen : Color(.systemGray5))
                    .frame(height: 3)
                    .animation(.spring(duration: 0.3), value: step)
            }
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if step > minStep {
                Button {
                    direction = -1
                    withAnimation(.spring(duration: 0.32)) { step = prevStep(from: step) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.cohInk)
                }
            } else {
                Button(strings.cancel) { dismiss() }
            }
        }
        // In setup mode, show a subtitle indicating which asset is being set up
        if existingAsset != nil {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: selectedType.icon)
                        .font(.caption).foregroundStyle(selectedType.color)
                    Text(strings.settingUp)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.cohInk)
                }
            }
        }
    }

    // MARK: Step content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1: typeStep
        case 2: detailsStep
        case 3: valueStep
        case 4: ownershipStep
        case 5: contributionsStep
        default: EmptyView()
        }
    }

    // Step 1 — Type
    private var typeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                stepHeader(stepTitle)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                    ForEach(AssetType.allCases, id: \.self) { type in
                        wizardTypeCell(type)
                    }
                }
            }
            .padding(.horizontal, 28)
        }
    }

    private func wizardTypeCell(_ type: AssetType) -> some View {
        let selected = selectedType == type
        return Button {
            withAnimation(.spring(duration: 0.18)) { selectedType = type }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                direction = 1
                withAnimation(.spring(duration: 0.32)) { step = 2 }
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(selected ? type.color : type.color.opacity(0.10))
                        .frame(height: 68)
                    Image(systemName: type.icon)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(selected ? .white : type.color)
                }
                Text(type.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selected ? type.color : .secondary)
            }
            .scaleEffect(selected ? 1.03 : 1.0)
            .animation(.spring(duration: 0.18), value: selected)
        }
        .buttonStyle(.plain)
    }

    // Step 2 — Name
    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                stepHeader(stepTitle)
                Text(strings.stepNameSub)
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            VStack(spacing: 16) {
                bigField(strings.fieldName, placeholder: selectedType.displayName, text: $label, keyboard: .default)
                bigField(selectedType.secondaryLabel + " " + strings.fieldOptional,
                         placeholder: selectedType.secondaryPlaceholder, text: $address, keyboard: .default)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    // Step 3 — Value
    private var valueStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                stepHeader(stepTitle)
                Text(label).font(.subheadline).foregroundStyle(Color.cohGreen)
            }
            VStack(spacing: 16) {
                bigField(selectedType.valueLabel,
                         placeholder: selectedType.valuePlaceholder,
                         text: $valueText, keyboard: .decimalPad,
                         prefix: household.currencySymbol)
                if selectedType.showLoan {
                    bigField(selectedType.loanLabel, placeholder: "0",
                             text: $loanText, keyboard: .decimalPad,
                             prefix: household.currencySymbol)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    // Step 4 — Ownership
    private var ownershipStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                stepHeader(stepTitle)
                Text(label).font(.subheadline).foregroundStyle(Color.cohGreen)
            }
            if selectedType.ownershipUsesPercent {
                VStack(alignment: .leading, spacing: 10) {
                    Text(selectedType.ownershipHint)
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Text("\(household.partnerAName)'s \(selectedType.ownershipLabel)")
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 2) {
                            TextField("50", text: $shareAText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 52)
                                .font(.title3.bold().monospacedDigit())
                            Text("%").foregroundStyle(.secondary)
                        }
                    }
                    .padding(18)
                    .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        ownerChip(household.partnerAName, mode: .personA)
                        ownerChip(strings.sharedLabel, mode: .shared)
                        ownerChip(household.partnerBName, mode: .personB)
                        ownerChip("%", mode: .custom)
                    }
                    if ownerMode == .custom {
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(household.partnerAName): \(shareAText)%")
                                    .font(.subheadline.monospacedDigit()).foregroundStyle(Color.cohGreen)
                                Spacer()
                                Text("\(household.partnerBName): \(String(100 - (Int(shareAText) ?? 50)))%")
                                    .font(.subheadline.monospacedDigit()).foregroundStyle(Color.cohBlue)
                            }
                            Slider(value: Binding(
                                get: { Double(shareAText) ?? 50 },
                                set: { shareAText = String(Int($0)) }
                            ), in: 0...100, step: 1).tint(.cohGreen)
                        }
                        .padding(18)
                        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.25), value: ownerMode == .custom)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    // Step 5 — Contributions
    private var contributionsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    stepHeader(stepTitle)
                    Text(strings.stepContribsSub)
                        .font(.subheadline).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Partner A
                bigField(
                    "\(household.partnerAName) — \(depositLabel)",
                    placeholder: "0",
                    text: $depositAText,
                    keyboard: .decimalPad,
                    prefix: household.currencySymbol
                )

                // Partner B
                bigField(
                    "\(household.partnerBName) — \(depositLabel)",
                    placeholder: "0",
                    text: $depositBText,
                    keyboard: .decimalPad,
                    prefix: household.currencySymbol
                )

                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.stepPurchaseDate)
                        .font(.caption.weight(.semibold))
                        .tracking(0.3)
                        .foregroundStyle(.secondary)
                    DatePicker("", selection: $contributionDate, displayedComponents: .date)
                        .labelsHidden()
                        .padding(14)
                        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                }

                // Hint
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption2).foregroundStyle(Color.cohTertiary)
                    Text(String(format: strings.contribInterestHint,
                                String(format: "%.0f%%", household.annualInterestRate * 100)))
                        .font(.caption2).foregroundStyle(Color.cohTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Color(.separator).frame(height: 0.5)
            VStack(spacing: 10) {
                Button {
                    let next = nextStep(from: step)
                    if next > totalSteps {
                        save()
                    } else {
                        direction = 1
                        withAnimation(.spring(duration: 0.32)) { step = next }
                    }
                } label: {
                    Text(isLastStep ? strings.addAssetNavTitle : strings.continueButton)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            canAdvance ? Color.cohGreen : Color(.systemGray4),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
                .disabled(!canAdvance)

                // Skip button on contributions step (step 5, if shown)
                if isLastStep && effectiveSteps.contains(5) {
                    Button {
                        depositAText = ""; depositBText = ""
                        save()
                    } label: {
                        Text(strings.stepSkipContribs)
                            .font(.subheadline)
                            .foregroundStyle(Color.cohSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(Color.cohBg)
    }

    // MARK: Reusable sub-views

    private func stepHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 26, weight: .bold, design: .serif))
            .foregroundStyle(Color.cohInk)
    }

    private func bigField(_ label: String, placeholder: String,
                           text: Binding<String>, keyboard: UIKeyboardType,
                           prefix: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .tracking(0.3)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                if let p = prefix {
                    Text(p).foregroundStyle(.secondary).font(.title3)
                }
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .font(.title3)
            }
            .padding(18)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        }
    }

    private func ownerChip(_ label: String, mode: OwnerMode) -> some View {
        let selected = ownerMode == mode
        return Button { ownerMode = mode } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(selected ? .white : Color.cohInk)
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(selected ? Color.cohGreen : Color(.systemGray6)))
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private func applyOwnerMode(_ mode: OwnerMode) {
        switch mode {
        case .personA: shareAText = "100"
        case .shared:  shareAText = "50"
        case .personB: shareAText = "0"
        case .custom:  break
        }
    }

    private func save() {
        let value  = Double(valueText.replacingOccurrences(of: ",", with: "")) ?? 0
        let loan   = selectedType.showLoan
            ? (Double(loanText.replacingOccurrences(of: ",", with: "")) ?? 0) : 0
        let shareA = min(1, max(0, (Double(shareAText) ?? 50) / 100))
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)

        let target: Asset
        if let existing = existingAsset {
            // Update mode — fill in the blank asset created during onboarding
            existing.assetType       = selectedType.rawValue
            existing.label           = trimmedLabel.isEmpty ? selectedType.displayName : trimmedLabel
            existing.address         = address.trimmingCharacters(in: .whitespaces)
            existing.currentValue    = value
            existing.remainingLoan   = loan
            existing.salesCostFraction = selectedType.defaultSalesCostFraction
            existing.ownershipShareA   = shareA
            target = existing
        } else {
            // Create mode
            let asset = Asset(
                assetType: selectedType.rawValue,
                label: trimmedLabel,
                address: address.trimmingCharacters(in: .whitespaces),
                currentValue: value,
                remainingLoan: loan,
                salesCostFraction: selectedType.defaultSalesCostFraction,
                ownershipShareA: shareA
            )
            household.assets.append(asset)
            target = asset
        }

        // Log initial equity contributions if entered
        let dA = Double(depositAText.replacingOccurrences(of: ",", with: "")) ?? 0
        let dB = Double(depositBText.replacingOccurrences(of: ",", with: "")) ?? 0
        if dA > 0 {
            target.contributions.append(ContributionRecord(
                ownerKey: "A", amount: dA, date: contributionDate,
                label: depositLabel, category: depositCategory
            ))
        }
        if dB > 0 {
            target.contributions.append(ContributionRecord(
                ownerKey: "B", amount: dB, date: contributionDate,
                label: depositLabel, category: depositCategory
            ))
        }

        // Mirror to Supabase if signed in and household is synced
        if let householdId = store.household?.id {
            let capturedTarget = target
            let capturedType   = selectedType
            let capturedLabel  = capturedTarget.label
            let capturedAddr   = capturedTarget.address
            let capturedValue  = capturedTarget.currentValue
            let capturedLoan   = capturedTarget.remainingLoan
            let capturedFrac   = capturedTarget.salesCostFraction
            let capturedShare  = capturedTarget.ownershipShareA
            let capturedDLabel = depositLabel
            let capturedDCat   = depositCategory
            let capturedDate   = contributionDate
            let capturedDA     = dA
            let capturedDB     = dB
            Task {
                let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
                do {
                    let dbAsset = try await SupabaseService.insertAsset(
                        householdId: householdId,
                        assetType: capturedType.rawValue,
                        label: capturedLabel,
                        address: capturedAddr,
                        currentValue: capturedValue,
                        remainingLoan: capturedLoan,
                        salesCostFraction: capturedFrac,
                        ownershipShareA: capturedShare,
                        purchaseDate: df.string(from: Date()))
                    // Align local SwiftData UUID with the Supabase-generated UUID
                    capturedTarget.id = dbAsset.id

                    // Mirror initial contributions
                    if capturedDA > 0 {
                        _ = try? await SupabaseService.insertContribution(
                            assetId: dbAsset.id, ownerKey: "a",
                            amount: capturedDA, date: df.string(from: capturedDate),
                            label: capturedDLabel, category: capturedDCat)
                    }
                    if capturedDB > 0 {
                        _ = try? await SupabaseService.insertContribution(
                            assetId: dbAsset.id, ownerKey: "b",
                            amount: capturedDB, date: df.string(from: capturedDate),
                            label: capturedDLabel, category: capturedDCat)
                    }
                } catch {
                    // Supabase mirror failed — local SwiftData write already succeeded
                    print("[Supabase] insertAsset failed: \(error)")
                }
            }
        }

        dismiss()
    }
}

// MARK: - Edit asset sheet

struct EditAssetView: View {
    let asset: Asset
    let household: Household
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var strings = AppStrings.shared
    @Environment(HouseholdStore.self) private var store

    @State private var selectedType: AssetType = .home
    @State private var label = ""
    @State private var address = ""
    @State private var valueText = ""
    @State private var loanText = ""
    @State private var shareAText = "50"
    @State private var ownerMode: AddAssetView.OwnerMode = .shared
    @State private var showAddContribution = false
    @State private var showDeleteConfirm = false

    private var canSave: Bool { !label.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // ── Add contribution — most common edit action, shown first ──
                    addContribBanner

                    // ── Existing contributions ──
                    if !asset.contributions.isEmpty {
                        contribList
                    }

                    // ── Value (second most common: annual update) ──
                    editSection(selectedType.showLoan ? strings.sectionValueLoan : strings.sectionValue) {
                        bigField(selectedType.valueLabel,
                                 placeholder: selectedType.valuePlaceholder,
                                 text: $valueText, keyboard: .decimalPad,
                                 prefix: household.currencySymbol)
                        if selectedType.showLoan {
                            bigField(selectedType.loanLabel,
                                     placeholder: "0",
                                     text: $loanText, keyboard: .decimalPad,
                                     prefix: household.currencySymbol)
                        }
                    }

                    // ── Details ──
                    editSection(strings.sectionDetails) {
                        bigField(strings.fieldName,
                                 placeholder: selectedType.displayName,
                                 text: $label, keyboard: .default)
                        bigField(selectedType.secondaryLabel + " " + strings.fieldOptional,
                                 placeholder: selectedType.secondaryPlaceholder,
                                 text: $address, keyboard: .default)
                    }

                    // ── Ownership ──
                    editSection(strings.assetOwnership) {
                        ownershipContent
                    }

                    // ── Delete ──
                    Button { showDeleteConfirm = true } label: {
                        Label(strings.deleteAsset, systemImage: "trash")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
                .padding(24)
                .padding(.bottom, 8)
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle(label.isEmpty ? strings.editAssetTitle : label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(strings.cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.save) { save() }.bold().disabled(!canSave)
                }
            }
        }
        .onAppear { populate() }
        .sheet(isPresented: $showAddContribution) {
            AddContributionView(asset: asset, household: household)
        }
        .confirmationDialog(
            "\(strings.deleteAsset) \"\(asset.label)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(strings.deleteAsset, role: .destructive) { deleteAsset() }
        } message: {
            Text(strings.deleteAssetMessage)
        }
    }

    // MARK: Add contribution banner

    private var addContribBanner: some View {
        Button { showAddContribution = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.cohGreen.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.cohGreen)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(strings.addContribButton)
                        .font(.headline).foregroundStyle(Color.cohInk)
                    Text(selectedType.contributionSubtitle)
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold()).foregroundStyle(Color.cohTertiary)
            }
            .padding(16)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.cohGreen.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.cohGreen.opacity(0.08), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: Contributions list

    private var contribList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings.sectionContribs)
                .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)

            let sorted = asset.contributions.sorted { $0.date < $1.date }
            VStack(spacing: 0) {
                ForEach(sorted) { c in
                    ContributionRow(c: c, household: household) {
                        modelContext.delete(c)
                    }
                    if c.id != sorted.last?.id {
                        Divider().padding(.vertical, 4)
                    }
                }
            }
            .padding(16)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        }
    }

    // MARK: Ownership content

    private var ownershipContent: some View {
        Group {
            if selectedType.ownershipUsesPercent {
                VStack(alignment: .leading, spacing: 12) {
                    // Partner labels + percentages
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(household.partnerAName)
                                .font(.caption.weight(.semibold)).foregroundStyle(Color.cohGreen)
                            Text("\(Int(Double(shareAText) ?? 50))%")
                                .font(.title3.bold().monospacedDigit()).foregroundStyle(Color.cohInk)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(household.partnerBName)
                                .font(.caption.weight(.semibold)).foregroundStyle(Color.cohBlue)
                            Text("\(100 - Int(Double(shareAText) ?? 50))%")
                                .font(.title3.bold().monospacedDigit()).foregroundStyle(Color.cohInk)
                        }
                    }
                    Slider(value: Binding(
                        get: { Double(shareAText) ?? 50 },
                        set: { shareAText = String(Int($0)) }
                    ), in: 0...100, step: 1).tint(.cohGreen)
                    Text(selectedType.ownershipHint)
                        .font(.caption).foregroundStyle(Color.cohTertiary)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        ownerChip(household.partnerAName, mode: .personA)
                        ownerChip(strings.sharedLabel, mode: .shared)
                        ownerChip(household.partnerBName, mode: .personB)
                        ownerChip("%", mode: .custom)
                    }
                    if ownerMode == .custom {
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(household.partnerAName): \(shareAText)%")
                                    .font(.subheadline.monospacedDigit()).foregroundStyle(Color.cohGreen)
                                Spacer()
                                Text("\(household.partnerBName): \(String(100 - (Int(shareAText) ?? 50)))%")
                                    .font(.subheadline.monospacedDigit()).foregroundStyle(Color.cohBlue)
                            }
                            Slider(value: Binding(
                                get: { Double(shareAText) ?? 50 },
                                set: { shareAText = String(Int($0)) }
                            ), in: 0...100, step: 1).tint(.cohGreen)
                        }
                        .padding(16)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.25), value: ownerMode == .custom)
            }
        }
    }

    // MARK: Owner chip

    private func ownerChip(_ label: String, mode: AddAssetView.OwnerMode) -> some View {
        let selected = ownerMode == mode
        return Button {
            ownerMode = mode
            switch mode {
            case .personA: shareAText = "100"
            case .shared:  shareAText = "50"
            case .personB: shareAText = "0"
            case .custom:  break
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(selected ? .white : Color.cohInk)
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(selected ? Color.cohGreen : Color(.systemGray6)))
        }
        .buttonStyle(.plain)
    }

    // MARK: Section container

    private func editSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
            content()
        }
    }

    // MARK: Big field (matches AddAssetView style)

    private func bigField(_ label: String, placeholder: String,
                           text: Binding<String>, keyboard: UIKeyboardType,
                           prefix: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold)).tracking(0.3).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                if let p = prefix { Text(p).foregroundStyle(.secondary).font(.title3) }
                TextField(placeholder, text: text)
                    .keyboardType(keyboard).font(.title3)
            }
            .padding(18)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        }
    }

    // MARK: Populate / Save / Delete

    private func populate() {
        selectedType = AssetType(rawValue: asset.assetType) ?? .other
        label     = asset.label
        address   = asset.address
        valueText = asset.currentValue > 0  ? String(Int(asset.currentValue))  : ""
        loanText  = asset.remainingLoan > 0 ? String(Int(asset.remainingLoan)) : ""
        let pct   = Int(asset.ownershipShareA * 100)
        shareAText = String(pct)
        switch pct {
        case 100:  ownerMode = .personA
        case 0:    ownerMode = .personB
        case 50:   ownerMode = .shared
        default:   ownerMode = .custom
        }
    }

    private func save() {
        asset.assetType     = selectedType.rawValue
        asset.label         = label.trimmingCharacters(in: .whitespaces)
        asset.address       = address.trimmingCharacters(in: .whitespaces)
        asset.currentValue  = Double(valueText.replacingOccurrences(of: ",", with: "")) ?? asset.currentValue
        asset.remainingLoan = selectedType.showLoan
            ? (Double(loanText.replacingOccurrences(of: ",", with: "")) ?? 0) : 0
        asset.salesCostFraction = selectedType.defaultSalesCostFraction
        asset.ownershipShareA   = min(1, max(0, (Double(shareAText) ?? 50) / 100))

        // Mirror to Supabase
        let assetId    = asset.id
        let assetLabel = asset.label
        let assetAddr  = asset.address
        let assetValue = asset.currentValue
        let assetLoan  = asset.remainingLoan
        let assetShare = asset.ownershipShareA
        Task {
            try? await SupabaseService.updateAsset(
                assetId, label: assetLabel, address: assetAddr,
                currentValue: assetValue, remainingLoan: assetLoan,
                ownershipShareA: assetShare)
        }

        dismiss()
    }

    private func deleteAsset() {
        // Mirror delete to Supabase before local removal
        let assetId = asset.id
        Task { try? await SupabaseService.deleteAsset(assetId) }

        // Remove from the relationship array first so any observer (contract, UI)
        // sees the change immediately, before SwiftData cascades the deletion.
        household.assets.removeAll { $0.id == asset.id }
        modelContext.delete(asset)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Contribution row

struct ContributionRow: View {
    let c: ContributionRecord
    let household: Household
    let onDelete: () -> Void

    @State private var confirmDelete = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(c.label)
                    .font(.subheadline.weight(.medium))
                Text(c.date, style: .date)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(household.currencySymbol + fmtAmount(c.amount))
                    .font(.subheadline.bold().monospacedDigit())
                Text(c.ownerKey == "A" ? household.partnerAName : household.partnerBName)
                    .font(.caption)
                    .foregroundStyle(c.ownerKey == "A"
                        ? Color.cohGreen
                        : Color.cohBlue)
            }
            Button { confirmDelete = true } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(Color.cohTertiary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .confirmationDialog(
            AppStrings.shared.removeContrib,
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button(AppStrings.shared.removeContribButton, role: .destructive) {
                onDelete()
            }
        } message: {
            Text("\(c.label) · \(fmtAmount(c.amount))")
        }
    }

    private func fmtAmount(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

// MARK: - Add contribution sheet

struct AddContributionView: View {
    let asset: Asset
    let household: Household
    @Environment(\.dismiss) private var dismiss
    @Environment(HouseholdStore.self) private var store

    @State private var ownerKey   = "A"
    @State private var amountText = ""
    @State private var date       = Date()
    @State private var label      = ""
    @State private var category   = "deposit"

    private struct Category {
        let id: String; let label: String; let icon: String; let color: Color
    }
    private var categories: [Category] {
        let s = AppStrings.shared
        return [
            Category(id: "deposit",         label: s.catDeposit,        icon: "banknote.fill",         color: .cohGreen),
            Category(id: "extra_repayment", label: s.catExtraRepayment, icon: "arrow.down.circle.fill", color: Color.cohBlue),
            Category(id: "renovation",      label: s.catRenovation,     icon: "hammer.fill",           color: Color(red: 0.93, green: 0.50, blue: 0.18)),
            Category(id: "inheritance",     label: s.catInheritance,    icon: "gift.fill",             color: Color(red: 0.54, green: 0.31, blue: 0.96)),
            Category(id: "other",           label: s.catOther,          icon: "ellipsis.circle.fill",  color: Color(.systemGray)),
        ]
    }

    private var canAdd: Bool {
        (Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0) > 0
    }

    private var selectedCategory: Category? { categories.first { $0.id == category } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Who contributed
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppStrings.shared.addContribWho)
                            .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            partnerChip(household.partnerAName, key: "A")
                            partnerChip(household.partnerBName, key: "B")
                        }
                    }

                    // Amount + date
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppStrings.shared.addContribAmountDate)
                            .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            Text(household.currencySymbol).foregroundStyle(.secondary).font(.title3)
                            TextField("0", text: $amountText).keyboardType(.decimalPad).font(.title3)
                        }
                        .padding(16).background(Color.cohCard, in: RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                    }

                    // Category icons
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppStrings.shared.addContribCategory)
                            .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(categories, id: \.id) { cat in
                                let selected = category == cat.id
                                Button { category = cat.id } label: {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selected ? cat.color : cat.color.opacity(0.1))
                                                .frame(height: 52)
                                            Image(systemName: cat.icon)
                                                .font(.title3).foregroundStyle(selected ? .white : cat.color)
                                        }
                                        Text(cat.label)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(selected ? cat.color : .secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .buttonStyle(.plain)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(selected ? cat.color : .clear, lineWidth: 1.5)
                                        .padding(.bottom, 20)
                                )
                            }
                        }
                    }

                    // Optional label
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppStrings.shared.addContribNote)
                            .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
                        TextField(AppStrings.shared.addContribNotePlaceholder, text: $label)
                            .padding(14).background(Color.cohCard, in: RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                    }

                    // Add button
                    Button { add() } label: {
                        Text(AppStrings.shared.addContribTitle)
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(canAdd ? Color.cohGreen : Color(.systemGray4),
                                        in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canAdd)
                }
                .padding(24)
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle(AppStrings.shared.addContribTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(AppStrings.shared.cancel) { dismiss() } }
            }
        }
    }

    private func partnerChip(_ name: String, key: String) -> some View {
        let selected = ownerKey == key
        return Button { ownerKey = key } label: {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? .white : Color.cohInk)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(selected ? Color.cohGreen : Color(.systemGray6),
                            in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func add() {
        let amount = Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
        let displayLabel = label.trimmingCharacters(in: .whitespaces).isEmpty
            ? (categories.first { $0.id == category }?.label ?? "Contribution")
            : label.trimmingCharacters(in: .whitespaces)
        asset.contributions.append(
            ContributionRecord(ownerKey: ownerKey, amount: amount, date: date,
                               label: displayLabel, category: category)
        )

        // Mirror to Supabase
        let assetId       = asset.id
        let capturedKey   = ownerKey.lowercased()   // Supabase expects "a" or "b"
        let capturedAmt   = amount
        let capturedDate  = date
        let capturedLabel = displayLabel
        let capturedCat   = category
        Task {
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            _ = try? await SupabaseService.insertContribution(
                assetId: assetId, ownerKey: capturedKey,
                amount: capturedAmt, date: df.string(from: capturedDate),
                label: capturedLabel, category: capturedCat)
        }

        dismiss()
    }
}
