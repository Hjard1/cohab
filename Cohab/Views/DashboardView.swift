import SwiftUI
import SwiftData

// MARK: - Dashboard

struct DashboardView: View {
    @Query private var households: [Household]
    @Environment(\.modelContext) private var modelContext
    @State private var showSetup = false
    @State private var showAddAsset = false
    @State private var editingAsset: Asset?

    private var household: Household? { households.first }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.cohBg.ignoresSafeArea()

                if let h = household {
                    ScrollView {
                        VStack(spacing: 0) {
                            householdHeader(h)
                                .padding(.top, 8)
                            assetsList(h)
                                .padding(.top, 24)
                            Spacer(minLength: 100)
                        }
                    }

                    addButton
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
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Text("cohab")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Color.cohGreen)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSetup = true } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(Color(.tertiaryLabel))
                    .font(.body)
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
                        Button { editingAsset = asset } label: {
                            AssetCard(asset: asset, household: h)
                        }
                        .buttonStyle(.plain)
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

    private var result: SettlementResult {
        SettlementEngine.settle(
            SettlementInput(
                salePrice: asset.currentValue,
                remainingLoan: asset.remainingLoan,
                salesCosts: asset.estimatedSalesCost,
                ownershipShareA: asset.ownershipShareA,
                annualRate: household.annualInterestRate,
                contributions: asset.contributions.map { c in
                    Contribution(
                        owner: c.ownerKey == "A" ? .a : .b,
                        amount: c.amount,
                        date: c.date,
                        label: c.label
                    )
                },
                settlementDate: Date()
            )
        )
    }

    private let typeColor: Color
    private let typeIcon: String

    init(asset: Asset, household: Household) {
        self.asset = asset
        self.household = household
        let t = asset.type
        self.typeColor = t.color
        self.typeIcon = t.icon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            assetHeader
            Color(.separator).frame(height: 0.5).padding(.vertical, 16)
            settlementRow
            if result.shortfall { shortfallBadge.padding(.top, 12) }
        }
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 4)
        .padding(.horizontal, 20)
    }

    private var assetHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(typeColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: typeIcon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(typeColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(asset.label)
                    .font(.headline)
                if !asset.address.isEmpty {
                    Text(asset.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(household.currencySymbol + fmt(asset.currentValue))
                    .font(.subheadline.bold().monospacedDigit())
                if asset.remainingLoan > 0 {
                    Text("Loan: −" + fmt(asset.remainingLoan))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.orange)
                }
                HStack(spacing: 3) {
                    Image(systemName: "pencil")
                        .font(.caption2)
                    Text("Edit")
                        .font(.caption2)
                }
                .foregroundStyle(Color(.tertiaryLabel))
                .padding(.top, 2)
            }
        }
    }

    private var settlementRow: some View {
        HStack(alignment: .top) {
            payoutColumn(
                household.partnerAName,
                payout: result.payout[.a] ?? 0,
                accrued: result.accrued[.a] ?? 0,
                color: .cohGreen
            )
            Spacer()
            VStack(spacing: 2) {
                Text("If settled today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            Spacer()
            payoutColumn(
                household.partnerBName,
                payout: result.payout[.b] ?? 0,
                accrued: result.accrued[.b] ?? 0,
                color: Color(red: 0.20, green: 0.49, blue: 0.96)
            )
        }
    }

    private func payoutColumn(_ name: String, payout: Double, accrued: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.caption.weight(.medium))
                .foregroundStyle(color)
            Text(household.currencySymbol + fmt(payout))
                .font(.title3.bold().monospacedDigit())
            if accrued > 0 {
                Text("incl. " + household.currencySymbol + fmt(accrued) + " contributions")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shortfallBadge: some View {
        Label("Net value below contributions — proportional split applied", systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(.orange)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

// MARK: - Household setup sheet

struct HouseholdSetupView: View {
    let household: Household?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var nameA = ""
    @State private var nameB = ""
    @State private var currency = "GBP"
    @State private var rateText = "5.0"

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
                            .foregroundStyle(Color.cohGreen)
                            .frame(width: 24)
                        TextField("Partner A name", text: $nameA)
                    }
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color(red: 0.20, green: 0.49, blue: 0.96))
                            .frame(width: 24)
                        TextField("Partner B name", text: $nameB)
                    }
                } header: { Text("Partners") }

                Section {
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { Text($0) }
                    }
                    HStack {
                        Text("Interest rate")
                        Spacer()
                        TextField("5.0", text: $rateText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%").foregroundStyle(.secondary)
                    }
                } header: { Text("Settings") }

                Section {
                    Text("The interest rate determines how much each contribution grows over time. 5% is a sensible default — adjust to your central bank's current rate if you prefer precision.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(household == nil ? "Set up household" : "Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.bold().disabled(!canSave)
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
}

// MARK: - Add asset sheet

struct AddAssetView: View {
    let household: Household
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: AssetType = .home
    @State private var label = ""
    @State private var address = ""
    @State private var valueText = ""
    @State private var loanText = ""
    @State private var shareAText = "50"

    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty && Double(valueText) != nil
    }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    typePicker
                    detailsSection
                    valueSection
                    ownershipSection
                }
                .padding(24)
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle("Add asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { save() }.bold().disabled(!canSave)
                }
            }
        }
    }

    // MARK: Type picker

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TYPE")
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AssetType.allCases, id: \.self) { type in
                    typeCell(type)
                }
            }
        }
    }

    private func typeCell(_ type: AssetType) -> some View {
        let selected = selectedType == type
        return Button { selectedType = type } label: {
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

    // MARK: Form sections

    private var detailsSection: some View {
        formCard("DETAILS") {
            VStack(spacing: 14) {
                formField(
                    icon: "tag.fill",
                    label: "Name",
                    placeholder: selectedType.displayName,
                    text: $label,
                    keyboard: .default
                )
                formField(
                    icon: "mappin.circle.fill",
                    label: selectedType.secondaryLabel + " (optional)",
                    placeholder: selectedType.secondaryPlaceholder,
                    text: $address,
                    keyboard: .default
                )
            }
        }
    }

    private var valueSection: some View {
        let cfg = selectedType
        return formCard(cfg.showLoan ? "VALUE & LOAN" : "VALUE") {
            VStack(spacing: 14) {
                formField(
                    icon: "arrow.up.right.circle.fill",
                    label: cfg.valueLabel,
                    placeholder: cfg.valuePlaceholder,
                    prefix: household.currencySymbol,
                    text: $valueText,
                    keyboard: .decimalPad
                )
                if cfg.showLoan {
                    formField(
                        icon: "arrow.down.right.circle.fill",
                        label: cfg.loanLabel,
                        placeholder: "0",
                        prefix: household.currencySymbol,
                        text: $loanText,
                        keyboard: .decimalPad
                    )
                }
            }
        }
    }

    private var ownershipSection: some View {
        formCard("OWNERSHIP") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(household.partnerAName)'s \(selectedType.ownershipLabel)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    HStack(spacing: 2) {
                        TextField("50", text: $shareAText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 44)
                            .font(.subheadline.bold().monospacedDigit())
                        Text("%")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
                Text(selectedType.ownershipHint)
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
    }

    // MARK: Helpers

    private func formCard<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func formField(
        icon: String,
        label: String,
        placeholder: String,
        prefix: String? = nil,
        text: Binding<String>,
        keyboard: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.cohGreen)
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            HStack {
                if let p = prefix {
                    Text(p)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func save() {
        let value  = Double(valueText.replacingOccurrences(of: ",", with: "")) ?? 0
        let loan   = selectedType.showLoan
            ? (Double(loanText.replacingOccurrences(of: ",", with: "")) ?? 0)
            : 0
        let shareA = min(1, max(0, (Double(shareAText) ?? 50) / 100))
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
