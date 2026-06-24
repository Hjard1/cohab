import SwiftUI
import SwiftData

// MARK: - Dashboard

struct DashboardView: View {
    @Query private var households: [Household]
    @Environment(\.modelContext) private var modelContext
    @State private var showSetup = false
    @State private var showAddAsset = false

    private var household: Household? { households.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.05).ignoresSafeArea()
                if let h = household {
                    householdContent(h)
                } else {
                    emptyState
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("cohab")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(.green)
                }
                if household != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showSetup = true } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSetup) {
            HouseholdSetupView(household: household)
        }
        .sheet(isPresented: $showAddAsset) {
            if let h = household { AddAssetView(household: h) }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green.opacity(0.7))
            Text("Set up your household")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Track shared assets, who contributed what, and get a fair settlement if you ever need one.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Get started") { showSetup = true }
                .buttonStyle(.borderedProminent)
                .tint(.green)
        }
    }

    // MARK: Main content

    private func householdContent(_ h: Household) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                partnersHeader(h)

                if h.assets.isEmpty {
                    noAssetsPrompt { showAddAsset = true }
                } else {
                    ForEach(h.assets) { asset in
                        AssetCard(asset: asset, household: h)
                    }
                    Button {
                        showAddAsset = true
                    } label: {
                        Label("Add asset", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(24)
        }
    }

    private func partnersHeader(_ h: Household) -> some View {
        HStack(spacing: 8) {
            partnerChip(h.partnerAName, color: .green)
            Image(systemName: "arrow.left.arrow.right")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.2))
            partnerChip(h.partnerBName, color: .blue)
            Spacer()
            Text(h.currency)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    private func partnerChip(_ name: String, color: Color) -> some View {
        Text(name)
            .font(.footnote.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
    }

    private func noAssetsPrompt(action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No assets yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Add your home or any shared asset to start tracking contributions and see a fair settlement breakdown.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
            Button("Add first asset", action: action)
                .buttonStyle(.borderedProminent)
                .tint(.green)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(asset.label)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if !asset.address.isEmpty {
                        Text(asset.address)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(household.currencySymbol + fmt(asset.currentValue))
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(.white)
                    Text("current value")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }

            if asset.remainingLoan > 0 {
                HStack {
                    Text("Remaining loan")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Text("−" + household.currencySymbol + fmt(asset.remainingLoan))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.orange.opacity(0.8))
                }
            }

            Divider().overlay(.white.opacity(0.08))

            HStack {
                payoutColumn(household.partnerAName, result.payout[.a] ?? 0, color: .green)
                Spacer()
                payoutColumn(household.partnerBName, result.payout[.b] ?? 0, color: .blue)
            }

            if result.shortfall {
                Label("Value below contributions — proportional payout applied", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(20)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }

    private func payoutColumn(_ name: String, _ amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name)
                .font(.caption)
                .foregroundStyle(color.opacity(0.8))
            Text(household.currencySymbol + fmt(amount))
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.white)
        }
    }

    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
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
                Section("Partner names") {
                    TextField("Partner A", text: $nameA)
                    TextField("Partner B", text: $nameB)
                }
                Section("Settings") {
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
                }
                Section {
                    Text("Used to calculate how much each contribution has grown over time. A 5% default works well for most countries — adjust to your central bank's current rate if you prefer precision.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(household == nil ? "Set up household" : "Household settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(!canSave)
                }
            }
        }
        .onAppear {
            guard let h = household else { return }
            nameA = h.partnerAName
            nameB = h.partnerBName
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
            modelContext.insert(Household(partnerAName: a, partnerBName: b, currency: currency, annualInterestRate: rate))
        }
        dismiss()
    }
}

// MARK: - Add asset sheet

struct AddAssetView: View {
    let household: Household
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var address = ""
    @State private var valueText = ""
    @State private var loanText = ""
    @State private var shareAText = "50"

    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(valueText) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Asset details") {
                    TextField("Label (e.g. Main home)", text: $label)
                    TextField("Address (optional)", text: $address)
                }
                Section("Value & loan") {
                    HStack {
                        Text(household.currencySymbol)
                        TextField("Current value", text: $valueText)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text(household.currencySymbol)
                        TextField("Remaining loan (0 if none)", text: $loanText)
                            .keyboardType(.decimalPad)
                    }
                }
                Section("Registered ownership") {
                    HStack {
                        Text("\(household.partnerAName)'s share")
                        Spacer()
                        TextField("50", text: $shareAText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%").foregroundStyle(.secondary)
                    }
                }
            }
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

    private func save() {
        let value = Double(valueText) ?? 0
        let loan = Double(loanText) ?? 0
        let shareA = (Double(shareAText) ?? 50) / 100
        let asset = Asset(
            label: label.trimmingCharacters(in: .whitespaces),
            address: address.trimmingCharacters(in: .whitespaces),
            currentValue: value,
            remainingLoan: loan,
            ownershipShareA: min(1, max(0, shareA))
        )
        household.assets.append(asset)
        dismiss()
    }
}
