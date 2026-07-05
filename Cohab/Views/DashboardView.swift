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
    @State private var showAgreementSheet = false
    @State private var agreementSubmission: DocuSealSubmission?
    @State private var isGeneratingAgreement = false
    @State private var agreementError: String?
    @State private var availableRate: CentralBankRate?
    @State private var showRateSaved = false

    private var household: Household? { households.first }

    var body: some View {
        NavigationStack {
            ZStack {
                // Green fills everything — shows in header area
                Color.cohGreen.ignoresSafeArea()

                if let h = household {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // GREEN HEADER
                            headerSection(h)
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                                .padding(.bottom, 36)

                            // CREAM CONTENT — rounded top overlaps header
                            VStack(spacing: 0) {
                                if let rate = availableRate,
                                   abs(rate.rate - h.annualInterestRate) > 0.001 {
                                    rateUpdateBanner(household: h, rate: rate)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 20)
                                }

                                quickActions(h)
                                    .padding(.top, 20)

                                assetsList(h).padding(.top, 20)
                                if h.isFormalMode {
                                    agreementStatusRow(h)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 12)
                                }
                                Spacer(minLength: 100)
                            }
                            .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.65)
                            .background(Color.cohBg)
                            .clipShape(.rect(topLeadingRadius: 28, topTrailingRadius: 28))
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
                        HStack { Spacer(); addButton }
                            .padding(.trailing, 20)
                            .padding(.bottom, 8)
                    }

                } else {
                    Color.cohBg.ignoresSafeArea()
                    emptyState
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { toolbarContent }
        }
        .sheet(isPresented: $showSetup) {
            HouseholdSetupView(household: household)
        }
        .sheet(isPresented: $showAddAsset) {
            if let h = household { AddAssetView(household: h) }
        }
        .sheet(item: $editingAsset) { asset in
            if let h = household {
                // Unconfigured asset (no value set) → wizard, otherwise normal edit
                if asset.currentValue == 0 && asset.contributions.isEmpty {
                    AddAssetView(household: h, existingAsset: asset)
                } else {
                    EditAssetView(asset: asset, household: h)
                }
            }
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
                    .foregroundStyle(.white.opacity(0.85))
                    .font(.body)
            }
        }
    }

    // MARK: Header section (Revolut-style green hero)

    private func headerSection(_ h: Household) -> some View {
        let (equityA, equityB) = totalNetEquity(h)
        let total = equityA + equityB
        let shareA: Double = total > 0 ? equityA / total : 0.5
        let pctA = Int((shareA * 100).rounded())
        let pctB = 100 - pctA
        let sym = h.currencySymbol

        return VStack(alignment: .leading, spacing: 20) {
            // Partner names
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(.white).frame(width: 8, height: 8)
                    Text(h.partnerAName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer()
                HStack(spacing: 6) {
                    Text(h.partnerBName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.70))
                        .lineLimit(1)
                    Circle().fill(.white.opacity(0.55)).frame(width: 8, height: 8)
                }
            }

            // Hero equity number
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(sym)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(Int(total).formatted())
                        .font(.system(size: 42, weight: .bold, design: .serif).monospacedDigit())
                        .foregroundStyle(.white)
                }
                Text(strings.dashboardNetEquity.lowercased())
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }

            // Split bar + percentages
            if !h.assets.isEmpty {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Text("\(pctA)%")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.white)
                            .frame(width: 32, alignment: .trailing)

                        Capsule()
                            .fill(.white.opacity(0.22))
                            .overlay(alignment: .leading) {
                                GeometryReader { geo in
                                    Capsule()
                                        .fill(.white)
                                        .frame(width: geo.size.width * CGFloat(shareA),
                                               height: geo.size.height)
                                }
                            }
                            .frame(height: 6)

                        Text("\(pctB)%")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.white.opacity(0.65))
                            .frame(width: 32, alignment: .leading)
                    }

                    // Per-partner amounts
                    HStack {
                        Text(sym + Int(equityA).formatted())
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.80))
                        Spacer()
                        Text(sym + Int(equityB).formatted())
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.60))
                    }
                    .padding(.horizontal, 42) // align under bar labels
                }
            }
        }
    }

    // Kept for use in other parts
    private func equityPartnerRow(name: String, amount: Double,
                                  symbol: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Circle().fill(color).frame(width: 10, height: 10)
                .padding(.leading, 20)
            Text(name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.cohInk)
                .lineLimit(1)
            Spacer()
            Text(symbol + Int(amount).formatted())
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(Color.cohInk)
                .padding(.trailing, 20)
        }
        .padding(.vertical, 14)
    }

    private func totalNetEquity(_ h: Household) -> (Double, Double) {
        h.assets.reduce((0.0, 0.0)) { acc, asset in
            // Use SettlementEngine with no sale costs so payout[A]+payout[B] = net equity.
            // This correctly returns contributions+interest first, then splits surplus by ownership.
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
                Text("Set up your household")
                    .font(.title2.bold())
                Text("Track shared assets, contributions, and get a fair settlement whenever you need it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button { showSetup = true } label: {
                Text("Get started")
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
                    .foregroundStyle(Color(.tertiaryLabel))
                Text(h.currency)
                    .font(.caption.bold())
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6), in: Capsule())

            Spacer()
            partnerPill(h.partnerBName, color: Color(red: 0.20, green: 0.49, blue: 0.96))
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
            HStack {
                Text("Assets")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(h.assets.count) \(h.assets.count == 1 ? "item" : "items")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            if h.assets.isEmpty {
                noAssetsPrompt { showAddAsset = true }
                    .padding(.top, 16)
            } else {
                VStack(spacing: 16) {
                    ForEach(h.assets) { asset in
                        AssetCard(asset: asset, household: h,
                                  onEdit: { editingAsset = asset })
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    private func noAssetsPrompt(action: @escaping () -> Void) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "plus.square.dashed")
                .font(.system(size: 36))
                .foregroundStyle(Color(.tertiaryLabel))
            Text("No assets yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add your home, car, or any shared asset to track contributions and see a fair settlement breakdown.")
                .font(.subheadline)
                .foregroundStyle(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: Floating add button

    // MARK: Helpers

    private func sortedAssets(_ assets: [Asset]) -> [Asset] {
        let order: [AssetType] = [.home, .cabin, .car, .savings, .investment, .furniture, .pet, .other]
        return assets.sorted { (order.firstIndex(of: $0.type) ?? 99) < (order.firstIndex(of: $1.type) ?? 99) }
    }

    // MARK: Quick actions — always exactly 4 chips, content rotates with context

    private func quickActions(_ h: Household) -> some View {
        let noPartner  = h.partnerBName.trimmingCharacters(in: .whitespaces).isEmpty
        let noAssets   = h.assets.isEmpty
        let noContribs = !h.assets.contains { !$0.contributions.isEmpty }
        let partnerB   = h.partnerBName.isEmpty ? "Partner" : h.partnerBName

        // ── Chip 1: Next step (most important thing to do) ──────────────────
        let chip1: (icon: String, label: String, accent: Color, action: () -> Void)
        if noPartner {
            chip1 = ("person.badge.plus", strings.inviteTitle, Color.cohGreen, { showSetup = true })
        } else if noAssets {
            chip1 = ("plus.square.fill", strings.dashboardAddAsset, Color.cohGreen, { showAddAsset = true })
        } else if noContribs {
            chip1 = ("arrow.up.circle.fill", strings.addContribTitle,
                     Color(red: 0.54, green: 0.31, blue: 0.96),
                     { editingAsset = sortedAssets(h.assets).first })
        } else {
            // All done → invite partner to download app
            chip1 = ("envelope.badge.fill", strings.inviteGenerate,
                     Color.cohGreen, { showSetup = true })
        }

        // ── Chip 3: Agreement — always, label/action changes with status ────
        let agreementIcon: String
        let agreementLabel: String
        let agreementAccent = Color(red: 0.04, green: 0.65, blue: 0.75)
        let agreementAction: () -> Void
        switch h.agreementStatus {
        case "pending":
            agreementIcon   = "clock.fill"
            agreementLabel  = strings.agreementPending
            agreementAction = { agreementSubmission = nil; showAgreementSheet = true }
        case "signed" where !h.agreementNeedsUpdate:
            agreementIcon   = "checkmark.seal.fill"
            agreementLabel  = strings.agreementSigned
            agreementAction = { agreementSubmission = nil; showAgreementSheet = true }
        default:
            agreementIcon   = "doc.text.fill"
            agreementLabel  = h.isFormalMode ? strings.agreementGenerate : strings.onboardingYesAgreement
            agreementAction = {
                agreementSubmission = nil; agreementError = nil
                showAgreementSheet = true
            }
        }

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // 1 — Next step
                quickActionChip(icon: chip1.icon, label: chip1.label,
                                accent: chip1.accent, action: chip1.action)

                // 2 — Expenses (always)
                quickActionNavChip(
                    icon: "dollarsign.circle.fill",
                    label: strings.calcExpenseTitle,
                    accent: Color(red: 0.20, green: 0.49, blue: 0.96),
                    destination: ExpenseSplitView(
                        nameA: h.partnerAName, nameB: partnerB,
                        symbol: h.currencySymbol
                    )
                )

                // 3 — Agreement (always, content changes)
                quickActionChip(icon: agreementIcon, label: agreementLabel,
                                accent: agreementAccent, action: agreementAction)

                // 4 — Settlement estimate (always)
                quickActionNavChip(
                    icon: "scale.3d",
                    label: strings.dashboardShowCalculation,
                    accent: Color(red: 0.93, green: 0.50, blue: 0.18),
                    destination: SettlementTabView()
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
    }

    private func quickActionChip(
        icon: String,
        label: String,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(accent.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(accent)
                }
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.cohInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 72)
            }
            .padding(.vertical, 12).padding(.horizontal, 4)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func quickActionNavChip<D: View>(
        icon: String,
        label: String,
        accent: Color,
        destination: D
    ) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(accent.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(accent)
                }
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.cohInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 72)
            }
            .padding(.vertical, 12).padding(.horizontal, 4)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button { showAddAsset = true } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Color.cohGreen, in: Circle())
                .shadow(color: .cohGreen.opacity(0.35), radius: 14, y: 6)
        }
        .padding(24)
    }
}

