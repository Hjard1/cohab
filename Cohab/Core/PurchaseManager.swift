import StoreKit
import Supabase
import Foundation

@MainActor
final class PurchaseManager: ObservableObject {
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

    init() {
        self.hasFormalAccess = UserDefaults.standard.bool(forKey: "formalUnlocked")
    }

    func load() async {
        // Never trust the persisted flag blindly — it may be a leftover from a
        // dev build that granted free access. Re-verify with StoreKit on every
        // launch and grant only on a verified, unrevoked entitlement.
        hasFormalAccess = false
        UserDefaults.standard.set(false, forKey: "formalUnlocked")
        // Verify any existing entitlement with StoreKit
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.productID == Self.formalProductID && tx.revocationDate == nil {
                grant()
                return
            }
        }
        // No local StoreKit entitlement — check the server-side entitlement
        // (set by a web purchase via Stripe) before concluding.
        await refreshServerEntitlement()
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

    func purchase() async throws {
        guard let product else { return }
        isLoading = true
        defer { isLoading = false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let tx) = verification else { return }
            grant()
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
                return
            }
        }
    }

    /// Checks the server-side entitlement (cohab_entitlements) for the
    /// signed-in user. A web purchase via Stripe sets formal_unlocked — this
    /// merges it with the local StoreKit entitlement. Fails silently when
    /// offline or signed out; local behavior is unchanged in that case.
    func refreshServerEntitlement() async {
        guard let session = try? await supabase.auth.session else { return }
        do {
            let rows: [EntitlementRow] = try await supabase
                .from("cohab_entitlements")
                .select("formal_unlocked")
                .eq("user_id", value: session.user.id)
                .limit(1)
                .execute()
                .value
            if rows.first?.formalUnlocked == true { grant() }
        } catch {
            // No network or no row — keep the local StoreKit-only behavior.
        }
    }

    private struct EntitlementRow: Decodable {
        let formalUnlocked: Bool
        enum CodingKeys: String, CodingKey { case formalUnlocked = "formal_unlocked" }
    }

    private func grant() {
        hasFormalAccess = true
        UserDefaults.standard.set(true, forKey: "formalUnlocked")
    }
}
