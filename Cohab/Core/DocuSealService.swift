import Foundation

// MARK: - Types

struct DocuSealSubmission: Codable {
    let submissionId: String
    let slug: String
    let signingUrlA: String
    let signingUrlB: String
}

enum DocuSealError: LocalizedError {
    case missingEmail
    case httpError(Int, String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .missingEmail:
            return "Both partners need an email address to receive signing links."
        case .httpError(let code, let msg):
            return "Server error \(code): \(msg)"
        case .decodingError(let msg):
            return "Unexpected response from server: \(msg)"
        }
    }
}

// MARK: - Service

enum DocuSealService {
    /// Polls Supabase to check if a submission has been completed by both parties.
    /// Returns true when the status is "completed" in the DB.
    @MainActor
    static func checkSigned(household: Household) async -> Bool {
        guard !household.docusealSlug.isEmpty else { return false }

        // Query Supabase REST API directly — no Edge Function needed.
        let urlStr = "\(APIConfig.supabaseURL)/rest/v1/cohab_docuseal_submissions"
            + "?slug=eq.\(household.docusealSlug)&select=status&limit=1"
        guard let url = URL(string: urlStr) else { return false }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(APIConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        req.setValue(APIConfig.supabaseKey,             forHTTPHeaderField: "apikey")
        req.timeoutInterval = 8

        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let status = rows.first?["status"] as? String else { return false }

        if status == "completed" {
            household.agreementStatus = "signed"
            return true
        }
        return false
    }
    /// Generates the agreement PDF, submits it via the Supabase Edge Function,
    /// and updates the household's agreementStatus and docusealSlug.
    @MainActor
    static func submit(household: Household) async throws -> DocuSealSubmission {
        guard !household.emailA.isEmpty, !household.emailB.isEmpty else {
            throw DocuSealError.missingEmail
        }

        let output = ContractGenerator.generate(household: household)

        let body: [String: Any] = [
            "pdf_base64":   output.pdfData.base64EncodedString(),
            "name_a":       household.partnerAName,
            "email_a":      household.emailA,
            "name_b":       household.partnerBName,
            "email_b":      household.emailB,
            "sig_y":        output.sigYFraction,   // fraction 0–1, from top
            "sig_page":     output.sigPage,         // 0-indexed (DocuSeal: 0 = first page)
            "household_id": household.id.uuidString,
            // [cohab] prefix keeps templates distinct from Samboappen on the
            // shared DocuSeal account dashboard.
            "title": "[cohab] \(household.partnerAName) & \(household.partnerBName) — Ownership Agreement"
        ]

        var request = URLRequest(url: APIConfig.submitURL)
        request.httpMethod = "POST"
        request.setValue("application/json",        forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw DocuSealError.httpError(http.statusCode, msg)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let result = try decoder.decode(DocuSealSubmission.self, from: data)
            household.agreementStatus   = "pending"
            household.docusealSlug      = result.slug
            // Snapshot state so we can detect changes later
            household.signedAssetCount  = household.assets.count
            household.signedContribCount = household.assets.reduce(0) { $0 + $1.contributions.count }
            return result
        } catch {
            throw DocuSealError.decodingError(error.localizedDescription)
        }
    }
}
