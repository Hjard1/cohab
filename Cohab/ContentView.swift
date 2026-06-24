import SwiftUI

struct ContentView: View {
    private let result = SettlementEngine.settle(.demo)

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.05).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("COHAB")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .tracking(4)
                        .foregroundStyle(.green)

                    Text("What you own,\ntogether.")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 20)

                    Text("Track who owns what, who contributed what, and what's "
                         + "fair if you split or change your ownership share.")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.top, 16)

                    Text(positioningLine)
                        .font(.callout)
                        .padding(.leading, 14)
                        .overlay(alignment: .leading) {
                            Rectangle().fill(.green.opacity(0.6)).frame(width: 2)
                        }
                        .padding(.top, 32)

                    settlementCard
                        .padding(.top, 36)
                }
                .padding(28)
            }
        }
    }

    private var positioningLine: AttributedString {
        var spent = AttributedString("Splitwise tracks what you spent. ")
        spent.foregroundColor = .white.opacity(0.4)
        var own = AttributedString("cohab tracks what you own.")
        own.foregroundColor = .white.opacity(0.85)
        return spent + own
    }

    private var settlementCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settlement preview")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Demo: net \(money(result.netProceeds)) split after contributions + interest")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.5))

            Divider().overlay(.white.opacity(0.1))

            payoutRow("Partner A", result.payout[.a] ?? 0)
            payoutRow("Partner B", result.payout[.b] ?? 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }

    private func payoutRow(_ name: String, _ value: Double) -> some View {
        HStack {
            Text(name).foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(money(value))
                .foregroundStyle(.white)
                .monospacedDigit()
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func money(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "£" + (formatter.string(from: NSNumber(value: value)) ?? "0")
    }
}

extension SettlementInput {
    /// An illustrative scenario so the scaffold shows live engine output.
    static var demo: SettlementInput {
        let now = Date()
        let year = 365.25 * 24.0 * 60 * 60
        return SettlementInput(
            salePrice: 450_000,
            remainingLoan: 300_000,
            salesCosts: 8_000,
            ownershipShareA: 0.5,
            annualRate: 0.05,
            contributions: [
                Contribution(owner: .a, amount: 40_000, date: now.addingTimeInterval(-3 * year), label: "Deposit"),
                Contribution(owner: .b, amount: 25_000, date: now.addingTimeInterval(-3 * year), label: "Deposit"),
                Contribution(owner: .a, amount: 15_000, date: now.addingTimeInterval(-1 * year), label: "Kitchen renovation"),
            ],
            settlementDate: now
        )
    }
}

#Preview {
    ContentView()
}
