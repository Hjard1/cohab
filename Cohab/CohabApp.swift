import SwiftUI
import SwiftData
import UserNotifications

/// Handles APNs registration callbacks and shows banners while the app is
/// in the foreground (otherwise iOS silences them).
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in PushManager.shared.didRegister(deviceToken: deviceToken) }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) { }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

@main
struct CohabApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
                // A web purchase (Stripe) unlocks "formal" server-side —
                // pick it up whenever the user signs in.
                .onChange(of: auth.isSignedIn) { _, signedIn in
                    if signedIn {
                        Task { await purchaseManager.refreshServerEntitlement() }
                    }
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
