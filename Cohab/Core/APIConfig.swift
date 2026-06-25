import Foundation

enum APIConfig {
    static let supabaseURL  = "https://yvckcujoopwqjjnoxsze.supabase.co"
    // Publishable (anon) key — safe to include in the iOS binary.
    static let supabaseKey  = "sb_publishable_ShKAIkIDOr2p25_Qg8dyFw_kWFU7d0e"

    static let submitURL = URL(string: "\(supabaseURL)/functions/v1/docuseal-submit")!
}
