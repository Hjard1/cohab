import SwiftUI
import SwiftData

struct CalculatorsView: View {
    @Query private var households: [Household]
    @ObservedObject private var strings = AppStrings.shared

    private var nameA: String { households.first?.partnerAName ?? "Partner A" }
    private var nameB: String { households.first?.partnerBName ?? "Partner B" }
    private var symbol: String { households.first?.currencySymbol ?? "£" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(strings.tabCalculators)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(Color.cohInk)
                        Text(strings.calculatorsFreeToUse)
                            .font(.subheadline)
                            .foregroundStyle(Color.cohSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    VStack(spacing: 14) {
                        calcCard(
                            icon: "person.2.fill",
                            color: Color.cohGreen,
                            title: strings.calcOwnershipTitle,
                            subtitle: strings.calcOwnershipSub,
                            destination: { OwnershipCalculatorView(nameA: nameA, nameB: nameB, symbol: symbol) }
                        )
                        calcCard(
                            icon: "dollarsign.circle.fill",
                            color: Color.cohBlue,
                            title: strings.calcExpenseTitle,
                            subtitle: strings.calcExpenseSub,
                            destination: { ExpenseSplitView(nameA: nameA, nameB: nameB, symbol: symbol) }
                        )
                        calcCard(
                            icon: "xmark.circle.fill",
                            color: Color(red: 0.93, green: 0.50, blue: 0.18),
                            title: strings.calcRebalanceTitle,
                            subtitle: strings.calcRebalanceSub,
                            destination: { RebalanceView(nameA: nameA, nameB: nameB, symbol: symbol) }
                        )
                        calcCard(
                            icon: "banknote.fill",
                            color: Color(red: 0.04, green: 0.65, blue: 0.75),
                            title: strings.calcSavingsTitle,
                            subtitle: strings.calcSavingsSub,
                            destination: { SavingsCalculatorView(nameA: nameA, nameB: nameB, symbol: symbol) }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func calcCard<Dest: View>(
        icon: String, color: Color,
        title: String, subtitle: String,
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
                    Text(title).font(.headline).foregroundStyle(Color.cohInk)
                    Text(subtitle).font(.subheadline).foregroundStyle(Color.cohSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold()).foregroundStyle(Color.cohTertiary)
            }
            .padding(18)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }
}

#Preview { CalculatorsView() }
