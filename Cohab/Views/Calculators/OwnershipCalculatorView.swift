import SwiftUI

struct OwnershipCalculatorView: View {
    let nameA: String
    let nameB: String
    let symbol: String
    let country: String

    @ObservedObject private var strings = AppStrings.shared

    init(nameA: String = "Partner A", nameB: String = "Partner B", symbol: String = "£", country: String = "GB") {
        self.nameA = nameA; self.nameB = nameB; self.symbol = symbol; self.country = country
    }

    @State private var purchasePrice = ""
    @State private var purchaseCosts = ""
    @State private var depositA = ""
    @State private var depositB = ""
    @State private var loanShareA = 50.0

    private var price:  Double { parse(purchasePrice) }
    private var costs:  Double { parse(purchaseCosts) }
    private var dA:     Double { parse(depositA) }
    private var dB:     Double { parse(depositB) }

    private var totalCost:    Double { price + costs }
    private var totalDeps:    Double { dA + dB }
    private var loanAmount:   Double { max(0, totalCost - totalDeps) }
    private var loanFracA:    Double { loanShareA / 100 }

    private var contribA:     Double { dA + loanAmount * loanFracA }
    private var contribB:     Double { dB + loanAmount * (1 - loanFracA) }
    private var totalContrib: Double { contribA + contribB }

    private var fairShareA: Double { totalContrib > 0 ? contribA / totalContrib : 0.5 }
    private var fairShareB: Double { 1 - fairShareA }
    private var hasInput:   Bool   { price > 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                resultCard
                inputCard(strings.calcOwnPurchaseSection) {
                    inputRow(strings.calcOwnPurchasePrice, placeholder: "350,000", text: $purchasePrice)
                    inputRow(strings.calcOwnPurchaseCosts, placeholder: "5,000", text: $purchaseCosts)
                }
                inputCard(strings.calcOwnDepositsSection) {
                    inputRow(strings.calcOwnDeposit(nameA), placeholder: "30,000", text: $depositA)
                    inputRow(strings.calcOwnDeposit(nameB), placeholder: "20,000", text: $depositB)
                }
                inputCard(strings.calcOwnLoanSection) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(strings.calcOwnResponsibleFor(nameA))
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(String(format: "%.0f%%", loanShareA))
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(Color.cohGreen)
                        }
                        Slider(value: $loanShareA, in: 0...100, step: 1)
                            .tint(.cohGreen)
                        if loanAmount > 0 {
                            Text(strings.calcOwnLoanNote(fmt(loanAmount)))
                                .font(.subheadline)
                                .foregroundStyle(Color.cohSecondary)
                        }
                    }
                }
                if hasInput { detailsCard }
            }
            .padding(20)
        }
        .background(Color.cohBg.ignoresSafeArea())
        .navigationTitle(strings.calcOwnershipTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Result card (always visible)

    private var resultCard: some View {
        VStack(spacing: 16) {
            Text(strings.calcOwnFairSplit)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.cohSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                shareColumn(nameA, share: hasInput ? fairShareA : 0.5, color: .cohGreen)
                shareColumn(nameB, share: hasInput ? fairShareB : 0.5,
                            color: Color(red: 0.20, green: 0.49, blue: 0.96))
            }

            // Visual bar
            GeometryReader { g in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.cohGreen)
                        .frame(width: max(8, g.size.width * (hasInput ? fairShareA : 0.5) - 1.5))
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(red: 0.20, green: 0.49, blue: 0.96))
                }
            }
            .frame(height: 10)

            if !hasInput {
                Text(strings.calcOwnEnterValues)
                    .font(.subheadline)
                    .foregroundStyle(Color.cohSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
    }

    private func shareColumn(_ name: String, share: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f%%", share * 100))
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(hasInput ? color : Color.cohTertiary)
            Text(name)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.cohSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(hasInput ? 0.08 : 0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private var detailsCard: some View {
        VStack(spacing: 10) {
            detailRow(strings.calcOwnTotalStake(nameA),  fmt(contribA))
            detailRow(strings.calcOwnTotalStake(nameB),  fmt(contribB))
            Color(.separator).frame(height: 0.5)
            detailRow(strings.calcOwnTotalToFinance,       fmt(totalCost))
            if loanAmount > 0 {
                detailRow(strings.calcOwnAutoLoan, fmt(loanAmount))
            }
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
    }

    // MARK: Shared helpers

    private func inputCard<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
            content()
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func inputRow(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption.weight(.medium)).foregroundStyle(Color.cohSecondary)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .font(.subheadline.monospacedDigit())
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Color.cohSecondary)
            Spacer()
            Text(value).font(.subheadline.bold().monospacedDigit())
        }
    }

    private func parse(_ s: String) -> Double { parseExpenseAmount(s) }
    private func fmt(_ v: Double) -> String {
        fmtGroupedAmount(v, country: country)
    }
}

#Preview { NavigationStack { OwnershipCalculatorView(nameA: "Sarah", nameB: "James") } }
