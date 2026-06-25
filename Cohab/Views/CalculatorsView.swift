import SwiftUI

struct CalculatorsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    calcCard(
                        icon: "chart.pie.fill",
                        color: .cohGreen,
                        title: "Ownership share",
                        subtitle: "What % should each partner own given their deposits and loan responsibility?",
                        destination: { OwnershipCalculatorView() }
                    )
                    calcCard(
                        icon: "arrow.left.arrow.right.circle.fill",
                        color: Color(red: 0.20, green: 0.49, blue: 0.96),
                        title: "Expense split",
                        subtitle: "Find a fair monthly split based on income — weighted or equal disposable income.",
                        destination: { ExpenseSplitView() }
                    )
                    calcCard(
                        icon: "scalemass.fill",
                        color: Color(red: 0.93, green: 0.50, blue: 0.18),
                        title: "Rebalance ownership",
                        subtitle: "How much to pay to reach a new ownership split, with an optional payment plan.",
                        destination: { RebalanceView() }
                    )
                }
                .padding(20)
                .padding(.top, 8)
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Calculators")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                }
            }
        }
    }

    private func calcCard<Dest: View>(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        @ViewBuilder destination: () -> Dest
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.1))
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(18)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
        }
    }
}

#Preview { CalculatorsView() }
