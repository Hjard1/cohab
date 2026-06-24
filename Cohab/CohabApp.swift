import SwiftUI
import SwiftData

@main
struct CohabApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: [Household.self, Asset.self, ContributionRecord.self, SharedExpense.self]
        )
    }
}
