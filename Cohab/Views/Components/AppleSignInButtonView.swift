import SwiftUI
import AuthenticationServices

// MARK: - Reusable "Sign in with Apple" button
//
// Wraps the full Apple → Supabase flow so every entry point — onboarding
// and the returning-user sign-in screen — shares one implementation.
// No nonce is used: Supabase accepts the Apple identity token without one
// (same pattern as the published Samboappen app, which signs in fine on
// the same devices where the nonce variant failed with ASAuthorization
// error 1000).
// Requires the `com.apple.developer.applesignin` entitlement to function.

struct AppleSignInButtonView: View {
    /// Called after a Supabase session is successfully established.
    let onSuccess: () -> Void
    /// Called with a user-facing message when sign-in fails (cancellation is ignored).
    let onError: (String) -> Void

    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
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

            Task { @MainActor in
                do {
                    try await authManager.signInWithApple(idToken: idToken)
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
}
