import SwiftData
import Foundation

@Model
final class Household {
    var id: UUID
    var partnerAName: String
    var partnerBName: String
    var currency: String
    var annualInterestRate: Double
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var assets: [Asset]
    @Relationship(deleteRule: .cascade) var expenses: [SharedExpense]

    init(
        partnerAName: String,
        partnerBName: String,
        currency: String = "GBP",
        annualInterestRate: Double = 0.05
    ) {
        self.id = UUID()
        self.partnerAName = partnerAName
        self.partnerBName = partnerBName
        self.currency = currency
        self.annualInterestRate = annualInterestRate
        self.createdAt = Date()
        self.assets = []
        self.expenses = []
    }

    var currencySymbol: String {
        switch currency {
        case "GBP": return "£"
        case "USD": return "$"
        case "EUR": return "€"
        case "AUD": return "A$"
        case "CAD": return "C$"
        case "NOK", "SEK", "DKK": return "kr"
        default: return currency
        }
    }
}

@Model
final class Asset {
    var id: UUID
    var label: String
    var address: String
    var currentValue: Double
    var remainingLoan: Double
    var salesCostFraction: Double
    var ownershipShareA: Double
    var purchaseDate: Date

    @Relationship(deleteRule: .cascade) var contributions: [ContributionRecord]

    init(
        label: String,
        address: String = "",
        currentValue: Double,
        remainingLoan: Double = 0,
        salesCostFraction: Double = 0.02,
        ownershipShareA: Double = 0.5,
        purchaseDate: Date = Date()
    ) {
        self.id = UUID()
        self.label = label
        self.address = address
        self.currentValue = currentValue
        self.remainingLoan = remainingLoan
        self.salesCostFraction = salesCostFraction
        self.ownershipShareA = ownershipShareA
        self.purchaseDate = purchaseDate
        self.contributions = []
    }

    var netEquity: Double { currentValue - remainingLoan }
    var estimatedSalesCost: Double { currentValue * salesCostFraction }
    var netProceeds: Double { netEquity - estimatedSalesCost }
}

@Model
final class ContributionRecord {
    var id: UUID
    var ownerKey: String
    var amount: Double
    var date: Date
    var label: String
    var category: String

    init(
        ownerKey: String,
        amount: Double,
        date: Date = Date(),
        label: String,
        category: String = "other"
    ) {
        self.id = UUID()
        self.ownerKey = ownerKey
        self.amount = amount
        self.date = date
        self.label = label
        self.category = category
    }
}

@Model
final class SharedExpense {
    var id: UUID
    var label: String
    var amount: Double
    var paidByKey: String
    var splitRatioA: Double
    var date: Date
    var category: String
    var isRecurring: Bool

    init(
        label: String,
        amount: Double,
        paidByKey: String,
        splitRatioA: Double = 0.5,
        date: Date = Date(),
        category: String = "other",
        isRecurring: Bool = false
    ) {
        self.id = UUID()
        self.label = label
        self.amount = amount
        self.paidByKey = paidByKey
        self.splitRatioA = splitRatioA
        self.date = date
        self.category = category
        self.isRecurring = isRecurring
    }

    var amountOwedByA: Double { amount * splitRatioA }
    var amountOwedByB: Double { amount * (1 - splitRatioA) }
}
