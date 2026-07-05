import Supabase
import GoogleSignIn
import SwiftUI

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isSignedIn = false
    @Published private(set) var currentUserId: UUID?
    @Published private(set) var isLoading = true

    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            currentUserId = session.user.id
            isSignedIn = true
        } catch {
            isSignedIn = false
            currentUserId = nil
        }
        isLoading = false
    }

    /// Sign in with Google → exchange for Supabase session.
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        let config = GIDConfiguration(clientID: APIConfig.googleClientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingIdToken
        }

        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken)
        )
        let session = try await supabase.auth.session
        currentUserId = session.user.id
        isSignedIn = true
    }

    /// Sign in with Apple ID token (exchanged from ASAuthorizationAppleIDCredential).
    /// The raw nonce must match the SHA-256 nonce sent in the original Apple request.
    func signInWithApple(idToken: String, rawNonce: String) async throws {
        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: rawNonce)
        )
        let session = try await supabase.auth.session
        currentUserId = session.user.id
        isSignedIn = true
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        isSignedIn = false
        currentUserId = nil
    }

    /// Permanently deletes the Supabase auth account and all associated data.
    /// Calls the `delete-account` Edge Function which uses the service-role key.
    func deleteAccount() async throws {
        try await supabase.functions.invoke("delete-account", options: .init())
        await signOut()
    }

    // Listen for auth state changes (call once on app launch)
    func listenForAuthChanges() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn, .tokenRefreshed, .userUpdated:
                        currentUserId = session?.user.id
                        isSignedIn = true
                    case .signedOut:
                        currentUserId = nil
                        isSignedIn = false
                    default:
                        break
                    }
                    isLoading = false
                }
            }
        }
    }

    enum AuthError: LocalizedError {
        case missingIdToken
        var errorDescription: String? {
            "Could not retrieve Google ID token."
        }
    }
}
