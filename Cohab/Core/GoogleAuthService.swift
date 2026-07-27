import SwiftUI
import GoogleSignIn
import Supabase

// MARK: - Google Auth result

struct GoogleUser {
    let email: String
    let displayName: String
    let givenName: String
}

// MARK: - Service

enum GoogleAuthError: LocalizedError {
    case missingIdToken
    var errorDescription: String? {
        "Could not retrieve Google ID token. Check the Google Sign-In configuration."
    }
}

enum AuthExchangeError: LocalizedError {
    case timeout
    var errorDescription: String? { AppStrings.shared.authSignInTimeout }
}

/// Runs a Supabase auth exchange with a timeout and ONE automatic retry.
/// Works around the occasional first-attempt stall where the Supabase
/// client's initial session processing (stored-session load / token refresh)
/// serializes ahead of the exchange — the retry goes through immediately
/// once that has finished. signInWithIdToken is idempotent, so a retry is safe.
func withAuthExchangeTimeout<T>(
    seconds: UInt64 = 20,
    operation: @escaping () async throws -> T
) async throws -> T {
    do {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
                try Task.checkCancellation()
                throw AuthExchangeError.timeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    } catch AuthExchangeError.timeout {
        return try await operation()
    }
}

enum GoogleAuthService {
    /// Sign in with Google and return the user's basic profile.
    /// Call this from the Welcome screen so email is pre-filled in onboarding.
    @MainActor
    static func signIn(presenting viewController: UIViewController) async throws -> GoogleUser {
        let config = GIDConfiguration(clientID: APIConfig.googleClientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        let profile = result.user.profile

        // Exchange the Google ID token for a Supabase session so a profile row is
        // created (handle_new_user trigger) and every subsequent write is
        // authenticated. This MUST succeed — if it throws, the Google provider or
        // its Authorized Client IDs are misconfigured in the Supabase Dashboard
        // (Auth → Providers → Google). We surface the error instead of swallowing
        // it, otherwise the user appears "signed in" while all writes silently fail.
        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleAuthError.missingIdToken
        }
        try await withAuthExchangeTimeout {
            try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .google, idToken: idToken)
            )
        }

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
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.cohInk.opacity(0.2), lineWidth: 1.5)
            )
        }
        .disabled(isLoading)
    }
}
