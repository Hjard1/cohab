import Foundation

/// Which partner a contribution or payout belongs to.
enum Partner: String, CaseIterable {
    case a = "A"
    case b = "B"
}

/// An equity contribution toward a shared asset — a deposit, an extra loan
/// repayment, a renovation, and so on. Earns interest from `date` until
/// settlement.
struct Contribution: Identifiable {
    let id = UUID()
    var owner: Partner
    /// TODO(money): use `Decimal` in production. `Double` here is a scaffold
    /// simplification — fine for previews, not for real settlements.
    var amount: Double
    var date: Date
    var label: String
}

/// Everything needed to answer "if we sell / split today, who gets what".
struct SettlementInput {
    var salePrice: Double
    var remainingLoan: Double
    var salesCosts: Double
    /// 0...1 — partner B implicitly gets `1 - ownershipShareA`.
    var ownershipShareA: Double
    /// e.g. 0.05 == 5%. User-chosen — deliberately NOT the Norges Bank key rate.
    var annualRate: Double
    var contributions: [Contribution]
    var settlementDate: Date
}

struct SettlementResult {
    var netProceeds: Double
    /// Contributions plus accrued interest, per partner.
    var accrued: [Partner: Double]
    /// Final amount each partner receives.
    var payout: [Partner: Double]
    /// True when net value is below total contributions (a loss scenario).
    var shortfall: Bool
}

/// Ported from Samboappen's documented settlement logic, with the three
/// Norway anchors removed: the interest rate is user-chosen (not key rate + 1%),
/// amounts are currency-agnostic, and there is no tax engine.
enum SettlementEngine {
    /// Compound `principal` annually at `rate` over the fractional number of
    /// years between `from` and `to`.
    ///
    /// Samboappen capitalizes on Dec 31 each year; this seed uses fractional-year
    /// compounding as a portable default. Exact calendar-boundary capitalization
    /// is a later refinement.
    static func accrue(_ principal: Double, rate: Double, from: Date, to: Date) -> Double {
        let years = max(0, to.timeIntervalSince(from)) / (365.25 * 24 * 60 * 60)
        return principal * pow(1 + rate, years)
    }

    static func settle(_ input: SettlementInput) -> SettlementResult {
        let net = input.salePrice - input.remainingLoan - input.salesCosts

        var accrued: [Partner: Double] = [.a: 0, .b: 0]
        for c in input.contributions {
            accrued[c.owner, default: 0] += accrue(
                c.amount, rate: input.annualRate, from: c.date, to: input.settlementDate
            )
        }
        let totalAccrued = (accrued[.a] ?? 0) + (accrued[.b] ?? 0)

        var payout: [Partner: Double] = [.a: 0, .b: 0]
        let shortfall = net < totalAccrued

        if shortfall {
            // Loss protection: not enough value to repay everyone in full, so
            // split the net value proportionally to each partner's accrued
            // contributions.
            if totalAccrued > 0 {
                payout[.a] = net * ((accrued[.a] ?? 0) / totalAccrued)
                payout[.b] = net * ((accrued[.b] ?? 0) / totalAccrued)
            } else {
                payout[.a] = net * input.ownershipShareA
                payout[.b] = net * (1 - input.ownershipShareA)
            }
        } else {
            // Contributions are repaid first (with interest); the remaining
            // surplus is split by registered ownership share.
            let remainder = net - totalAccrued
            payout[.a] = (accrued[.a] ?? 0) + remainder * input.ownershipShareA
            payout[.b] = (accrued[.b] ?? 0) + remainder * (1 - input.ownershipShareA)
        }

        return SettlementResult(
            netProceeds: net, accrued: accrued, payout: payout, shortfall: shortfall
        )
    }
}
