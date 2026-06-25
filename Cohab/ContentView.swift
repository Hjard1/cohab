import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @Query private var households: [Household]

    var body: some View {
        Group {
            if onboardingComplete || !households.isEmpty {
                mainApp
            } else {
                OnboardingView()
            }
        }
        // If the app was installed before onboarding was added, skip it
        .onAppear {
            if !households.isEmpty && !onboardingComplete {
                onboardingComplete = true
            }
        }
    }

    private var mainApp: some View {
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
