import Supabase
import Foundation

/// Shared Supabase client — use this everywhere instead of constructing a new one.
let supabase: SupabaseClient = {
    guard let url = URL(string: APIConfig.supabaseURL), !APIConfig.supabaseURL.isEmpty else {
        fatalError("Invalid or missing SUPABASE_URL in APIConfig")
    }
    return SupabaseClient(supabaseURL: url, supabaseKey: APIConfig.supabaseKey)
}()
