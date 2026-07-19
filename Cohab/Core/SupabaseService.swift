import Supabase
import Foundation

enum SupabaseService {

    // MARK: - Household

    static func createHousehold(
        partnerALabel: String, partnerBLabel: String,
        currency: String, country: String,
        annualInterestRate: Double,
        setupMode: String, relationshipType: String, agreementType: String,
        emailA: String, emailB: String
    ) async throws -> UUID {
        return try await supabase
            .rpc("create_household", params: CreateHouseholdParams(
                pPartnerALabel: partnerALabel, pPartnerBLabel: partnerBLabel,
                pCurrency: currency, pCountry: country,
                pAnnualInterestRate: annualInterestRate,
                pSetupMode: setupMode, pRelationshipType: relationshipType,
                pAgreementType: agreementType,
                pEmailA: emailA, pEmailB: emailB))
            .execute()
            .value
    }

    static func fetchHousehold() async throws -> DBHousehold? {
        guard let uid = try? await supabase.auth.session.user.id else { return nil }
        let rows: [DBHousehold] = try await supabase
            .from("households")
            .select("*, household_members!inner(user_id)")
            .eq("household_members.user_id", value: uid.uuidString)
            // A user can end up with several memberships (re-onboarding, an
            // accepted invite). Pick deterministically: the newest household
            // is the one they most recently set up or joined.
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Claim local household

    /// Inserts a household row with a caller-chosen id. Used when a household was
    /// created locally while signed out (possible before sign-in was mandatory) and
    /// is now being claimed to the cloud — preserving the id means assets and
    /// contributions keep their references without remapping.
    ///
    /// NOTE: plain inserts, not upserts — Postgres applies the table's SELECT
    /// policy during ON CONFLICT arbitration, so upserts fail RLS with 42501 for
    /// rows that are not yet visible (no membership yet). Retries after a
    /// partial claim are handled by ignoring duplicate-key (23505) errors.
    static func insertHouseholdPreservingId(
        id: UUID, partnerALabel: String, partnerBLabel: String,
        currency: String, country: String, annualInterestRate: Double,
        setupMode: String, relationshipType: String, agreementType: String,
        emailA: String, emailB: String
    ) async throws {
        struct Row: Encodable {
            let id: String
            let partner_a_label: String; let partner_b_label: String
            let currency: String; let country: String
            let annual_interest_rate: Double
            let setup_mode: String; let relationship_type: String
            let agreement_type: String
            let email_a: String; let email_b: String
        }
        try await supabase
            .from("households")
            .insert(Row(id: id.uuidString,
                        partner_a_label: partnerALabel, partner_b_label: partnerBLabel,
                        currency: currency, country: country,
                        annual_interest_rate: annualInterestRate,
                        setup_mode: setupMode, relationship_type: relationshipType,
                        agreement_type: agreementType,
                        email_a: emailA, email_b: emailB),
                    returning: .minimal)
            .execute()
    }

    /// Registers the current user as partner A of the household.
    static func insertMembership(householdId: UUID) async throws {
        struct Row: Encodable {
            let household_id: String; let user_id: String; let role: String
        }
        let uid = try await supabase.auth.session.user.id
        try await supabase
            .from("household_members")
            .insert(Row(household_id: householdId.uuidString,
                        user_id: uid.uuidString, role: "a"),
                    returning: .minimal)
            .execute()
    }

    static func insertAssetPreservingId(
        id: UUID, householdId: UUID, assetType: String, label: String, address: String,
        currentValue: Double, remainingLoan: Double, salesCostFraction: Double,
        ownershipShareA: Double, sortOrder: Int, purchaseDate: String
    ) async throws {
        struct Row: Encodable {
            let id: String; let household_id: String; let asset_type: String
            let label: String; let address: String
            let current_value: Double; let remaining_loan: Double
            let sales_cost_fraction: Double; let ownership_share_a: Double
            let sort_order: Int; let purchase_date: String
        }
        try await supabase
            .from("assets")
            .insert(Row(id: id.uuidString, household_id: householdId.uuidString,
                        asset_type: assetType, label: label, address: address,
                        current_value: currentValue, remaining_loan: remainingLoan,
                        sales_cost_fraction: salesCostFraction,
                        ownership_share_a: ownershipShareA,
                        sort_order: sortOrder, purchase_date: purchaseDate),
                    returning: .minimal)
            .execute()
    }

    static func insertContributionPreservingId(
        id: UUID, assetId: UUID, ownerKey: String, amount: Double,
        date: String, label: String, category: String
    ) async throws {
        struct Row: Encodable {
            let id: String; let asset_id: String; let owner_key: String
            let amount: Double; let date: String; let label: String; let category: String
        }
        try await supabase
            .from("contributions")
            .insert(Row(id: id.uuidString, asset_id: assetId.uuidString,
                        owner_key: ownerKey, amount: amount, date: date,
                        label: label, category: category),
                    returning: .minimal)
            .execute()
    }

    /// Records the onboarding disclaimer acceptance on the user's profile —
    /// a legal trail of who accepted what, and when.
    static func recordDisclaimerAcceptance(version: String) async throws {
        guard let uid = try? await supabase.auth.session.user.id else { return }
        struct Row: Encodable {
            let user_id: String
            let disclaimer_accepted_at: String
            let disclaimer_version: String
        }
        let iso = ISO8601DateFormatter()
        try await supabase
            .from("profiles")
            .upsert(Row(user_id: uid.uuidString,
                        disclaimer_accepted_at: iso.string(from: Date()),
                        disclaimer_version: version))
            .execute()
    }

    /// The disclaimer version the signed-in user has accepted, if any.
    static func fetchProfileDisclaimerVersion() async throws -> String? {
        guard let uid = try? await supabase.auth.session.user.id else { return nil }
        struct Row: Decodable { let disclaimer_version: String? }
        let rows: [Row] = try await supabase
            .from("profiles")
            .select("disclaimer_version")
            .eq("user_id", value: uid.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first?.disclaimer_version
    }

    static func updateAgreementStatus(
        householdId: UUID, status: String, signedAt: Date?
    ) async throws {
        struct Update: Encodable {
            let agreement_status: String
            let signed_at: String?
        }
        let iso = ISO8601DateFormatter()
        try await supabase
            .from("households")
            .update(Update(agreement_status: status,
                           signed_at: signedAt.map { iso.string(from: $0) }))
            .eq("id", value: householdId.uuidString)
            .execute()
    }

    static func updateHousehold(
        householdId: UUID, partnerALabel: String, partnerBLabel: String,
        currency: String, annualInterestRate: Double
    ) async throws {
        struct Update: Encodable {
            let partner_a_label: String; let partner_b_label: String
            let currency: String; let annual_interest_rate: Double
        }
        try await supabase
            .from("households")
            .update(Update(partner_a_label: partnerALabel, partner_b_label: partnerBLabel,
                           currency: currency, annual_interest_rate: annualInterestRate))
            .eq("id", value: householdId.uuidString)
            .execute()
    }

    static func updateHouseholdEmails(
        householdId: UUID, emailA: String, emailB: String
    ) async throws {
        struct Update: Encodable { let email_a: String; let email_b: String }
        try await supabase
            .from("households")
            .update(Update(email_a: emailA, email_b: emailB))
            .eq("id", value: householdId.uuidString)
            .execute()
    }

    /// Persists the monthly budget snapshot saved from the expense-split
    /// calculator, so both partners see the same overview on the dashboard.
    static func updateHouseholdBudget(
        householdId: UUID,
        incomeA: Double, incomeB: Double, totalExpenses: Double,
        splitA: Double, paysA: Double, paysB: Double,
        netTransfer: Double, savedAt: Date
    ) async throws {
        struct Update: Encodable {
            let budget_income_a: Double
            let budget_income_b: Double
            let budget_total_expenses: Double
            let budget_split_a: Double
            let budget_pays_a: Double
            let budget_pays_b: Double
            let budget_net_transfer: Double
            let budget_saved_at: String
        }
        let iso = ISO8601DateFormatter()
        try await supabase
            .from("households")
            .update(Update(
                budget_income_a: incomeA, budget_income_b: incomeB,
                budget_total_expenses: totalExpenses, budget_split_a: splitA,
                budget_pays_a: paysA, budget_pays_b: paysB,
                budget_net_transfer: netTransfer,
                budget_saved_at: iso.string(from: savedAt)))
            .eq("id", value: householdId.uuidString)
            .execute()
    }

    /// Persists the live expense-split working state (preset rows + incomes),
    /// so both partners see and edit the same numbers in the calculator.
    static func updateExpensePresets(
        householdId: UUID,
        presets: [DBExpensePreset],
        incomeA: Double, incomeB: Double,
        updatedAt: Date
    ) async throws {
        struct Update: Encodable {
            let expense_presets: [DBExpensePreset]
            let expense_income_a: Double
            let expense_income_b: Double
            let expenses_updated_at: String
        }
        let iso = ISO8601DateFormatter()
        try await supabase
            .from("households")
            .update(Update(
                expense_presets: presets,
                expense_income_a: incomeA, expense_income_b: incomeB,
                expenses_updated_at: iso.string(from: updatedAt)))
            .eq("id", value: householdId.uuidString)
            .execute()
    }

    /// Persists the agreement configuration that drives the contract text, so
    /// both partners generate an identical document.
    static func updateAgreementConfig(
        householdId: UUID,
        rentAmount: Double, rentPayerKey: String, rentPaymentDay: Int,
        includeDissolutionClause: Bool, includeSeparatePropertyClause: Bool,
        includeBuyoutRightsClause: Bool, includeDisposalConsentClause: Bool,
        includeDisputeResolutionClause: Bool, includeDebtClause: Bool
    ) async throws {
        struct Update: Encodable {
            let rent_amount: Double
            let rent_payer_key: String
            let rent_payment_day: Int
            let include_dissolution_clause: Bool
            let include_separate_property_clause: Bool
            let include_buyout_rights_clause: Bool
            let include_disposal_consent_clause: Bool
            let include_dispute_resolution_clause: Bool
            let include_debt_clause: Bool
        }
        try await supabase
            .from("households")
            .update(Update(
                rent_amount: rentAmount, rent_payer_key: rentPayerKey,
                rent_payment_day: rentPaymentDay,
                include_dissolution_clause: includeDissolutionClause,
                include_separate_property_clause: includeSeparatePropertyClause,
                include_buyout_rights_clause: includeBuyoutRightsClause,
                include_disposal_consent_clause: includeDisposalConsentClause,
                include_dispute_resolution_clause: includeDisputeResolutionClause,
                include_debt_clause: includeDebtClause))
            .eq("id", value: householdId.uuidString)
            .execute()
    }

    static func updateDocusealInfo(
        householdId: UUID, slug: String, viewUrl: String,
        assetCount: Int, contribCount: Int
    ) async throws {
        struct Update: Encodable {
            let docuseal_slug: String; let docuseal_view_url: String
            let signed_asset_count: Int; let signed_contrib_count: Int
        }
        try await supabase
            .from("households")
            .update(Update(docuseal_slug: slug, docuseal_view_url: viewUrl,
                           signed_asset_count: assetCount, signed_contrib_count: contribCount))
            .eq("id", value: householdId.uuidString)
            .execute()
    }

    // MARK: - Invite

    /// Number of members in the household (1 = only you, 2 = partner joined).
    static func fetchMemberCount(householdId: UUID) async throws -> Int {
        struct Row: Decodable { let user_id: UUID }
        let rows: [Row] = try await supabase
            .from("household_members").select("user_id")
            .eq("household_id", value: householdId.uuidString)
            .execute().value
        return rows.count
    }

    static func createInviteToken(householdId: UUID) async throws -> UUID {
        struct Row: Encodable { let household_id: String; let created_by: String }
        let uid = try await supabase.auth.session.user.id
        let result: DBInviteToken = try await supabase
            .from("invite_tokens")
            .insert(Row(household_id: householdId.uuidString, created_by: uid.uuidString))
            .select().single().execute().value
        return result.token
    }

    static func joinHousehold(token: UUID) async throws -> UUID {
        return try await supabase
            .rpc("join_household_via_token", params: JoinHouseholdParams(pToken: token))
            .execute()
            .value
    }

    // MARK: - Assets

    static func fetchAssets(householdId: UUID) async throws -> [DBAsset] {
        return try await supabase
            .from("assets").select()
            .eq("household_id", value: householdId.uuidString)
            .order("sort_order")
            .order("created_at").execute().value
    }

    static func insertAsset(
        householdId: UUID, assetType: String, label: String, address: String,
        currentValue: Double, remainingLoan: Double,
        salesCostFraction: Double, ownershipShareA: Double, purchaseDate: String
    ) async throws -> DBAsset {
        struct Row: Encodable {
            let household_id: String; let asset_type: String
            let label: String; let address: String
            let current_value: Double; let remaining_loan: Double
            let sales_cost_fraction: Double; let ownership_share_a: Double
            let purchase_date: String
        }
        return try await supabase
            .from("assets")
            .insert(Row(household_id: householdId.uuidString, asset_type: assetType,
                        label: label, address: address, current_value: currentValue,
                        remaining_loan: remainingLoan, sales_cost_fraction: salesCostFraction,
                        ownership_share_a: ownershipShareA, purchase_date: purchaseDate))
            .select().single().execute().value
    }

    static func updateAsset(
        _ id: UUID, assetType: String, label: String, address: String,
        currentValue: Double, remainingLoan: Double,
        salesCostFraction: Double, ownershipShareA: Double
    ) async throws {
        struct Update: Encodable {
            let asset_type: String
            let label: String; let address: String
            let current_value: Double; let remaining_loan: Double
            let sales_cost_fraction: Double
            let ownership_share_a: Double
        }
        try await supabase
            .from("assets")
            .update(Update(asset_type: assetType, label: label, address: address,
                           current_value: currentValue, remaining_loan: remainingLoan,
                           sales_cost_fraction: salesCostFraction,
                           ownership_share_a: ownershipShareA))
            .eq("id", value: id.uuidString).execute()
    }

    static func updateAssetSortOrder(_ id: UUID, sortOrder: Int) async throws {
        struct Update: Encodable { let sort_order: Int }
        try await supabase
            .from("assets")
            .update(Update(sort_order: sortOrder))
            .eq("id", value: id.uuidString)
            .execute()
    }

    static func deleteAsset(_ id: UUID) async throws {
        try await supabase.from("assets").delete()
            .eq("id", value: id.uuidString).execute()
    }

    // MARK: - Contributions

    static func fetchContributions(assetId: UUID) async throws -> [DBContribution] {
        return try await supabase
            .from("contributions").select()
            .eq("asset_id", value: assetId.uuidString)
            .order("date", ascending: false).execute().value
    }

    static func insertContribution(
        assetId: UUID, ownerKey: String, amount: Double,
        date: String, label: String, category: String
    ) async throws -> DBContribution {
        struct Row: Encodable {
            let asset_id: String; let owner_key: String
            let amount: Double; let date: String
            let label: String; let category: String
        }
        return try await supabase
            .from("contributions")
            .insert(Row(asset_id: assetId.uuidString, owner_key: ownerKey,
                        amount: amount, date: date, label: label, category: category))
            .select().single().execute().value
    }

    static func deleteContribution(_ id: UUID) async throws {
        try await supabase.from("contributions").delete()
            .eq("id", value: id.uuidString).execute()
    }

    // MARK: - Shared Expenses

    static func fetchExpenses(householdId: UUID) async throws -> [DBExpense] {
        return try await supabase
            .from("shared_expenses").select()
            .eq("household_id", value: householdId.uuidString)
            .order("date", ascending: false).execute().value
    }

    static func insertExpense(
        householdId: UUID, label: String, amount: Double,
        paidByKey: String, splitRatioA: Double, date: String,
        category: String, isRecurring: Bool
    ) async throws -> DBExpense {
        struct Row: Encodable {
            let household_id: String; let label: String; let amount: Double
            let paid_by_key: String; let split_ratio_a: Double
            let date: String; let category: String; let is_recurring: Bool
        }
        return try await supabase
            .from("shared_expenses")
            .insert(Row(household_id: householdId.uuidString, label: label,
                        amount: amount, paid_by_key: paidByKey,
                        split_ratio_a: splitRatioA, date: date,
                        category: category, is_recurring: isRecurring))
            .select().single().execute().value
    }

    static func deleteExpense(_ id: UUID) async throws {
        try await supabase.from("shared_expenses").delete()
            .eq("id", value: id.uuidString).execute()
    }
}
