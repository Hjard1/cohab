import SwiftUI
import SwiftData
import AuthenticationServices
import CryptoKit

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @EnvironmentObject private var authManager: AuthManager
    @Query private var households: [Household]

    @State private var errorMessage: String?
    @State private var showResetConfirm = false
    @State private var currentNonce = ""    // raw nonce, kept for Supabase verification

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
                            // Google
                            GoogleSignInButton(label: "Continue with Google") { user in
                                onboardingComplete = true
                                dismiss()
                            } onError: { err in
                                errorMessage = err.localizedDescription
                            }

                            // Apple — full Supabase integration with nonce
                            SignInWithAppleButton(.signIn) { request in
                                let nonce = randomNonceString()
                                currentNonce = nonce
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = sha256(nonce)
                            } onCompletion: { result in
                                handleAppleResult(result)
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

                    // Bottom action
                    if households.isEmpty {
                        Button { dismiss() } label: {
                            Text("Back to sign up")
                                .font(.subheadline)
                                .foregroundStyle(Color.cohMuted)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom, 40)
                    } else {
                        // Shown as root after logout — offer clean slate
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
                            Text("Your local assets and contributions will be removed. Sign in later to restore cloud data.")
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if households.isEmpty {
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

    // MARK: - Apple Sign-In handler

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData   = credential.identityToken,
                let idToken     = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Could not extract Apple identity token."
                return
            }

            let nonce = currentNonce   // capture before Task

            Task { @MainActor in
                do {
                    try await authManager.signInWithApple(idToken: idToken, rawNonce: nonce)
                    onboardingComplete = true
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

        case .failure(let error):
            // ASAuthorizationError.canceled (code 1001) — user cancelled, no message needed
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Nonce helpers (Apple requires SHA-256 of the nonce)

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        guard SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes) == errSecSuccess
        else { return UUID().uuidString }
        return randomBytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthManager())
}
