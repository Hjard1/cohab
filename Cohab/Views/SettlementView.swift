import SwiftUI

struct SettlementView: View {
    let asset: Asset
    let household: Household

    @State private var salePriceText: String
    @State private var loanText: String
    @State private var costsText: String
    @State private var showCalculation = false
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var strings = AppStrings.shared

    init(asset: Asset, household: Household) {
        self.asset = asset
        self.household = household
        _salePriceText = State(initialValue: String(Int(asset.currentValue)))
        _loanText      = State(initialValue: String(Int(asset.remainingLoan)))
        _costsText     = State(initialValue: String(Int(asset.currentValue * asset.salesCostFraction)))
    }

    // MARK: - Derived values

    private var salePrice: Double { Double(salePriceText.filter(\.isNumber)) ?? asset.currentValue }
    private var loan:      Double { Double(loanText.filter(\.isNumber))      ?? asset.remainingLoan }
    private var costs:     Double { Double(costsText.filter(\.isNumber))     ?? (asset.currentValue * asset.salesCostFraction) }

    private var result: SettlementResult {
        SettlementEngine.settle(SettlementInput(
            salePrice:       salePrice,
            remainingLoan:   loan,
            salesCosts:      costs,
            ownershipShareA: asset.ownershipShareA,
            annualRate:      household.annualInterestRate,
            contributions:   asset.contributions.map {
                Contribution(owner: $0.ownerKey == "A" ? .a : .b,
                             amount: $0.amount, date: $0.date, label: $0.label)
            },
            settlementDate: Date()
        ))
    }

    private var accruedA: Double { result.accrued[.a] ?? 0 }
    private var accruedB: Double { result.accrued[.b] ?? 0 }
    private var payoutA:  Double { result.payout[.a]  ?? 0 }
    private var payoutB:  Double { result.payout[.b]  ?? 0 }

    private var principalA: Double { asset.contributions.filter { $0.ownerKey == "A" }.reduce(0) { $0 + $1.amount } }
    private var principalB: Double { asset.contributions.filter { $0.ownerKey == "B" }.reduce(0) { $0 + $1.amount } }
    private var interestA:  Double { max(0, accruedA - principalA) }
    private var interestB:  Double { max(0, accruedB - principalB) }

    private var totalAccrued: Double { accruedA + accruedB }
    private var surplus:      Double { max(0, result.netProceeds - totalAccrued) }
    private var surplusA:     Double { surplus * asset.ownershipShareA }
    private var surplusB:     Double { surplus * (1 - asset.ownershipShareA) }

