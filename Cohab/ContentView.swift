import SwiftUI
import SwiftData

struct ContentView: View {
    @Binding var pendingInviteToken: UUID?

    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @AppStorage("wasSignedOut") private var wasSignedOut = false
    @Query private var households: [Household]
    @EnvironmentObject private var strings: AppStrings
    @EnvironmentObject private var auth: AuthManager
    @Environment(HouseholdStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @State private var isJoiningHousehold = false
    @State private var joinError: String? = nil

    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if (onboardingComplete || !households.isEmpty) && !wasSignedOut {
                // Has data and not explicitly signed out → main app (signed in or offline)
                mainApp
            } else if wasSignedOut && (onboardingComplete || !households.isEmpty) {
                // Explicitly signed out → re-auth screen (data preserved on device)
                SignInView()
            } else {
                // No data → full onboarding
                OnboardingView()
            }
        }
        .task(id: auth.isSignedIn) {
            if auth.isSignedIn {
                await store.sync(modelContext: modelContext)
                if let h = households.first {
                    store.subscribeRealtime(householdId: h.id, modelContext: modelContext)
                }
                // Handle pending invite token after sign-in
                if let token = pendingInviteToken {
                    await handleJoin(token: token)
                    pendingInviteToken = nil
                }
            }
        }
        .onChange(of: pendingInviteToken) { _, token in
            guard let token, auth.isSignedIn else { return }
            Task {
                await handleJoin(token: token)
                pendingInviteToken = nil
            }
        }
        .onChange(of: households.first?.id) { _, id in
            if let id, auth.isSignedIn {
                store.subscribeRealtime(householdId: id, modelContext: modelContext)
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
        let s = AppStrings.shared
        return TabView {
            DashboardView()
                .tabItem { Label(s.tabHome, systemImage: "house.fill") }
            SettlementTabView()
                .tabItem { Label(s.tabEquity, systemImage: "chart.pie.fill") }
            AgreementTabView()
                .tabItem { Label(s.tabAgreement, systemImage: "doc.text.fill") }
            CalculatorsView()
                .tabItem { Label(s.tabCalculators, systemImage: "function") }
        }
        .tint(Color.cohInk)
        .preferredColorScheme(.light)
    }

    // MARK: - Invite join

    private func handleJoin(token: UUID) async {
        isJoiningHousehold = true
        do {
            _ = try await SupabaseService.joinHousehold(token: token)
            await store.sync(modelContext: modelContext)
            onboardingComplete = true
        } catch {
            joinError = error.localizedDescription
        }
        isJoiningHousehold = false
    }
}

#Preview {
    ContentView(pendingInviteToken: .constant(nil))
        .modelContainer(
            for: [Household.self, Asset.self, ContributionRecord.self, SharedExpense.self],
            inMemory: true
        )
}
