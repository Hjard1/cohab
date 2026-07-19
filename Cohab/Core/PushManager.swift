import UIKit
import UserNotifications

/// Registers for APNs and keeps the device token synced to Supabase so the
/// notify-partner edge function can push partner-activity alerts to this
/// device. Tokens live in the `device_tokens` table, one row per device.
@MainActor
final class PushManager: NSObject {
    static let shared = PushManager()
    private override init() {}

    private var pendingToken: String?
    private static let uploadedKey = "cohab.push.uploaded"

    /// Asks for notification permission (the system only prompts the first
    /// time) and registers with APNs. Safe to call on every signed-in launch.
    func requestAndRegister() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Called from the AppDelegate with the raw APNs token.
    func didRegister(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        pendingToken = token
        Task { await upload(token: token) }
    }

    /// Retries an upload that failed because the user was not signed in yet.
    func uploadPendingIfNeeded() async {
        if let token = pendingToken { await upload(token: token) }
    }

    private func upload(token: String) async {
        guard let uid = try? await supabase.auth.session.user.id else { return }
        let marker = "\(uid.uuidString):\(token)"
        guard UserDefaults.standard.string(forKey: Self.uploadedKey) != marker else { return }
        struct Row: Encodable {
            let user_id: String
            let token: String
            let language: String
            let platform: String
            let updated_at: String
        }
        let iso = ISO8601DateFormatter()
        do {
            try await supabase
                .from("device_tokens")
                .upsert(Row(user_id: uid.uuidString,
                            token: token,
                            language: AppStrings.shared.language.rawValue,
                            platform: "ios",
                            updated_at: iso.string(from: Date())),
                        onConflict: "token")
                .execute()
            UserDefaults.standard.set(marker, forKey: Self.uploadedKey)
        } catch {
            // Marker stays unset — retried on the next registration or sign-in.
        }
    }
}
