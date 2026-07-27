import SwiftUI
import SwiftData

// MARK: - Expense Split View (persistent, Supabase-backed)

struct ExpenseSplitView: View {
    let nameA: String
    let nameB: String
    let symbol: String
    let country: String

    @Query private var households: [Household]
    private var household: Household? { households.first }
    @Environment(HouseholdStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var strings = AppStrings.shared

    @State private var incomeAText = ""
    @State private var incomeBText = ""
    @State private var showAdd = false
    @State private var savedBudget = false
    @State private var expenseError: String?
    @State private var showFairInfo = false

    // Preset amounts, payers & split — mirrored to the Household model and
    // pushed to Supabase (debounced) so both partners edit the same numbers.
    @State private var presetAmts: [String] = ["", "", "", "", ""]
    @State private var presetPays: [String] = ["a", "a", "a", "a", "a"]     // "a" | "b" | "both"
    @State private var presetSplits: [Double] = [0.5, 0.5, 0.5, 0.5, 0.5]   // A's share when "both"
    @State private var lastLocalEdit = Date.distantPast
    @State private var pushTask: Task<Void, Never>?

    private var presetNames: [String] {
        [strings.expenseCatHousing, strings.expenseCatCar, strings.expenseCatFood,
         strings.expenseCatElectricity, strings.expenseCatInternet]
    }
    private let presetIcons = ["house.fill", "car.fill", "cart.fill", "bolt.fill", "wifi"]

    init(nameA: String = "Partner A", nameB: String = "Partner B", symbol: String = "£", country: String = "GB") {
        self.nameA = nameA; self.nameB = nameB; self.symbol = symbol; self.country = country
    }

    // MARK: Calculations

    private var iA: Double { parse(incomeAText) }
    private var iB: Double { parse(incomeBText) }
    private var totalIncome: Double { iA + iB }

    private struct Totals {
        var paysA, paysB, shareA, shareB, netAtoB, netBtoA: Double
        // Kept for the budget snapshot payload — never shown to the user as a
        // transfer instruction (how partners settle up is their own business).
        var netTransfer: Double { netBtoA - netAtoB }
    }

    private var totals: Totals {
        var t = Totals(paysA: 0, paysB: 0, shareA: 0, shareB: 0, netAtoB: 0, netBtoA: 0)
        for e in store.expenses {
            accumulate(into: &t, amount: e.amount, splitA: e.splitRatioA, payer: e.paidByKey)
        }
        for i in 0..<5 {
            let amt = parse(presetAmts[i])
            guard amt > 0 else { continue }
            accumulate(into: &t, amount: amt, splitA: presetSplits[i], payer: presetPays[i])
        }
        return t
    }

    /// Applies one expense to the running totals. `splitA` is A's share of the cost.
    /// `shareA/shareB` track what each partner bears; `paysA/paysB` what each
    /// physically pays. The difference (netAtoB/netBtoA) is only persisted in the
    /// budget snapshot — the app does not suggest any transfer.
    private func accumulate(into t: inout Totals, amount: Double, splitA: Double, payer: String) {
        let shareA = amount * splitA
        let shareB = amount * (1 - splitA)
        t.shareA += shareA
        t.shareB += shareB
        switch payer {
        case "a":
            t.paysA += amount
            t.netBtoA += shareB
        case "b":
            t.paysB += amount
            t.netAtoB += shareA
        default:                     // "both" — each pays their own share
            t.paysA += shareA
            t.paysB += shareB
        }
    }

    private var hasAnyExpense: Bool {
        !store.expenses.isEmpty || presetAmts.contains { parse($0) > 0 }
    }

    /// Partner deleted their account — the view becomes read-only: no edits
    /// and nothing pushed to Supabase (mirrors the dashboard's locks).
    private var isReadOnly: Bool { store.household?.partnerLeftAt != nil }

    // MARK: Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                incomeCard
                expensesCard
                if hasAnyExpense { resultCard }
            }
            .padding(20)
            .animation(.spring(duration: 0.35), value: store.expenses.count)
            .onChange(of: presetAmts) { _, _ in persistWorkingState() }
            .onChange(of: presetPays) { _, _ in persistWorkingState() }
            .onChange(of: presetSplits) { _, _ in persistWorkingState() }
            .onChange(of: incomeAText) { _, _ in persistWorkingState() }
            .onChange(of: incomeBText) { _, _ in persistWorkingState() }
            .onChange(of: household?.expensesUpdatedAt) { _, ts in
                // Remote edit from the partner — adopt it unless we typed more recently.
                guard let h = household, let ts, ts > lastLocalEdit else { return }
                applyFromHousehold(h)
            }
        }
        .background(Color.cohBg.ignoresSafeArea())
        .navigationTitle(strings.calcExpenseTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Hide/show the budget card on the dashboard — synced, so it
            // applies to both partners. Only relevant when a budget exists.
            if !isReadOnly, let h = household, h.hasBudget {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            toggleBudgetHidden()
                        } label: {
                            Label(h.budgetHidden ? strings.budgetShowOnOverview : strings.budgetHideFromOverview,
                                  systemImage: h.budgetHidden ? "eye" : "eye.slash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.cohInk)
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddExpenseSheet(nameA: nameA, nameB: nameB, symbol: symbol) { label, amount, paidBy, splitA, recurring in
                Task {
                    do {
                        try await store.addExpense(
                            label: label, amount: amount, paidByKey: paidBy,
                            splitRatioA: splitA, date: Date(),
                            category: "other", isRecurring: recurring
                        )
                    } catch {
                        expenseError = error.localizedDescription
                    }
                }
            }
        }
        .alert(strings.error, isPresented: Binding(
            get: { expenseError != nil },
            set: { if !$0 { expenseError = nil } }
        )) {
            Button(strings.ok, role: .cancel) { expenseError = nil }
        } message: {
            Text(expenseError ?? "")
        }
        .onAppear {
            if let h = household, h.expensesUpdatedAt != nil {
                // Synced working state exists — use it.
                applyFromHousehold(h)
            } else {
                // Legacy path: migrate any UserDefaults values from before sync existed.
                migrateLegacyDefaults()
            }
        }
    }

    // MARK: Working-state persistence (Household + Supabase)

    /// Loads the synced working state from the Household model into the text fields.
    /// The assignments re-trigger .onChange → persistWorkingState, which compares
    /// against the model and no-ops because nothing actually changed.
    private func applyFromHousehold(_ h: Household) {
        for i in 0..<5 {
            presetAmts[i] = h.presetAmounts[i] > 0 ? fmt(h.presetAmounts[i]) : ""
            presetPays[i] = h.presetPayers[i]
            presetSplits[i] = h.presetSplits[i]
        }
        incomeAText = h.expenseIncomeA > 0 ? fmt(h.expenseIncomeA) : ""
        incomeBText = h.expenseIncomeB > 0 ? fmt(h.expenseIncomeB) : ""
    }

    /// One-time migration of the old UserDefaults-based values (pre-sync builds).
    private func migrateLegacyDefaults() {
        let d = UserDefaults.standard
        for i in 0..<5 {
            if let amt = d.string(forKey: "cohab.p\(i).amt"), !amt.isEmpty { presetAmts[i] = amt }
            if let pay = d.string(forKey: "cohab.p\(i).pay") { presetPays[i] = pay }
            if d.object(forKey: "cohab.p\(i).split") != nil {
                presetSplits[i] = d.double(forKey: "cohab.p\(i).split")
            }
        }
        if let a = d.string(forKey: "cohab.income.a"), !a.isEmpty { incomeAText = a }
        else if let h = household, h.budgetIncomeA > 0 { incomeAText = fmtInc(h.budgetIncomeA) }
        if let b = d.string(forKey: "cohab.income.b"), !b.isEmpty { incomeBText = b }
        else if let h = household, h.budgetIncomeB > 0 { incomeBText = fmtInc(h.budgetIncomeB) }
        // The assignments above trigger persistWorkingState via .onChange,
        // which writes them to the Household and pushes them to Supabase.
    }

    /// Mirrors the current field values into the Household model and schedules
    /// a debounced push to Supabase. Skips no-op writes (e.g. remote echoes).
    private func persistWorkingState() {
        guard let h = household else { return }
        let amts = presetAmts.map { parse($0) }
        let incA = parse(incomeAText)
        let incB = parse(incomeBText)
        guard amts != h.presetAmounts || presetPays != h.presetPayers
                || presetSplits != h.presetSplits
                || incA != h.expenseIncomeA || incB != h.expenseIncomeB else { return }

        let now = Date()
        lastLocalEdit = now
        h.presetAmounts = amts
        h.presetPayers = presetPays
        h.presetSplits = presetSplits
        h.expenseIncomeA = incA
        h.expenseIncomeB = incB
        h.expensesUpdatedAt = now
        try? modelContext.save()

        pushTask?.cancel()
        let householdId = h.id
        let presets = (0..<5).map {
            DBExpensePreset(amount: amts[$0], payer: presetPays[$0], splitA: presetSplits[$0])
        }
        pushTask = Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            try? await SupabaseService.updateExpensePresets(
                householdId: householdId, presets: presets,
                incomeA: incA, incomeB: incB, updatedAt: now
            )
        }
    }

    // MARK: Income card

    private var incomeCard: some View {
        cardShell(strings.expenseIncomeTitle) {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.expenseIncomeSubtitle)
                    .font(.caption)
                    .foregroundStyle(Color.cohSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                incomeRow(nameA, color: Color.cohGreen, text: $incomeAText)
                incomeRow(nameB, color: Color(red: 0.20, green: 0.49, blue: 0.96), text: $incomeBText)
            }
        }
    }

    private func incomeRow(_ name: String, color: Color, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(name).font(.caption.weight(.medium)).foregroundStyle(color)
            }
            HStack {
                Text(symbol).foregroundStyle(Color.cohSecondary).font(.subheadline)
                TextField("0", text: text).keyboardType(.decimalPad)
                    .font(.subheadline.monospacedDigit())
                    .disabled(isReadOnly)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: Expenses card

    private var expensesCard: some View {
        cardShell(strings.expenseExpensesTitle) {
            VStack(spacing: 0) {
                // Preset rows
                ForEach(0..<5, id: \.self) { i in
                    presetRow(index: i)
                    if i < 4 { Divider().padding(.leading, 40) }
                }

                // Custom DB expenses — same row design as the preset rows
                if !store.expenses.isEmpty {
                    Divider().padding(.vertical, 8)
                    ForEach(store.expenses) { exp in
                        CustomExpenseRow(exp: exp, nameA: nameA, nameB: nameB,
                                         symbol: symbol, store: store) { expenseError = $0 }
                        if exp.id != store.expenses.last?.id {
                            Divider().padding(.leading, 40)
                        }
                    }
                }

                // Add custom expense button — hidden in read-only mode
                // (partner deleted their account)
                if store.household?.partnerLeftAt == nil {
                    Button { showAdd = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill").foregroundStyle(Color.cohGreen)
                            Text(strings.expenseAddExpense)
                                .font(.subheadline.weight(.medium)).foregroundStyle(Color.cohGreen)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.cohGreen.opacity(0.4),
                                              style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        )
                    }
                    .padding(.top, 12)
                }
            }
        }
    }

    // MARK: Preset row

    private func presetRow(index i: Int) -> some View {
        let blueColor = Color(red: 0.20, green: 0.49, blue: 0.96)
        return VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle().fill(Color.cohGreen.opacity(0.10)).frame(width: 34, height: 34)
                    Image(systemName: presetIcons[i])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.cohGreen)
                }
                // Name
                Text(presetNames[i])
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.cohInk)
                    .frame(width: 72, alignment: .leading)
                // Amount field
                HStack(spacing: 2) {
                    Text(symbol).font(.caption).foregroundStyle(Color.cohSecondary)
                    TextField("0", text: Binding(
                        get: { presetAmts[i] },
                        set: { presetAmts[i] = $0 }
                    ))
                    .keyboardType(.decimalPad)
                    .font(.subheadline.monospacedDigit())
                    .frame(maxWidth: .infinity)
                    .disabled(isReadOnly)
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                // Payer toggle — A / Both / B
                HStack(spacing: 4) {
                    payerPill(nameA, key: "a", current: presetPays[i], color: Color.cohGreen) {
                        presetPays[i] = "a"
                    }
                    payerPill(strings.expenseBoth, key: "both", current: presetPays[i], color: Color.cohInk) {
                        presetPays[i] = "both"
                    }
                    payerPill(nameB, key: "b", current: presetPays[i], color: blueColor) {
                        presetPays[i] = "b"
                    }
                }
                .disabled(isReadOnly)
            }
            // Split slider — only when "both" pays
            if presetPays[i] == "both" {
                splitSlider(
                    ratioA: Binding(
                        get: { presetSplits[i] },
                        set: { presetSplits[i] = $0 }
                    ),
                    colorA: Color.cohGreen, colorB: blueColor
                )
                .disabled(isReadOnly)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 10)
        .animation(.spring(duration: 0.3), value: presetPays[i])
    }

    private func payerPill(_ name: String, key: String, current: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(String(name.prefix(1)).uppercased())
                .font(.caption2.bold())
                .foregroundStyle(current == key ? .white : color)
                .frame(width: 24, height: 24)
                .background(current == key ? color : color.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
    }

    /// Reusable A%/B% split slider. `ratioA` is Partner A's fraction (0…1).
    private func splitSlider(ratioA: Binding<Double>, colorA: Color, colorB: Color) -> some View {
        expenseSplitSlider(ratioA: ratioA, colorA: colorA, colorB: colorB,
                           nameA: nameA, nameB: nameB)
    }

    // MARK: Result card

    private var resultCard: some View {
        let t = totals
        let blueColor = Color(red: 0.20, green: 0.49, blue: 0.96)

        return VStack(spacing: 14) {
            // Who physically pays out
            HStack(spacing: 12) {
                payoutPanel(nameA, amount: t.paysA, color: Color.cohGreen)
                payoutPanel(nameB, amount: t.paysB, color: blueColor)
            }

            // Income-based fair split (only when both incomes are entered)
            if totalIncome > 0 {
                Divider()
                let totalExp = t.paysA + t.paysB
                let incomeShareA = iA / totalIncome
                let fairA = totalExp * incomeShareA
                let fairB = totalExp * (1 - incomeShareA)
                let adjustment = t.shareA - fairA
                let pctA = Int((incomeShareA * 100).rounded())

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 5) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption2).foregroundStyle(Color.cohGreen)
                        Text(strings.expenseFairSplitTitle)
                            .font(.caption2.bold()).tracking(0.8).foregroundStyle(Color.cohSecondary)
                    }
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.cohGreen).frame(width: 6, height: 6)
                                Text(nameA).font(.caption).foregroundStyle(Color.cohSecondary)
                            }
                            Text(symbol + fmt(fairA))
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(Color.cohGreen)
                            Text(strings.expensePctOfIncome(pctA))
                                .font(.caption).foregroundStyle(Color.cohMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Circle().fill(blueColor).frame(width: 6, height: 6)
                                Text(nameB).font(.caption).foregroundStyle(Color.cohSecondary)
                            }
                            Text(symbol + fmt(fairB))
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(blueColor)
                            Text(strings.expensePctOfIncome(100 - pctA))
                                .font(.caption).foregroundStyle(Color.cohMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    // One-tap: apply the income-proportional split to every
                    // expense row paid by "both".
                    Button { applyIncomeSplit() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.and.right")
                                .font(.caption)
                            Text(strings.expenseApplyIncomeSplit)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Color.cohGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.cohGreen.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(isReadOnly)
                    if abs(adjustment) >= 1 {
                        let over = adjustment > 0 ? nameA : nameB
                        // Tappable — expands into a plain-language explanation
                        // of what the income-based split means.
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                withAnimation(.spring(duration: 0.25)) { showFairInfo.toggle() }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "info.circle").font(.caption2).foregroundStyle(Color.cohSecondary)
                                    Text(strings.expensePaysMoreThanFair(over, symbol + fmt(abs(adjustment))))
                                        .font(.caption).foregroundStyle(Color.cohSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                    Image(systemName: showFairInfo ? "chevron.up" : "chevron.down")
                                        .font(.caption2.bold()).foregroundStyle(Color.cohTertiary)
                                }
                            }
                            .buttonStyle(.plain)

                            if showFairInfo {
                                Text(strings.expenseFairSplitExplanation(pctA, 100 - pctA))
                                    .font(.caption).foregroundStyle(Color.cohMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                }
            }

            // Left over after bills — income minus each partner's borne share
            if totalIncome > 0 {
                Divider()
                HStack {
                    leftoverView(nameA, income: iA, share: t.shareA, color: Color.cohGreen)
                    Spacer()
                    leftoverView(nameB, income: iB, share: t.shareB, color: blueColor)
                }
            }

            // Save to overview
            if household != nil {
                Divider()
                Button { saveToOverview() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: savedBudget ? "checkmark.circle.fill" : "square.and.arrow.down")
                        Text(savedBudget ? strings.expenseSavedToOverview : strings.expenseSaveToOverview)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(savedBudget ? Color.cohGreen : Color.cohSecondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 11)
                    .background(
                        savedBudget ? Color.cohGreen.opacity(0.08) : Color(.systemGray6),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isReadOnly)
                .animation(.spring(duration: 0.3), value: savedBudget)
            }
        }
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
    }

    private func payoutPanel(_ name: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.caption.weight(.semibold)).foregroundStyle(color)
            Text(strings.expensePaysOut).font(.caption).foregroundStyle(Color.cohSecondary)
            Text(symbol + fmt(amount))
                .font(.title3.bold().monospacedDigit()).foregroundStyle(Color.cohInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }

    private func leftoverView(_ name: String, income: Double, share: Double, color: Color) -> some View {
        let left = income - share
        return VStack(alignment: .leading, spacing: 3) {
            Text(strings.expenseLeftOver(name)).font(.caption).foregroundStyle(Color.cohSecondary)
            Text(symbol + fmt(max(0, left)))
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(left >= 0 ? color : Color.red)
        }
    }

    // MARK: Helpers

    /// Applies the income-proportional split to every row paid by "both" —
    /// preset rows via working-state sync, individual expenses via the store.
    private func applyIncomeSplit() {
        guard totalIncome > 0 else { return }
        let share = iA / totalIncome
        for i in 0..<5 where presetPays[i] == "both" {
            presetSplits[i] = share   // .onChange → persistWorkingState pushes
        }
        for e in store.expenses where e.paidByKey == "both" {
            Task {
                try? await store.updateExpense(e.id, amount: e.amount,
                                               paidByKey: e.paidByKey,
                                               splitRatioA: share)
            }
        }
    }

    /// Toggles the dashboard visibility of the budget card and pushes the
    /// flag to Supabase so the partner's dashboard matches.
    private func toggleBudgetHidden() {
        guard let h = household else { return }
        h.budgetHidden.toggle()
        try? modelContext.save()
        guard h.hasBudget, let savedAt = h.budgetSavedAt else { return }
        Task {
            try? await SupabaseService.updateHouseholdBudget(
                householdId: h.id,
                incomeA: h.budgetIncomeA, incomeB: h.budgetIncomeB,
                totalExpenses: h.budgetTotalExpenses, splitA: h.budgetSplitA,
                paysA: h.budgetPaysA, paysB: h.budgetPaysB,
                netTransfer: h.budgetNetTransfer, savedAt: savedAt,
                hidden: h.budgetHidden
            )
        }
    }

    private func saveToOverview() {
        guard let h = household else { return }
        let t = totals
        let total = t.paysA + t.paysB
        let now = Date()
        h.budgetIncomeA     = iA          // stored as MONTHLY net income
        h.budgetIncomeB     = iB
        h.budgetTotalExpenses = total
        h.budgetSplitA      = total > 0 ? t.paysA / total : 0.5
        h.budgetPaysA       = t.paysA
        h.budgetPaysB       = t.paysB
        h.budgetNetTransfer = t.netTransfer   // + = B owes A, − = A owes B
        h.budgetFairnessMode = "custom"
        h.budgetSavedAt     = now
        try? modelContext.save()
        // Push the snapshot to Supabase so the partner's dashboard matches.
        Task {
            try? await SupabaseService.updateHouseholdBudget(
                householdId: h.id,
                incomeA: iA, incomeB: iB, totalExpenses: total,
                splitA: h.budgetSplitA, paysA: t.paysA, paysB: t.paysB,
                netTransfer: t.netTransfer, savedAt: now,
                hidden: h.budgetHidden
            )
        }
        withAnimation { savedBudget = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedBudget = false }
        }
    }

    private func cardShell<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
            content()
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func payerName(_ key: String) -> String {
        switch key {
        case "a": return nameA
        case "b": return nameB
        default:  return strings.expenseBoth
        }
    }

    /// Parses a typed/formatted amount. Strips grouping separators — commas
    /// (en) and spaces incl. non-breaking (nb/sv) — so locale-formatted values
    /// round-trip correctly (e.g. "12,000" and "12 000" both parse to 12000).
    private func parse(_ s: String) -> Double { parseExpenseAmount(s) }
    private func fmt(_ v: Double) -> String {
        fmtGroupedAmount(v, country: country)
    }
    private func fmtInc(_ v: Double) -> String { v == 0 ? "" : fmt(v) }
}

