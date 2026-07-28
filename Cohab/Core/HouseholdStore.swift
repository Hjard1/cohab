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
    private(set) var memberCount = 0
    private(set) var isLoading = false
    private(set) var error: String?

    // Realtime channel — retained so it is not deallocated
    private var realtimeChannel: RealtimeChannelV2?

    // Guard against re-entrant claims (realtime events firing during a claim)
    private var isClaiming = false

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
            memberCount = (try? await SupabaseService.fetchMemberCount(householdId: householdId)) ?? 0
        } catch { self.error = error.localizedDescription }
    }

    // MARK: - SwiftData Sync

    /// Pulls the full household + assets + contributions from Supabase and
    /// upserts everything into the local SwiftData store.
    func sync(modelContext: ModelContext) async {
        do {
            guard let dbHousehold = try await SupabaseService.fetchHousehold() else {
                // Nothing on the server for this user. If they are signed in and
                // have a local household (created while signed out, possible before
                // sign-in was mandatory), claim it to the cloud so expenses,
                // agreement and partner sync work.
                await claimLocalHouseholdIfNeeded(modelContext: modelContext)
                return
            }

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
            localHousehold.partnerLeft        = dbHousehold.partnerLeftAt != nil
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
            if let v = dbHousehold.budgetHidden        { localHousehold.budgetHidden = v }

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
            memberCount = (try? await SupabaseService.fetchMemberCount(householdId: householdId)) ?? memberCount
            // Custom-expense mirror for ExpenseSplitView — without this the
            // list was empty at every launch, looking like adds never saved.
            expenses = (try? await SupabaseService.fetchExpenses(householdId: householdId)) ?? []

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
                    // An earlier claim preserved ids, so the asset may still be
                    // attached to a leftover local household — re-home it to the
                    // canonical one (it is detached from the leftover in the
                    // prune below, before the context is saved).
                    if !localHousehold.assets.contains(where: { $0.id == assetId }) {
                        localHousehold.assets.append(existing)
                    }
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

                // Reconcile: remove local contributions the server no longer
                // has (deleted by either partner, or a local delete whose
                // autosave was lost). Our own pushes preserve ids and realtime
                // re-fires sync after each commit, so a just-added row is
                // already present in dbContribs at this point.
                let remoteContribIds = Set(dbContribs.map { $0.id })
                let staleContribs = localAsset.contributions.filter { !remoteContribIds.contains($0.id) }
                for stale in staleContribs {
                    modelContext.delete(stale)
                }
            }

            // Reconcile assets: drop local assets of the canonical household
            // that no longer exist remotely (deleted by either partner).
            // Their contributions cascade-delete with them.
            let remoteAssetIds = Set(dbAssets.map { $0.id })
            let staleAssets = localHousehold.assets.filter { !remoteAssetIds.contains($0.id) }
            for stale in staleAssets {
                modelContext.delete(stale)
            }

            // Remove leftover local households that don't match the canonical
            // remote one (e.g. from a repeated onboarding, or a pre-sign-in
            // local household whose remote copy was superseded). Once a remote
            // household exists, a divergent local one can never be claimed —
            // claim only runs when the server has nothing — so keeping it only
            // lets stale data hijack `households.first` in every view: wrong id
            // → FK failures on invite, silent no-op pushes, split-brain views.
            // Children unique to the leftover are deleted with it; children
            // shared with the canonical household (ids preserved by an earlier
            // claim) are kept — they were re-homed in the asset loop above.
            let allLocal = (try? modelContext.fetch(FetchDescriptor<Household>())) ?? []
            for extra in allLocal where extra.id != householdId {
                for asset in extra.assets
                where !localHousehold.assets.contains(where: { $0.id == asset.id }) {
                    modelContext.delete(asset)
                }
                for expense in extra.expenses {
                    modelContext.delete(expense)
                }
                // Detach before delete so the cascade cannot touch children
                // that were re-homed to the canonical household.
                extra.assets = []
                extra.expenses = []
                modelContext.delete(extra)
            }

            try? modelContext.save()
            // Clear any previous sync error only after a fully successful
            // pass — the dashboard banner reflects the latest state.
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// One-time migration for households created locally while signed out.
    /// Pushes the local SwiftData graph to Supabase — preserving ids so nothing
    /// needs remapping — then re-runs sync to adopt the canonical remote state.
    private func claimLocalHouseholdIfNeeded(modelContext: ModelContext) async {
        guard !isClaiming else { return }
        // Claiming requires an authenticated session (RLS).
        guard (try? await supabase.auth.session.user.id) != nil else { return }
        let locals = (try? modelContext.fetch(FetchDescriptor<Household>())) ?? []
        guard let local = locals.first else { return }

        isClaiming = true
        defer { isClaiming = false }

        do {
            try await ignoreAlreadyClaimed {
                try await SupabaseService.insertHouseholdPreservingId(
                    id: local.id,
                    partnerALabel: local.partnerAName, partnerBLabel: local.partnerBName,
                    currency: local.currency, country: local.country,
                    annualInterestRate: local.annualInterestRate,
                    setupMode: local.setupMode, relationshipType: local.relationshipType,
                    agreementType: local.agreementType,
                    emailA: local.emailA, emailB: local.emailB)
            }
            try await ignoreAlreadyClaimed {
                try await SupabaseService.insertMembership(householdId: local.id)
            }

            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
            for asset in local.assets {
                try await ignoreAlreadyClaimed {
                    try await SupabaseService.insertAssetPreservingId(
                        id: asset.id, householdId: local.id,
                        assetType: asset.assetType, label: asset.label, address: asset.address,
                        currentValue: asset.currentValue, remainingLoan: asset.remainingLoan,
                        salesCostFraction: asset.salesCostFraction,
                        ownershipShareA: min(max(asset.ownershipShareA, 0), 1),
                        sortOrder: asset.sortOrder, purchaseDate: f.string(from: asset.purchaseDate))
                }
                // The DB requires amount > 0 — skip empty rows rather than fail the claim.
                for c in asset.contributions where c.amount > 0 {
                    try await ignoreAlreadyClaimed {
                        try await SupabaseService.insertContributionPreservingId(
                            id: c.id, assetId: asset.id,
                            ownerKey: c.ownerKey.lowercased(), amount: c.amount,
                            date: f.string(from: c.date), label: c.label, category: c.category)
                    }
                }
            }

            // Extended household state lives in separate columns — reuse the
            // existing update methods rather than widening the upsert row.
            try await SupabaseService.updateAgreementConfig(
                householdId: local.id,
                rentAmount: local.rentAmount, rentPayerKey: local.rentPayerKey,
                rentPaymentDay: local.rentPaymentDay,
                includeDissolutionClause: local.includeDissolutionClause,
                includeSeparatePropertyClause: local.includeSeparatePropertyClause,
                includeBuyoutRightsClause: local.includeBuyoutRightsClause,
                includeDisposalConsentClause: local.includeDisposalConsentClause,
                includeDisputeResolutionClause: local.includeDisputeResolutionClause,
                includeDebtClause: local.includeDebtClause)

            if local.hasBudget, let savedAt = local.budgetSavedAt {
                try await SupabaseService.updateHouseholdBudget(
                    householdId: local.id,
                    incomeA: local.budgetIncomeA, incomeB: local.budgetIncomeB,
                    totalExpenses: local.budgetTotalExpenses, splitA: local.budgetSplitA,
                    paysA: local.budgetPaysA, paysB: local.budgetPaysB,
                    netTransfer: local.budgetNetTransfer, savedAt: savedAt,
                    hidden: local.budgetHidden)
            }

            if let updatedAt = local.expensesUpdatedAt,
               local.presetAmounts.count == 5, local.presetPayers.count == 5,
               local.presetSplits.count == 5 {
                let presets = (0..<5).map {
                    DBExpensePreset(amount: local.presetAmounts[$0],
                                    payer: local.presetPayers[$0],
                                    splitA: local.presetSplits[$0])
                }
                try await SupabaseService.updateExpensePresets(
                    householdId: local.id, presets: presets,
                    incomeA: local.expenseIncomeA, incomeB: local.expenseIncomeB,
                    updatedAt: updatedAt)
            }

            // Adopt the canonical remote state (sets household, assets, expenses…).
            await sync(modelContext: modelContext)
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Tolerates duplicate-key errors (23505) so a retry after a partially
    /// completed claim continues past rows that already made it to the server.
    private func ignoreAlreadyClaimed(_ work: () async throws -> Void) async throws {
        do { try await work() }
        catch let e as PostgrestError where e.code == "23505" { }
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

        // Membership changes (partner joined) — updates the invite card visibility
        _ = channel.onPostgresChange(AnyAction.self, schema: "public", table: "household_members") { [weak self] _ in
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
        Task { await SupabaseService.notifyPartner(kind: "asset", label: label, householdId: h.id) }
        return row
    }

    func updateAsset(_ id: UUID, assetType: String, label: String, address: String,
                     currentValue: Double, remainingLoan: Double,
                     salesCostFraction: Double, ownershipShareA: Double) async throws {
        try await SupabaseService.updateAsset(id, assetType: assetType, label: label,
                                               address: address, currentValue: currentValue,
                                               remainingLoan: remainingLoan,
                                               salesCostFraction: salesCostFraction,
                                               ownershipShareA: ownershipShareA)
        if let i = assets.firstIndex(where: { $0.id == id }) {
            assets[i].assetType = assetType
            assets[i].label = label; assets[i].address = address
            assets[i].currentValue = currentValue; assets[i].remainingLoan = remainingLoan
            assets[i].salesCostFraction = salesCostFraction
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
        if let hid = household?.id {
            let assetLabel = assets.first(where: { $0.id == assetId })?.label ?? label
            Task { await SupabaseService.notifyPartner(kind: "contribution", label: assetLabel, householdId: hid) }
        }
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
        Task { await SupabaseService.notifyPartner(kind: "expense", label: label, householdId: h.id) }
    }

    func deleteExpense(_ id: UUID) async throws {
        try await SupabaseService.deleteExpense(id)
        expenses.removeAll { $0.id == id }
    }

    func updateExpense(_ id: UUID, amount: Double, paidByKey: String,
                       splitRatioA: Double) async throws {
        try await SupabaseService.updateExpense(id: id, amount: amount,
                                                paidByKey: paidByKey, splitRatioA: splitRatioA)
        if let i = expenses.firstIndex(where: { $0.id == id }) {
            expenses[i].amount = amount
            expenses[i].paidByKey = paidByKey
            expenses[i].splitRatioA = splitRatioA
        }
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
