import SwiftUI
import SwiftData

struct SignInView: View {
    /// True when presented as a sheet from inside the app (e.g. the dashboard
    /// sign-in banner) rather than as the root post-logout screen. Hides the
    /// destructive "start fresh" option and always shows a close button.
    var presentedAsSheet = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @AppStorage("wasSignedOut") private var wasSignedOut = false
    @EnvironmentObject private var authManager: AuthManager
    @ObservedObject private var strings = AppStrings.shared
    @Query private var households: [Household]

    @State private var errorMessage: String?
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cohBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 24) {
                        // Logo + heading
                        VStack(spacing: 12) {
                            Text("cohab")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .tracking(5)
                                .foregroundStyle(Color.cohGreen)

                            Text(strings.signInWelcomeBack)
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundStyle(Color.cohInk)

                            Text(strings.signInSubtitle)
                                .font(.subheadline)
                                .foregroundStyle(Color.cohMuted)
                                .multilineTextAlignment(.center)
                        }

                        // Sign-in buttons
                        VStack(spacing: 12) {
                            // Google
                            GoogleSignInButton(label: strings.onboardingContinueWithGoogle) { _ in
                                wasSignedOut = false
                                onboardingComplete = true
                                dismiss()
                            } onError: { err in
                                errorMessage = err.localizedDescription
                            }

                            // Apple — shared component (full Supabase integration + nonce)
                            AppleSignInButtonView {
                                wasSignedOut = false
                                onboardingComplete = true
                                dismiss()
                            } onError: { msg in
                                errorMessage = msg
                            }
                        }

                        if let err = errorMessage {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 28)

                    Spacer()

                    // Bottom action
                    if households.isEmpty {
                        Button { dismiss() } label: {
                            Text(strings.signInBackToSignUp)
                                .font(.subheadline)
                                .foregroundStyle(Color.cohMuted)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom, 40)
                    } else if !presentedAsSheet {
                        // Shown as root after logout — offer clean slate
                        Button { showResetConfirm = true } label: {
                            Text(strings.signInStartFresh)
                                .font(.caption)
                                .foregroundStyle(Color.cohTertiary)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom, 40)
                        .confirmationDialog(strings.signInDeleteTitle,
                                            isPresented: $showResetConfirm,
                                            titleVisibility: .visible) {
                            Button(strings.signInDeleteConfirm, role: .destructive) {
                                for h in households { modelContext.delete(h) }
                                try? modelContext.save()
                                onboardingComplete = false
                            }
                            Button(strings.cancel, role: .cancel) {}
                        } message: {
                            Text(strings.signInDeleteMessage)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if households.isEmpty || presentedAsSheet {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.cohMuted)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthManager())
}
