import StoreKit
import Foundation

@MainActor
final class PurchaseManager: ObservableObject {
    static let formalProductID = "com.hjard.cohab.formal"

    @Published private(set) var hasFormalAccess: Bool
    @Published private(set) var isLoading = false
    @Published private(set) var priceDisplay: String = "$39"

    private var product: Product?

    init() {
        self.hasFormalAccess = UserDefaults.standard.bool(forKey: "formalUnlocked")
    }

    func load() async {
        // Verify any existing entitlement with StoreKit
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.productID == Self.formalProductID && tx.revocationDate == nil {
                grant()
                return
            }
        }
        // Load product for price display
        if let products = try? await Product.products(for: [Self.formalProductID]),
           let p = products.first {
            product = p
            priceDisplay = p.displayPrice
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
