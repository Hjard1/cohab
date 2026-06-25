import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            CalculatorsView()
                .tabItem { Label("Calculators", systemImage: "function") }
        }
        .tint(.cohGreen)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [Household.self, Asset.self, ContributionRecord.self, SharedExpense.self],
            inMemory: true
        )
}
