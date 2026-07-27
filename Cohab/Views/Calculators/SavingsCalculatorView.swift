import SwiftUI

struct SavingsCalculatorView: View {
    let nameA: String
    let nameB: String
    let symbol: String
    let country: String

    init(nameA: String = "Partner A", nameB: String = "Partner B", symbol: String = "£", country: String = "GB") {
        self.nameA = nameA; self.nameB = nameB; self.symbol = symbol; self.country = country
    }

    @ObservedObject private var strings = AppStrings.shared

    @State private var monthlySavingsText = ""
    @State private var mortgagePercent: Double = 50
    @State private var yearsHorizon: Double = 10
    @State private var mortgageRate: Double = 5.0
    @State private var fundReturn: Double = 7.0
    @State private var showSettings = false

    private var savings: Double { parseExpenseAmount(monthlySavingsText) }
    private var hasInput: Bool { savings > 0 }
    private var mortgageSavings: Double { savings * mortgagePercent / 100 }
    private var fundSavings: Double { savings * (1 - mortgagePercent / 100) }

    // MARK: Projections

    private struct Projection {
        let mPaid, mInterest, mTotal: Double
        let fPaid, fValue, fGain: Double
        var totalValue: Double { mTotal + fValue }
    }

    private var projection: Projection {
        let months = Int(yearsHorizon) * 12
        let monthlyMRate = mortgageRate / 100 / 12
        let monthlyFRate = fundReturn / 100 / 12

        var mPaid = 0.0, mInterest = 0.0
        for m in 1...max(1, months) {
            mPaid += mortgageSavings
            mInterest += mortgageSavings * monthlyMRate * Double(months - m)
        }

        var fValue = 0.0
        for _ in 1...max(1, months) {
            fValue = (fValue + fundSavings) * (1 + monthlyFRate)
        }
        let fPaid = fundSavings * Double(months)

        return Projection(
            mPaid: mPaid, mInterest: mInterest, mTotal: mPaid + mInterest,
            fPaid: fPaid, fValue: fValue, fGain: fValue - fPaid
        )
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                inputCard
                if hasInput {
                    splitCard
                        .transition(.move(edge: .top).combined(with: .opacity))
                    horizonCard
                        .transition(.move(edge: .top).combined(with: .opacity))
                    resultsCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .padding(20)
            .animation(.spring(duration: 0.35), value: hasInput)
        }
        .background(Color.cohBg.ignoresSafeArea())
        .navigationTitle(strings.calcSavingsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Input card

    private var inputCard: some View {
        cardSection(strings.savingsMonthlySavingsHeader) {
            VStack(alignment: .leading, spacing: 8) {
                Text(strings.savingsMonthlySavingsPrompt)
                    .font(.subheadline).foregroundStyle(Color.cohSecondary)
                HStack(spacing: 6) {
                    Text(symbol).foregroundStyle(Color.cohSecondary).font(.title3)
                    TextField("0", text: $monthlySavingsText)
                        .keyboardType(.decimalPad).font(.title3)
                }
                .padding(18)
                .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.03), radius: 4, y: 2)

                if hasInput {
                    Text(symbol + fmt(savings * 12) + strings.savingsPerYear)
                        .font(.caption).foregroundStyle(Color.cohSecondary)
                }
            }
        }
    }

    // MARK: Split card

