import SwiftUI
import SwiftData

enum AppTab: Hashable { case home, equity, agreement, calculators }

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
    @State private var initialSyncCompleted = false
    @State private var completedOnboardingThisSession = false
    @State private var selectedTab: AppTab = .home

    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isJoiningHousehold {
                // Deep-link join in progress — show spinner with message
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.4)
                    Text(strings.joiningHousehold)
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.cohBg.ignoresSafeArea())
            } else if pendingInviteToken != nil && !auth.isSignedIn {
                // Invitee opened a join link but isn't signed in. Send them to sign in
                // (not onboarding — that would create a *separate* household). The join
                // fires automatically once the session is established (see .task below).
                SignInView()
            } else if (onboardingComplete || completedOnboardingThisSession || !households.isEmpty) && !wasSignedOut {
                mainApp
            } else if wasSignedOut && (onboardingComplete || !households.isEmpty) {
                SignInView()
            } else if auth.isSignedIn && !initialSyncCompleted {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                OnboardingView {
                    completedOnboardingThisSession = true
                }
            }
        }
        // Show join error as an alert on top of whatever screen is showing
        .alert(strings.joinFailed, isPresented: Binding(
            get: { joinError != nil },
            set: { if !$0 { joinError = nil } }
        )) {
            Button(strings.ok, role: .cancel) { joinError = nil }
        } message: {
            Text(joinError ?? "")
        }
        .task(id: auth.isSignedIn) {
            initialSyncCompleted = false
            if auth.isSignedIn {
                await store.sync(modelContext: modelContext)
                if let h = households.first {
                    store.subscribeRealtime(householdId: h.id, modelContext: modelContext)
                }
                if let token = pendingInviteToken {
                    await handleJoin(token: token)
                    pendingInviteToken = nil
                }
            }
            initialSyncCompleted = true
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
        return TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tabItem { Label(s.tabHome, systemImage: "house.fill") }
                .tag(AppTab.home)
            SettlementTabView()
                .tabItem { Label(s.tabEquity, systemImage: "chart.pie.fill") }
                .tag(AppTab.equity)
            AgreementTabView()
                .tabItem { Label(s.tabAgreement, systemImage: "doc.text.fill") }
                .tag(AppTab.agreement)
            CalculatorsView()
                .tabItem { Label(s.tabCalculators, systemImage: "function") }
                .tag(AppTab.calculators)
        }
        .tint(Color.cohInk)
        .preferredColorScheme(.light)
        .toolbarBackground(Color.cohBg, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
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
