import SwiftUI
import AuthenticationServices

// MARK: - Reusable "Sign in with Apple" button
//
// Drives ASAuthorizationController MANUALLY with an explicit presentation
// anchor instead of using SwiftUI's SignInWithAppleButton. The SwiftUI
// button resolves its own presentation context, and in some view
// hierarchies that resolution fails and Apple returns ASAuthorizationError
// 1000 ("Sign Up Not Completed") before any token is issued — exactly the
// failure seen on-device. The manual controller (same pattern the
// Capacitor plugin in Samboappen uses) is the robust approach.
// Requires the `com.apple.developer.applesignin` entitlement to function.

struct AppleSignInButtonView: View {
    /// Called after a Supabase session is successfully established.
    let onSuccess: () -> Void
    /// Called with a user-facing message when sign-in fails (cancellation is ignored).
    let onError: (String) -> Void

    @EnvironmentObject private var authManager: AuthManager
    @ObservedObject private var strings = AppStrings.shared
    @StateObject private var coordinator = AppleSignInCoordinator()

    var body: some View {
        Button {
            coordinator.signIn(authManager: authManager,
                               onSuccess: onSuccess, onError: onError)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "applelogo")
                    .font(.system(size: 17, weight: .semibold))
                Text(strings.onboardingContinueWithApple)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.black, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(strings.onboardingContinueWithApple)
    }
}

// MARK: - Coordinator

/// Keeps the ASAuthorizationController alive for the duration of the flow
/// and provides the presentation anchor Apple requires.
@MainActor
private final class AppleSignInCoordinator: NSObject, ObservableObject {
    private var authManager: AuthManager?
    private var onSuccess: (() -> Void)?
    private var onError: ((String) -> Void)?

    func signIn(authManager: AuthManager,
                onSuccess: @escaping () -> Void,
                onError: @escaping (String) -> Void) {
        self.authManager = authManager
        self.onSuccess = onSuccess
        self.onError = onError

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
                ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            if let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first {
                return window
            }
            return ASPresentationAnchor()
        }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController,
                                             didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData  = credential.identityToken,
                let idToken    = String(data: tokenData, encoding: .utf8),
                let authManager
            else {
                onError?(AppStrings.shared.authAppleTokenError)
                return
            }
            do {
                try await authManager.signInWithApple(idToken: idToken)
                onSuccess?()
            } catch {
                onError?(error.localizedDescription)
            }
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController,
                                             didCompleteWithError error: Error) {
        Task { @MainActor in
            // ASAuthorizationError.canceled (code 1001) — user cancelled, stay quiet.
            if (error as? ASAuthorizationError)?.code != .canceled {
                onError?(error.localizedDescription)
            }
        }
    }
}