// MARK: - Shared amount helpers (Norwegian-tolerant)
//
// parseExpenseAmount lives in Core/Parsing.swift, shared across the app.

/// Formats for an editable amount field — round-trips through parseExpenseAmount.
private func fmtExpenseAmount(_ v: Double) -> String {
    let f = NumberFormatter(); f.numberStyle = .decimal
    f.maximumFractionDigits = 2; f.minimumFractionDigits = 0
    return f.string(from: NSNumber(value: v)) ?? "0"
}

/// Reusable A%/B% split slider shared by preset and custom expense rows.
private func expenseSplitSlider(ratioA: Binding<Double>, colorA: Color, colorB: Color,
                                nameA: String, nameB: String) -> some View {
    let pctA = Int((ratioA.wrappedValue * 100).rounded())
    return VStack(spacing: 4) {
        HStack {
            Text("\(nameA) \(pctA)%")
                .font(.caption2.weight(.semibold)).foregroundStyle(colorA)
            Spacer()
            Text("\(nameB) \(100 - pctA)%")
                .font(.caption2.weight(.semibold)).foregroundStyle(colorB)
        }
        Slider(value: ratioA, in: 0...1, step: 0.05)
            .tint(colorA)
    }
    .padding(.leading, 46)
}

// MARK: - Custom expense row (DB-backed, preset-styled)

