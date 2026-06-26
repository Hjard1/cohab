import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    @State private var isLoadingGoogle = false
    @State private var errorMessage: String?

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

                            Text("Sign in to access your household data.")
                                .font(.subheadline)
                                .foregroundStyle(Color.cohMuted)
                                .multilineTextAlignment(.center)
                        }

                        // Sign-in buttons
                        VStack(spacing: 12) {
                            // Google
                            GoogleSignInButton(label: "Continue with Google") { user in
                                handleSignIn(email: user.email, name: user.givenName)
                            } onError: { err in
                                errorMessage = err.localizedDescription
                            }

                            // Apple
                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                switch result {
                                case .success(let auth):
                                    if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                                        let email = credential.email ?? ""
                                        let name = credential.fullName?.givenName ?? ""
                                        handleSignIn(email: email, name: name)
                                    }
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

                        // Coming soon note
                        Text("Cloud sync is coming soon. Signing in now establishes your identity for when sync launches.")
                            .font(.caption)
                            .foregroundStyle(Color.cohMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 28)

                    Spacer()

                    Button { dismiss() } label: {
                        Text("Back to sign up")
                            .font(.subheadline)
                            .foregroundStyle(Color.cohMuted)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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

    private func handleSignIn(email: String, name: String) {
        // TODO: check Supabase for existing household data and restore it.
        // For now, mark onboarding complete so they land on the (empty) dashboard.
        // When cloud sync ships, this is where we fetch and restore their data.
        withAnimation { onboardingComplete = true }
        dismiss()
    }
}

#Preview {
    SignInView()
}
