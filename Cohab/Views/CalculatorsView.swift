import SwiftUI

struct CalculatorsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.05).ignoresSafeArea()
                List {
                    Section {
                        navRow(
                            icon: "chart.pie.fill",
                            color: .green,
                            title: "Ownership share",
                            subtitle: "What % should each own given your deposits and loan split?"
                        ) { OwnershipCalculatorView() }

                        navRow(
                            icon: "arrow.left.arrow.right.circle.fill",
                            color: .blue,
                            title: "Expense split",
                            subtitle: "Fair monthly split based on income — weighted or equal disposable"
                        ) { ExpenseSplitView() }

                        navRow(
                            icon: "scalemass.fill",
                            color: .orange,
                            title: "Rebalance ownership",
                            subtitle: "How much to pay to reach a new ownership split, with optional payment plan"
                        ) { RebalanceView() }
                    } header: {
                        Text("Tools")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.4))
                            .textCase(nil)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Calculators")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func navRow<Dest: View>(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        @ViewBuilder destination: () -> Dest
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(.vertical, 6)
        }
    }
}

#Preview {
    CalculatorsView()
}
