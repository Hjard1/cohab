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

    /// Dark forest green used for the serif headline — same token as the
    /// onboarding welcome step so both screens read as one design.
    private var headlineGreen: Color { Color(red: 0.07, green: 0.27, blue: 0.17) }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let photoHeight = max(geo.size.height * 0.55, 300)

                ZStack(alignment: .top) {
                    Color.cohBg.ignoresSafeArea()

                    // PHOTO — pinned to the bottom, fades into cream at the top
                    // (same treatment as the onboarding welcome step).
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Image("onboardingCouple")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width,
                                   height: photoHeight + geo.safeAreaInsets.bottom)
                            .clipped()
                            .overlay(alignment: .top) {
                                LinearGradient(
                                    colors: [Color.cohBg, Color.cohBg.opacity(0.6), .clear],
                                    startPoint: .top, endPoint: .bottom
                                )
                                .frame(height: 90)
                            }
                    }
                    .ignoresSafeArea(edges: .bottom)

                    // CONTENT — logo, headline, subtitle at top; sign-in CTAs
                    // pinned to the bottom so they sit on top of the photo.
                    VStack(spacing: 0) {
                        Image("cohabLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 168)
                            .padding(.top, geo.safeAreaInsets.top + 28)

                        Text(strings.signInWelcomeBack)
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundStyle(headlineGreen)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.top, 28)

                        Text(strings.signInSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.cohSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 12)

                        Spacer(minLength: 0)

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

                            if let err = errorMessage {
                                Text(err)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                            }

                            // Secondary action sits over the photo — capsule
                            // keeps it legible against the image.
                            if households.isEmpty {
                                // Only meaningful as a sheet — as the root view (after
                                // sign-out or in the invite flow) dismiss() is a no-op,
                                // so the button is hidden rather than dead.
                                if presentedAsSheet {
                                    Button { dismiss() } label: {
                                        Text(strings.signInBackToSignUp)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.cohMuted)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(Color.cohBg.opacity(0.85), in: Capsule())
                                    }
                                }
                            } else if !presentedAsSheet {
                                // Shown as root after logout — offer clean slate
                                Button { showResetConfirm = true } label: {
                                    Text(strings.signInStartFresh)
                                        .font(.caption)
                                        .foregroundStyle(Color.cohTertiary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Color.cohBg.opacity(0.85), in: Capsule())
                                }
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
                        .padding(.bottom, geo.safeAreaInsets.bottom + 32)
                    }
                    .padding(.horizontal, 28)
                }
                // Decorative soft mint shapes — see OnboardingView for why they
                // must live in a background (never size the layout).
                .background {
                    Circle()
                        .fill(Color.cohGreen.opacity(0.08))
                        .frame(width: geo.size.width * 1.15, height: geo.size.width * 1.15)
                        .offset(x: -geo.size.width * 0.60, y: -geo.size.width * 0.75)
                    Circle()
                        .fill(Color.cohGreen.opacity(0.06))
                        .frame(width: geo.size.width * 1.3, height: geo.size.width * 1.3)
                        .offset(x: geo.size.width * 0.55, y: geo.size.height * 0.55)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Close button only as a sheet — as the root view dismiss()
                // is a no-op that would leave the user stuck.
                if presentedAsSheet {
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
