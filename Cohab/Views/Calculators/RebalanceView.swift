import SwiftUI

/// Calculates how much needs to be paid to move from the current registered
/// ownership split to a target split, with an optional amortization plan.
///
/// Payment = netEquity × (targetShareA − currentShareA)
/// Positive: B pays A. Negative: A pays B.
struct RebalanceView: View {
    @State private var valueText = ""
    @State private var loanText = ""
    @State private var currentShareA = 50.0
    @State private var targetShareA = 50.0
    @State private var showPlan = false
    @State private var rateText = "5.0"
    @State private var yearsText = "5"

    private var value: Double { parse(valueText) }
    private var loan: Double { parse(loanText) }
    private var netEquity: Double { max(0, value - loan) }

    private var payment: Double { netEquity * (targetShareA - currentShareA) / 100 }
    private var absPayment: Double { abs(payment) }

    private var monthlyPayment: Double? {
        guard showPlan, absPayment > 0 else { return nil }
        let r = (parse(rateText) / 100) / 12
        let n = Double(Int(parse(yearsText)) * 12)
        guard r > 0, n > 0 else { return absPayment / (n > 0 ? n : 1) }
        return absPayment * r * pow(1 + r, n) / (pow(1 + r, n) - 1)
    }

    private var hasInput: Bool { value > 0 }
    private var hasChange: Bool { abs(payment) > 0.5 }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.05).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    inputSection
                    if hasInput { resultSection }
                }
                .padding(24)
            }
        }
        .navigationTitle("Rebalance ownership")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            cardSection("Property") {
                inputRow("Current market value", placeholder: "450,000", binding: $valueText)
                inputRow("Remaining loan", placeholder: "300,000", binding: $loanText)
                if value > 0 {
                    HStack {
                        Text("Net equity").font(.caption).foregroundStyle(.white.opacity(0.4))
                        Spacer()
                        Text(fmt(netEquity))
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(netEquity >= 0 ? .green : .orange)
                    }
                }
            }

            cardSection("Current registered ownership") {
                sliderRow("Partner A currently owns", value: $currentShareA)
            }

            cardSection("Target ownership") {
                sliderRow("Partner A should own", value: $targetShareA)
            }
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Result")
                .font(.headline)
                .foregroundStyle(.white)

            if hasChange {
                let fromName = payment > 0 ? "Partner B" : "Partner A"
                let toName = payment > 0 ? "Partner A" : "Partner B"

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(fromName) pays \(toName)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(fmt(absPayment))
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                    Text(String(format: "Moving from %.0f%%/%.0f%% to %.0f%%/%.0f%%",
                                currentShareA, 100 - currentShareA,
                                targetShareA, 100 - targetShareA))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))

                Toggle(isOn: $showPlan.animation()) {
                    Text("Show payment plan")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .tint(.green)

                if showPlan {
                    paymentPlanSection
                }
            } else {
                Text("Ownership is already balanced at \(String(format: "%.0f", currentShareA))% / \(String(format: "%.0f", 100 - currentShareA))%.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private var paymentPlanSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardSection("Plan parameters") {
                inputRow("Annual interest rate (%)", placeholder: "5.0", binding: $rateText)
                inputRow("Years to repay", placeholder: "5", binding: $yearsText)
            }
            if let monthly = monthlyPayment {
                let n = max(1, Int(parse(yearsText)) * 12)
                let total = monthly * Double(n)
                VStack(alignment: .leading, spacing: 8) {
                    detailRow("Monthly payment", fmt(monthly))
                    detailRow("Total paid", fmt(total))
                    detailRow("Total interest", fmt(total - absPayment))
                }
                .padding(16)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func sliderRow(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(String(format: "%.0f%%", value.wrappedValue))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.green)
            }
            Slider(value: value, in: 0...100, step: 1).tint(.green)
        }
    }

    private func detailRow(_ label: String, _ val: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(val).font(.caption.bold().monospacedDigit()).foregroundStyle(.white)
        }
    }

    private func cardSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased()).font(.caption.bold()).tracking(1).foregroundStyle(.white.opacity(0.35))
            content()
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    private func inputRow(_ label: String, placeholder: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.5))
            TextField(placeholder, text: binding)
                .keyboardType(.decimalPad)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func parse(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: "")) ?? 0 }
    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

#Preview { NavigationStack { RebalanceView() } }