/// Same visual language as the preset rows: icon circle, label, amount
/// capsule, payer pills and split slider. Edits are debounced and pushed to
/// Supabase so both partners always see identical numbers.
private struct CustomExpenseRow: View {
    let exp: DBExpense
    let nameA: String
    let nameB: String
    let symbol: String
    let store: HouseholdStore
    let onError: (String) -> Void

    @ObservedObject private var strings = AppStrings.shared
    @State private var amountText = ""
    @State private var pays = "a"
    @State private var splitA = 0.5
    @State private var lastLocalEdit = Date.distantPast
    @State private var pushTask: Task<Void, Never>?

    /// Partner deleted their account — row is display-only, nothing pushed.
    private var isReadOnly: Bool { store.household?.partnerLeftAt != nil }

    var body: some View {
        let blueColor = Color(red: 0.20, green: 0.49, blue: 0.96)
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Icon — same size/style as presets
                ZStack {
                    Circle().fill(Color.cohGreen.opacity(0.10)).frame(width: 34, height: 34)
                    Image(systemName: exp.isRecurring ? "arrow.clockwise" : "banknote.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.cohGreen)
                }
                // Label — same width as preset names
                Text(exp.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.cohInk)
                    .lineLimit(1)
                    .frame(width: 72, alignment: .leading)
                // Amount capsule
                HStack(spacing: 2) {
                    Text(symbol).font(.caption).foregroundStyle(Color.cohSecondary)
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.subheadline.monospacedDigit())
                        .frame(maxWidth: .infinity)
                        .disabled(isReadOnly)
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                // Payer pills — A / Both / B
                HStack(spacing: 4) {
                    pill(nameA, key: "a", color: Color.cohGreen)
                    pill(strings.expenseBoth, key: "both", color: Color.cohInk)
                    pill(nameB, key: "b", color: blueColor)
                }
                .disabled(isReadOnly)
                // Delete — subtle, same tertiary tone as the rest of the app
                Button {
                    Task {
                        do { try await store.deleteExpense(exp.id) }
                        catch { onError(error.localizedDescription) }
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption).foregroundStyle(Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .disabled(isReadOnly)
            }
            if pays == "both" {
                expenseSplitSlider(ratioA: $splitA, colorA: Color.cohGreen, colorB: blueColor,
                                   nameA: nameA, nameB: nameB)
                .disabled(isReadOnly)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 10)
        .animation(.spring(duration: 0.3), value: pays)
        .onAppear { apply(exp) }
        .onChange(of: exp.amount) { _, _ in refreshIfRemote(exp) }
        .onChange(of: exp.paidByKey) { _, _ in refreshIfRemote(exp) }
        .onChange(of: exp.splitRatioA) { _, _ in refreshIfRemote(exp) }
        .onChange(of: amountText) { _, _ in schedulePush() }
        .onChange(of: pays) { _, _ in schedulePush() }
        .onChange(of: splitA) { _, _ in schedulePush() }
    }

    private func pill(_ name: String, key: String, color: Color) -> some View {
        Button {
            pays = key
        } label: {
            Text(String(name.prefix(1)).uppercased())
                .font(.caption2.bold())
                .foregroundStyle(pays == key ? .white : color)
                .frame(width: 24, height: 24)
                .background(pays == key ? color : color.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func apply(_ e: DBExpense) {
        amountText = e.amount > 0 ? fmtExpenseAmount(e.amount) : ""
        pays = e.paidByKey
        splitA = e.splitRatioA
    }

    /// Remote edit from the partner — adopt unless we typed more recently.
    private func refreshIfRemote(_ e: DBExpense) {
        guard Date().timeIntervalSince(lastLocalEdit) > 2 else { return }
        apply(e)
    }

    /// Debounced push; no-ops when the fields still match the server row
    /// (e.g. the assignments in apply() re-triggering onChange).
    private func schedulePush() {
        let amount = parseExpenseAmount(amountText)
        guard amount != exp.amount || pays != exp.paidByKey || splitA != exp.splitRatioA
        else { return }
        lastLocalEdit = Date()
        pushTask?.cancel()
        let payer = pays, split = splitA, id = exp.id
        pushTask = Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            do {
                try await store.updateExpense(id, amount: amount,
                                              paidByKey: payer, splitRatioA: split)
            } catch {
                onError(error.localizedDescription)
            }
        }
    }
}

// MARK: - Add Expense Sheet

struct AddExpenseSheet: View {
    let nameA: String
    let nameB: String
    let symbol: String
    let onSave: (String, Double, String, Double, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var strings = AppStrings.shared
    @State private var selectedCategory: String? = nil   // holds preset.key
    @State private var label = ""
    @State private var amountText = ""
    @State private var paidByKey = "a"                    // "a" | "b" | "both"
    @State private var splitA: Double = 0.5               // A's share when "both"
    @State private var isRecurring = true

    private struct ExpensePreset {
        let key: String          // stable identity, language-independent
        let icon: String
        let title: String        // localized display name
    }

    private var presets: [ExpensePreset] {
        [
            .init(key: "rent",        icon: "house.fill",  title: strings.expenseCatRent),
            .init(key: "electricity", icon: "bolt.fill",   title: strings.expenseCatElectricity),
            .init(key: "internet",    icon: "wifi",        title: strings.expenseCatInternet),
            .init(key: "groceries",   icon: "cart.fill",   title: strings.expenseCatGroceries),
            .init(key: "streaming",   icon: "play.tv.fill",title: strings.expenseCatStreaming),
            .init(key: "transport",   icon: "car.fill",    title: strings.expenseCatTransport),
            .init(key: "insurance",   icon: "heart.fill",  title: strings.expenseCatInsurance),
            .init(key: "custom",      icon: "pencil",      title: strings.expenseCatCustom),
        ]
    }

    private var blueColor: Color { Color(red: 0.20, green: 0.49, blue: 0.96) }
    private var amount: Double { parseExpenseAmount(amountText) }
    private var canSave: Bool { !label.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0 }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Category chips
                    categoryPicker
                    // Label field — always visible
                    labelCard
                    // Amount — appears once label non-empty
                    if !label.trimmingCharacters(in: .whitespaces).isEmpty {
                        amountCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    // Who pays + recurring — appears once amount > 0
                    if amount > 0 {
                        whoPaysCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        recurringCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: label.isEmpty)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: amount > 0)
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle(strings.expenseAddTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(strings.cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.add) {
                        onSave(label.trimmingCharacters(in: .whitespaces), amount,
                               paidByKey, paidByKey == "both" ? splitA : 0.5, isRecurring)
                        dismiss()
                    }
                    .bold()
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: Category picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(presets, id: \.key) { preset in
                    let selected = selectedCategory == preset.key
                    Button {
                        selectedCategory = preset.key
                        label = preset.key == "custom" ? "" : preset.title
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(selected ? Color.cohGreen : Color.cohCard)
                                    .frame(width: 48, height: 48)
                                    .shadow(color: .black.opacity(selected ? 0 : 0.05), radius: 4, y: 2)
                                Image(systemName: preset.icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(selected ? .white : Color.cohGreen)
                            }
                            Text(preset.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(selected ? Color.cohGreen : Color.cohInk)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    // MARK: Cards

    private var labelCard: some View {
        cardShell(strings.expenseWhatIsIt) {
            TextField(strings.expenseWhatPlaceholder, text: $label)
                .font(.body)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var amountCard: some View {
        cardShell(strings.expenseAmountTitle) {
            HStack {
                Text(symbol).foregroundStyle(Color.cohSecondary).font(.body)
                TextField("0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.title3.weight(.semibold).monospacedDigit())
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var whoPaysCard: some View {
        cardShell(strings.expenseWhoPays) {
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    payerButton(name: nameA, key: "a", color: Color.cohGreen)
                    payerButton(name: strings.expenseBoth, key: "both", color: Color.cohInk)
                    payerButton(name: nameB, key: "b", color: blueColor)
                }
                if paidByKey == "both" {
                    splitControl
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.spring(duration: 0.3), value: paidByKey)
        }
    }

    private var splitControl: some View {
        let pctA = Int((splitA * 100).rounded())
        return VStack(spacing: 6) {
            HStack {
                Text("\(nameA) \(pctA)%")
                    .font(.caption.weight(.semibold)).foregroundStyle(Color.cohGreen)
                Spacer()
                Text("\(nameB) \(100 - pctA)%")
                    .font(.caption.weight(.semibold)).foregroundStyle(blueColor)
            }
            Slider(value: $splitA, in: 0...1, step: 0.05).tint(Color.cohGreen)
        }
    }

    private var recurringCard: some View {
        cardShell(strings.expenseRecurringTitle) {
            Toggle(strings.expenseRecurringToggle, isOn: $isRecurring)
                .font(.subheadline)
        }
    }

    // MARK: Helpers

    private func payerButton(name: String, key: String, color: Color) -> some View {
        Button { paidByKey = key } label: {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(paidByKey == key ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(paidByKey == key ? color : color.opacity(0.1),
                             in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func cardShell<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
            content()
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

#Preview {
    NavigationStack {
        ExpenseSplitView(nameA: "John", nameB: "Sara", symbol: "£")
    }
}
