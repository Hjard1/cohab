import SwiftUI

/// Calculates the fair ownership split given each party's deposit and
/// share of loan responsibility.
///
/// Formula: fair share A = (depositA + loan × loanShareA) / (totalDeposits + loan)
struct OwnershipCalculatorView: View {
    @State private var purchasePrice = ""
    @State private var purchaseCosts = ""
    @State private var depositA = ""
    @State private var depositB = ""
    @State private var loanShareA = 50.0

    private var price: Double { parse(purchasePrice) }
    private var costs: Double { parse(purchaseCosts) }
    private var dA: Double { parse(depositA) }
    private var dB: Double { parse(depositB) }

    private var totalCost: Double { price + costs }
    private var totalDeposits: Double { dA + dB }
    private var loanAmount: Double { max(0, totalCost - totalDeposits) }
    private var loanShareAFraction: Double { loanShareA / 100 }

    private var contribA: Double { dA + loanAmount * loanShareAFraction }
    private var contribB: Double { dB + loanAmount * (1 - loanShareAFraction) }
    private var totalContrib: Double { contribA + contribB }

    private var fairShareA: Double { totalContrib > 0 ? contribA / totalContrib : 0.5 }
    private var fairShareB: Double { 1 - fairShareA }

    private var hasInput: Bool { price > 0 }

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
        .navigationTitle("Ownership share")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            cardSection("Purchase") {
                inputRow("Purchase price", placeholder: "350,000", binding: $purchasePrice)
                inputRow("Purchase costs (legal, stamp duty…)", placeholder: "5,000", binding: $purchaseCosts)
            }
            cardSection("Deposits") {
                inputRow("Partner A deposit", placeholder: "30,000", binding: $depositA)
                inputRow("Partner B deposit", placeholder: "20,000", binding: $depositB)
            }
            cardSection("Loan split") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Partner A responsible for")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text(String(format: "%.0f%%", loanShareA))
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(.green)
                    }
                    Slider(value: $loanShareA, in: 0...100, step: 1)
                        .tint(.green)
                    if loanAmount > 0 {
                        Text("Loan: \(fmt(loanAmount)) (auto-calculated from price − deposits)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fair ownership")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                ownershipBar(label: "Partner A", share: fairShareA, color: .green)
                ownershipBar(label: "Partner B", share: fairShareB, color: .blue)
            }

            shareBar

            VStack(alignment: .leading, spacing: 8) {
                detailRow("Partner A total stake", fmt(contribA))
                detailRow("Partner B total stake", fmt(contribB))
                detailRow("Total to finance", fmt(totalCost))
            }
            .padding(16)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

            Text("These percentages are what each party should own based on financial contribution. Register them as the deed ownership to make the settlement calculation accurate.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    private func ownershipBar(label: String, share: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(String(format: "%.1f%%", share * 100))
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private var shareBar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.green.opacity(0.7))
                    .frame(width: geo.size.width * fairShareA - 1)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.blue.opacity(0.7))
            }
        }
        .frame(height: 8)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value).font(.caption.bold().monospacedDigit()).foregroundStyle(.white)
        }
    }

    private func cardSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(.white.opacity(0.35))
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func parse(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

#Preview { NavigationStack { OwnershipCalculatorView() } }
