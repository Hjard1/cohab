import SwiftUI

struct OwnershipCalculatorView: View {
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
                inputCard("PURCHASE") {
                    inputRow("Purchase price",           placeholder: "350,000", text: $purchasePrice)
                    inputRow("Purchase costs (stamp duty, legal…)", placeholder: "5,000", text: $purchaseCosts)
                }
                inputCard("DEPOSITS") {
                    inputRow("Partner A deposit", placeholder: "30,000", text: $depositA)
                    inputRow("Partner B deposit", placeholder: "20,000", text: $depositB)
                }
                inputCard("LOAN RESPONSIBILITY") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Partner A responsible for")
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
                            Text("Loan: \(fmt(loanAmount)) (price + costs − deposits)")
                                .font(.caption)
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                    }
                }
                if hasInput { detailsCard }
            }
            .padding(20)
        }
        .background(Color.cohBg.ignoresSafeArea())
        .navigationTitle("Ownership share")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Result card (always visible)

    private var resultCard: some View {
        VStack(spacing: 16) {
            Text("Fair ownership split")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                shareColumn("Partner A", share: hasInput ? fairShareA : 0.5, color: .cohGreen)
                shareColumn("Partner B", share: hasInput ? fairShareB : 0.5,
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
                Text("Enter values above to calculate your fair ownership split.")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
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
                .foregroundStyle(hasInput ? color : Color(.tertiaryLabel))
            Text(name)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(hasInput ? 0.08 : 0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private var detailsCard: some View {
        VStack(spacing: 10) {
            detailRow("Partner A total stake",  fmt(contribA))
            detailRow("Partner B total stake",  fmt(contribB))
            Color(.separator).frame(height: 0.5)
            detailRow("Total to finance",       fmt(totalCost))
            if loanAmount > 0 {
                detailRow("Auto-calculated loan", fmt(loanAmount))
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
                .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
            content()
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func inputRow(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .font(.subheadline.monospacedDigit())
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.bold().monospacedDigit())
        }
    }

    private func parse(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: "")) ?? 0 }
    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

#Preview { NavigationStack { OwnershipCalculatorView() } }