    private var splitCard: some View {
        cardSection(strings.savingsAllocationHeader) {
            VStack(spacing: 12) {
                // Visual split bar
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        ZStack(alignment: .leading) {
                            Color.cohBlue.opacity(0.15)
                            HStack {
                                Image(systemName: "house.fill")
                                    .font(.caption2).foregroundStyle(Color.cohBlue)
                                Text("\(Int(mortgagePercent))%  \(symbol)\(fmt(mortgageSavings))")
                                    .font(.caption.bold().monospacedDigit())
                                    .foregroundStyle(Color.cohBlue)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                        }
                        .frame(width: max(0, geo.size.width * mortgagePercent / 100))

                        ZStack(alignment: .trailing) {
                            Color.cohGreen.opacity(0.15)
                            HStack {
                                Spacer()
                                Text("\(100 - Int(mortgagePercent))%  \(symbol)\(fmt(fundSavings))")
                                    .font(.caption.bold().monospacedDigit())
                                    .foregroundStyle(Color.cohGreen)
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.caption2).foregroundStyle(Color.cohGreen)
                            }
                            .padding(.horizontal, 10)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(height: 40)
                .animation(.spring(duration: 0.25), value: mortgagePercent)

                Slider(value: $mortgagePercent, in: 0...100, step: 5).tint(.cohBlue)

                HStack {
                    Text(strings.savingsMoreToMortgage)
                    Spacer()
                    Text(strings.savingsMoreToInvesting)
                }
                .font(.caption).foregroundStyle(Color.cohTertiary)
            }
        }
    }

    // MARK: Horizon card

    private var horizonCard: some View {
        cardSection(strings.savingsTimeHorizonHeader) {
            VStack(spacing: 10) {
                HStack {
                    Text(strings.savingsSaveFor)
                        .font(.subheadline).foregroundStyle(Color.cohSecondary)
                    Spacer()
                    Text("\(Int(yearsHorizon)) \(strings.savingsYears)")
                        .font(.title3.bold().monospacedDigit()).foregroundStyle(Color.cohInk)
                }
                Slider(value: $yearsHorizon, in: 1...30, step: 1).tint(.cohGreen)

                // Collapsible settings
                Button {
                    withAnimation(.spring(duration: 0.25)) { showSettings.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showSettings ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                        Text(strings.savingsAdjustRates)
                            .font(.caption)
                    }
                    .foregroundStyle(Color.cohSecondary)
                }
                .buttonStyle(.plain)

                if showSettings {
                    VStack(spacing: 12) {
                        rateRow(strings.savingsMortgageRate,
                                value: $mortgageRate, range: 1...15, color: Color.cohBlue)
                        rateRow(strings.savingsExpectedReturn,
                                value: $fundReturn, range: 1...15, color: Color.cohGreen)
                    }
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private func rateRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.caption).foregroundStyle(Color.cohSecondary)
                Spacer()
                Text(String(format: "%.1f%%", value.wrappedValue))
                    .font(.caption.bold().monospacedDigit()).foregroundStyle(color)
            }
            Slider(value: value, in: range, step: 0.1).tint(color)
        }
    }

    // MARK: Results card

    private var resultsCard: some View {
        let p = projection
        let years = Int(yearsHorizon)

        return VStack(spacing: 16) {
            // Total headline
            VStack(spacing: 4) {
                Text(String(format: strings.savingsAfterYears, years))
                    .font(.caption.weight(.semibold)).foregroundStyle(Color.cohSecondary)
                Text(symbol + fmt(p.totalValue))
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.cohInk)
                Text(strings.savingsTotalAccumulated)
                    .font(.caption).foregroundStyle(Color.cohTertiary)
            }
            .frame(maxWidth: .infinity)

            Color(.separator).frame(height: 0.5)

            // Two comparison columns
            HStack(spacing: 10) {
                resultColumn(
                    icon: "house.fill",
                    color: Color.cohBlue,
                    title: strings.savingsMortgageLabel,
                    paid: p.mPaid,
                    gain: p.mInterest,
                    total: p.mTotal,
                    gainLabel: strings.savingsInterestSaved
                )
                resultColumn(
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color.cohGreen,
                    title: strings.savingsInvestingLabel,
                    paid: p.fPaid,
                    gain: p.fGain,
                    total: p.fValue,
                    gainLabel: strings.savingsReturns
                )
            }

            // Winner banner
            let moreToMortgage = mortgagePercent > 50
            if p.mPaid > 0 && p.fPaid > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption2).foregroundStyle(Color.cohTertiary)
                    Text(moreToMortgage
                         ? strings.savingsMortgagePrioritisedNote
                         : strings.savingsInvestingPrioritisedNote)
                        .font(.caption).foregroundStyle(Color.cohTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(strings.savingsProjectionsDisclaimer)
                .font(.caption).foregroundStyle(Color(.quaternaryLabel))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
    }

    private func resultColumn(icon: String, color: Color, title: String,
                               paid: Double, gain: Double, total: Double, gainLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption).foregroundStyle(color)
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(symbol + fmt(total))
                    .font(.title3.bold().monospacedDigit()).foregroundStyle(Color.cohInk)
                Text("+ \(symbol)\(fmt(gain)) \(gainLabel)")
                    .font(.caption2.monospacedDigit()).foregroundStyle(color.opacity(0.8))
                Text(symbol + fmt(paid) + strings.savingsPaidIn)
                    .font(.caption.monospacedDigit()).foregroundStyle(Color.cohTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Helpers

    private func cardSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
            content()
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func fmt(_ v: Double) -> String {
        fmtGroupedAmount(v, country: country)
    }
}

#Preview { NavigationStack { SavingsCalculatorView(nameA: "Sarah", nameB: "James") } }
