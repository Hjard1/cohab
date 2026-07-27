import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Dashboard

struct DashboardView: View {
    @Binding var selectedTab: AppTab
    @Query private var households: [Household]
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var strings = AppStrings.shared
    @State private var showSetup = false
    @State private var showAddAsset = false
    @State private var editingAsset: Asset?
    @State private var availableRate: CentralBankRate?
    @State private var showRateSaved = false
    @State private var navigatingToAsset: Asset?
    @State private var showContribPicker = false
    @State private var showInvitePartner = false
    @State private var showSignInSheet = false
    @EnvironmentObject private var auth: AuthManager
    @Environment(HouseholdStore.self) private var store

    private var household: Household? { households.first }

    var body: some View {
        NavigationStack {
            ZStack {
                if let h = household {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // HEADER + quick actions over the photo background
                            VStack(spacing: 0) {
                                headerSection(h)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                                    .padding(.bottom, 32)

                                // Quick actions — over the photo, Revolut-style
                                quickActionsOnGreen(h)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 32)
                            }

                            // CREAM CONTENT — rounded top overlaps header
                            VStack(spacing: 0) {
                                if h.partnerLeft == true {
                                    partnerLeftBanner
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)
                                }
                                if !auth.isSignedIn {
                                    signInBanner
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)
                                }
                                if auth.isSignedIn, store.memberCount < 2, h.partnerLeft != true {
                                    invitePartnerBanner(h)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)
                                }
                                if let rate = availableRate {
                                    rateUpdateBanner(household: h, rate: rate)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)
                                }

