import Foundation
import Supabase

// MARK: - Types

struct DealBuilderCase: Codable {
    let documentId: String
    let appUrl: String
    let previewUrl: String
    /// Personal, login-free signing links per signatory (nil for cases
    /// created before these were stored — fall back to appUrl then).
    let signingUrlA: String?
    let signingUrlB: String?
}

enum DealBuilderError: LocalizedError {
    case missingEmail
    case creditsExhausted
    case httpError(Int, String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .missingEmail:
            return "Both partners need an email address to receive signing links."
        case .creditsExhausted:
            return "The included BankID signing is used. Purchase an extra signing to continue."
        case .httpError(let code, let msg):
            return "Server error \(code): \(msg)"
        case .decodingError(let msg):
            return "Unexpected response from server: \(msg)"
        }
    }
}

// MARK: - Service

/// BankID signing via DealBuilder. Signing links are emailed to both
/// partners; the signing itself happens in their browser with BankID —
/// nothing native is required in the app.
enum DealBuilderService {
    /// Countries where BankID signing is offered. NO uses the Norwegian
    /// BankID template; SE uses the Swedish template when the account has
    /// one configured (`DEALBUILDER_TEMPLATE_ID_SV`), otherwise falls back
    /// to the default template. Extend this set if the DealBuilder account
    /// adds templates for other eIDs (MitID, Finnish Trust Network, ...).
    static let supportedCountries: Set<String> = ["NO", "SE"]

    static func isSupported(country: String) -> Bool {
        supportedCountries.contains(country)
    }

