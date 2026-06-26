import Foundation

struct CentralBankRate: Codable {
    let currency: String
    let country: String
    let rate: Double        // fraction (0.0425 = 4.25%)
    let source: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case currency, country, rate, source
        case updatedAt = "updated_at"
    }
}

enum InterestRateService {
    /// Fetches the current central bank rate for the given currency from Supabase.
    /// Returns nil on network error or unknown currency.
    static func fetch(currency: String) async -> CentralBankRate? {
        guard let url = URL(string: "\(APIConfig.supabaseURL)/functions/v1/interest-rates?currency=\(currency)") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(APIConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200 else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let str = try decoder.singleValueContainer().decode(String.self)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = iso.date(from: str) { return d }
            iso.formatOptions = [.withInternetDateTime]
            return iso.date(from: str) ?? Date()
        }
        return try? decoder.decode(CentralBankRate.self, from: data)
    }
}
