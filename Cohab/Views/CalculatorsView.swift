import SwiftUI

struct CalculatorsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    calcCard(
                        icon: "person.2.fill",
                        color: Color.cohGreen,
                        title: "Ownership split",
                        subtitle: "Calculate equity based on deposits and payments.",
                        destination: { OwnershipCalculatorView() }
                    )
                    calcCard(
                        icon: "dollarsign.circle.fill",
                        color: Color(red: 0.20, green: 0.49, blue: 0.96),
                        title: "Expense split",
                        subtitle: "Fairly divide monthly household costs.",
                        destination: { ExpenseSplitView() }
                    )
                    calcCard(
                        icon: "xmark.circle.fill",
                        color: Color(red: 0.93, green: 0.50, blue: 0.18),
                        title: "Rebalance",
                        subtitle: "See what it takes to reach 50/50 ownership.",
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
                        .foregroundStyle(Color.cohInk)
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
                        .fill(color.opacity(0.10))
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.cohInk)
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
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }
}

#Preview { CalculatorsView() }
