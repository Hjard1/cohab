import SwiftUI

struct RebalanceView: View {
    @State private var valueText    = ""
    @State private var loanText     = ""
    @State private var currentShareA = 50.0
    @State private var targetShareA  = 50.0
    @State private var showPlan      = false
    @State private var rateText      = "5.0"
    @State private var yearsText     = "5"

    private var value:      Double { parse(valueText) }
    private var loan:       Double { parse(loanText) }
    private var netEquity:  Double { max(0, value - loan) }
    private var payment:    Double { netEquity * (targetShareA - currentShareA) / 100 }
    private var absPayment: Double { abs(payment) }
    private var hasInput:   Bool   { value > 0 }
    private var hasChange:  Bool   { abs(payment) > 0.5 }

    private var monthlyPayment: Double? {
        guard showPlan, absPayment > 0 else { return nil }
        let r = (parse(rateText) / 100) / 12
        let n = Double(max(1, Int(parse(yearsText))) * 12)
        guard r > 0 else { return absPayment / n }
        return absPayment * r * pow(1 + r, n) / (pow(1 + r, n) - 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                resultCard
                inputCard("PROPERTY") {
                    inputRow("Current market value", placeholder: "450,000", text: $valueText)
                    inputRow("Remaining loan",        placeholder: "300,000", text: $loanText)
                    if value > 0 {
                        HStack {
                            Text("Net equity").font(.subheadline).foregroundStyle(.secondary)
                            Spacer()
                            Text(fmt(netEquity))
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(netEquity >= 0 ? Color.cohGreen : .red)
                        }
                    }
                }
                inputCard("CURRENT REGISTERED OWNERSHIP") {
                    sliderRow("Partner A currently owns", value: $currentShareA)
                }
                inputCard("TARGET OWNERSHIP") {
                    sliderRow("Partner A should own", value: $targetShareA)
                }
                if hasInput && hasChange { paymentPlanCard }
            }
            .padding(20)
        }
        .background(Color.cohBg.ignoresSafeArea())
        .navigationTitle("Rebalance ownership")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Result card

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rebalancing payment")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if hasInput && hasChange {
                let fromName = payment > 0 ? "Partner B" : "Partner A"
                let toName   = payment > 0 ? "Partner A" : "Partner B"

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(fmt(absPayment))
                            .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                        Text("from \(fromName) to \(toName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    }
                    Text(String(format: "Moves ownership from %.0f%%/%.0f%% → %.0f%%/%.0f%%",
                                currentShareA, 100 - currentShareA,
                                targetShareA, 100 - targetShareA))
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            } else if hasInput {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.cohGreen)
                    Text("Ownership is already balanced — no payment needed.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Enter a property value and adjust the sliders to see how much a rebalancing payment would be.")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
    }

    // MARK: Payment plan card

    private var paymentPlanCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PAYMENT PLAN")
                        .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
                    Text("Spread the payment over time")
                        .font(.caption).foregroundStyle(Color(.tertiaryLabel))
                }
                Spacer()
                Toggle("", isOn: $showPlan.animation())
                    .tint(.cohGreen)
                    .labelsHidden()
            }

            if showPlan {
                HStack(spacing: 12) {
                    inputRow("Annual rate (%)", placeholder: "5.0", text: $rateText)
                    inputRow("Years",           placeholder: "5",   text: $yearsText)
                }
                if let monthly = monthlyPayment {
                    let n     = max(1, Int(parse(yearsText)) * 12)
                    let total = monthly * Double(n)
                    VStack(spacing: 10) {
                        Color(.separator).frame(height: 0.5)
                        detailRow("Monthly payment",  fmt(monthly), bold: true)
                        detailRow("Total paid",       fmt(total))
                        detailRow("Total interest",   fmt(total - absPayment))
                    }
                }
            }
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: Helpers

    private func sliderRow(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(.subheadline).foregroundStyle(.primary)
                Spacer()
                Text(String(format: "%.0f%%", value.wrappedValue))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Color.cohGreen)
            }
            Slider(value: value, in: 0...100, step: 1).tint(.cohGreen)
        }
    }

    private func inputCard<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
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

    private func detailRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(bold ? .subheadline.bold().monospacedDigit() : .subheadline.monospacedDigit())
                .foregroundStyle(bold ? Color.cohGreen : .primary)
        }
    }

    private func parse(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: "")) ?? 0 }
    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

#Preview { NavigationStack { RebalanceView() } }
