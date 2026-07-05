import SwiftUI
import SwiftData
import AuthenticationServices

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @EnvironmentObject private var auth: AuthManager
    @Query private var households: [Household]

    @State private var errorMessage: String?
    @State private var showResetConfirm = false

    // When used as root (after logout), dismiss() is a no-op.
    // ContentView reacts to auth.isSignedIn changing to true.
    private var isRoot: Bool { !households.isEmpty && !onboardingComplete }

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

                            Text("Welcome back")
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundStyle(Color.cohInk)

                            Text("Sign in to access your household.")
                                .font(.subheadline)
                                .foregroundStyle(Color.cohMuted)
                                .multilineTextAlignment(.center)
                        }

                        // Sign-in buttons
                        VStack(spacing: 12) {
                            GoogleSignInButton(label: "Continue with Google") { user in
                                // Auth state listener in ContentView will switch to mainApp
                                // once auth.isSignedIn = true. No dismiss() needed.
                                onboardingComplete = true
                                dismiss()   // no-op as root, works fine as sheet
                            } onError: { err in
                                errorMessage = err.localizedDescription
                            }

                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                switch result {
                                case .success(_):
                                    // Apple auth — ContentView reacts when auth.isSignedIn flips
                                    onboardingComplete = true
                                    dismiss()
                                case .failure(let err):
                                    errorMessage = err.localizedDescription
                                }
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 52)
                            .cornerRadius(14)
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

                    // "New user / start fresh" — only meaningful when shown as root
                    if households.isEmpty {
                        // Shown as sheet from onboarding — simple dismiss
                        Button { dismiss() } label: {
                            Text("Back to sign up")
                                .font(.subheadline)
                                .foregroundStyle(Color.cohMuted)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom, 40)
                    } else {
                        // Shown as root after logout — offer to clear data and start fresh
                        Button { showResetConfirm = true } label: {
                            Text("Start fresh — delete local data")
                                .font(.caption)
                                .foregroundStyle(Color.cohTertiary)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom, 40)
                        .confirmationDialog("Delete local data?",
                                            isPresented: $showResetConfirm,
                                            titleVisibility: .visible) {
                            Button("Delete and start over", role: .destructive) {
                                for h in households { modelContext.delete(h) }
                                try? modelContext.save()
                                onboardingComplete = false
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Your local assets and contributions will be removed. You can sign in later to restore cloud data.")
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isRoot {
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
}
