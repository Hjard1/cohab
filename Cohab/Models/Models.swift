import SwiftData
import SwiftUI
import Foundation

// MARK: - Asset type

enum AssetType: String, CaseIterable {
    case home       = "home"
    case car        = "car"
    case cabin      = "cabin"
    case investment = "investment"
    case savings    = "savings"
    case other      = "other"

    var displayName: String {
        switch self {
        case .home:       return "Home"
        case .car:        return "Car"
        case .cabin:      return "Cabin"
        case .investment: return "Investment"
        case .savings:    return "Savings"
        case .other:      return "Other"
        }
    }

    var icon: String {
        switch self {
        case .home:       return "house.fill"
        case .car:        return "car.fill"
        case .cabin:      return "tent.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .savings:    return "banknote.fill"
        case .other:      return "shippingbox.fill"
        }
    }

    var color: Color {
        switch self {
        case .home:       return Color(red: 0.10, green: 0.68, blue: 0.45)
        case .car:        return Color(red: 0.20, green: 0.49, blue: 0.96)
        case .cabin:      return Color(red: 0.93, green: 0.50, blue: 0.18)
        case .investment: return Color(red: 0.54, green: 0.31, blue: 0.96)
        case .savings:    return Color(red: 0.04, green: 0.65, blue: 0.75)
        case .other:      return Color(.systemGray)
        }
    }
}

// MARK: - Design tokens

extension Color {
    static let cohGreen   = Color(red: 0.10, green: 0.68, blue: 0.45)
    static let cohBg      = Color(.systemGroupedBackground)
    static let cohCard    = Color(.systemBackground)
}

// MARK: - SwiftData models

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
    var assetType: String       // AssetType.rawValue, default "home"
    var label: String
    var address: String
    var currentValue: Double
    var remainingLoan: Double
    var salesCostFraction: Double
    var ownershipShareA: Double
    var purchaseDate: Date

    @Relationship(deleteRule: .cascade) var contributions: [ContributionRecord]

    init(
        assetType: String = "home",
        label: String,
        address: String = "",
        currentValue: Double,
        remainingLoan: Double = 0,
        salesCostFraction: Double = 0.02,
        ownershipShareA: Double = 0.5,
        purchaseDate: Date = Date()
    ) {
        self.id = UUID()
        self.assetType = assetType
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
    var type: AssetType { AssetType(rawValue: assetType) ?? .other }
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
}