                                assetsList(h).padding(.top, 20)
                                if !h.assets.isEmpty {
                                    // History lives under the assets list —
                                    // budget is intentionally NOT shown here.
                                    historySection(h).padding(.top, 28)
                                }
                                if h.isFormalMode {
                                    agreementStatusRow(h)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 12)
                                }
                                Spacer(minLength: 100)
                            }
                            .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height)
                            .background(Color.cohBg)
                            .clipShape(.rect(topLeadingRadius: 28, topTrailingRadius: 28))
                        }
                    }
                    // Light photo behind the header — attached as the
                    // ScrollView's background so it bleeds under the status bar
                    // WITHOUT disturbing the scroll view's safe-area insets
                    // (a ZStack sibling pushed content under the notch).
                    .background(
                        Image("overviewBg")
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(y: -1)
                            .ignoresSafeArea(.all, edges: .top)
                    )
                    .task {
                        // Only show banner if fetched rate meaningfully differs from current
                        if let fetched = await InterestRateService.fetch(currency: h.currency),
                           abs(fetched.rate - h.annualInterestRate) > 0.001 {
                            availableRate = fetched
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        if h.agreementStatus == "pending" {
                            Task { await DocuSealService.checkSigned(household: h) }
                        }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if h.partnerLeft != true {
                            HStack { Spacer(); addButton }
                                .padding(.trailing, 20)
                                .padding(.bottom, 8)
                        }
                    }

                } else {
                    Color.cohBg.ignoresSafeArea()
                    emptyState
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(Color.cohBg, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbar { toolbarContent }
            .navigationDestination(item: $navigatingToAsset) { asset in
                if let h = household {
                    AssetDetailView(asset: asset, household: h)
                }
            }
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
        .sheet(isPresented: $showContribPicker) {
            if let h = household {
                ContribAssetPickerView(household: h)
            }
        }
        .sheet(isPresented: $showSignInSheet) {
            SignInView(presentedAsSheet: true)
        }
        .sheet(isPresented: $showInvitePartner) {
            if let h = household {
                NavigationStack {
                    InvitePartnerView(household: h)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSetup = true } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(Color.cohInk.opacity(0.75))
                    .font(.body)
            }
        }
    }

    // MARK: Header section (hero over light photo background)

    private func headerSection(_ h: Household) -> some View {
        let (equityA, equityB) = totalNetEquity(h)
        let total = equityA + equityB
        let sym = h.currencySymbol

        return VStack(alignment: .leading, spacing: 20) {
            // Partner names
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color.cohGreen).frame(width: 8, height: 8)
                    Text(h.partnerAName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.cohInk)
                        .lineLimit(1)
                }
                Spacer()
                HStack(spacing: 6) {
                    Text(h.partnerBName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.cohSecondary)
                        .lineLimit(1)
                    Circle().fill(Color.cohBlue.opacity(0.6)).frame(width: 8, height: 8)
                }
            }

            // Hero equity number
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(sym)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.cohInk.opacity(0.6))
                    Text(fmtGroupedAmount(total, country: h.country))
                        .font(.system(size: 42, weight: .bold, design: .serif).monospacedDigit())
                        .foregroundStyle(Color.cohInk)
                }
                Text(strings.dashboardNetEquity.lowercased())
                    .font(.caption)
                    .foregroundStyle(Color.cohSecondary)
            }

        }
    }

    // Kept for use in other parts
    private func equityPartnerRow(name: String, amount: Double,
                                  symbol: String, country: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Circle().fill(color).frame(width: 10, height: 10)
                .padding(.leading, 20)
            Text(name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.cohInk)
                .lineLimit(1)
            Spacer()
            Text(symbol + fmtGroupedAmount(amount, country: country))
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
                Label(strings.agreementSigned, systemImage: "checkmark.seal.fill")
                    .font(.subheadline.bold()).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 12))
            case "pending":
                Label(strings.agreementSentWaiting, systemImage: "clock.fill")
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
                Text(strings.dashboardEmptyTitle)
                    .font(.title2.bold())
                Text(strings.dashboardEmptySub)
                    .font(.subheadline)
                    .foregroundStyle(Color.cohSecondary)
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
                    .foregroundStyle(Color(.tertiaryLabel))
                Text(h.currency)
                    .font(.caption.bold())
                    .foregroundStyle(Color.cohSecondary)
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
                Text(strings.dashboardAssets)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(h.assets.count) \(h.assets.count == 1 ? strings.dashboardItem : strings.dashboardItems)")
                    .font(.caption)
                    .foregroundStyle(Color.cohSecondary)
            }
            .padding(.horizontal, 24)

            if h.assets.isEmpty {
                noAssetsPrompt { showAddAsset = true }
                    .padding(.top, 16)
            } else {
                VStack(spacing: 16) {
                    ForEach(sortedAssets(h.assets)) { asset in
                        HouseholdStoryCard(asset: asset, household: h,
                                          onTap: {
                                              if asset.currentValue == 0 && asset.contributions.isEmpty {
                                                  editingAsset = asset
                                              } else {
                                                  navigatingToAsset = asset
                                              }
                                          })
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    private func sortedAssets(_ assets: [Asset]) -> [Asset] {
        let order: [AssetType] = [.home, .cabin, .car, .savings, .investment, .furniture, .pet, .other]
        return assets.sorted { (order.firstIndex(of: $0.type) ?? 99) < (order.firstIndex(of: $1.type) ?? 99) }
    }

    // MARK: History — contribution feed across all assets (shown under the assets list)

    private struct ContribRow: Identifiable {
        let asset: Asset
        let contrib: ContributionRecord
        var id: UUID { contrib.id }
    }

    private func contributionRows(_ h: Household) -> [ContribRow] {
        h.assets
            .flatMap { asset in asset.contributions.map { ContribRow(asset: asset, contrib: $0) } }
            .sorted { $0.contrib.date > $1.contrib.date }
    }

    private func historySection(_ h: Household) -> some View {
        let rows = contributionRows(h)
        return VStack(spacing: 0) {
            HStack {
                Text(strings.dashboardHistory)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(rows.count) \(rows.count == 1 ? strings.dashboardContrib : strings.dashboardContribs)")
                    .font(.caption)
                    .foregroundStyle(Color.cohSecondary)
            }
            .padding(.horizontal, 24)

            if rows.isEmpty {
                noContribsPrompt
                    .padding(.top, 16)
            } else {
                contributionSummary(h, rows: rows)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                contributionList(h, rows: rows)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
        }
    }

    private var noContribsPrompt: some View {
        VStack(spacing: 14) {
            Text(strings.assetNoContribs)
                .font(.subheadline)
                .foregroundStyle(Color.cohSecondary)
            Button { showContribPicker = true } label: {
                Label(strings.addContribTitle, systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    // Totals + A/B split bar, like the top of the contributions design
    private func contributionSummary(_ h: Household, rows: [ContribRow]) -> some View {
        let total = rows.reduce(0) { $0 + $1.contrib.amount }
        let month = rows
            .filter { Calendar.current.isDate($0.contrib.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.contrib.amount }
        let sumA = rows.filter { $0.contrib.ownerKey == "A" }.reduce(0) { $0 + $1.contrib.amount }
        let sumB = total - sumA
        let fracA = total > 0 ? sumA / total : 0.5

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.dashboardTotalContributed)
                        .font(.caption).foregroundStyle(Color.cohSecondary)
                    Text(h.moneyText(total))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(Color.cohInk)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(strings.dashboardThisMonth)
                        .font(.caption).foregroundStyle(Color.cohSecondary)
                    Text(h.moneyText(month))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(Color.cohInk)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(strings.dashboardContribSplit)
                    .font(.caption).foregroundStyle(Color.cohSecondary)
                GeometryReader { geo in
                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.cohGreen)
                            .frame(width: max(geo.size.width * fracA - 1.5, 8))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.cohBlue.opacity(0.35))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 10)
                HStack(spacing: 16) {
                    splitLegend(name: h.partnerAName, color: .cohGreen,
                                amount: h.moneyText(sumA))
                    splitLegend(name: h.partnerBName, color: .cohBlue.opacity(0.6),
                                amount: h.moneyText(sumB))
                    Spacer()
                }
            }
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func splitLegend(name: String, color: Color, amount: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(name)
                .font(.caption.weight(.medium)).foregroundStyle(Color.cohInk)
            Text(amount)
                .font(.caption.monospacedDigit()).foregroundStyle(Color.cohSecondary)
        }
    }

    private func contributionList(_ h: Household, rows: [ContribRow]) -> some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                let ownerColor: Color = row.contrib.ownerKey == "A" ? .cohGreen : .cohBlue
                HStack(spacing: 4) {
                    Button { navigatingToAsset = row.asset } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(row.asset.type.color.opacity(0.12))
                                    .frame(width: 38, height: 38)
                                Image(systemName: row.asset.type.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(row.asset.type.color)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(row.contrib.label.isEmpty ? row.contrib.category.capitalized : row.contrib.label)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.cohInk)
                                Text(row.asset.label)
                                    .font(.caption)
                                    .foregroundStyle(Color.cohSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text(h.moneyText(row.contrib.amount))
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundStyle(ownerColor)
                                Text(row.contrib.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(Color.cohSecondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(Color.cohTertiary)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    // Delete — remote first, local row removed only on success
                    // (otherwise the next sync would resurrect it).
                    Button {
                        let id = row.contrib.id
                        let householdId = h.id
                        let assetId = row.asset.id
                        let signedIn = auth.isSignedIn
                        Task { @MainActor in
                            do {
                                try await SupabaseService.deleteContribution(id)
                                modelContext.delete(row.contrib)
                                await AssetImageStore.deleteReceipt(
                                    contributionId: id, householdId: householdId,
                                    assetId: assetId, signedIn: signedIn)
                            } catch {
                                print("[Cohab] Delete contribution failed: \(error.localizedDescription)")
                            }
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color(.quaternaryLabel))
                            .padding(.leading, 4)
                    }
                    .buttonStyle(.plain)
                }

                if row.id != rows.last?.id {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func noAssetsPrompt(action: @escaping () -> Void) -> some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.cohGreen.opacity(0.08))
                    .frame(width: 90, height: 90)
                Circle()
                    .strokeBorder(Color.cohGreen.opacity(0.15), lineWidth: 1.5)
                    .frame(width: 90, height: 90)
                Image(systemName: "house.and.flag.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.cohGreen)
            }
            VStack(spacing: 8) {
                Text(strings.assetsNoAssetsTitle)
                    .font(.title3.bold())
                    .foregroundStyle(Color.cohInk)
                Text(strings.assetsNoAssetsSub)
                    .font(.subheadline)
                    .foregroundStyle(Color.cohSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button(action: action) {
                Label(strings.assetsAddFirst, systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: Floating add button

    // MARK: Quick actions on green — Revolut-style circles with white icons

    private func quickActionsOnGreen(_ h: Household) -> some View {
        let noPartner  = h.partnerBName.trimmingCharacters(in: .whitespaces).isEmpty
        let noAssets   = h.assets.isEmpty
        let noContribs = !h.assets.contains { !$0.contributions.isEmpty }
        let partnerB   = h.partnerBName.isEmpty ? "Partner" : h.partnerBName

        let chip1: (icon: String, label: String, action: () -> Void)
        if h.partnerLeft == true {
            // Read-only mode — the banner at the top explains why
            chip1 = ("person.fill.xmark", strings.partnerLeftChip, {})
        } else if noPartner {
            // No partner name set yet → open settings to add
            chip1 = ("person.badge.plus", strings.inviteTitle, { showSetup = true })
        } else if noAssets {
            // Partner name set but no assets → invite right away (most useful next step)
            chip1 = ("envelope.badge.fill", strings.inviteGenerate, { showInvitePartner = true })
        } else if noContribs {
            chip1 = ("arrow.up.circle.fill", strings.addContribTitle, { showContribPicker = true })
        } else {
            chip1 = ("envelope.badge.fill", strings.inviteGenerate, { showInvitePartner = true })
        }

        let agreementIcon: String
        let agreementLabel: String
        let agreementAction: () -> Void
        switch h.agreementStatus {
        case "pending":
            agreementIcon = "clock.fill"
            agreementLabel = strings.agreementPending
            agreementAction = { selectedTab = .agreement }
        case "signed" where !h.agreementNeedsUpdate:
            agreementIcon = "checkmark.seal.fill"
            agreementLabel = strings.agreementSigned
            agreementAction = { selectedTab = .agreement }
        default:
            agreementIcon = "doc.text.fill"
            agreementLabel = h.isFormalMode ? strings.agreementGenerate : strings.onboardingYesAgreement
            agreementAction = { selectedTab = .agreement }
        }

        return HStack(spacing: 0) {
            greenChip(icon: chip1.icon, label: chip1.label, action: chip1.action)
                .disabled(h.partnerLeft == true)   // read-only chip, no action
            greenNavChip(icon: "dollarsign.circle.fill", label: strings.calcExpenseTitle,
                         destination: ExpenseSplitView(nameA: h.partnerAName, nameB: partnerB,
                                                       symbol: h.currencySymbol))
            greenChip(icon: agreementIcon, label: agreementLabel, action: agreementAction)
            greenNavChip(icon: "scale.3d", label: strings.dashboardShowCalculation,
                         destination: SettlementTabView())
        }
    }

    private func greenChip(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { greenChipContent(icon: icon, label: label) }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func greenNavChip<D: View>(icon: String, label: String, destination: D) -> some View {
        NavigationLink(destination: destination) { greenChipContent(icon: icon, label: label) }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
    }

    private func greenChipContent(icon: String, label: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.cohGreen)
            }
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.cohInk)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 70)
        }
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
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
                     { showContribPicker = true })
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
            agreementAction = { selectedTab = .agreement }
        case "signed" where !h.agreementNeedsUpdate:
            agreementIcon   = "checkmark.seal.fill"
            agreementLabel  = strings.agreementSigned
            agreementAction = { selectedTab = .agreement }
        default:
            agreementIcon   = "doc.text.fill"
            agreementLabel  = h.isFormalMode ? strings.agreementGenerate : strings.onboardingYesAgreement
            agreementAction = { selectedTab = .agreement }
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

    // Deep forest green — same hue as brand, but dark enough to read
    // clearly on cream. Distinct from partner-A green (#1a9960).
    private static let fabColor = Color(red: 0.06, green: 0.32, blue: 0.20)

    private var addButton: some View {
        Button { showAddAsset = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Self.fabColor, in: Circle())
                .shadow(color: Self.fabColor.opacity(0.45), radius: 16, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Household story card (dashboard)

struct HouseholdStoryCard: View {
    let asset: Asset
    let household: Household
    let onTap: () -> Void
    @ObservedObject private var strings = AppStrings.shared

    private var ownershipLine: String {
        guard asset.currentValue > 0 else { return strings.assetTapToSetUp }
        let shareA = asset.ownershipShareA
        let nameA = household.partnerAName
        let nameB = household.partnerBName
        if shareA >= 0.99 { return "\(nameA)'s" }
        if shareA <= 0.01 { return "\(nameB)'s" }
        let pA = Int((shareA * 100).rounded())
        let pB = 100 - pA
        if abs(pA - 50) <= 2 { return strings.assetSharedEqually }
        return "\(strings.assetSharedFormat) \(pA)/\(pB)"
    }

    private var ownershipColor: Color {
        guard asset.currentValue > 0 else { return Color.cohGreen }
        let shareA = asset.ownershipShareA
        if shareA >= 0.99 { return Color.cohGreen }
        if shareA <= 0.01 { return Color(red: 0.20, green: 0.49, blue: 0.96) }
        return Color(.secondaryLabel)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(asset.type.color.opacity(0.10))
                        .frame(width: 56, height: 56)
                    Image(systemName: asset.type.icon)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(asset.type.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.label)
                        .font(.headline)
                        .foregroundStyle(Color.cohInk)
                    if !asset.address.isEmpty {
                        Text(asset.address)
                            .font(.caption)
                            .foregroundStyle(Color.cohSecondary)
                            .lineLimit(1)
                    }
                    Text(ownershipLine)
                        .font(.subheadline)
                        .foregroundStyle(ownershipColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(18)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
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
        Button(action: onEdit) {
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
        .buttonStyle(.plain)
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
                    Text(asset.address).font(.caption).foregroundStyle(Color.cohSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(household.moneyText(asset.currentValue))
                    .font(.subheadline.bold().monospacedDigit())
                if asset.remainingLoan > 0 {
                    Text(strings.dashboardLoan + ": −" + fmt(asset.remainingLoan))
                        .font(.caption2.monospacedDigit()).foregroundStyle(.orange)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
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
                    .font(.caption).foregroundStyle(Color.cohMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func equityColumn(_ name: String, equity: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.caption.weight(.medium)).foregroundStyle(color)
            Text(household.moneyText(equity))
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
                        .font(.caption.weight(.medium)).foregroundStyle(Color.cohSecondary)
                    if !showBreakdown {
                        Text(strings.dashboardSaleCostsSub)
                            .font(.caption).foregroundStyle(Color.cohMuted)
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
            sectionLabel(strings.assetNetProceedsSection)
            calcRow(strings.calcCurrentValue, fmt(asset.currentValue))
            if asset.remainingLoan > 0 {
                calcRow(strings.calcRemainingLoan, "−" + fmt(asset.remainingLoan), dim: true)
            }
            if asset.estimatedSalesCost > 0 {
                let pct = Int(asset.salesCostFraction * 100)
                calcRow("\(strings.calcSaleCosts) (\(pct)%)", "−" + fmt(asset.estimatedSalesCost), dim: true)
            }
            Divider()
            calcRow(strings.calcNetProceeds, fmt(result.netProceeds), bold: true)
        }
    }

    // ── Per-partner contributions ────────────────────────────────────────

    private func contributionSection(partner: Partner, name: String, color: Color) -> some View {
        let rows = contribRows(partner: partner)
        let total = result.accrued[partner] ?? 0
        guard !rows.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(VStack(alignment: .leading, spacing: 6) {
            sectionLabel(String(format: strings.contribSectionTitle, name.uppercased()))
            ForEach(rows, id: \.id) { row in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.label).font(.caption).foregroundStyle(.primary)
                        Text(row.dateStr).font(.caption).foregroundStyle(Color.cohSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(household.moneyText(row.withInterest))
                            .font(.caption.monospacedDigit().weight(.medium))
                            .foregroundStyle(color)
                        if row.interest > 1 {
                            Text("+" + household.moneyText(row.interest) + " \(strings.interestWord)")
                                .font(.caption.monospacedDigit()).foregroundStyle(Color.cohSecondary)
                        }
                    }
                }
            }
            if rows.count > 1 { Divider() }
            if rows.count > 1 { calcRow(strings.calcTotalReturned, fmt(total), bold: true, tint: color) }
        })
    }

    // ── Surplus / shortfall ──────────────────────────────────────────────

    private var surplusSection: some View {
        let totalAccrued = (result.accrued[.a] ?? 0) + (result.accrued[.b] ?? 0)
        return VStack(alignment: .leading, spacing: 6) {
            if result.shortfall {
                sectionLabel(strings.shortfallSection)
                Text(String(format: strings.shortfallExplanation,
                            household.moneyText(result.netProceeds),
                            household.moneyText(totalAccrued)))
                    .font(.caption).foregroundStyle(Color.cohSecondary)
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
                Text("  \(strings.assetContribInterestLine) \(household.moneyText(accruedA))")
                    .font(.caption).foregroundStyle(Color.cohMuted)
            }
            calcRow(household.partnerBName, fmt(result.payout[.b] ?? 0), bold: true,
                    tint: Color(red: 0.20, green: 0.49, blue: 0.96))
            if hasContribs && accruedB > 0 {
                Text("  \(strings.assetContribInterestLine) \(household.moneyText(accruedB))")
                    .font(.caption).foregroundStyle(Color.cohMuted)
            }
            Text("\(strings.assetRateLine) \(String(format: "%.1f%%", household.annualInterestRate * 100)) p.a. · \(strings.assetPerAgreement)")
                .font(.caption).foregroundStyle(Color.cohMuted).padding(.top, 2)
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
        Text(text).font(.caption2.bold()).tracking(0.8).foregroundStyle(Color.cohMuted)
    }

    private func calcRow(_ label: String, _ value: String, bold: Bool = false,
                          dim: Bool = false, tint: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(bold ? .caption.weight(.semibold) : .caption)
                .foregroundStyle(dim ? Color.cohMuted : Color.cohSecondary)
            Spacer()
            Text(household.currencySymbol + value)
                .font(bold ? .caption.bold().monospacedDigit() : .caption.monospacedDigit())
                .foregroundStyle(tint ?? (bold ? Color(.label) : Color.cohSecondary))
        }
    }

    private func fmt(_ v: Double) -> String {
        fmtGroupedAmount(v, country: household.country)
    }
}

// MARK: - Rate update banner

extension DashboardView {
    /// Shown while the user has no Supabase session. Signing in claims the local
    /// household to the cloud (see HouseholdStore.claimLocalHouseholdIfNeeded) and
    /// enables partner sync, shared expenses and the agreement flow.
    var signInBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.subheadline)
                .foregroundStyle(Color.cohGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text(strings.localized(
                    en: "Sign in to sync",
                    nb: "Logg inn for å synkronisere",
                    sv: "Logga in för att synkronisera",
                    da: "Log ind for at synkronisere",
                    fi: "Kirjaudu sisään synkronoidaksesi",
                    de: "Zum Synchronisieren anmelden",
                    fr: "Connectez-vous pour synchroniser",
                    es: "Inicia sesión para sincronizar"))
                    .font(.caption.weight(.semibold))
                Text(strings.localized(
                    en: "Back up your data and share everything with your partner.",
                    nb: "Sikre dataene dine og del alt med partneren din.",
                    sv: "Säkra dina data och dela allt med din partner.",
                    da: "Sikr dine data, og del alt med din partner.",
                    fi: "Varmuuskopioi tietosi ja jaa kaikki kumppanisi kanssa.",
                    de: "Sichern Sie Ihre Daten und teilen Sie alles mit Ihrem Partner.",
                    fr: "Sauvegardez vos données et partagez tout avec votre partenaire.",
                    es: "Protege tus datos y comparte todo con tu pareja."))
                    .font(.caption).foregroundStyle(Color.cohSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {
                showSignInSheet = true
            } label: {
                Text(strings.localized(
                    en: "Sign in",
                    nb: "Logg inn",
                    sv: "Logga in",
                    da: "Log ind",
                    fi: "Kirjaudu",
                    de: "Anmelden",
                    fr: "Connexion",
                    es: "Entrar"))
                    .font(.caption.weight(.semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.cohGreen, in: Capsule())
            }
        }
        .padding(14)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    /// Persistent invite entry point — shown until the partner has joined
    /// (household has fewer than 2 members).
    func invitePartnerBanner(_ h: Household) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.badge.fill")
                .font(.subheadline)
                .foregroundStyle(Color.cohGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text(h.partnerBName.isEmpty
                     ? strings.inviteTitle
                     : "\(strings.inviteTitle) \(h.partnerBName)")
                    .font(.caption.weight(.semibold))
                Text(strings.localized(
                    en: "Share a link so you both see the same numbers.",
                    nb: "Del en lenke, så ser dere de samme tallene.",
                    sv: "Dela en länk så ser ni samma siffror.",
                    da: "Del et link, så I ser de samme tal.",
                    fi: "Jaa linkki, jotta näette samat luvut.",
                    de: "Teilen Sie einen Link, damit beide dieselben Zahlen sehen.",
                    fr: "Partagez un lien pour voir les mêmes chiffres.",
                    es: "Comparte un enlace para ver los mismos números."))
                    .font(.caption).foregroundStyle(Color.cohSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {
                showInvitePartner = true
            } label: {
                Text(strings.inviteTitle)
                    .font(.caption.weight(.semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.cohGreen, in: Capsule())
            }
        }
        .padding(14)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    /// Shown when the other partner deleted their account: the data stays
    /// readable, but every "add new" path is disabled.
    private var partnerLeftBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill.xmark")
                .font(.subheadline)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(strings.partnerLeftTitle)
                    .font(.caption.weight(.semibold))
                Text(strings.partnerLeftSub)
                    .font(.caption).foregroundStyle(Color.cohSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }

    func rateUpdateBanner(household: Household, rate: CentralBankRate) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(.subheadline)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(strings.dashboardRateUpdated(rate.source))
                    .font(.caption.weight(.semibold))
                Text(String(format: "%.2f%%", rate.rate * 100) + " " + strings.dashboardRateCurrently(String(format: "%.2f%%", household.annualInterestRate * 100)))
                    .font(.caption).foregroundStyle(Color.cohSecondary)
            }
            Spacer()
            if showRateSaved {
                Label(strings.saved, systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(Color.cohGreen)
            } else {
                Button(strings.update) {
                    household.annualInterestRate = rate.rate
                    let householdId = store.household?.id ?? household.id
                    let nameA = household.partnerAName, nameB = household.partnerBName
                    let cur = household.currency
                    Task {
                        try? await SupabaseService.updateHousehold(
                            householdId: householdId, partnerALabel: nameA,
                            partnerBLabel: nameB, currency: cur,
                            annualInterestRate: rate.rate)
                    }
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
                    .font(.caption2).foregroundStyle(Color.cohSecondary)
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
                    Text(strings.agreementCardTitle)
                        .font(.headline)
                }
                Spacer()
                statusBadge(h.agreementStatus, needsUpdate: h.agreementNeedsUpdate)
            }

            Color(.separator).frame(height: 0.5)

            // ── Scope description ─────────────────────────────────────
            Text(h.includeDissolutionClause
                 ? strings.agreementCoversFull
                 : strings.agreementCoversBasic)
                .font(.subheadline)
                .foregroundStyle(Color.cohSecondary)

            // ── Update notice ─────────────────────────────────────────
            if h.agreementNeedsUpdate && h.agreementStatus != "none" {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                    Text(h.changesSinceSigning + strings.agreementSinceLastSuffix)
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
                Label(strings.agreementSigned, systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.cohGreen)
            }

            // ── Action button ─────────────────────────────────────────
            if h.agreementStatus != "signed" || h.agreementNeedsUpdate {
                let buttonLabel = buttonText(for: h)
                Button {
                    selectedTab = .agreement
                } label: {
                    HStack(spacing: 8) {
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
            }
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
    }

    private func buttonText(for h: Household) -> String {
        if h.agreementNeedsUpdate    { return strings.agreementUpdateResend }
        if h.agreementStatus == "pending" { return strings.agreementViewSigningLinks }
        return strings.agreementGenerateSign
    }

    private func statusBadge(_ status: String, needsUpdate: Bool) -> some View {
        let (label, color): (String, Color) = {
            if needsUpdate && status != "none" { return (strings.agreementUpdateNeeded, .orange) }
            switch status {
            case "pending": return (strings.agreementPendingSignatures, .orange)
            case "signed":  return (strings.agreementSignedShort, .cohGreen)
            default:        return (strings.agreementNotSigned, Color(.systemGray))
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

/// How the agreement is sent for signing: DocuSeal e-signature (free,
/// 10/month) or BankID via DealBuilder (1 included, then a paid credit).
private enum SigningMethod {
    case docuseal, bankid
}

struct AgreementSheetView: View {
    let household: Household
    @Binding var submission: DocuSealSubmission?
    @Binding var isGenerating: Bool
    @Binding var error: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var pm: PurchaseManager
    @ObservedObject private var strings = AppStrings.shared
    @State private var hasStarted = false
    @State private var isSigned = false
    @State private var reviewMode = false
    @State private var draftEmailA = ""
    @State private var draftEmailB = ""
    @State private var signingMethod: SigningMethod = .docuseal
    @State private var bankIDCase: DealBuilderCase?
    @State private var showBankIDLimit = false
    @State private var isPurchasingExtra = false

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
                } else if let dbCase = bankIDCase {
                    bankIDWaitingView(dbCase)
                } else if reviewMode {
                    reviewSendView
                } else {
                    EmptyView()
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.done) { dismiss() }
                }
            }
        }
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true

            // Recovery: rebuild the in-memory submission from the URL we stored at creation time.
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

            // BankID recovery: a pending BankID case lives server-side only —
            // look it up and restore the waiting view.
            if submission == nil, household.agreementStatus == "pending",
               household.docusealViewUrl.isEmpty {
                Task {
                    if let dbCase = await DealBuilderService.currentCase(household: household) {
                        bankIDCase = dbCase
                        let signed = await DealBuilderService.checkSigned(household: household)
                        if signed { withAnimation { isSigned = true } }
                    } else {
                        draftEmailA = household.emailA
                        draftEmailB = household.emailB
                        reviewMode = true
                    }
                }
                return
            }

            // New submission: show the review-and-send screen. Nothing is generated
            // or emailed until the user explicitly taps "Send for signing".
            if submission == nil {
                draftEmailA = household.emailA
                draftEmailB = household.emailB
                reviewMode = true
            }
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
        // Same polling for a pending BankID case
        .task(id: bankIDCase?.documentId) {
            guard let docId = bankIDCase?.documentId, !docId.isEmpty else { return }
            do {
                while !isSigned {
                    try await Task.sleep(for: .seconds(6))
                    let signed = await DealBuilderService.checkSigned(household: household)
                    if signed {
                        withAnimation { isSigned = true }
                        return
                    }
                }
            } catch {
                // Task cancelled — sheet was dismissed, nothing to do
            }
        }
        .alert(strings.bankIDLimitTitle, isPresented: $showBankIDLimit) {
            Button(strings.bankIDBuyExtra(pm.bankIDPriceDisplay)) {
                buyExtraAndRetry()
            }
            Button(strings.cancel, role: .cancel) { }
        } message: {
            Text(strings.bankIDLimitBody(pm.bankIDPriceDisplay))
        }
    }

    private var navTitle: String {
        if isSigned { return strings.agreementSignedTitle }
        if (submission != nil || bankIDCase != nil) && !isGenerating { return strings.agreementSignTitle }
        return strings.agreementReviewSendTitle
    }

    // MARK: Review & send — confirm recipients + document BEFORE anything is sent

    private var partnerBDisplay: String {
        household.partnerBName.isEmpty ? "Partner" : household.partnerBName
    }

    private var canSend: Bool {
        DocuSealService.isValidEmail(draftEmailA) && DocuSealService.isValidEmail(draftEmailB)
    }

    private var reviewSendView: some View {
        let clauseCount = [household.includeDissolutionClause,
                           household.includeSeparatePropertyClause,
                           household.includeBuyoutRightsClause,
                           household.includeDisposalConsentClause,
                           household.includeDisputeResolutionClause,
                           household.includeDebtClause].filter { $0 }.count

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.agreementReviewSendHeading)
                        .font(.title3.bold()).foregroundStyle(Color.cohInk)
                    Text(strings.agreementReviewSendSub)
                        .font(.subheadline).foregroundStyle(Color.cohMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Document summary
                VStack(alignment: .leading, spacing: 10) {
                    Text(strings.agreementDocumentTitle)
                        .font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
                    summaryLine(icon: "house.fill",
                                text: "\(household.assets.count) \(household.assets.count == 1 ? strings.agreementSharedAsset : strings.agreementSharedAssets)")
                    summaryLine(icon: "list.bullet.rectangle",
                                text: "\(clauseCount) \(strings.agreementClausesSelected)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))

                // Recipients
                VStack(alignment: .leading, spacing: 14) {
                    Text(strings.agreementRecipientsTitle)
                        .font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
                    emailField(label: "\(household.partnerAName)\(strings.agreementPartnerEmailSuffix)",
                               text: $draftEmailA)
                    emailField(label: "\(partnerBDisplay)\(strings.agreementPartnerEmailSuffix)",
                               text: $draftEmailB)
                }

                // Signing method — BankID only in supported countries
                if DealBuilderService.isSupported(country: household.country) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(strings.signingMethodTitle)
                            .font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
                        methodCard(title: strings.signingMethodDocuSeal,
                                   info: strings.signingMethodDocuSealInfo,
                                   icon: "signature",
                                   method: .docuseal)
                        methodCard(title: strings.signingMethodBankID,
                                   info: strings.signingMethodBankIDInfo(pm.bankIDPriceDisplay),
                                   icon: "person.badge.key.fill",
                                   method: .bankid)
                    }
                }

                // Explicit send explainer + button
                Text(strings.agreementSendExplainer(partnerBDisplay))
                    .font(.subheadline).foregroundStyle(Color.cohSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    household.emailA = draftEmailA.trimmingCharacters(in: .whitespaces)
                    household.emailB = draftEmailB.trimmingCharacters(in: .whitespaces)
                    reviewMode = false
                    generate()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text(strings.agreementSendForSigning)
                    }
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(canSend ? Color.cohGreen : Color.cohGreen.opacity(0.35),
                                in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canSend)
            }
            .padding(24)
        }
    }

    private func summaryLine(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.caption).foregroundStyle(Color.cohGreen).frame(width: 20)
            Text(text).font(.subheadline).foregroundStyle(Color.cohInk)
        }
    }

    private func emailField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption.bold()).tracking(0.5)
                .foregroundStyle(Color.cohSecondary)
            TextField("email@example.com", text: text)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .font(.body)
                .padding(.horizontal, 14).padding(.vertical, 13)
                .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 1))
        }
    }

    // MARK: Signing method choice

    private func methodCard(title: String, info: String, icon: String, method: SigningMethod) -> some View {
        let selected = signingMethod == method
        return Button {
            signingMethod = method
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title3)
                    .foregroundStyle(selected ? Color.cohGreen : Color.cohSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.bold()).foregroundStyle(Color.cohInk)
                    Text(info).font(.subheadline).foregroundStyle(Color.cohSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.cohGreen : Color.cohMuted)
            }
            .padding(14)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(selected ? Color.cohGreen : Color(.separator).opacity(0.4),
                              lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: BankID waiting — both partners sign from their email

    private func bankIDWaitingView(_ dbCase: DealBuilderCase) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Color.cohGreen.opacity(0.1)).frame(width: 90, height: 90)
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 40)).foregroundStyle(Color.cohGreen)
            }
            VStack(spacing: 8) {
                Text(strings.bankIDCheckEmailTitle)
                    .font(.title2.bold())
                Text(strings.bankIDCheckEmailBody(partnerBDisplay))
                    .font(.subheadline).foregroundStyle(Color.cohSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            // Personal signing link (login-free). appUrl is only a fallback
            // for cases created before personal links were stored.
            let myLink = dbCase.signingUrlA?.isEmpty == false ? dbCase.signingUrlA! : dbCase.appUrl
            if !myLink.isEmpty, let url = URL(string: myLink) {
                Button {
                    openURL(url)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                        Text(strings.bankIDOpenSigningLink)
                    }
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
            }
            // Partner B's personal link — share it if the DealBuilder email
            // didn't reach them (spam folder, wrong address, …).
            if let bLink = dbCase.signingUrlB, !bLink.isEmpty, let url = URL(string: bLink) {
                ShareLink(item: url) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text(strings.bankIDSharePartnerLink)
                    }
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohGreen)
                }
            }
            HStack(spacing: 8) {
                ProgressView()
                Text(strings.bankIDWaitingForBoth)
                    .font(.subheadline).foregroundStyle(Color.cohSecondary)
            }
            Button(strings.bankIDCheckStatus) {
                Task {
                    let signed = await DealBuilderService.checkSigned(household: household)
                    if signed { withAnimation { isSigned = true } }
                }
            }
            .font(.subheadline).foregroundStyle(Color.cohGreen)
            Spacer()
        }
    }

    // MARK: Extra BankID signing purchase

    private func buyExtraAndRetry() {
        guard !isPurchasingExtra else { return }
        isPurchasingExtra = true
        Task {
            defer { isPurchasingExtra = false }
            do {
                if let jws = try await pm.purchaseBankIDExtra() {
                    do {
                        try await DealBuilderService.addExtraCredit(jws: jws)
                        reviewMode = false
                        generate()
                    } catch {
                        // The purchase went through, but the credit could not
                        // be activated. Logged (NSLog + server-side) so
                        // support can follow up and grant it manually.
                        self.error = strings.bankIDCreditActivationFailed
                    }
                }
                // Not purchased → user cancelled; stay on the review screen.
            } catch {
                self.error = strings.bankIDPurchaseFailed
            }
        }
    }

    private var signedConfirmation: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(Color.cohGreen.opacity(0.1)).frame(width: 90, height: 90)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44)).foregroundStyle(Color.cohGreen)
            }
            VStack(spacing: 8) {
                Text(strings.agreementSignedTitle)
                    .font(.title2.bold())
                Text(strings.agreementSignedBody(household.partnerAName, partnerBDisplay))
                    .font(.subheadline).foregroundStyle(Color.cohSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            Button(strings.done) { dismiss() }
                .buttonStyle(.borderedProminent).tint(Color.cohGreen)
        }
    }

    // MARK: Loading

    private var generatingView: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.3)
            Text(strings.agreementPreparingTitle)
                .font(.subheadline).foregroundStyle(Color.cohSecondary)
            Text(strings.agreementPreparingSub)
                .font(.subheadline).foregroundStyle(Color.cohMuted)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
    }

    // MARK: Error

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill").font(.system(size: 44)).foregroundStyle(.red)
            Text(strings.agreementSomethingWrong).font(.headline)
            Text(msg).font(.subheadline).foregroundStyle(Color.cohSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Button(strings.agreementTryAgain) { error = nil; reviewMode = true }
                .buttonStyle(.borderedProminent).tint(.cohGreen)
        }
    }

    // MARK: Signing form (in-app WKWebView)

    private func signingView(_ sub: DocuSealSubmission) -> some View {
        VStack(spacing: 0) {
            // Prominent: this signs for the current user; the partner signs by email.
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill").font(.subheadline).foregroundStyle(Color.cohGreen)
                Text(strings.agreementYouSignHereNote(partnerBDisplay))
                    .font(.caption).foregroundStyle(Color.cohInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.cohGreen.opacity(0.08))

            // Embedded DocuSeal signing form — only for the current user (Partner A)
            DocuSealSigningView(signingURL: sub.signingUrlA)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: Generate

    private func generate() {
        isGenerating = true
        // Capture the config on the main actor before the background work.
        let hid = household.id
        let rentAmount = household.rentAmount
        let rentPayerKey = household.rentPayerKey
        let rentPaymentDay = household.rentPaymentDay
        let inclDissolution = household.includeDissolutionClause
        let inclSeparate = household.includeSeparatePropertyClause
        let inclBuyout = household.includeBuyoutRightsClause
        let inclDisposal = household.includeDisposalConsentClause
        let inclDispute = household.includeDisputeResolutionClause
        let inclDebt = household.includeDebtClause
        Task {
            do {
                // Persist the config that produced this contract so the partner's
                // device generates/reads an identical agreement.
                func syncConfig() async {
                    try? await SupabaseService.updateAgreementConfig(
                        householdId: hid,
                        rentAmount: rentAmount, rentPayerKey: rentPayerKey,
                        rentPaymentDay: rentPaymentDay,
                        includeDissolutionClause: inclDissolution,
                        includeSeparatePropertyClause: inclSeparate,
                        includeBuyoutRightsClause: inclBuyout,
                        includeDisposalConsentClause: inclDisposal,
                        includeDisputeResolutionClause: inclDispute,
                        includeDebtClause: inclDebt)
                }
                if signingMethod == .bankid {
                    let result = try await DealBuilderService.submit(household: household)
                    await syncConfig()
                    await MainActor.run { bankIDCase = result; isGenerating = false }
                } else {
                    let result = try await DocuSealService.submit(household: household)
                    await syncConfig()
                    await MainActor.run { submission = result; isGenerating = false }
                }
            } catch DealBuilderError.creditsExhausted {
                // Included BankID signing is used — offer to buy an extra one.
                await MainActor.run {
                    isGenerating = false
                    reviewMode = true
                    showBankIDLimit = true
                }
            } catch DocuSealError.monthlyLimit {
                await MainActor.run {
                    self.error = strings.docuSealMonthlyLimit
                    isGenerating = false
                }
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
    @Environment(HouseholdStore.self) private var store
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @AppStorage("wasSignedOut") private var wasSignedOut = false
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
                    Picker(strings.settingsCurrency, selection: $currency) {
                        ForEach(currencies, id: \.self) { Text($0) }
                    }
                    HStack {
                        Text(strings.settingsInterestRate)
                        Spacer()
                        TextField("5.0", text: $rateText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%").foregroundStyle(Color.cohSecondary)
                    }
                } header: { Text(strings.settingsTitle) }

                Section {
                    Text(strings.settingsInterestRateFooter)
                        .font(.subheadline).foregroundStyle(Color.cohSecondary)
                }

                if let h = household {
                    Section {
                        Button {
                            if let url = URL(string: "mailto:support@cohab.app?subject=Support%20request") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label(strings.settingsContactSupport,
                                  systemImage: "envelope.fill")
                        }
                        Button {
                            exportURL = generateExportCSV(household: h)
                            showExportSheet = exportURL != nil
                        } label: {
                            Label(strings.settingsExportCSV,
                                  systemImage: "arrow.up.doc.fill")
                        }
                    } footer: {
                        Text(strings.settingsExportFooter)
                    }
                }

                if household != nil {
                    Section {
                        Button(role: .destructive) { showSignOutConfirm = true } label: {
                            Label(strings.settingsSignOut,
                                  systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }

                    Section {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label(strings.settingsDeleteLocal,
                                  systemImage: "trash")
                        }
                        Button(role: .destructive) { showDeleteAccountConfirm = true } label: {
                            Label(strings.settingsDeleteAccount,
                                  systemImage: "person.crop.circle.badge.minus")
                        }
                    } footer: {
                        Text(strings.settingsDeleteAccountFooter)
                    }
                }
            }
            .navigationTitle(household == nil ? strings.settingsSetupHousehold : strings.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(strings.cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.save) { save() }.bold().disabled(!canSave)
                }
            }
            .confirmationDialog(strings.settingsDeleteLocalTitle,
                                isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button(strings.settingsDeleteEverything, role: .destructive) { deleteAll() }
                Button(strings.cancel, role: .cancel) {}
            } message: {
                Text(strings.settingsDeleteLocalMessage)
            }
            .confirmationDialog(strings.settingsSignOutTitle,
                                isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button(strings.settingsSignOut, role: .destructive) { signOut() }
                Button(strings.cancel, role: .cancel) {}
            }
            .confirmationDialog(strings.settingsDeleteAccountTitle,
                                isPresented: $showDeleteAccountConfirm, titleVisibility: .visible) {
                Button(strings.settingsDeleteMyAccount, role: .destructive) {
                    deleteAccount()
                }
                Button(strings.cancel, role: .cancel) {}
            } message: {
                Text(strings.settingsDeleteAccountMessage)
            }
            .alert(strings.settingsDeleteAccountError,
                   isPresented: Binding(get: { deleteAccountError != nil },
                                        set: { if !$0 { deleteAccountError = nil } })) {
                Button(strings.ok, role: .cancel) {}
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
            let householdId = store.household?.id ?? h.id
            Task {
                try? await SupabaseService.updateHousehold(
                    householdId: householdId, partnerALabel: a, partnerBLabel: b,
                    currency: currency, annualInterestRate: rate)
            }
        } else {
            modelContext.insert(
                Household(partnerAName: a, partnerBName: b, currency: currency, annualInterestRate: rate)
            )
        }
        dismiss()
    }

    private func signOut() {
        wasSignedOut = true          // triggers SignInView in ContentView
        onboardingComplete = false
        Task { await auth.signOut() }
    }

    private func deleteAll() {
        // Delete EVERY local household, not just the current one — leftovers
        // from an earlier account would otherwise survive and break invites.
        let all = (try? modelContext.fetch(FetchDescriptor<Household>())) ?? []
        for h in all { modelContext.delete(h) }
        try? modelContext.save()
        wasSignedOut = false         // full reset — go to OnboardingView
        onboardingComplete = false
    }

    private func deleteAccount() {
        Task { @MainActor in
            do {
                // Remote first — only wipe local data once the account is
                // actually gone, otherwise a failed delete would leave the
                // user signed in with their local data already removed.
                try await auth.deleteAccount()
                let all = (try? modelContext.fetch(FetchDescriptor<Household>())) ?? []
                for h in all { modelContext.delete(h) }
                try? modelContext.save()
                wasSignedOut = false         // full reset — go to OnboardingView
                onboardingComplete = false
            } catch {
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
    @Environment(HouseholdStore.self) private var store
    @ObservedObject private var strings = AppStrings.shared

    @State private var step = 0
    @State private var selectedType: AssetType = .home
    @State private var label = ""
    @State private var address = ""
    @State private var valueText = ""
    @State private var loanText = ""
    @State private var shareA: Double = 0.5
    @State private var isRegistered: Bool = true
    @State private var ekTextA = ""
    @State private var ekTextB = ""
    @State private var ekDate = Date()
    @State private var sheetDetent: PresentationDetent = .fraction(0.62)

    private var canBeRegistered: Bool { [.home, .cabin, .car].contains(selectedType) }
    /// New assets get an extra, optional purchase-equity step after ownership.
    private var totalSteps: Int { existingAsset == nil ? 4 : 3 }

    private var s: AppStrings { strings }
    private var sym: String { household.currencySymbol }
    private let bluePartner = Color(red: 0.20, green: 0.49, blue: 0.96)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cohBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Progress bar (steps 1..totalSteps)
                    if step > 0 {
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.cohGreen.opacity(0.12)).frame(height: 3)
                                Capsule().fill(Color.cohGreen)
                                    .frame(width: g.size.width * CGFloat(step) / CGFloat(totalSteps), height: 3)
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
                        case 3: ownershipStep
                        default: equityStep
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
            .presentationDetents([.fraction(0.62), .large], selection: $sheetDetent)
            .presentationDragIndicator(.visible)
            // Ratchet: expand when keyboard shows, never shrink back automatically
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                sheetDetent = .large
            }
            .onChange(of: step) { _, newStep in
                if newStep == 0 { sheetDetent = .large }
            }
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                wizardHeader(s.stepNameIt, subtitle: s.stepNameSub)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                VStack(spacing: 12) {
                    wizardField(label: s.fieldName,
                                placeholder: selectedType.displayName,
                                text: $label, keyboard: .default)
                    wizardField(label: selectedType.secondaryLabel + " (\(s.optional))",
                                placeholder: selectedType.secondaryPlaceholder,
                                text: $address, keyboard: .default)
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 120)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            wizardCTA(s.onboardingContinue,
                      enabled: !label.trimmingCharacters(in: .whitespaces).isEmpty) {
                withAnimation(.easeInOut(duration: 0.28)) { step = 2 }
            }
        }
    }

    // MARK: Step 2 — Value

    private var valueStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                wizardHeader(s.stepWhatWorth)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
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
                Spacer(minLength: 120)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            wizardCTA(s.onboardingContinue, enabled: true) {
                withAnimation(.easeInOut(duration: 0.28)) { step = 3 }
            }
        }
    }

    // MARK: Step 3 — Ownership

    private var ownershipStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                wizardHeader(s.stepWhoOwns, subtitle: selectedType.ownershipHint)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                VStack(spacing: 20) {
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

                    if canBeRegistered {
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(s.assetIsRegistered, isOn: $isRegistered)
                                .font(.subheadline)
                            Text(s.assetIsRegisteredHint)
                                .font(.subheadline)
                                .foregroundStyle(Color.cohSecondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 120)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if existingAsset == nil {
                wizardCTA(s.onboardingContinue, enabled: true) {
                    withAnimation(.easeInOut(duration: 0.28)) { step = 4 }
                }
            } else {
                wizardCTA(s.add, enabled: true) { save() }
            }
        }
    }

    // MARK: Step 4 — Purchase equity (optional, new assets only)

    private var equityStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                wizardHeader(s.addAssetEquityTitle, subtitle: s.addAssetEquitySub)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                VStack(spacing: 12) {
                    equityRow(name: household.partnerAName, color: Color.cohGreen, text: $ekTextA)
                    equityRow(name: household.partnerBName.isEmpty ? "Partner" : household.partnerBName,
                              color: bluePartner, text: $ekTextB)
                    HStack {
                        Text(s.contribDateLabel)
                            .font(.subheadline).foregroundStyle(Color.cohSecondary)
                        Spacer()
                        DatePicker("", selection: $ekDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 1))
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 120)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            let hasAmount = parseAmount(ekTextA) > 0 || parseAmount(ekTextB) > 0
            wizardCTA(hasAmount ? s.add : s.addAssetSkip, enabled: true) { save() }
        }
    }

    private func equityRow(name: String, color: Color, text: Binding<String>) -> some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(name).font(.subheadline.weight(.medium)).foregroundStyle(Color.cohInk)
            }
            Spacer()
            Text(sym).foregroundStyle(Color.cohMuted).font(.subheadline)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 110)
        }
        .padding(.horizontal, 14).padding(.vertical, 13)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 1))
    }

    /// Tolerant amount parser: accepts "10 000", "10.000,50", "10000,50"
    /// and "10000.50" (same rules as AddContributionView).
    private func parseAmount(_ text: String) -> Double {
        var t = text.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "\u{202F}", with: "")
            .replacingOccurrences(of: " ", with: "")
        if t.contains(",") && t.contains(".") {
            t = t.replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
        } else if t.contains(",") {
            t = t.replacingOccurrences(of: ",", with: ".")
        }
        return Double(t) ?? 0
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
                .foregroundStyle(Color.cohSecondary)
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
        let trimmedLabel   = label.trimmingCharacters(in: .whitespaces)
        let trimmedAddress = address.trimmingCharacters(in: .whitespaces)
        let type   = selectedType.rawValue
        let salesCost = selectedType.defaultSalesCostFraction

        if let existing = existingAsset {
            existing.assetType               = type
            existing.label                   = trimmedLabel
            existing.address                 = trimmedAddress
            existing.currentValue            = value
            existing.remainingLoan           = loan
            existing.salesCostFraction       = salesCost
            existing.ownershipShareA         = shareA
            existing.isOwnershipRegistered   = canBeRegistered && isRegistered
            let id = existing.id
            Task {
                try? await store.updateAsset(
                    id, assetType: type, label: trimmedLabel, address: trimmedAddress,
                    currentValue: value, remainingLoan: loan,
                    salesCostFraction: salesCost, ownershipShareA: shareA)
            }
        } else {
            let asset = Asset(
                assetType: type,
                label: trimmedLabel,
                address: trimmedAddress,
                currentValue: value,
                remainingLoan: loan,
                salesCostFraction: salesCost,
                ownershipShareA: shareA,
                isOwnershipRegistered: canBeRegistered && isRegistered
            )
            household.assets.append(asset)
            // Optional purchase equity from step 4 — logged as the first
            // contributions (category "deposit") on the asset.
            let ekA = parseAmount(ekTextA)
            let ekB = parseAmount(ekTextB)
            var firstContribs: [ContributionRecord] = []
            if ekA > 0 {
                let r = ContributionRecord(ownerKey: "A", amount: ekA, date: ekDate,
                                           label: s.contribCatDeposit, category: "deposit")
                asset.contributions.append(r)
                firstContribs.append(r)
            }
            if ekB > 0 {
                let r = ContributionRecord(ownerKey: "B", amount: ekB, date: ekDate,
                                           label: s.contribCatDeposit, category: "deposit")
                asset.contributions.append(r)
                firstContribs.append(r)
            }
            // Insert remotely preserving the local id, so the next sync adopts
            // this row instead of recreating a duplicate from the server.
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
            let assetId = asset.id
            let householdId = store.household?.id ?? household.id
            let sortOrder = household.assets.count - 1
            Task {
                try? await SupabaseService.insertAssetPreservingId(
                    id: assetId, householdId: householdId,
                    assetType: type, label: trimmedLabel, address: trimmedAddress,
                    currentValue: value, remainingLoan: loan,
                    salesCostFraction: salesCost,
                    ownershipShareA: min(max(shareA, 0), 1),
                    sortOrder: sortOrder, purchaseDate: f.string(from: Date()))
                for r in firstContribs {
                    do {
                        try await SupabaseService.insertContributionPreservingId(
                            id: r.id, assetId: assetId, ownerKey: r.ownerKey.lowercased(),
                            amount: r.amount, date: f.string(from: r.date),
                            label: r.label, category: r.category)
                    } catch {
                        print("[Cohab] Purchase-equity push failed: \(error.localizedDescription)")
                    }
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
    @Environment(HouseholdStore.self) private var store
    @ObservedObject private var strings = AppStrings.shared

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
                ToolbarItem(placement: .topBarLeading) { Button(strings.cancel) { dismiss() } }
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
            "Delete \"\(asset.label)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(strings.deleteAsset, role: .destructive) { deleteAsset() }
        } message: {
            Text(strings.assetDeleteMessage)
        }
    }

    // MARK: Type picker

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(strings.assetTypeLabel).font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
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
                                .foregroundStyle(selected ? type.color : Color.cohSecondary)
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
                        Text("%").foregroundStyle(Color.cohSecondary).font(.subheadline)
                    }
                }
                Text(selectedType.ownershipHint)
                    .font(.subheadline).foregroundStyle(Color.cohMuted)
            }
        }
    }

    // MARK: Contributions

    private var contributionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(strings.assetEquityContributions)
                        .font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
                    Text(selectedType.contributionSubtitle)
                        .font(.subheadline).foregroundStyle(Color.cohMuted)
                }
                Spacer()
                if household.partnerLeft != true {
                    Button { showAddContribution = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.cohGreen)
                    }
                }
            }

            if asset.contributions.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "tray")
                        .foregroundStyle(Color(.tertiaryLabel))
                    Text(strings.noContribsYet)
                        .font(.subheadline).foregroundStyle(Color.cohMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
            } else {
                let sorted = asset.contributions.sorted { $0.date < $1.date }
                VStack(spacing: 0) {
                    ForEach(sorted) { c in
                        ContributionRow(c: c, household: household) {
                            let id = c.id
                            // Delete remotely first; remove the local row only on
                            // success. The old fire-and-forget order let a failed
                            // remote delete resurrect the row on the next sync.
                            Task { @MainActor in
                                do {
                                    try await SupabaseService.deleteContribution(id)
                                    modelContext.delete(c)
                                } catch {
                                    print("[Cohab] Delete contribution failed: \(error.localizedDescription)")
                                }
                            }
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
            Label(strings.deleteAsset, systemImage: "trash")
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
            Text(title).font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
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
                Text(label).font(.caption.weight(.medium)).foregroundStyle(Color.cohSecondary)
            }
            HStack {
                if let p = prefix { Text(p).foregroundStyle(Color.cohSecondary).font(.subheadline) }
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
        asset.currentValue    = valueText.isEmpty ? asset.currentValue : parseExpenseAmount(valueText)
        asset.remainingLoan   = selectedType.showLoan
            ? parseExpenseAmount(loanText)
            : 0
        asset.salesCostFraction = selectedType.defaultSalesCostFraction
        asset.ownershipShareA   = min(1, max(0, (Double(shareAText) ?? 50) / 100))
        let id = asset.id
        let type = asset.assetType, lbl = asset.label, addr = asset.address
        let val = asset.currentValue, loan = asset.remainingLoan
        let salesCost = asset.salesCostFraction, share = asset.ownershipShareA
        Task {
            try? await store.updateAsset(
                id, assetType: type, label: lbl, address: addr,
                currentValue: val, remainingLoan: loan,
                salesCostFraction: salesCost, ownershipShareA: share)
        }
        dismiss()
    }

    private func deleteAsset() {
        let id = asset.id
        // Delete remotely first; remove the local row only on success,
        // otherwise the next sync would resurrect the asset.
        Task { @MainActor in
            do {
                try await store.deleteAsset(id)
                modelContext.delete(asset)
                dismiss()
            } catch {
                print("[Cohab] Delete asset failed: \(error.localizedDescription)")
            }
        }
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
                    .font(.caption).foregroundStyle(Color.cohSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(household.moneyText(c.amount))
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
}

// MARK: - Contribution asset picker

struct ContribAssetPickerView: View {
    let household: Household
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var strings = AppStrings.shared
    @State private var selectedAsset: Asset?

    private var sortedAssets: [Asset] {
        household.assets
            .filter { $0.currentValue > 0 }
            .sorted { $0.label < $1.label }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(sortedAssets) { asset in
                        Button { selectedAsset = asset } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(asset.type.color.opacity(0.12))
                                        .frame(width: 46, height: 46)
                                    Image(systemName: asset.type.icon)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(asset.type.color)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(asset.label)
                                        .font(.headline).foregroundStyle(Color.cohInk)
                                    if !asset.address.isEmpty {
                                        Text(asset.address)
                                            .font(.caption).foregroundStyle(Color.cohSecondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(Int(asset.ownershipShareA * 100))/\(100 - Int(asset.ownershipShareA * 100))")
                                        .font(.caption.bold().monospacedDigit())
                                        .foregroundStyle(Color.cohSecondary)
                                    Text(household.moneyText(asset.currentValue))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(Color.cohSecondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                            .padding(16)
                            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle(strings.addContribTitle)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(strings.cancel) { dismiss() }
                }
            }
        }
        .sheet(item: $selectedAsset) { asset in
            AddContributionView(asset: asset, household: household, onComplete: { dismiss() })
        }
    }
}

// MARK: - Add contribution sheet

struct AddContributionView: View {
    let asset: Asset
    let household: Household
    var onComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthManager
    @ObservedObject private var strings = AppStrings.shared

    @State private var ownerKey        = "A"
    @State private var amountText      = ""
    @State private var amountTextB     = ""
    @State private var date            = Date()
    @State private var label           = ""
    @State private var category        = "deposit"
    @State private var adjustOwnership = false
    @State private var ownershipShareA = 0.5
    @State private var receiptImage: UIImage?
    @State private var receiptPickItem: PhotosPickerItem?

    private struct ContribCategory {
        let key: String
        let label: String
        let icon: String
    }

    private var categories: [ContribCategory] {
        let s = AppStrings.shared
        switch asset.type {
        case .home, .cabin:
            return [
                .init(key: "deposit",         label: s.contribCatDeposit,    icon: "banknote.fill"),
                .init(key: "extra_repayment", label: s.contribCatRepayment,  icon: "arrow.down.to.line"),
                .init(key: "renovation",      label: s.contribCatRenovation, icon: "hammer.fill"),
                .init(key: "inheritance",     label: s.contribCatGift,       icon: "gift.fill"),
            ]
        case .car:
            return [
                .init(key: "deposit",         label: s.contribCatDeposit,    icon: "banknote.fill"),
                .init(key: "extra_repayment", label: s.contribCatRepayment,  icon: "arrow.down.to.line"),
                .init(key: "renovation",      label: s.contribCatRepairs,    icon: "hammer.fill"),
                .init(key: "inheritance",     label: s.contribCatGift,       icon: "gift.fill"),
            ]
        case .investment, .savings:
            return [
                .init(key: "deposit",     label: s.contribCatDeposit, icon: "banknote.fill"),
                .init(key: "inheritance", label: s.contribCatGift,    icon: "gift.fill"),
            ]
        case .furniture, .pet:
            return [
                .init(key: "deposit",     label: s.contribCatPurchase, icon: "banknote.fill"),
                .init(key: "inheritance", label: s.contribCatGift,     icon: "gift.fill"),
            ]
        case .other:
            return [
                .init(key: "deposit",         label: s.contribCatPayment,    icon: "banknote.fill"),
                .init(key: "extra_repayment", label: s.contribCatRepayment,  icon: "arrow.down.to.line"),
                .init(key: "renovation",      label: s.contribCatRenovation, icon: "hammer.fill"),
                .init(key: "inheritance",     label: s.contribCatGift,       icon: "gift.fill"),
            ]
        }
    }

    /// Tolerant parser for Norwegian amounts: accepts "10 000", "10.000,50",
    /// "10000,50" and "10000.50". (The old code stripped commas, so "10,5"
    /// silently became 105 and "10 000" failed to parse at all.)
    private func parseAmount(_ text: String) -> Double {
        var t = text.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "\u{202F}", with: "")
            .replacingOccurrences(of: " ", with: "")
        if t.contains(",") && t.contains(".") {
            // Norwegian convention: dot = thousands separator, comma = decimal
            t = t.replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
        } else if t.contains(",") {
            t = t.replacingOccurrences(of: ",", with: ".")
        }
        return Double(t) ?? 0
    }

    private var canAdd: Bool {
        let a = parseAmount(amountText)
        if ownerKey == "BOTH" {
            return a > 0 || parseAmount(amountTextB) > 0
        }
        return a > 0
    }

    private var selectedCategory: ContribCategory {
        categories.first { $0.key == category } ?? categories[0]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(strings.contribWhoSection) {
                    Picker("Partner", selection: $ownerKey) {
                        Text(household.partnerAName).tag("A")
                        Text(household.partnerBName).tag("B")
                        Text(strings.contribBoth).tag("BOTH")
                    }
                    .pickerStyle(.segmented)
                }

                Section(strings.contribCategorySection) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.key) { cat in
                            let selected = category == cat.key
                            Button {
                                let wasAuto = categories.contains(where: { $0.label == label })
                                category = cat.key
                                if label.isEmpty || wasAuto {
                                    label = cat.label
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(selected ? Color.cohGreen : Color(.systemGray5))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(selected ? .white : Color.cohGreen)
                                    }
                                    Text(cat.label)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(selected ? Color.cohGreen : Color.cohSecondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section(strings.contribDetailsSection) {
                    if ownerKey == "BOTH" {
                        VStack(spacing: 10) {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle().fill(Color.cohGreen).frame(width: 8, height: 8)
                                    Text(household.partnerAName)
                                        .font(.caption.weight(.medium)).foregroundStyle(Color.cohSecondary)
                                }
                                Spacer()
                                Text(household.currencySymbol).foregroundStyle(Color.cohSecondary).font(.subheadline)
                                TextField("0", text: $amountText).keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                            Divider()
                            HStack {
                                HStack(spacing: 6) {
                                    Circle().fill(Color(red: 0.20, green: 0.49, blue: 0.96)).frame(width: 8, height: 8)
                                    Text(household.partnerBName)
                                        .font(.caption.weight(.medium)).foregroundStyle(Color.cohSecondary)
                                }
                                Spacer()
                                Text(household.currencySymbol).foregroundStyle(Color.cohSecondary).font(.subheadline)
                                TextField("0", text: $amountTextB).keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        HStack {
                            Text(household.currencySymbol).foregroundStyle(Color.cohSecondary)
                            TextField(strings.contribAmountPlaceholder, text: $amountText).keyboardType(.decimalPad)
                        }
                    }
                    DatePicker(strings.contribDateLabel, selection: $date, displayedComponents: .date)
                    TextField(strings.contribLabelPlaceholder, text: $label)

                    // Optional receipt attached to this contribution
                    if let receiptImage {
                        HStack(spacing: 12) {
                            Image(uiImage: receiptImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Text(strings.assetReceipt)
                                .font(.subheadline).foregroundStyle(Color.cohInk)
                            Spacer()
                            Button { self.receiptImage = nil } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color(.quaternaryLabel))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(strings.assetReceipt)
                        }
                    } else {
                        PhotosPicker(selection: $receiptPickItem, matching: .images) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.cohGreen)
                                Text(strings.assetAddReceipt)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.cohGreen)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Toggle(strings.contribAdjustOwnership, isOn: $adjustOwnership)
                    if adjustOwnership {
                        VStack(spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle().fill(Color.cohGreen).frame(width: 8, height: 8)
                                    Text(household.partnerAName).font(.subheadline)
                                }
                                Spacer()
                                Text("\(Int((ownershipShareA * 100).rounded()))%")
                                    .font(.subheadline.bold().monospacedDigit())
                            }
                            HStack {
                                HStack(spacing: 6) {
                                    Circle().fill(Color(red: 0.20, green: 0.49, blue: 0.96)).frame(width: 8, height: 8)
                                    Text(household.partnerBName).font(.subheadline)
                                }
                                Spacer()
                                Text("\(100 - Int((ownershipShareA * 100).rounded()))%")
                                    .font(.subheadline.bold().monospacedDigit())
                            }
                            Slider(value: $ownershipShareA, in: 0...1, step: 0.01)
                                .tint(Color.cohGreen)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(strings.assetOwnership)
                } footer: {
                    if adjustOwnership {
                        Text(strings.contribOwnershipFooter)
                    }
                }
            }
            .navigationTitle(strings.addContribTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(strings.cancel) { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.add) { add() }.bold().disabled(!canAdd)
                }
            }
        }
        .onAppear { ownershipShareA = asset.ownershipShareA }
        .onChange(of: receiptPickItem) { _, item in
            guard let item else { return }
            Task { @MainActor in
                defer { receiptPickItem = nil }
                if let data = try? await item.loadTransferable(type: Data.self) {
                    receiptImage = UIImage(data: data)
                }
            }
        }
    }

    private func add() {
        let amount = parseAmount(amountText)
        let amountB = parseAmount(amountTextB)
        let displayLabel = label.trimmingCharacters(in: .whitespaces).isEmpty
            ? (categories.first { $0.key == category }?.label ?? "Contribution")
            : label.trimmingCharacters(in: .whitespaces)
        var created: [ContributionRecord] = []
        if ownerKey == "BOTH" {
            if amount > 0 {
                let r = ContributionRecord(ownerKey: "A", amount: amount, date: date,
                                           label: displayLabel, category: category)
                asset.contributions.append(r)
                created.append(r)
            }
            if amountB > 0 {
                let r = ContributionRecord(ownerKey: "B", amount: amountB, date: date,
                                           label: displayLabel, category: category)
                asset.contributions.append(r)
                created.append(r)
            }
        } else {
            let r = ContributionRecord(ownerKey: ownerKey, amount: amount, date: date,
                                       label: displayLabel, category: category)
            asset.contributions.append(r)
            created.append(r)
        }
        if adjustOwnership {
            asset.ownershipShareA = ownershipShareA
        }

        // Push remotely (preserving local ids) so the partner sees the same
        // contributions and the next sync doesn't recreate duplicates.
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let assetId = asset.id
        for r in created {
            let rid = r.id, key = r.ownerKey.lowercased(), amt = r.amount
            let dt = f.string(from: r.date), lbl = r.label, cat = r.category
            Task {
                do {
                    try await SupabaseService.insertContributionPreservingId(
                        id: rid, assetId: assetId, ownerKey: key, amount: amt,
                        date: dt, label: lbl, category: cat)
                } catch {
                    // Sync reconciles against the server, so a row whose push
                    // failed is removed locally on the next sync — log the
                    // failure so it is at least visible in the console.
                    print("[Cohab] Contribution push failed: \(error.localizedDescription)")
                }
            }
        }
        // Best-effort receipt upload for the new contribution — a failure
        // never blocks keeping the contribution itself.
        if let receipt = receiptImage, let first = created.first {
            let rid = first.id, hhId = household.id
            let signedIn = auth.isSignedIn
            Task {
                do {
                    try await AssetImageStore.saveReceipt(
                        receipt, contributionId: rid, householdId: hhId,
                        assetId: assetId, signedIn: signedIn)
                } catch {
                    print("[Cohab] Receipt upload failed: \(error.localizedDescription)")
                }
            }
        }
        if adjustOwnership {
            let share = ownershipShareA
            let type = asset.assetType, lbl = asset.label, addr = asset.address
            let val = asset.currentValue, loan = asset.remainingLoan
            let salesCost = asset.salesCostFraction
            Task {
                try? await SupabaseService.updateAsset(
                    assetId, assetType: type, label: lbl, address: addr,
                    currentValue: val, remainingLoan: loan,
                    salesCostFraction: salesCost, ownershipShareA: share)
            }
        }
        dismiss()
        DispatchQueue.main.async { onComplete?() }
    }
}