// MARK: - Asset card

struct AssetCard: View {
    let asset: Asset
    let household: Household
    let onEdit: () -> Void

    @State private var showBreakdown = false
    @ObservedObject private var strings = AppStrings.shared

    private var netEquity: Double { asset.currentValue - asset.remainingLoan }

    // Equity result: no sale costs, so payout[A]+payout[B] = netEquity.
    // Contributions + interest returned first; surplus split by ownership share.
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

    // Settlement result: includes 2% sale costs — used only in the expandable estimate.
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

    private let typeColor: Color
    private let typeIcon: String

    init(asset: Asset, household: Household, onEdit: @escaping () -> Void) {
        self.asset = asset; self.household = household; self.onEdit = onEdit
        self.typeColor = asset.type.color; self.typeIcon = asset.type.icon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            assetHeader
            Color(.separator).frame(height: 0.5).padding(.vertical, 16)
            equityRow
        }
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 4)
        .padding(.horizontal, 20)
    }

    // MARK: Header

    private var assetHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(typeColor.opacity(0.1)).frame(width: 50, height: 50)
                Image(systemName: typeIcon).font(.title3.weight(.semibold)).foregroundStyle(typeColor)
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
                Button(action: onEdit) {
                    HStack(spacing: 3) {
                        Image(systemName: "pencil").font(.caption2)
                        Text(strings.dashboardEdit).font(.caption2)
                    }
                    .foregroundStyle(Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Equity row

    private var equityRow: some View {
        let payoutA = equityResult.payout[.a] ?? 0
        let payoutB = equityResult.payout[.b] ?? 0
        let hasContribs = !asset.contributions.isEmpty
        return VStack(spacing: 10) {
            HStack(alignment: .top) {
                equityColumn(household.partnerAName, equity: payoutA, color: .cohGreen)
                Spacer()
                equityColumn(household.partnerBName, equity: payoutB,
                             color: Color(red: 0.20, green: 0.49, blue: 0.96))
            }
            if hasContribs {
                Text("\(strings.assetContribFirst) \(Int(asset.ownershipShareA * 100))/\(100 - Int(asset.ownershipShareA * 100))")
                    .font(.caption2).foregroundStyle(Color(.tertiaryLabel))
                    .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: Breakdown toggle

    private var breakdownToggle: some View {
        Button { showBreakdown.toggle() } label: {
            HStack {
                Image(systemName: "function")
                    .font(.caption2).foregroundStyle(Color.cohGreen)
                VStack(alignment: .leading, spacing: 1) {
                    Text(showBreakdown ? strings.dashboardHideCalculation : strings.dashboardShowCalculation)
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    if !showBreakdown {
                        Text(strings.dashboardSaleCostsSub)
                            .font(.caption2).foregroundStyle(Color(.tertiaryLabel))
                    }
                }
                Spacer()
                Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                    .font(.caption2).foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: Expandable breakdown

    private var breakdownContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            netProceedsSection
            contributionSection(partner: .a, name: household.partnerAName, color: .cohGreen)
            contributionSection(partner: .b, name: household.partnerBName,
                                color: Color(red: 0.20, green: 0.49, blue: 0.96))
            surplusSection
            finalPayoutSection
        }
        .padding(14)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    // ── Net proceeds ────────────────────────────────────────────────────

    private var netProceedsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("NET PROCEEDS")
            calcRow("Current value", fmt(asset.currentValue))
            if asset.remainingLoan > 0 {
                calcRow("Remaining loan", "−" + fmt(asset.remainingLoan), dim: true)
            }
            if asset.estimatedSalesCost > 0 {
                let pct = Int(asset.salesCostFraction * 100)
                calcRow("Sale costs (\(pct)%)", "−" + fmt(asset.estimatedSalesCost), dim: true)
            }
            Divider()
            calcRow("Net proceeds", fmt(result.netProceeds), bold: true)
        }
    }

    // ── Per-partner contributions ────────────────────────────────────────

    private func contributionSection(partner: Partner, name: String, color: Color) -> some View {
        let rows = contribRows(partner: partner)
        let total = result.accrued[partner] ?? 0
        guard !rows.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(VStack(alignment: .leading, spacing: 6) {
            sectionLabel(name.uppercased() + "'S CONTRIBUTIONS")
            ForEach(rows, id: \.id) { row in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.label).font(.caption).foregroundStyle(.primary)
                        Text(row.dateStr).font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(household.currencySymbol + fmt(row.withInterest))
                            .font(.caption.monospacedDigit().weight(.medium))
                            .foregroundStyle(color)
                        if row.interest > 1 {
                            Text("+\(household.currencySymbol)\(fmt(row.interest)) interest")
                                .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if rows.count > 1 { Divider() }
            if rows.count > 1 { calcRow("Total returned", fmt(total), bold: true, tint: color) }
        })
    }

    // ── Surplus / shortfall ──────────────────────────────────────────────

    private var surplusSection: some View {
        let totalAccrued = (result.accrued[.a] ?? 0) + (result.accrued[.b] ?? 0)
        return VStack(alignment: .leading, spacing: 6) {
            if result.shortfall {
                sectionLabel("SHORTFALL")
                Text("Net proceeds (\(household.currencySymbol)\(fmt(result.netProceeds))) are below total contributions (\(household.currencySymbol)\(fmt(totalAccrued))). Each partner receives a proportional share of available funds.")
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                let surplus = result.netProceeds - totalAccrued
                let shareA = Int(asset.ownershipShareA * 100)
                let shareB = 100 - shareA
                sectionLabel(strings.assetDistribution)
                if totalAccrued > 0 {
                    calcRow(strings.assetContribInterest, fmt(totalAccrued), dim: true)
                }
                calcRow(strings.assetRemainingSurplus, fmt(surplus))
                Divider()
                calcRow("\(household.partnerAName) (\(shareA)%)", fmt(surplus * asset.ownershipShareA))
                calcRow("\(household.partnerBName) (\(shareB)%)", fmt(surplus * (1 - asset.ownershipShareA)))
            }
        }
    }

    // ── Final payout ─────────────────────────────────────────────────────

    private var finalPayoutSection: some View {
        let accruedA = result.accrued[.a] ?? 0
        let accruedB = result.accrued[.b] ?? 0
        let hasContribs = accruedA + accruedB > 0
        return VStack(alignment: .leading, spacing: 6) {
            sectionLabel(strings.assetTotalPayout)
            calcRow(household.partnerAName, fmt(result.payout[.a] ?? 0), bold: true, tint: .cohGreen)
            if hasContribs && accruedA > 0 {
                Text("  \(strings.assetContribInterestLine) \(household.currencySymbol)\(fmt(accruedA))")
                    .font(.caption2).foregroundStyle(Color(.tertiaryLabel))
            }
            calcRow(household.partnerBName, fmt(result.payout[.b] ?? 0), bold: true,
                    tint: Color(red: 0.20, green: 0.49, blue: 0.96))
            if hasContribs && accruedB > 0 {
                Text("  \(strings.assetContribInterestLine) \(household.currencySymbol)\(fmt(accruedB))")
                    .font(.caption2).foregroundStyle(Color(.tertiaryLabel))
            }
            Text("\(strings.assetRateLine) \(String(format: "%.1f%%", household.annualInterestRate * 100)) p.a. · \(strings.assetPerAgreement)")
                .font(.caption2).foregroundStyle(Color(.tertiaryLabel)).padding(.top, 2)
        }
    }

    // MARK: Data helpers

    private struct ContribRow: Identifiable {
        let id = UUID()
        let label: String
        let dateStr: String
        let original: Double
        let withInterest: Double
        var interest: Double { withInterest - original }
    }

    private func contribRows(partner: Partner) -> [ContribRow] {
        let key = partner == .a ? "A" : "B"
        let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .none
        let now = Date()
        return asset.contributions
            .filter { $0.ownerKey == key }
            .sorted { $0.date < $1.date }
            .map { c in
                let accrued = SettlementEngine.accrue(c.amount, rate: household.annualInterestRate,
                                                       from: c.date, to: now)
                return ContribRow(label: c.label, dateStr: df.string(from: c.date),
                                  original: c.amount, withInterest: accrued)
            }
    }

    // MARK: UI building blocks

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.caption2.bold()).tracking(0.8).foregroundStyle(Color(.tertiaryLabel))
    }

    private func calcRow(_ label: String, _ value: String, bold: Bool = false,
                          dim: Bool = false, tint: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(bold ? .caption.weight(.semibold) : .caption)
                .foregroundStyle(dim ? Color(.tertiaryLabel) : .secondary)
            Spacer()
            Text(household.currencySymbol + value)
                .font(bold ? .caption.bold().monospacedDigit() : .caption.monospacedDigit())
                .foregroundStyle(tint ?? (bold ? Color(.label) : .secondary))
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
        HStack(spacing: 12) {
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(.subheadline)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(rate.source) rate updated")
                    .font(.caption.weight(.semibold))
                Text(String(format: "%.2f%%", rate.rate * 100) + " (currently " + String(format: "%.2f%%", household.annualInterestRate * 100) + ")")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if showRateSaved {
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(Color.cohGreen)
            } else {
                Button("Update") {
                    household.annualInterestRate = rate.rate
                    showRateSaved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        availableRate = nil
                        showRateSaved = false
                    }
                }
                .font(.caption.weight(.semibold)).foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.cohGreen, in: Capsule())
            }
            Button { availableRate = nil } label: {
                Image(systemName: "xmark")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
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
                    Text("Ownership Agreement")
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
                .font(.caption).foregroundStyle(Color(.tertiaryLabel))
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
                    .font(.caption2).foregroundStyle(Color(.tertiaryLabel))
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
    @EnvironmentObject private var auth: AuthManager
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @ObservedObject private var strings = AppStrings.shared

    @State private var nameA = ""
    @State private var nameB = ""
    @State private var currency = "GBP"
    @State private var rateText = "5.0"
    @State private var showDeleteConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var showSignOutConfirm = false
    @State private var deleteAccountError: String?
    @State private var exportURL: URL?
    @State private var showExportSheet = false

    let currencies = ["GBP", "USD", "EUR", "AUD", "CAD", "NOK", "SEK"]
    private var canSave: Bool {
        !nameA.trimmingCharacters(in: .whitespaces).isEmpty &&
        !nameB.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.cohGreen).frame(width: 24)
                        TextField(strings.onboardingYourName, text: $nameA)
                    }
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color(red: 0.20, green: 0.49, blue: 0.96)).frame(width: 24)
                        TextField(strings.onboardingPartnerName, text: $nameB)
                    }
                } header: { Text(strings.onboardingWhoDoYouShare) }

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

                if let h = household {
                    Section {
                        Button {
                            exportURL = generateExportCSV(household: h)
                            showExportSheet = exportURL != nil
                        } label: {
                            Label(s(en: "Export to Excel / CSV", nb: "Eksporter til Excel / CSV"),
                                  systemImage: "arrow.up.doc.fill")
                        }
                    } footer: {
                        Text(s(en: "Exports all assets, contributions and expenses as a .csv file (Excel, Numbers, Google Sheets).",
                               nb: "Eksporterer alle eiendeler, bidrag og utgifter som en .csv-fil (Excel, Numbers, Google Sheets)."))
                    }
                }

                if household != nil {
                    Section {
                        Button(role: .destructive) { signOut() } label: {
                            Label(s(en: "Sign out", nb: "Logg ut"),
                                  systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }

                    Section {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label(s(en: "Delete all local data", nb: "Slett alle lokale data"),
                                  systemImage: "trash")
                        }
                        Button(role: .destructive) { showDeleteAccountConfirm = true } label: {
                            Label(s(en: "Delete account", nb: "Slett konto"),
                                  systemImage: "person.crop.circle.badge.minus")
                        }
                    } footer: {
                        Text(s(en: "\"Delete account\" permanently removes your account and all data from our servers. This cannot be undone.",
                               nb: "\"Slett konto\" sletter kontoen din og alle data fra serverne våre permanent. Dette kan ikke angres."))
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
            .confirmationDialog(s(en: "Delete all local data?", nb: "Slette alle lokale data?"),
                                isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button(s(en: "Delete everything", nb: "Slett alt"), role: .destructive) { deleteAll() }
                Button(s(en: "Cancel", nb: "Avbryt"), role: .cancel) {}
            } message: {
                Text(s(en: "Assets, contributions, and your agreement will be removed from this device.",
                       nb: "Eiendeler, bidrag og avtalen din fjernes fra denne enheten."))
            }
            .confirmationDialog(s(en: "Delete account?", nb: "Slette konto?"),
                                isPresented: $showDeleteAccountConfirm, titleVisibility: .visible) {
                Button(s(en: "Delete my account", nb: "Slett kontoen min"), role: .destructive) {
                    deleteAccount()
                }
                Button(s(en: "Cancel", nb: "Avbryt"), role: .cancel) {}
            } message: {
                Text(s(en: "Your account and all data will be permanently deleted from our servers. This cannot be undone.",
                       nb: "Kontoen din og alle data slettes permanent fra serverne våre. Dette kan ikke angres."))
            }
            .alert(s(en: "Could not delete account", nb: "Kunne ikke slette konto"),
                   isPresented: Binding(get: { deleteAccountError != nil },
                                        set: { if !$0 { deleteAccountError = nil } })) {
                Button(s(en: "OK", nb: "OK"), role: .cancel) {}
            } message: {
                Text(deleteAccountError ?? "")
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(url: url)
                }
            }
        }
        .onAppear {
            guard let h = household else { return }
            nameA = h.partnerAName; nameB = h.partnerBName
            currency = h.currency
            rateText = String(format: "%.1f", h.annualInterestRate * 100)
        }
    }

    private func save() {
        let rate = (Double(rateText.replacingOccurrences(of: ",", with: ".")) ?? 5.0) / 100
        let a = nameA.trimmingCharacters(in: .whitespaces)
        let b = nameB.trimmingCharacters(in: .whitespaces)
        if let h = household {
            h.partnerAName = a; h.partnerBName = b
            h.currency = currency; h.annualInterestRate = rate
        } else {
            modelContext.insert(
                Household(partnerAName: a, partnerBName: b, currency: currency, annualInterestRate: rate)
            )
        }
        dismiss()
    }

    private func signOut() {
        // Set onboardingComplete first — ContentView transitions away, sheet closes naturally
        onboardingComplete = false
        Task { await auth.signOut() }
    }

    private func deleteAll() {
        if let h = household { modelContext.delete(h) }
        try? modelContext.save()
        onboardingComplete = false
    }

    private func deleteAccount() {
        if let h = household { modelContext.delete(h) }
        try? modelContext.save()
        onboardingComplete = false
        Task {
            do {
                try await auth.deleteAccount()
            } catch {
                // Account deletion failed — user is still signed out locally
                deleteAccountError = error.localizedDescription
            }
        }
    }

    // MARK: CSV Export

    private func generateExportCSV(household h: Household) -> URL? {
        let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .none
        let sym = h.currencySymbol
        var lines: [String] = []

        // ── Header ──────────────────────────────────────────────────────────
        lines += [
            "COHAB EXPORT",
            "Generated,\(df.string(from: Date()))",
            "Household,\(h.partnerAName) & \(h.partnerBName)",
            "Currency,\(h.currency)",
            "Country,\(h.country)",
            "Interest rate,\(String(format: "%.1f%%", h.annualInterestRate * 100))",
            ""
        ]

        // ── Assets ──────────────────────────────────────────────────────────
        lines += ["ASSETS", "Name,Type,Current value,Remaining loan,\(h.partnerAName) %,\(h.partnerBName) %,Address"]
        for asset in h.assets.sorted(by: { $0.label < $1.label }) {
            let pA = Int((asset.ownershipShareA * 100).rounded())
            lines.append([
                csvEsc(asset.label),
                csvEsc(asset.type.rawValue),
                "\(sym)\(Int(asset.currentValue))",
                asset.remainingLoan > 0 ? "\(sym)\(Int(asset.remainingLoan))" : "",
                "\(pA)%",
                "\(100 - pA)%",
                csvEsc(asset.address)
            ].joined(separator: ","))
        }
        lines.append("")

        // ── Contributions ───────────────────────────────────────────────────
        lines += ["CONTRIBUTIONS", "Asset,Date,Partner,Amount,Label"]
        for asset in h.assets.sorted(by: { $0.label < $1.label }) {
            for c in asset.contributions.sorted(by: { $0.date < $1.date }) {
                let partner = c.ownerKey == "A" ? h.partnerAName : h.partnerBName
                lines.append([
                    csvEsc(asset.label),
                    df.string(from: c.date),
                    csvEsc(partner),
                    "\(sym)\(Int(c.amount))",
                    csvEsc(c.label)
                ].joined(separator: ","))
            }
        }
        lines.append("")

        // ── Shared expenses ─────────────────────────────────────────────────
        lines += ["SHARED EXPENSES", "Label,Amount,Paid by,\(h.partnerAName) %,\(h.partnerBName) %,Recurring,Date"]
        for exp in h.expenses.sorted(by: { $0.label < $1.label }) {
            let paidBy = exp.paidByKey == "a" ? h.partnerAName : h.partnerBName
            let pA = Int((exp.splitRatioA * 100).rounded())
            lines.append([
                csvEsc(exp.label),
                "\(sym)\(Int(exp.amount))",
                csvEsc(paidBy),
                "\(pA)%",
                "\(100 - pA)%",
                exp.isRecurring ? "Yes" : "No",
                df.string(from: exp.date)
            ].joined(separator: ","))
        }

        let csv = lines.joined(separator: "\n")
        let nameSlug = "\(h.partnerAName)-\(h.partnerBName)".lowercased()
            .replacingOccurrences(of: " ", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("cohab-\(nameSlug).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func csvEsc(_ s: String) -> String {
        s.contains(",") || s.contains("\"") || s.contains("\n")
            ? "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\""
            : s
    }

    private func s(en: String, nb: String) -> String {
        strings.language == .nb ? nb : en
    }
}

// MARK: - Share sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Add asset sheet (4-step wizard)

struct AddAssetView: View {
    let household: Household
    var existingAsset: Asset? = nil          // nil = new asset, non-nil = configure blank
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var strings = AppStrings.shared

    @State private var step = 0
    @State private var selectedType: AssetType = .home
    @State private var label = ""
    @State private var address = ""
    @State private var valueText = ""
    @State private var loanText = ""
    @State private var shareA: Double = 0.5

    private var s: AppStrings { strings }
    private var sym: String { household.currencySymbol }
    private let bluePartner = Color(red: 0.20, green: 0.49, blue: 0.96)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cohBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Progress bar (steps 1-3)
                    if step > 0 {
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.cohGreen.opacity(0.12)).frame(height: 3)
                                Capsule().fill(Color.cohGreen)
                                    .frame(width: g.size.width * CGFloat(step) / 3.0, height: 3)
                                    .animation(.easeInOut(duration: 0.3), value: step)
                            }
                        }
                        .frame(height: 3)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }

                    ZStack {
                        switch step {
                        case 0: typeStep
                        case 1: nameStep
                        case 2: valueStep
                        default: ownershipStep
                        }
                    }
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.28), value: step)
                }
            }
            .navigationTitle(existingAsset == nil ? s.addAssetNavTitle : s.completeSetup)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let a = existingAsset {
                    selectedType = a.type
                    label = a.label
                    address = a.address
                    shareA = a.ownershipShareA
                    step = 1   // skip type step — type already known
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step == 0 {
                        Button(s.cancel) { dismiss() }
                    } else {
                        Button { withAnimation(.easeInOut(duration: 0.28)) { step -= 1 } } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.cohInk)
                        }
                    }
                }
            }
        }
    }

    // MARK: Step 0 — Type

    private var typeStep: some View {
        VStack(spacing: 0) {
            wizardHeader(s.stepWhatType)
            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                    spacing: 12
                ) {
                    ForEach(AssetType.allCases, id: \.self) { type in
                        Button {
                            selectedType = type
                            label = ""; address = ""
                            withAnimation(.easeInOut(duration: 0.28)) { step = 1 }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(type == selectedType
                                              ? type.color
                                              : Color.cohCard)
                                        .frame(height: 60)
                                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                                    Image(systemName: type.icon)
                                        .font(.title2.weight(.medium))
                                        .foregroundStyle(type == selectedType ? .white : type.color)
                                }
                                Text(type.displayName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(type == selectedType ? type.color : Color.cohInk)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: Step 1 — Name

    private var nameStep: some View {
        VStack(spacing: 0) {
            wizardHeader(s.stepNameIt, subtitle: s.stepNameSub)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    wizardField(label: s.fieldName,
                                placeholder: selectedType.displayName,
                                text: $label, keyboard: .default)
                    wizardField(label: selectedType.secondaryLabel + " (\(s.optional))",
                                placeholder: selectedType.secondaryPlaceholder,
                                text: $address, keyboard: .default)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            wizardCTA(s.onboardingContinue,
                      enabled: !label.trimmingCharacters(in: .whitespaces).isEmpty) {
                withAnimation(.easeInOut(duration: 0.28)) { step = 2 }
            }
        }
    }

    // MARK: Step 2 — Value

    private var valueStep: some View {
        VStack(spacing: 0) {
            wizardHeader(s.stepWhatWorth)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    wizardField(label: selectedType.valueLabel,
                                placeholder: selectedType.valuePlaceholder,
                                prefix: sym, text: $valueText, keyboard: .decimalPad)
                    if selectedType.showLoan {
                        wizardField(label: selectedType.loanLabel + " (\(s.optional))",
                                    placeholder: "0",
                                    prefix: sym, text: $loanText, keyboard: .decimalPad)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            wizardCTA(s.onboardingContinue, enabled: true) {
                withAnimation(.easeInOut(duration: 0.28)) { step = 3 }
            }
        }
    }

    // MARK: Step 3 — Ownership

    private var ownershipStep: some View {
        VStack(spacing: 0) {
            wizardHeader(s.stepWhoOwns, subtitle: selectedType.ownershipHint)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Partner percentages
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(household.partnerAName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.cohGreen)
                            Text("\(Int((shareA * 100).rounded()))%")
                                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(Color.cohInk)
                                .contentTransition(.numericText())
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(household.partnerBName.isEmpty ? "Partner" : household.partnerBName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(bluePartner)
                            Text("\(Int(((1 - shareA) * 100).rounded()))%")
                                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(Color.cohInk)
                                .contentTransition(.numericText())
                        }
                    }

                    Slider(value: $shareA, in: 0...1, step: 0.01)
                        .tint(Color.cohGreen)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            wizardCTA(s.add, enabled: true) { save() }
        }
    }

    // MARK: Shared helpers

    private func wizardHeader(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(Color.cohInk)
            if let sub = subtitle {
                Text(sub)
                    .font(.subheadline)
                    .foregroundStyle(Color.cohMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }

    private func wizardField(label: String, placeholder: String,
                             prefix: String? = nil,
                             text: Binding<String>,
                             keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption.bold()).tracking(0.5)
                .foregroundStyle(Color(.secondaryLabel))
            HStack {
                if let p = prefix {
                    Text(p).foregroundStyle(Color.cohMuted).font(.body)
                }
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
                    .font(.body)
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 1))
        }
    }

    private func wizardCTA(_ label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(
                    enabled ? Color.cohGreen : Color.cohGreen.opacity(0.35),
                    in: RoundedRectangle(cornerRadius: 14)
                )
        }
        .disabled(!enabled)
        .padding(.horizontal, 24)
        .padding(.top, 8).padding(.bottom, 48)
        .background(Color.cohBg)
    }

    private func save() {
        let value = Double(valueText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let loan  = selectedType.showLoan
            ? (Double(loanText.replacingOccurrences(of: ",", with: ".")) ?? 0)
            : 0

        if let existing = existingAsset {
            // Update blank asset in-place
            existing.assetType      = selectedType.rawValue
            existing.label          = label.trimmingCharacters(in: .whitespaces)
            existing.address        = address.trimmingCharacters(in: .whitespaces)
            existing.currentValue   = value
            existing.remainingLoan  = loan
            existing.salesCostFraction = selectedType.defaultSalesCostFraction
            existing.ownershipShareA   = shareA
        } else {
            let asset = Asset(
                assetType: selectedType.rawValue,
                label: label.trimmingCharacters(in: .whitespaces),
                address: address.trimmingCharacters(in: .whitespaces),
                currentValue: value,
                remainingLoan: loan,
                salesCostFraction: selectedType.defaultSalesCostFraction,
                ownershipShareA: shareA
            )
            household.assets.append(asset)
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

    @State private var selectedType: AssetType = .home
    @State private var label = ""
    @State private var address = ""
    @State private var valueText = ""
    @State private var loanText = ""
    @State private var shareAText = "50"
    @State private var showAddContribution = false
    @State private var showDeleteConfirm = false

    private var canSave: Bool { !label.trimmingCharacters(in: .whitespaces).isEmpty }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    typePicker
                    detailsSection
                    valueSection
                    ownershipSection
                    contributionsSection
                    deleteSection
                }
                .padding(20)
                .padding(.bottom, 8)
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle(label.isEmpty ? "Edit asset" : label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.bold().disabled(!canSave)
                }
            }
        }
        .onAppear { populate() }
        .sheet(isPresented: $showAddContribution) {
            AddContributionView(asset: asset, household: household)
        }
        .confirmationDialog(
            "Delete \"\(asset.label)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete asset", role: .destructive) { deleteAsset() }
        } message: {
            Text("All contributions linked to this asset will also be deleted.")
        }
    }

    // MARK: Type picker

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TYPE").font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AssetType.allCases, id: \.self) { type in
                    let selected = selectedType == type
                    Button { selectedType = type } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(selected ? type.color : type.color.opacity(0.1))
                                    .frame(height: 56)
                                Image(systemName: type.icon)
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(selected ? .white : type.color)
                            }
                            Text(type.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selected ? type.color : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(selected ? type.color : .clear, lineWidth: 2)
                            .padding(.bottom, 22)
                    )
                }
            }
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: Form sections

    private var detailsSection: some View {
        formCard("DETAILS") {
            formField(icon: "tag.fill", label: "Name",
                      placeholder: selectedType.displayName, text: $label, keyboard: .default)
            formField(icon: "mappin.circle.fill",
                      label: selectedType.secondaryLabel + " (optional)",
                      placeholder: selectedType.secondaryPlaceholder,
                      text: $address, keyboard: .default)
        }
    }

    private var valueSection: some View {
        let cfg = selectedType
        return formCard(cfg.showLoan ? "VALUE & LOAN" : "VALUE") {
            formField(icon: "arrow.up.right.circle.fill", label: cfg.valueLabel,
                      placeholder: cfg.valuePlaceholder, prefix: household.currencySymbol,
                      text: $valueText, keyboard: .decimalPad)
            if cfg.showLoan {
                formField(icon: "arrow.down.right.circle.fill", label: cfg.loanLabel,
                          placeholder: "0", prefix: household.currencySymbol,
                          text: $loanText, keyboard: .decimalPad)
            }
        }
    }

    private var ownershipSection: some View {
        formCard("OWNERSHIP") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(household.partnerAName)'s \(selectedType.ownershipLabel)")
                        .font(.subheadline).foregroundStyle(.primary)
                    Spacer()
                    HStack(spacing: 2) {
                        TextField("50", text: $shareAText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 44)
                            .font(.subheadline.bold().monospacedDigit())
                        Text("%").foregroundStyle(.secondary).font(.subheadline)
                    }
                }
                Text(selectedType.ownershipHint)
                    .font(.caption).foregroundStyle(Color(.tertiaryLabel))
            }
        }
    }

    // MARK: Contributions

    private var contributionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("EQUITY CONTRIBUTIONS")
                        .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
                    Text(selectedType.contributionSubtitle)
                        .font(.caption).foregroundStyle(Color(.tertiaryLabel))
                }
                Spacer()
                Button { showAddContribution = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.cohGreen)
                }
            }

            if asset.contributions.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "tray")
                        .foregroundStyle(Color(.tertiaryLabel))
                    Text("No contributions yet")
                        .font(.subheadline).foregroundStyle(Color(.tertiaryLabel))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
            } else {
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
            }
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var deleteSection: some View {
        Button { showDeleteConfirm = true } label: {
            Label("Delete asset", systemImage: "trash")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: Helpers

    private func formCard<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
            content()
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func formField(
        icon: String, label: String, placeholder: String,
        prefix: String? = nil, text: Binding<String>, keyboard: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption).foregroundStyle(Color.cohGreen)
                Text(label).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            }
            HStack {
                if let p = prefix { Text(p).foregroundStyle(.secondary).font(.subheadline) }
                TextField(placeholder, text: text)
                    .keyboardType(keyboard).font(.subheadline)
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func populate() {
        selectedType = AssetType(rawValue: asset.assetType) ?? .other
        label      = asset.label
        address    = asset.address
        valueText  = asset.currentValue > 0  ? String(Int(asset.currentValue))  : ""
        loanText   = asset.remainingLoan > 0 ? String(Int(asset.remainingLoan)) : ""
        shareAText = String(Int(asset.ownershipShareA * 100))
    }

    private func save() {
        asset.assetType       = selectedType.rawValue
        asset.label           = label.trimmingCharacters(in: .whitespaces)
        asset.address         = address.trimmingCharacters(in: .whitespaces)
        asset.currentValue    = Double(valueText.replacingOccurrences(of: ",", with: "")) ?? asset.currentValue
        asset.remainingLoan   = selectedType.showLoan
            ? (Double(loanText.replacingOccurrences(of: ",", with: "")) ?? 0)
            : 0
        asset.salesCostFraction = selectedType.defaultSalesCostFraction
        asset.ownershipShareA   = min(1, max(0, (Double(shareAText) ?? 50) / 100))
        dismiss()
    }

    private func deleteAsset() {
        modelContext.delete(asset)
        dismiss()
    }
}

// MARK: - Contribution row

struct ContributionRow: View {
    let c: ContributionRecord
    let household: Household
    let onDelete: () -> Void

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
                        : Color(red: 0.20, green: 0.49, blue: 0.96))
            }
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(.quaternaryLabel))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
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

    @State private var ownerKey   = "A"
    @State private var amountText = ""
    @State private var date       = Date()
    @State private var label      = ""
    @State private var category   = "deposit"

    private let categories: [(String, String)] = [
        ("deposit",         "Deposit"),
        ("extra_repayment", "Extra loan repayment"),
        ("renovation",      "Renovation / improvement"),
        ("inheritance",     "Inheritance or gift"),
        ("other",           "Other"),
    ]

    private var canAdd: Bool {
        (Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Who contributed?") {
                    Picker("Partner", selection: $ownerKey) {
                        Text(household.partnerAName).tag("A")
                        Text(household.partnerBName).tag("B")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    HStack {
                        Text(household.currencySymbol).foregroundStyle(.secondary)
                        TextField("Amount", text: $amountText).keyboardType(.decimalPad)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Label (e.g. Deposit, Kitchen renovation)", text: $label)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.0) { c in Text(c.1).tag(c.0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Add contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { add() }.bold().disabled(!canAdd)
                }
            }
        }
    }

    private func add() {
        let amount = Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
        let displayLabel = label.trimmingCharacters(in: .whitespaces).isEmpty
            ? (categories.first { $0.0 == category }?.1 ?? "Contribution")
            : label.trimmingCharacters(in: .whitespaces)
        asset.contributions.append(
            ContributionRecord(ownerKey: ownerKey, amount: amount, date: date,
                               label: displayLabel, category: category)
        )
        dismiss()
    }
}
