import SwiftUI
import SwiftData

// MARK: - Expense Split View (persistent, Supabase-backed)

struct ExpenseSplitView: View {
    let nameA: String
    let nameB: String
    let symbol: String

    @Query private var households: [Household]
    private var household: Household? { households.first }
    @Environment(HouseholdStore.self) private var store
    @ObservedObject private var strings = AppStrings.shared

    @State private var incomeAText = ""
    @State private var incomeBText = ""
    @State private var showAdd = false
    @State private var savedBudget = false
    @State private var deleteError: String?

    init(nameA: String = "Partner A", nameB: String = "Partner B", symbol: String = "£") {
        self.nameA = nameA; self.nameB = nameB; self.symbol = symbol
    }

    // MARK: Calculations

    private var iA: Double { parse(incomeAText) }
    private var iB: Double { parse(incomeBText) }
    private var totalIncome: Double { iA + iB }

    private struct Totals {
        var paysA, paysB, netAtoB, netBtoA: Double
        var netTransfer: Double { netBtoA - netAtoB }   // + = B owes A, - = A owes B
    }

    private var totals: Totals {
        var t = Totals(paysA: 0, paysB: 0, netAtoB: 0, netBtoA: 0)
        for e in store.expenses {
            let shareA = e.amount * e.splitRatioA
            let shareB = e.amount * (1 - e.splitRatioA)
            if e.paidByKey == "a" {
                t.paysA += e.amount
                t.netBtoA += shareB      // B owes A for B's share of an A-paid expense
            } else {
                t.paysB += e.amount
                t.netAtoB += shareA      // A owes B for A's share of a B-paid expense
            }
        }
        return t
    }

