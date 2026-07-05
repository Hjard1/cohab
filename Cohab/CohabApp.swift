import SwiftUI
import SwiftData

@main
struct CohabApp: App {
    @StateObject private var strings = AppStrings.shared
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var auth = AuthManager()
    @State private var store = HouseholdStore()
    @State private var pendingInviteToken: UUID? = nil

    var body: some Scene {
        WindowGroup {
            ContentView(pendingInviteToken: $pendingInviteToken)
                .environmentObject(strings)
                .environmentObject(purchaseManager)
                .environmentObject(auth)
                .environment(store)
                .task { await purchaseManager.load() }
                .task {
                    await auth.checkSession()   // fast local session check before network
                    auth.listenForAuthChanges() // then stream auth events
                }
                .onOpenURL { url in
                    // cohab://join?token=UUID
                    if url.scheme == "cohab", url.host == "join",
                       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let tokenStr = components.queryItems?.first(where: { $0.name == "token" })?.value,
                       let token = UUID(uuidString: tokenStr) {
                        pendingInviteToken = token
                    }
                }
        }
        .modelContainer(
            for: [Household.self, Asset.self, ContributionRecord.self, SharedExpense.self, FurnitureItem.self]
        )
    }
}
