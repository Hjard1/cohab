import Foundation

/// A published contract-clause template from the `contract_templates`
/// Supabase table. Bodies may contain `{{token}}` placeholders which
/// ContractGenerator replaces at render time.
struct ContractTemplate: Codable {
    let clauseKey: String
    let language: String
    let title: String?
    let body: String
    let version: Int

    enum CodingKeys: String, CodingKey {
        case clauseKey = "clause_key"
        case language, title, body, version
    }
}

/// Fetches published clause templates for the document language via the
/// Supabase REST API (same pattern as DocuSealService.checkSigned). The
/// result is cached per language in UserDefaults so a later fetch failure
/// (offline, timeout, …) silently falls back to the last known templates —
/// and ultimately to the app's bundled strings when nothing is cached.
enum ContractTemplateStore {
    private static func cacheKey(for language: String) -> String {
        "contractTemplates.\(language)"
    }

    private static func cached(for language: String) -> [String: ContractTemplate] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey(for: language)),
              let map = try? JSONDecoder().decode([String: ContractTemplate].self, from: data)
        else { return [:] }
        return map
    }

    /// Returns published templates reduced to the highest version per clause
    /// key. Never throws — on any failure returns the cached map, or [:].
    static func templates(for language: String) async -> [String: ContractTemplate] {
        let urlStr = "\(APIConfig.supabaseURL)/rest/v1/contract_templates"
            + "?language=eq.\(language)&status=eq.published"
            + "&select=clause_key,language,title,body,version"
        guard let url = URL(string: urlStr) else { return cached(for: language) }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(APIConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        req.setValue(APIConfig.supabaseKey,             forHTTPHeaderField: "apikey")
        req.timeoutInterval = 8

        guard let (data, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let rows = try? JSONDecoder().decode([ContractTemplate].self, from: data)
        else { return cached(for: language) }

        // Highest version per clause key wins.
        var map: [String: ContractTemplate] = [:]
        for row in rows {
            if let existing = map[row.clauseKey], existing.version >= row.version { continue }
            map[row.clauseKey] = row
        }

        if let encoded = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(encoded, forKey: cacheKey(for: language))
        }
        return map
    }
}
