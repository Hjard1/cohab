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
    /// Generates the agreement PDF, uploads to DocuSeal via the backend,
    /// and updates the household's agreementStatus and docusealSlug.
    @MainActor
    static func submit(household: Household) async throws -> DocuSealSubmission {
        guard !household.emailA.isEmpty, !household.emailB.isEmpty else {
            throw DocuSealError.missingEmail
        }

        let output = ContractGenerator.generate(household: household)

        let body: [String: Any] = [
            "pdf_base64": output.pdfData.base64EncodedString(),
            "name_a": household.partnerAName,
            "email_a": household.emailA,
            "name_b": household.partnerBName,
            "email_b": household.emailB,
            "sig_y": Double(output.sigY),
            "title": "\(household.partnerAName) & \(household.partnerBName) — Ownership Agreement"
        ]

        let url = APIConfig.backendURL.appendingPathComponent("docuseal/submit")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw DocuSealError.httpError(httpResponse.statusCode, msg)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let result = try decoder.decode(DocuSealSubmission.self, from: data)
            household.agreementStatus = "pending"
            household.docusealSlug = result.slug
            return result
        } catch {
            throw DocuSealError.decodingError(error.localizedDescription)
        }
    }
}
