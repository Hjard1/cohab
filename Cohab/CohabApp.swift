import SwiftUI
import SwiftData

@main
struct CohabApp: App {
    @StateObject private var strings = AppStrings.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(strings)
        }
        .modelContainer(
            for: [Household.self, Asset.self, ContributionRecord.self, SharedExpense.self]
        )
    }
}
