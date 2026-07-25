import StoreKit
import Supabase
import Foundation

@MainActor
final class PurchaseManager: ObservableObject {
    /// One-time product that unlocks the formal agreement — what the paywall
    /// sells. Lifetime access, no subscription.
    static let formalProductID = "com.hjard.cohab.formal"
    /// Consumable: one extra BankID signing (125 NOK). The first BankID
    /// signing per household is included; every further one costs a credit.
    static let bankIDExtraProductID = "com.hjard.cohab.bankid_extra"

    @Published private(set) var hasFormalAccess: Bool
    @Published private(set) var isLoading = false
    @Published private(set) var priceDisplay: String = "$49"
    @Published private(set) var bankIDPriceDisplay: String = "125 kr"

    private var product: Product?
    private var bankIDProduct: Product?
    private var transactionListener: Task<Void, Never>?

    init() {
        self.hasFormalAccess = UserDefaults.standard.bool(forKey: "formalUnlocked")
        // Lives for the app's lifetime — catches renewals, expirations and
        // revocations while the app is running.
        transactionListener = listenForTransactions()
    }

    func load() async {
        // Never trust the persisted flag blindly — it may be a leftover from a
        // dev build that granted free access. Re-verify with StoreKit on every
        // launch and grant only on a verified, unrevoked entitlement.
        hasFormalAccess = false
        UserDefaults.standard.set(false, forKey: "formalUnlocked")
        // Verify any existing entitlement with StoreKit.
        var grantedJWS: String?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.productID == Self.formalProductID && tx.revocationDate == nil {
                grant()
                grantedJWS = result.jwsRepresentation
                break
            }
        }
        if !hasFormalAccess {
            // No local StoreKit entitlement — check the server-side entitlement
            // (set by a web purchase via Stripe) before concluding.
            await refreshServerEntitlement()
        }
        // Best-effort server sync so a purchase made in the app also unlocks
        // the web.
        if let jws = grantedJWS {
            await syncAppPurchase(jws: jws)
        }
        // Load products for price display
        if let products = try? await Product.products(for: [Self.formalProductID, Self.bankIDExtraProductID]) {
            for p in products {
                if p.id == Self.formalProductID {
                    product = p
                    priceDisplay = p.displayPrice
                } else if p.id == Self.bankIDExtraProductID {
                    bankIDProduct = p
                    bankIDPriceDisplay = p.displayPrice
                }
            }
        }
    }

    // MARK: - Transaction listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let tx) = update else { continue }
                await self?.handle(transaction: tx, jws: update.jwsRepresentation)
            }
        }
    }

    private func handle(transaction tx: StoreKit.Transaction, jws: String) async {
        if tx.productID == Self.formalProductID {
            if tx.revocationDate == nil {
                grant()
                await syncAppPurchase(jws: jws)
            } else {
                // Revoked (refund) — drop access unless another entitlement
                // still holds.
                await recheckEntitlements()
            }
        }
        await tx.finish()
    }

    /// Re-evaluates access after a revocation/expiration: grants when any
    /// entitlement (StoreKit or server) still holds, revokes otherwise.
    private func recheckEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.productID == Self.formalProductID && tx.revocationDate == nil {
                grant()
                return
            }
        }
        let serverGranted = await refreshServerEntitlement()
        if !serverGranted { revoke() }
    }

    // MARK: - Purchases

    func purchase() async throws {
        guard let product else { return }
        isLoading = true
        defer { isLoading = false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let tx) = verification else { return }
            grant()
            await syncAppPurchase(jws: verification.jwsRepresentation)
            await tx.finish()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    /// Purchases one extra BankID signing (consumable). Returns the verified
    /// transaction's JWS representation on success — the caller must POST it
    /// to the add-bankid-credit edge function, which verifies the purchase
    /// server-side and grants the credit.
    func purchaseBankIDExtra() async throws -> String? {
        guard let bankIDProduct else { return nil }
        isLoading = true
        defer { isLoading = false }
        let result = try await bankIDProduct.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let tx) = verification else { return nil }
            let jws = verification.jwsRepresentation
            await tx.finish()
            return jws
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.productID == Self.formalProductID && tx.revocationDate == nil {
                grant()
                await syncAppPurchase(jws: result.jwsRepresentation)
                return
            }
        }
        // Neither StoreKit nor the server grants access — make sure a stale
        // local flag is cleared.
        let serverGranted = await refreshServerEntitlement()
        if !serverGranted { revoke() }
    }

    // MARK: - Server entitlement

    /// Checks the server-side entitlement (cohab_entitlements) for the
    /// signed-in user. A web purchase via Stripe sets formal_unlocked — this
    /// merges it with the local StoreKit entitlement. A subscription row only
    /// grants while expires_at is null (legacy lifetime) or in the future.
    /// Fails silently when offline or signed out; local behavior is unchanged
    /// in that case. Returns true when the server granted access.
    @discardableResult
    func refreshServerEntitlement() async -> Bool {
        guard let session = try? await supabase.auth.session else { return false }
        do {
            let rows: [EntitlementRow] = try await supabase
                .from("cohab_entitlements")
                .select("formal_unlocked, expires_at")
                .eq("user_id", value: session.user.id)
                .limit(1)
                .execute()
                .value
            guard let row = rows.first, row.formalUnlocked else { return false }
            if let expiresAt = Self.parseServerDate(row.expiresAt), expiresAt < Date() {
                return false
            }
            grant()
            return true
        } catch {
            // No network or no row — keep the local StoreKit-only behavior.
            return false
        }
    }

    private struct EntitlementRow: Decodable {
        let formalUnlocked: Bool
        let expiresAt: String?
        enum CodingKeys: String, CodingKey {
            case formalUnlocked = "formal_unlocked"
            case expiresAt = "expires_at"
        }
    }

    private static func parseServerDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: raw) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: raw)
    }

    // MARK: - Server sync of App Store purchases

    /// Best-effort upload of a verified App Store transaction to the
    /// sync-app-purchase edge function, which re-verifies the JWS server-side
    /// and records the entitlement so web access matches the app. Fails
    /// silently — the local StoreKit entitlement is authoritative in the app.
    private func syncAppPurchase(jws: String) async {
        guard let session = try? await supabase.auth.session else { return }
        do {
            var request = URLRequest(url: URL(string: "\(APIConfig.supabaseURL)/functions/v1/sync-app-purchase")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["jws": jws])
            request.timeoutInterval = 15
            _ = try await URLSession.shared.data(for: request)
        } catch {
            // Offline or function unreachable — the next launch retries.
        }
    }

    // MARK: - Access flag

    private func grant() {
        hasFormalAccess = true
        UserDefaults.standard.set(true, forKey: "formalUnlocked")
    }

    private func revoke() {
        hasFormalAccess = false
        UserDefaults.standard.set(false, forKey: "formalUnlocked")
    }
}