    // MARK: Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                incomeCard
                expensesCard
                if !store.expenses.isEmpty { resultCard }
            }
            .padding(20)
            .animation(.spring(duration: 0.35), value: store.expenses.count)
        }
        .background(Color.cohBg.ignoresSafeArea())
        .navigationTitle(strings.calcExpenseTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) {
            AddExpenseSheet(nameA: nameA, nameB: nameB, symbol: symbol) { label, amount, paidBy, splitA, recurring in
                Task {
                    try? await store.addExpense(
                        label: label, amount: amount, paidByKey: paidBy,
                        splitRatioA: splitA, date: Date(),
                        category: "other", isRecurring: recurring
                    )
                }
            }
        }
        .onAppear {
            if let h = household {
                if h.budgetIncomeA > 0 { incomeAText = fmtInc(h.budgetIncomeA * 12) }
                if h.budgetIncomeB > 0 { incomeBText = fmtInc(h.budgetIncomeB * 12) }
            }
        }
    }

    // MARK: Income card

    private var incomeCard: some View {
        cardShell("MONTHLY NET INCOME") {
            VStack(spacing: 12) {
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
                Text(symbol).foregroundStyle(.secondary).font(.subheadline)
                TextField("0", text: text).keyboardType(.decimalPad)
                    .font(.subheadline.monospacedDigit())
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: Expenses card

    private var expensesCard: some View {
        cardShell("MONTHLY EXPENSES") {
            VStack(spacing: 0) {
                if store.expenses.isEmpty {
                    emptyExpenses
                } else {
                    ForEach(store.expenses) { exp in
                        expenseRow(exp)
                        if exp.id != store.expenses.last?.id {
                            Divider().padding(.leading, 4)
                        }
                    }
                }

                Button {
                    showAdd = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Color.cohGreen)
                        Text("Add expense")
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
                .padding(.top, store.expenses.isEmpty ? 0 : 12)
            }
        }
    }

    private var emptyExpenses: some View {
        VStack(spacing: 10) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color(.tertiaryLabel))
            Text("Add your shared monthly costs — rent, utilities, subscriptions…")
                .font(.caption).foregroundStyle(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func expenseRow(_ exp: DBExpense) -> some View {
        HStack(spacing: 10) {
            if exp.isRecurring {
                Image(systemName: "arrow.clockwise")
                    .font(.caption2).foregroundStyle(Color.cohGreen)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(exp.label).font(.subheadline.weight(.medium)).lineLimit(1)
                HStack(spacing: 4) {
                    Text("Paid by \(exp.paidByKey == "a" ? nameA : nameB)")
                    Text("·")
                    let pA = Int((exp.splitRatioA * 100).rounded())
                    Text("\(pA)% / \(100 - pA)%")
                }
                .font(.caption2).foregroundStyle(.secondary)
            }

            Spacer()

            Text(symbol + fmt(exp.amount))
                .font(.subheadline.bold().monospacedDigit())

            Button {
                Task { try? await store.deleteExpense(exp.id) }
            } label: {
                Image(systemName: "trash")
                    .font(.caption).foregroundStyle(Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }

    // MARK: Result card

    private var resultCard: some View {
        let t = totals
        let net = t.netTransfer   // + = B owes A, - = A owes B
        let blueColor = Color(red: 0.20, green: 0.49, blue: 0.96)

        return VStack(spacing: 14) {
            // Who physically pays out
            HStack(spacing: 12) {
                payoutPanel(nameA, amount: t.paysA, color: Color.cohGreen)
                payoutPanel(nameB, amount: t.paysB, color: blueColor)
            }

            Divider()

            // Net transfer
            if abs(net) >= 0.5 {
                let debtor  = net > 0 ? nameB : nameA
                let amount  = abs(net)
                HStack {
                    Image(systemName: "arrow.right.circle.fill").foregroundStyle(Color.cohGreen)
                    Text("\(debtor) owes \(symbol)\(fmt(amount))/month")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.cohGreen)
                    Text("Balanced — no transfer needed")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
            }

            // Left over (only when incomes are entered)
            if totalIncome > 0 {
                Divider()
                let effectivePayA = t.paysA - t.netBtoA + t.netAtoB  // what A actually ends up paying
                let effectivePayB = t.paysB - t.netAtoB + t.netBtoA
                HStack {
                    leftoverView(nameA, income: iA / 12, effectivePay: effectivePayA, color: Color.cohGreen)
                    Spacer()
                    leftoverView(nameB, income: iB / 12, effectivePay: effectivePayB, color: blueColor)
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
                    .foregroundStyle(savedBudget ? Color.cohGreen : Color(.secondaryLabel))
                    .frame(maxWidth: .infinity).padding(.vertical, 11)
                    .background(
                        savedBudget ? Color.cohGreen.opacity(0.08) : Color(.systemGray6),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
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
            Text("Pays out").font(.caption2).foregroundStyle(.secondary)
            Text(symbol + fmt(amount))
                .font(.title3.bold().monospacedDigit()).foregroundStyle(Color.cohInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }

    private func leftoverView(_ name: String, income: Double, effectivePay: Double, color: Color) -> some View {
        let left = income - effectivePay
        return VStack(alignment: .leading, spacing: 3) {
            Text("\(name) left over").font(.caption2).foregroundStyle(.secondary)
            Text(symbol + fmt(max(0, left)))
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(left >= 0 ? color : Color.red)
        }
    }

    // MARK: Helpers

    private func saveToOverview() {
        guard let h = household else { return }
        let t = totals
        let total = t.paysA + t.paysB
        h.budgetIncomeA     = iA / 12
        h.budgetIncomeB     = iB / 12
        h.budgetTotalExpenses = total
        h.budgetSplitA      = total > 0 ? t.paysA / total : 0.5
        h.budgetFairnessMode = "custom"
        h.budgetSavedAt     = Date()
        withAnimation { savedBudget = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedBudget = false }
        }
    }

    private func cardShell<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
            content()
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func parse(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: "")) ?? 0 }
    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
    private func fmtInc(_ v: Double) -> String { v == 0 ? "" : fmt(v) }
}

// MARK: - Add Expense Sheet

struct AddExpenseSheet: View {
    let nameA: String
    let nameB: String
    let symbol: String
    let onSave: (String, Double, String, Double, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var amountText = ""
    @State private var paidByKey = "a"
    @State private var splitA: Double = 0.5
    @State private var isRecurring = true

    private var blueColor: Color { Color(red: 0.20, green: 0.49, blue: 0.96) }
    private var pctA: Int { Int((splitA * 100).rounded()) }
    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Rent, Utilities, Netflix", text: $label)
                    HStack {
                        Text(symbol).foregroundStyle(.secondary)
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: { Text("EXPENSE") }

                Section {
                    Picker("Who pays it?", selection: $paidByKey) {
                        Text(nameA).tag("a")
                        Text(nameB).tag("b")
                    }
                    .pickerStyle(.segmented)
                    Text("The person who physically pays the bill.")
                        .font(.caption).foregroundStyle(.secondary)
                } header: { Text("WHO PAYS IT?") }

                Section {
                    VStack(spacing: 10) {
                        HStack {
                            HStack(spacing: 5) {
                                Circle().fill(Color.cohGreen).frame(width: 7, height: 7)
                                Text(nameA).font(.subheadline.weight(.medium))
                            }
                            Spacer()
                            Text("\(pctA)%")
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(Color.cohGreen)
                        }
                        Slider(value: $splitA, in: 0...1, step: 0.05).tint(Color.cohGreen)
                        HStack {
                            HStack(spacing: 5) {
                                Circle().fill(blueColor).frame(width: 7, height: 7)
                                Text(nameB).font(.subheadline.weight(.medium))
                            }
                            Spacer()
                            Text("\(100 - pctA)%")
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(blueColor)
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("COST SPLIT") }

                Section {
                    Toggle("Recurring monthly expense", isOn: $isRecurring)
                }
            }
            .navigationTitle("Add expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
                        onSave(label.trimmingCharacters(in: .whitespaces), amount, paidByKey, splitA, isRecurring)
                        dismiss()
                    }
                    .bold().disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExpenseSplitView(nameA: "John", nameB: "Sara", symbol: "£")
    }
}
