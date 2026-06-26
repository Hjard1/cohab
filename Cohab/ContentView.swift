import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @Query private var households: [Household]
    @EnvironmentObject private var strings: AppStrings

    var body: some View {
        Group {
            if onboardingComplete || !households.isEmpty {
                mainApp
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            if !households.isEmpty && !onboardingComplete {
                onboardingComplete = true
            }
            // Set language from household country
            if let h = households.first {
                strings.language = AppLanguage.from(country: h.country)
            }
        }
        .onChange(of: households.first?.country) { _, country in
            if let c = country {
                strings.language = AppLanguage.from(country: c)
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
