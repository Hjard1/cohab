import SwiftUI
import SwiftData
import Foundation
import Supabase

/// Wrapper that lets a `ModelContext` cross a `@Sendable` closure boundary.
/// Safe here because the context is only ever used on the main actor.
private struct UncheckedSendableModelContext: @unchecked Sendable {
    let value: ModelContext
}

// MARK: - HouseholdStore
//
// @Observable single source of truth for all remote data.
// Inject via .environment(store) in CohabApp; read via @Environment(HouseholdStore.self).
// SwiftData models are still used in the current session; this store coexists
// and will replace SwiftData views incrementally.

@Observable
final class HouseholdStore {

    // MARK: State
    private(set) var household: DBHousehold?
    private(set) var assets: [DBAsset] = []
    private(set) var contributions: [UUID: [DBContribution]] = [:]
    private(set) var expenses: [DBExpense] = []
    private(set) var isLoading = false
    private(set) var error: String?

    // Realtime channel — retained so it is not deallocated
    private var realtimeChannel: RealtimeChannelV2?

    // MARK: Convenience
    var partnerAName: String   { household?.partnerALabel    ?? "Partner A" }
    var partnerBName: String   { household?.partnerBLabel    ?? "Partner B" }
    var currencySymbol: String { household?.currencySymbol   ?? "£" }
    var currency: String       { household?.currency         ?? "GBP" }
    var country: String        { household?.country          ?? "GB" }
    var annualInterestRate: Double { household?.annualInterestRate ?? 0.05 }
    var hasHousehold: Bool     { household != nil }

    func contributions(for assetId: UUID) -> [DBContribution] {
        contributions[assetId] ?? []
    }

    // MARK: - Load