    // Transfer: bank pays by title, fair split may differ
    private var titlePayoutA:    Double { result.netProceeds * asset.ownershipShareA }
    private var transferAmount:  Double { abs(titlePayoutA - payoutA) }
    private var aTransfersToB:   Bool   { titlePayoutA > payoutA }
    private var showTransfer:    Bool   {
        transferAmount > 0.5 && !result.shortfall
        && asset.type != .savings && asset.type != .investment
    }
    private var hasContributions: Bool  { !asset.contributions.isEmpty }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    inputCard
                    if result.shortfall { shortfallBanner }
                    payoutCard
                    calculationDisclosure
                    if showTransfer { transferCard }
                    rateNote
                    Spacer(minLength: 60)
                }
                .padding(20)
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle(strings.settlementTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.cohTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Input card

    private var isLiquid: Bool { asset.type == .savings || asset.type == .investment }

    private var inputCard: some View {
        let sym = household.currencySymbol
        return VStack(alignment: .leading, spacing: 16) {
            Text(isLiquid
                 ? strings.settlementValueToday
                 : strings.settlementSectionIfSold)
                .font(.subheadline.bold())
                .foregroundStyle(Color.cohInk)

            inputRow(
                label: isLiquid
                    ? strings.settlementBalance
                    : strings.settlementSalePrice,
                text: $salePriceText, symbol: sym
            )

            if !isLiquid {
                Divider()
                inputRow(label: strings.settlementLoan,      text: $loanText,  symbol: sym)
                Divider()
                inputRow(label: strings.settlementSaleCosts, text: $costsText, symbol: sym)
            }

            Divider()

            HStack {
                Text(isLiquid
                     ? strings.settlementNet
                     : strings.settlementNetProceeds)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.cohInk)
                Spacer()
                let net = result.netProceeds
                Text(net >= 0
                     ? household.moneyText(net)
                     : "-" + household.moneyText(-net))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(net >= 0 ? Color.cohGreen : .red)
            }
        }
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func inputRow(label: String, text: Binding<String>, symbol: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Color.cohSecondary)
            Spacer()
            HStack(spacing: 2) {
                Text(symbol)
                    .font(.subheadline).foregroundStyle(Color.cohSecondary)
                TextField("0", text: text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Color.cohInk)
                    .frame(width: 110)
            }
        }
    }

    // MARK: - Shortfall banner

    private var shortfallBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.white)
                Text(strings.settlementShortfallTitle)
                    .font(.subheadline.bold()).foregroundStyle(.white)
            }
            Text(strings.settlementShortfallBody)
                .font(.caption).foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Waterfall card

    /// The step-by-step breakdown, collapsed by default — the payout card
    /// above is the answer; this is the derivation for those who want it.
    private var calculationDisclosure: some View {
        DisclosureGroup(isExpanded: $showCalculation) {
            waterfallCard
                .padding(.top, 12)
        } label: {
            Text(strings.settlementShowCalculation)
                .font(.subheadline.bold())
                .foregroundStyle(Color.cohInk)
        }
        .tint(Color.cohGreen)
        .padding(.horizontal, 4)
    }

    private var waterfallCard: some View {
        return VStack(alignment: .leading, spacing: 16) {
            Text(strings.settlementWaterfall)
                .font(.subheadline.bold()).foregroundStyle(Color.cohInk)

            // Step 1
            VStack(alignment: .leading, spacing: 10) {
                Label(strings.settlementStep1Label, systemImage: "1.circle.fill")
                    .font(.caption.bold()).foregroundStyle(Color.cohGreen)

                if hasContributions {
                    contribRow(name: household.partnerAName,
                               accrued: accruedA, interest: interestA,
                               color: Color.cohGreen)
                    contribRow(name: household.partnerBName,
                               accrued: accruedB, interest: interestB,
                               color: Color.cohBlue)
                } else {
                    Text(strings.settlementNoContributions)
                        .font(.subheadline).foregroundStyle(Color.cohSecondary)
                }
            }
            .padding(14)
            .background(Color.cohGreen.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

            // Step 2
            let step2Color = result.shortfall
                ? Color.orange
                : Color.cohBlue
            VStack(alignment: .leading, spacing: 10) {
                Label(result.shortfall ? strings.settlementShortfallStep2 : strings.settlementStep2Label,
                      systemImage: "2.circle.fill")
                    .font(.caption.bold()).foregroundStyle(step2Color)

                if result.shortfall {
                    let ratioA = totalAccrued > 0 ? accruedA / totalAccrued : asset.ownershipShareA
                    let ratioB = 1 - ratioA
                    shortfallRow(name: household.partnerAName,
                                 ratio: ratioA, amount: payoutA)
                    shortfallRow(name: household.partnerBName,
                                 ratio: ratioB, amount: payoutB)
                } else {
                    surplusRow(name: household.partnerAName,
                               share: asset.ownershipShareA, amount: surplusA)
                    surplusRow(name: household.partnerBName,
                               share: 1 - asset.ownershipShareA, amount: surplusB)
                }
            }
            .padding(14)
            .background(step2Color.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func contribRow(name: String, accrued: Double, interest: Double,
                             color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption.weight(.medium)).foregroundStyle(Color.cohInk).lineLimit(1)
                if interest > 0.5 {
                    Text(String(format: strings.settlementInterestEarned,
                                household.moneyText(interest)))
                        .font(.caption).foregroundStyle(Color.cohSecondary)
                }
            }
            Spacer()
            Text(household.moneyText(accrued))
                .font(.subheadline.bold().monospacedDigit()).foregroundStyle(color)
        }
    }

    private func surplusRow(name: String, share: Double, amount: Double) -> some View {
        HStack {
            Text("\(name)  (\(Int(share * 100))%)")
                .font(.caption).foregroundStyle(Color.cohSecondary).lineLimit(1)
            Spacer()
            Text(household.moneyText(amount))
                .font(.caption.bold().monospacedDigit()).foregroundStyle(Color.cohInk)
        }
    }

    private func shortfallRow(name: String, ratio: Double, amount: Double) -> some View {
        HStack {
            Text("\(name)  (\(Int(ratio * 100))%)")
                .font(.caption).foregroundStyle(Color.cohSecondary).lineLimit(1)
            Spacer()
            Text(household.moneyText(max(0, amount)))
                .font(.caption.bold().monospacedDigit()).foregroundStyle(Color.cohInk)
        }
    }

    // MARK: - Payout card

    private var payoutCard: some View {
        return VStack(alignment: .leading, spacing: 14) {
            Text(strings.settlementTotalPayout)
                .font(.caption.bold()).tracking(0.5).foregroundStyle(Color.cohSecondary)

            HStack(spacing: 20) {
                payoutPartner(name: household.partnerAName, amount: payoutA,
                              color: Color.cohGreen)
                Divider().frame(height: 44)
                payoutPartner(name: household.partnerBName, amount: payoutB,
                              color: Color.cohBlue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func payoutPartner(name: String, amount: Double,
                                color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(name).font(.caption).foregroundStyle(Color.cohSecondary).lineLimit(1)
            }
            Text(household.moneyText(max(0, amount)))
                .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.cohInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Transfer card

    private var transferCard: some View {
        let payer    = aTransfersToB ? household.partnerAName : household.partnerBName
        let receiver = aTransfersToB ? household.partnerBName : household.partnerAName
        let amtStr   = household.moneyText(transferAmount)

        return VStack(alignment: .leading, spacing: 10) {
            Label(strings.settlementTransferTitle,
                  systemImage: "arrow.left.arrow.right.circle.fill")
                .font(.subheadline.bold()).foregroundStyle(Color.cohInk)

            Text("\(payer)  →  \(receiver):  \(amtStr)")
                .font(.headline).foregroundStyle(Color.cohInk)
                .fixedSize(horizontal: false, vertical: true)

            Text(strings.settlementTransferNote)
                .font(.subheadline).foregroundStyle(Color.cohSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Rate note

    private var rateNote: some View {
        let rateStr = String(format: "%.1f%%", household.annualInterestRate * 100)
        return Text(String(format: strings.settlementRateNote, rateStr))
            .font(.caption)
            .foregroundStyle(Color.cohTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
