import Foundation

// All DB row types are prefixed with DB to avoid name collisions with
// SwiftData models (ContributionRecord, Asset etc.) and any SDK types.

// MARK: - DBProfile

struct DBProfile: Codable, Identifiable {
    let userId: UUID
    var displayName: String
    var email: String
    let createdAt: Date
    var id: UUID { userId }
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"; case displayName = "display_name"
        case email; case createdAt = "created_at"
    }
}

// MARK: - DBHousehold

struct DBHousehold: Codable, Identifiable {
    let id: UUID
    var partnerALabel: String
    var partnerBLabel: String
    var currency: String
    var country: String
    var annualInterestRate: Double
    var setupMode: String
    var relationshipType: String
    var agreementType: String
    var agreementStatus: String
    var signedAt: Date?
    var signedAssetCount: Int
    var signedContribCount: Int
    var docusealSlug: String
    var docusealViewUrl: String
    var emailA: String
    var emailB: String
    // Agreement config (optional so rows created before the migration still decode)
    var rentAmount: Double?
    var rentPayerKey: String?
    var rentPaymentDay: Int?
    var includeDissolutionClause: Bool?
    var includeSeparatePropertyClause: Bool?
    var includeBuyoutRightsClause: Bool?
    var includeDisposalConsentClause: Bool?
    var includeDisputeResolutionClause: Bool?
    var includeDebtClause: Bool?
    let createdAt: Date

    var isFormalMode: Bool { setupMode == "formal" }

    var currencySymbol: String {
        switch currency {
        case "GBP": return "£"; case "USD": return "$"; case "EUR": return "€"
        case "AUD": return "A$"; case "CAD": return "C$"
        case "NOK", "SEK", "DKK": return "kr"
        default: return currency
        }
    }

    var agreementNeedsUpdate: Bool {
        guard agreementStatus != "none" else { return false }
        return false // computed in store after fetching asset/contrib counts
    }

    enum CodingKeys: String, CodingKey {
        case id
        case partnerALabel    = "partner_a_label"
        case partnerBLabel    = "partner_b_label"
        case currency; case country
        case annualInterestRate = "annual_interest_rate"
        case setupMode        = "setup_mode"
        case relationshipType = "relationship_type"
        case agreementType    = "agreement_type"
        case agreementStatus  = "agreement_status"
        case signedAt         = "signed_at"
        case signedAssetCount = "signed_asset_count"
        case signedContribCount = "signed_contrib_count"
        case docusealSlug     = "docuseal_slug"
        case docusealViewUrl  = "docuseal_view_url"
        case emailA = "email_a"; case emailB = "email_b"
        case rentAmount = "rent_amount"
        case rentPayerKey = "rent_payer_key"
        case rentPaymentDay = "rent_payment_day"
        case includeDissolutionClause = "include_dissolution_clause"
        case includeSeparatePropertyClause = "include_separate_property_clause"
        case includeBuyoutRightsClause = "include_buyout_rights_clause"
        case includeDisposalConsentClause = "include_disposal_consent_clause"
        case includeDisputeResolutionClause = "include_dispute_resolution_clause"
        case includeDebtClause = "include_debt_clause"
        case createdAt = "created_at"
    }
}

// MARK: - DBHouseholdMember

struct DBHouseholdMember: Codable {
    let householdId: UUID
    let userId: UUID
    let role: String
    let joinedAt: Date
    enum CodingKeys: String, CodingKey {
        case householdId = "household_id"; case userId = "user_id"
        case role; case joinedAt = "joined_at"
    }
}

// MARK: - DBAsset

struct DBAsset: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    var assetType: String
    var label: String
    var address: String
    var currentValue: Double
    var remainingLoan: Double
    var salesCostFraction: Double
    var ownershipShareA: Double
    var sortOrder: Int
    var purchaseDate: String   // "YYYY-MM-DD"
    let createdAt: Date

    var netEquity: Double { currentValue - remainingLoan }
    var estimatedSalesCost: Double { currentValue * salesCostFraction }

    enum CodingKeys: String, CodingKey {
        case id; case householdId = "household_id"
        case assetType = "asset_type"; case label; case address
        case currentValue = "current_value"
        case remainingLoan = "remaining_loan"
        case salesCostFraction = "sales_cost_fraction"
        case ownershipShareA = "ownership_share_a"
        case sortOrder = "sort_order"
        case purchaseDate = "purchase_date"
        case createdAt = "created_at"
    }
}

// MARK: - DBContribution

struct DBContribution: Codable, Identifiable {
    let id: UUID
    let assetId: UUID
    var ownerKey: String   // "a" | "b"
    var amount: Double
    var date: String       // "YYYY-MM-DD"
    var label: String
    var category: String
    let createdAt: Date

    var parsedDate: Date {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: date) ?? Date()
    }

    enum CodingKeys: String, CodingKey {
        case id; case assetId = "asset_id"; case ownerKey = "owner_key"
        case amount; case date; case label; case category
        case createdAt = "created_at"
    }
}

// MARK: - DBExpense

struct DBExpense: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    var label: String
    var amount: Double
    var paidByKey: String   // "a" | "b"
    var splitRatioA: Double
    var date: String
    var category: String
    var isRecurring: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id; case householdId = "household_id"
        case label; case amount
        case paidByKey = "paid_by_key"
        case splitRatioA = "split_ratio_a"
        case date; case category
        case isRecurring = "is_recurring"
        case createdAt = "created_at"
    }
}

// MARK: - DBInviteToken

struct DBInviteToken: Codable {
    let token: UUID
    let householdId: UUID
    let role: String
    let createdBy: UUID
    let expiresAt: Date
    var usedAt: Date?
    enum CodingKeys: String, CodingKey {
        case token; case householdId = "household_id"; case role
        case createdBy = "created_by"; case expiresAt = "expires_at"
        case usedAt = "used_at"
    }
}

// MARK: - RPC params

struct CreateHouseholdParams: Encodable {
    let pPartnerALabel: String;      let pPartnerBLabel: String
    let pCurrency: String;           let pCountry: String
    let pAnnualInterestRate: Double; let pSetupMode: String
    let pRelationshipType: String;   let pAgreementType: String
    let pEmailA: String; let pEmailB: String
    enum CodingKeys: String, CodingKey {
        case pPartnerALabel = "p_partner_a_label"; case pPartnerBLabel = "p_partner_b_label"
        case pCurrency = "p_currency"; case pCountry = "p_country"
        case pAnnualInterestRate = "p_annual_interest_rate"; case pSetupMode = "p_setup_mode"
        case pRelationshipType = "p_relationship_type"
        case pAgreementType = "p_agreement_type"
        case pEmailA = "p_email_a"; case pEmailB = "p_email_b"
    }
}

struct JoinHouseholdParams: Encodable {
    let pToken: UUID
    enum CodingKeys: String, CodingKey { case pToken = "p_token" }
}
