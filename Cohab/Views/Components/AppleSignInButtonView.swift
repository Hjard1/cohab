import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - Reusable "Sign in with Apple" button
//
// Wraps the full Apple → Supabase flow (nonce generation, SHA-256 hashing,
// token extraction and `signInWithApple`) so every entry point — onboarding
// and the returning-user sign-in screen — shares one implementation.
// Requires the `com.apple.developer.applesignin` entitlement to function.

struct AppleSignInButtonView: View {
    /// Called after a Supabase session is successfully established.
    let onSuccess: () -> Void
    /// Called with a user-facing message when sign-in fails (cancellation is ignored).
    let onError: (String) -> Void

    @EnvironmentObject private var authManager: AuthManager
    @State private var currentNonce = ""   // raw nonce, kept for Supabase verification

    var body: some View {
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

    // MARK: - Handler

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData   = credential.identityToken,
                let idToken     = String(data: tokenData, encoding: .utf8)
            else {
                onError(AppStrings.shared.authAppleTokenError)
                return
            }

            let nonce = currentNonce   // capture before Task
            Task { @MainActor in
                do {
                    try await authManager.signInWithApple(idToken: idToken, rawNonce: nonce)
                    onSuccess()
                } catch {
                    onError(error.localizedDescription)
                }
            }

        case .failure(let error):
            // ASAuthorizationError.canceled (code 1001) — user cancelled, stay quiet.
            if (error as? ASAuthorizationError)?.code != .canceled {
                onError(error.localizedDescription)
            }
        }
    }

    // MARK: - Nonce helpers (Apple requires SHA-256 of the raw nonce)

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
