import Foundation

enum APIConfig {
    static let supabaseURL  = "https://yvckcujoopwqjjnoxsze.supabase.co"
    // Publishable (anon) key — safe to include in the iOS binary.
    static let supabaseKey  = "sb_publishable_ShKAIkIDOr2p25_Qg8dyFw_kWFU7d0e"

    static let submitURL = URL(string: "\(supabaseURL)/functions/v1/docuseal-submit")!

    // Google Sign-In iOS client ID.
    // Get this from Google Cloud Console → same project as Samboappen →
    // Credentials → Create credential → OAuth client ID → iOS.
    // Also set GOOGLE_REVERSED_CLIENT_ID in Xcode build settings
    // (the reversed form: com.googleusercontent.apps.YOUR-CLIENT-ID).
    static let googleClientID = "202318303891-bk19jn92jfdg01t6r3p7v6nqp53gk9ai.apps.googleusercontent.com"
}
