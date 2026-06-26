import SwiftUI
import GoogleSignIn

// MARK: - Google Auth result

struct GoogleUser {
    let email: String
    let displayName: String
    let givenName: String
}

// MARK: - Service

enum GoogleAuthService {
    /// Sign in with Google and return the user's basic profile.
    /// Call this from the Welcome screen so email is pre-filled in onboarding.
    @MainActor
    static func signIn(presenting viewController: UIViewController) async throws -> GoogleUser {
        let config = GIDConfiguration(clientID: APIConfig.googleClientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        let profile = result.user.profile

        return GoogleUser(
            email: profile?.email ?? "",
            displayName: profile?.name ?? "",
            givenName: profile?.givenName ?? ""
        )
    }

    /// Restore a previous sign-in silently (no UI). Returns nil if no session exists.
    @MainActor
    static func restorePreviousSignIn() async -> GoogleUser? {
        guard let user = try? await GIDSignIn.sharedInstance.restorePreviousSignIn() else {
            return nil
        }
        let profile = user.profile
        return GoogleUser(
            email: profile?.email ?? "",
            displayName: profile?.name ?? "",
            givenName: profile?.givenName ?? ""
        )
    }
}

// MARK: - SwiftUI helper

/// Wraps GoogleAuthService.signIn in a SwiftUI-friendly way.
struct GoogleSignInButton: View {
    let label: String
    let onSuccess: (GoogleUser) -> Void
    let onError: ((Error) -> Void)?

    @State private var isLoading = false

    var body: some View {
        Button {
            guard !isLoading else { return }
            isLoading = true
            Task { @MainActor in
                defer { isLoading = false }
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let vc = scene.windows.first?.rootViewController else { return }
                do {
                    let user = try await GoogleAuthService.signIn(presenting: vc)
                    onSuccess(user)
                } catch {
                    onError?(error)
                }
            }
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().scaleEffect(0.8).tint(Color.cohInk)
                } else {
                    // Google "G" icon using SF Symbol approximation
                    Image(systemName: "globe")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.cohInk)
                }
                Text(label)
                    .font(.headline)
                    .foregroundStyle(Color.cohInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.cohInk.opacity(0.2), lineWidth: 1.5)
            )
        }
        .disabled(isLoading)
    }
}