    /// Actively polls the DealBuilder status via the Edge Function (which
    /// also updates cohab_dealbuilder_cases). Returns true when signed.
    @MainActor
    static func checkSigned(household: Household) async -> Bool {
        let body: [String: Any] = ["household_id": household.id.uuidString]
        var req = URLRequest(url: APIConfig.dealBuilderStatusURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(APIConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 15

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let completed = json["is_completed"] as? Bool else { return false }

        if completed {
            household.agreementStatus = "signed"
            if household.signedAt == nil { household.signedAt = Date() }
            return true
        }
        return false
    }

    /// The household's current (non-superseded) signing case, if any —
    /// used to restore the "waiting for signatures" UI state after relaunch.
    @MainActor
    static func currentCase(household: Household) async -> DealBuilderCase? {
        let urlStr = "\(APIConfig.supabaseURL)/rest/v1/cohab_dealbuilder_cases"
            + "?household_id=eq.\(household.id.uuidString)&is_current=eq.true"
            + "&select=document_id,app_url,preview_url,signing_url_a,signing_url_b&limit=1"
        guard let url = URL(string: urlStr) else { return nil }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(APIConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        req.setValue(APIConfig.supabaseKey,             forHTTPHeaderField: "apikey")
        req.timeoutInterval = 8

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let row = rows.first,
              let documentId = row["document_id"] as? String else { return nil }

        return DealBuilderCase(
            documentId: documentId,
            appUrl: row["app_url"] as? String ?? "",
            previewUrl: row["preview_url"] as? String ?? "",
            signingUrlA: row["signing_url_a"] as? String,
            signingUrlB: row["signing_url_b"] as? String
        )
    }

    /// Grants one extra BankID signing credit after a StoreKit purchase of
    /// `com.hjard.cohab.bankid_extra`. The purchase is verified server-side:
    /// the app sends the transaction's JWS representation to the
    /// add-bankid-credit edge function, which validates the signature against
    /// Apple's certificate chain and only then adds the credit (the
    /// cohab_add_bankid_credit RPC is service-role only and cannot be called
    /// from the app). Throws when the credit could not be activated — the
    /// purchase itself is already completed at that point.
    @MainActor
    static func addExtraCredit(jws: String) async throws {
        let session = try await supabase.auth.session

        var req = URLRequest(url: APIConfig.addBankIDCreditURL)
        req.httpMethod = "POST"
        req.setValue("application/json",                 forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(session.accessToken)",    forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["jws": jws])
        req.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            // Logged so support can trace the failed activation and grant
            // the credit manually (the user has already paid).
            NSLog("add-bankid-credit failed (%ld): %@", code, msg)
            throw DealBuilderError.httpError(code, msg)
        }
    }

    /// Number of purchased but unused extra BankID signings.
    @MainActor
    static func extraCredits(household: Household) async -> Int {
        let urlStr = "\(APIConfig.supabaseURL)/rest/v1/cohab_household_credits"
            + "?household_id=eq.\(household.id.uuidString)&select=bankid_extra_credits&limit=1"
        guard let url = URL(string: urlStr) else { return 0 }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(APIConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        req.setValue(APIConfig.supabaseKey,             forHTTPHeaderField: "apikey")
        req.timeoutInterval = 8

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let credits = rows.first?["bankid_extra_credits"] as? Int else { return 0 }
        return credits
    }

    /// Supersedes the household's current case (used when the agreement
    /// data changes and the old signing case should no longer count).
    @MainActor
    static func reset(household: Household) async {
        let urlStr = "\(APIConfig.supabaseURL)/rest/v1/cohab_dealbuilder_cases"
            + "?household_id=eq.\(household.id.uuidString)&is_current=eq.true"
        guard let url = URL(string: urlStr) else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("Bearer \(APIConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        req.setValue(APIConfig.supabaseKey,             forHTTPHeaderField: "apikey")
        req.setValue("application/json",                forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["is_current": false])
        req.timeoutInterval = 8
        _ = try? await URLSession.shared.data(for: req)
    }

    /// Generates the agreement PDF, creates a DealBuilder signing case via
    /// the Edge Function, and updates the household's agreementStatus.
    @MainActor
    static func submit(household: Household) async throws -> DealBuilderCase {
        let emailA = household.emailA.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailB = household.emailB.trimmingCharacters(in: .whitespacesAndNewlines)

        guard DocuSealService.isValidEmail(emailA), DocuSealService.isValidEmail(emailB) else {
            throw DealBuilderError.missingEmail
        }

        // Fetch DB-published clause templates for the document language;
        // falls back to the bundled strings when unreachable.
        let docLang = ContractGenerator.docLanguageCode(household: household)
        let templates = await ContractTemplateStore.templates(for: docLang)
        let output = ContractGenerator.generate(household: household, templates: templates)

        // Audit trail: which template versions produced this document.
        let templateVersions: [String: Any] = templates.isEmpty
            ? ["source": "bundled"]
            : templates.mapValues { $0.version }

        let body: [String: Any] = [
            "pdf_base64":   output.pdfData.base64EncodedString(),
            "name_a":       household.partnerAName,
            "email_a":      emailA,
            "name_b":       household.partnerBName,
            "email_b":      emailB,
            "household_id": household.id.uuidString,
            "template_versions": templateVersions,
            // The edge function localizes the document title based on the
            // app's current language.
            "language":     AppStrings.shared.language.rawValue,
            "title": "\(household.partnerAName) & \(household.partnerBName) — Cohabitation Agreement"
        ]

        var request = URLRequest(url: APIConfig.dealBuilderSubmitURL)
        request.httpMethod = "POST"
        request.setValue("application/json",        forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            if http.statusCode == 402, msg.contains("BANKID_CREDITS_EXHAUSTED") {
                throw DealBuilderError.creditsExhausted
            }
            throw DealBuilderError.httpError(http.statusCode, msg)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let result = try decoder.decode(DealBuilderCase.self, from: data)
            household.agreementStatus    = "pending"
            // Snapshot all agreement-relevant data so any change triggers an update prompt
            household.signedAssetCount   = household.assets.count
            household.signedContribCount = household.assets.reduce(0) { $0 + $1.contributions.count }
            household.signedDataSnapshot = household.currentDataSnapshot
            return result
        } catch {
            throw DealBuilderError.decodingError(error.localizedDescription)
        }
    }
}