    func load() async {
        guard !isLoading else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            guard let h = try await SupabaseService.fetchHousehold() else { return }
            household = h
            await loadDetail(householdId: h.id)
        } catch { self.error = error.localizedDescription }
    }

    private func loadDetail(householdId: UUID) async {
        do {
            let fetched = try await SupabaseService.fetchAssets(householdId: householdId)
            assets = fetched
            await withTaskGroup(of: (UUID, [DBContribution]).self) { group in
                for asset in fetched {
                    group.addTask {
                        let c = (try? await SupabaseService.fetchContributions(assetId: asset.id)) ?? []
                        return (asset.id, c)
                    }
                }
                for await (id, c) in group { contributions[id] = c }
            }
            expenses = (try? await SupabaseService.fetchExpenses(householdId: householdId)) ?? []
        } catch { self.error = error.localizedDescription }
    }

    // MARK: - SwiftData Sync

    /// Pulls the full household + assets + contributions from Supabase and
    /// upserts everything into the local SwiftData store.
    func sync(modelContext: ModelContext) async {
        do {
            guard let dbHousehold = try await SupabaseService.fetchHousehold() else { return }

            // --- Upsert Household ---
            let householdId = dbHousehold.id
            let fetchDescriptor = FetchDescriptor<Household>(
                predicate: #Predicate { $0.id == householdId }
            )
            let existingHouseholds = (try? modelContext.fetch(fetchDescriptor)) ?? []

            let localHousehold: Household
            if let existing = existingHouseholds.first {
                localHousehold = existing
            } else {
                let newHousehold = Household(
                    partnerAName: dbHousehold.partnerALabel,
                    partnerBName: dbHousehold.partnerBLabel,
                    country: dbHousehold.country,
                    currency: dbHousehold.currency,
                    annualInterestRate: dbHousehold.annualInterestRate,
                    setupMode: dbHousehold.setupMode,
                    emailA: dbHousehold.emailA,
                    emailB: dbHousehold.emailB,
                    relationshipType: dbHousehold.relationshipType,
                    agreementType: dbHousehold.agreementType
                )
                newHousehold.id = householdId
                modelContext.insert(newHousehold)
                localHousehold = newHousehold
            }

            // Apply all fields from Supabase
            localHousehold.partnerAName       = dbHousehold.partnerALabel
            localHousehold.partnerBName       = dbHousehold.partnerBLabel
            localHousehold.currency           = dbHousehold.currency
            localHousehold.country            = dbHousehold.country
            localHousehold.annualInterestRate = dbHousehold.annualInterestRate
            localHousehold.setupMode          = dbHousehold.setupMode
            localHousehold.relationshipType   = dbHousehold.relationshipType
            localHousehold.agreementType      = dbHousehold.agreementType
            localHousehold.agreementStatus    = dbHousehold.agreementStatus
            localHousehold.signedAt           = dbHousehold.signedAt
            localHousehold.signedAssetCount   = dbHousehold.signedAssetCount
            localHousehold.signedContribCount = dbHousehold.signedContribCount
            localHousehold.docusealSlug       = dbHousehold.docusealSlug
            localHousehold.docusealViewUrl    = dbHousehold.docusealViewUrl
            localHousehold.emailA             = dbHousehold.emailA
            localHousehold.emailB             = dbHousehold.emailB

            // Agreement config — keep both partners' contracts identical.
            if let v = dbHousehold.rentAmount            { localHousehold.rentAmount = v }
            if let v = dbHousehold.rentPayerKey          { localHousehold.rentPayerKey = v }
            if let v = dbHousehold.rentPaymentDay        { localHousehold.rentPaymentDay = v }
            if let v = dbHousehold.includeDissolutionClause       { localHousehold.includeDissolutionClause = v }
            if let v = dbHousehold.includeSeparatePropertyClause  { localHousehold.includeSeparatePropertyClause = v }
            if let v = dbHousehold.includeBuyoutRightsClause      { localHousehold.includeBuyoutRightsClause = v }
            if let v = dbHousehold.includeDisposalConsentClause   { localHousehold.includeDisposalConsentClause = v }
            if let v = dbHousehold.includeDisputeResolutionClause { localHousehold.includeDisputeResolutionClause = v }
            if let v = dbHousehold.includeDebtClause              { localHousehold.includeDebtClause = v }

            // Budget snapshot — keep both partners' dashboards identical.
            if let v = dbHousehold.budgetIncomeA       { localHousehold.budgetIncomeA = v }
            if let v = dbHousehold.budgetIncomeB       { localHousehold.budgetIncomeB = v }
            if let v = dbHousehold.budgetTotalExpenses { localHousehold.budgetTotalExpenses = v }
            if let v = dbHousehold.budgetSplitA        { localHousehold.budgetSplitA = v }
            if let v = dbHousehold.budgetPaysA         { localHousehold.budgetPaysA = v }
            if let v = dbHousehold.budgetPaysB         { localHousehold.budgetPaysB = v }
            if let v = dbHousehold.budgetNetTransfer   { localHousehold.budgetNetTransfer = v }
            if let v = dbHousehold.budgetSavedAt       { localHousehold.budgetSavedAt = v }

            // Live expense-split working state — keep both partners' calculators identical.
            if let presets = dbHousehold.expensePresets, presets.count == 5 {
                localHousehold.presetAmounts = presets.map { $0.amount }
                localHousehold.presetPayers  = presets.map { $0.payer }
                localHousehold.presetSplits  = presets.map { $0.splitA }
            }
            if let v = dbHousehold.expenseIncomeA   { localHousehold.expenseIncomeA = v }
            if let v = dbHousehold.expenseIncomeB   { localHousehold.expenseIncomeB = v }
            if let v = dbHousehold.expensesUpdatedAt { localHousehold.expensesUpdatedAt = v }

            // Update in-memory state
            household = dbHousehold

            // --- Fetch remote assets ---
            let dbAssets = try await SupabaseService.fetchAssets(householdId: householdId)
            assets = dbAssets

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            for dbAsset in dbAssets {
                let assetId = dbAsset.id

                // Upsert Asset
                let assetDescriptor = FetchDescriptor<Asset>(
                    predicate: #Predicate { $0.id == assetId }
                )
                let existingAssets = (try? modelContext.fetch(assetDescriptor)) ?? []

                let localAsset: Asset
                if let existing = existingAssets.first {
                    localAsset = existing
                } else {
                    let purchaseDate = dateFormatter.date(from: dbAsset.purchaseDate) ?? Date()
                    let newAsset = Asset(
                        assetType: dbAsset.assetType,
                        label: dbAsset.label,
                        address: dbAsset.address,
                        currentValue: dbAsset.currentValue,
                        remainingLoan: dbAsset.remainingLoan,
                        salesCostFraction: dbAsset.salesCostFraction,
                        ownershipShareA: dbAsset.ownershipShareA,
                        sortOrder: dbAsset.sortOrder,
                        purchaseDate: purchaseDate
                    )
                    newAsset.id = assetId
                    modelContext.insert(newAsset)
                    if !localHousehold.assets.contains(where: { $0.id == assetId }) {
                        localHousehold.assets.append(newAsset)
                    }
                    localAsset = newAsset
                }

                // Apply fields
                localAsset.assetType        = dbAsset.assetType
                localAsset.label            = dbAsset.label
                localAsset.address          = dbAsset.address
                localAsset.currentValue     = dbAsset.currentValue
                localAsset.remainingLoan    = dbAsset.remainingLoan
                localAsset.salesCostFraction = dbAsset.salesCostFraction
                localAsset.ownershipShareA  = dbAsset.ownershipShareA
                localAsset.sortOrder          = dbAsset.sortOrder
                if let pd = dateFormatter.date(from: dbAsset.purchaseDate) {
                    localAsset.purchaseDate = pd
                }

                // --- Fetch and upsert Contributions ---
                let dbContribs = (try? await SupabaseService.fetchContributions(assetId: assetId)) ?? []
                contributions[assetId] = dbContribs

                for dbContrib in dbContribs {
                    let contribId = dbContrib.id
                    let contribDescriptor = FetchDescriptor<ContributionRecord>(
                        predicate: #Predicate { $0.id == contribId }
                    )
                    let existingContribs = (try? modelContext.fetch(contribDescriptor)) ?? []

                    // Convert lowercase ownerKey ("a"/"b") to uppercase ("A"/"B")
                    let ownerKey = dbContrib.ownerKey.uppercased()
                    let contribDate = dateFormatter.date(from: dbContrib.date) ?? Date()

                    if let existingContrib = existingContribs.first {
                        existingContrib.ownerKey = ownerKey
                        existingContrib.amount   = dbContrib.amount
                        existingContrib.date     = contribDate
                        existingContrib.label    = dbContrib.label
                        existingContrib.category = dbContrib.category
                    } else {
                        let newContrib = ContributionRecord(
                            ownerKey: ownerKey,
                            amount: dbContrib.amount,
                            date: contribDate,
                            label: dbContrib.label,
                            category: dbContrib.category
                        )
                        newContrib.id = contribId
                        modelContext.insert(newContrib)
                        if !localAsset.contributions.contains(where: { $0.id == contribId }) {
                            localAsset.contributions.append(newContrib)
                        }
                    }
                }
            }

            try? modelContext.save()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Realtime

    /// Subscribes to Supabase Realtime changes for assets, contributions, and
    /// households and calls sync(modelContext:) on every change.
    func subscribeRealtime(householdId: UUID, modelContext: ModelContext) {
        let channelName = "household-\(householdId.uuidString)"
        let channel = supabase.channel(channelName)

        // Capture modelContext as a local so closures don't capture self strongly
        // in a context where @Observable isolation could cause issues.
        let capturedModelContext = UncheckedSendableModelContext(value: modelContext)

        _ = channel.onPostgresChange(AnyAction.self, schema: "public", table: "households") { [weak self] _ in
            guard let self else { return }
            Task { await self.sync(modelContext: capturedModelContext.value) }
        }

        _ = channel.onPostgresChange(AnyAction.self, schema: "public", table: "assets") { [weak self] _ in
            guard let self else { return }
            Task { await self.sync(modelContext: capturedModelContext.value) }
        }

        _ = channel.onPostgresChange(AnyAction.self, schema: "public", table: "contributions") { [weak self] _ in
            guard let self else { return }
            Task { await self.sync(modelContext: capturedModelContext.value) }
        }

        _ = channel.onPostgresChange(AnyAction.self, schema: "public", table: "shared_expenses") { [weak self] _ in
            guard let self else { return }
            Task { await self.sync(modelContext: capturedModelContext.value) }
        }

        realtimeChannel = channel

        Task {
            try? await channel.subscribeWithError()
        }
    }

    // MARK: - Household

    func createHousehold(
        partnerALabel: String, partnerBLabel: String,
        currency: String, country: String, annualInterestRate: Double,
        setupMode: String, relationshipType: String, agreementType: String,
        emailA: String, emailB: String
    ) async throws {
        _ = try await SupabaseService.createHousehold(
            partnerALabel: partnerALabel, partnerBLabel: partnerBLabel,
            currency: currency, country: country,
            annualInterestRate: annualInterestRate, setupMode: setupMode,
            relationshipType: relationshipType, agreementType: agreementType,
            emailA: emailA, emailB: emailB)
        await load()
    }

    func setAgreementStatus(_ status: String, signedAt: Date? = nil) async throws {
        guard let h = household else { throw StoreError.noHousehold }
        try await SupabaseService.updateAgreementStatus(
            householdId: h.id, status: status, signedAt: signedAt)
        household?.agreementStatus = status
        if let d = signedAt { household?.signedAt = d }
    }

    func saveDocuseal(slug: String, viewUrl: String) async throws {
        guard let h = household else { throw StoreError.noHousehold }
        let assetCount  = assets.count
        let contribCount = contributions.values.reduce(0) { $0 + $1.count }
        try await SupabaseService.updateDocusealInfo(
            householdId: h.id, slug: slug, viewUrl: viewUrl,
            assetCount: assetCount, contribCount: contribCount)
        household?.docusealSlug    = slug
        household?.docusealViewUrl = viewUrl
        household?.signedAssetCount  = assetCount
        household?.signedContribCount = contribCount
    }

    // MARK: - Assets

    func addAsset(
        assetType: String, label: String, address: String,
        currentValue: Double, remainingLoan: Double,
        salesCostFraction: Double, ownershipShareA: Double
    ) async throws -> DBAsset {
        guard let h = household else { throw StoreError.noHousehold }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let row = try await SupabaseService.insertAsset(
            householdId: h.id, assetType: assetType, label: label, address: address,
            currentValue: currentValue, remainingLoan: remainingLoan,
            salesCostFraction: salesCostFraction, ownershipShareA: ownershipShareA,
            purchaseDate: f.string(from: Date()))
        assets.append(row)
        contributions[row.id] = []
        return row
    }

    func updateAsset(_ id: UUID, label: String, address: String,
                     currentValue: Double, remainingLoan: Double,
                     ownershipShareA: Double) async throws {
        try await SupabaseService.updateAsset(id, label: label, address: address,
                                               currentValue: currentValue,
                                               remainingLoan: remainingLoan,
                                               ownershipShareA: ownershipShareA)
        if let i = assets.firstIndex(where: { $0.id == id }) {
            assets[i].label = label; assets[i].address = address
            assets[i].currentValue = currentValue; assets[i].remainingLoan = remainingLoan
            assets[i].ownershipShareA = ownershipShareA
        }
    }

    func deleteAsset(_ id: UUID) async throws {
        try await SupabaseService.deleteAsset(id)
        assets.removeAll { $0.id == id }
        contributions.removeValue(forKey: id)
    }

    // MARK: - Contributions

    func addContribution(assetId: UUID, ownerKey: String, amount: Double,
                         date: Date, label: String, category: String) async throws {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let row = try await SupabaseService.insertContribution(
            assetId: assetId, ownerKey: ownerKey, amount: amount,
            date: f.string(from: date), label: label, category: category)
        contributions[assetId, default: []].insert(row, at: 0)
    }

    func deleteContribution(_ id: UUID, assetId: UUID) async throws {
        try await SupabaseService.deleteContribution(id)
        contributions[assetId]?.removeAll { $0.id == id }
    }

    // MARK: - Expenses

    func addExpense(label: String, amount: Double, paidByKey: String,
                    splitRatioA: Double, date: Date, category: String,
                    isRecurring: Bool) async throws {
        guard let h = household else { throw StoreError.noHousehold }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let row = try await SupabaseService.insertExpense(
            householdId: h.id, label: label, amount: amount,
            paidByKey: paidByKey, splitRatioA: splitRatioA,
            date: f.string(from: date), category: category, isRecurring: isRecurring)
        expenses.insert(row, at: 0)
    }

    func deleteExpense(_ id: UUID) async throws {
        try await SupabaseService.deleteExpense(id)
        expenses.removeAll { $0.id == id }
    }

    // MARK: - Invite

    func generateInviteLink() async throws -> URL {
        guard let h = household else { throw StoreError.noHousehold }
        let token = try await SupabaseService.createInviteToken(householdId: h.id)
        // Must match the scheme parsed in CohabApp.onOpenURL and the link built in
        // InvitePartnerView — a universal https link has no associated-domain setup.
        return URL(string: "cohab://join?token=\(token.uuidString)")!
    }

    func joinWithToken(_ tokenString: String) async throws {
        guard let token = UUID(uuidString: tokenString) else { throw StoreError.invalidToken }
        _ = try await SupabaseService.joinHousehold(token: token)
        await load()
    }

    // MARK: - Errors

    enum StoreError: LocalizedError {
        case noHousehold, invalidToken
        var errorDescription: String? {
            switch self {
            case .noHousehold: return "No household loaded."
            case .invalidToken: return "Invalid invite link."
            }
        }
    }
}
