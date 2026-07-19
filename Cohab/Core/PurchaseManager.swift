import StoreKit
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

    /// Purchases one extra BankID signing (consumable). Returns true when
    /// the transaction verified — the caller is responsible for granting
    /// the credit server-side after this returns true.
    func purchaseBankIDExtra() async throws -> Bool {
        guard let bankIDProduct else { return false }
        isLoading = true
        defer { isLoading = false }
        let result = try await bankIDProduct.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let tx) = verification else { return false }
            await tx.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
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

    private func grant() {
        hasFormalAccess = true
        UserDefaults.standard.set(true, forKey: "formalUnlocked")
    }
}
