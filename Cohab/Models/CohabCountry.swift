import Foundation

struct CohabCountry: Identifiable, Hashable, Equatable {
    let id: String          // ISO 3166 country code
    var code: String { id }
    let name: String
    let flag: String
    let currency: String    // ISO 4217
    let bankName: String    // Central bank name

    static func == (lhs: CohabCountry, rhs: CohabCountry) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static let defaults: [CohabCountry] = [
        CohabCountry(id: "GB", name: "United Kingdom",  flag: "🇬🇧", currency: "GBP", bankName: "Bank of England"),
        CohabCountry(id: "NO", name: "Norway",           flag: "🇳🇴", currency: "NOK", bankName: "Norges Bank"),
        CohabCountry(id: "SE", name: "Sweden",           flag: "🇸🇪", currency: "SEK", bankName: "Riksbanken"),
        CohabCountry(id: "DK", name: "Denmark",          flag: "🇩🇰", currency: "DKK", bankName: "Danmarks Nationalbank"),
        CohabCountry(id: "FI", name: "Finland",          flag: "🇫🇮", currency: "EUR", bankName: "European Central Bank"),
        CohabCountry(id: "IE", name: "Ireland",          flag: "🇮🇪", currency: "EUR", bankName: "European Central Bank"),
        CohabCountry(id: "NL", name: "Netherlands",      flag: "🇳🇱", currency: "EUR", bankName: "European Central Bank"),
        CohabCountry(id: "DE", name: "Germany",          flag: "🇩🇪", currency: "EUR", bankName: "European Central Bank"),
        CohabCountry(id: "FR", name: "France",           flag: "🇫🇷", currency: "EUR", bankName: "European Central Bank"),
        CohabCountry(id: "ES", name: "Spain",            flag: "🇪🇸", currency: "EUR", bankName: "European Central Bank"),
        CohabCountry(id: "CH", name: "Switzerland",      flag: "🇨🇭", currency: "CHF", bankName: "Swiss National Bank"),
        CohabCountry(id: "US", name: "United States",    flag: "🇺🇸", currency: "USD", bankName: "Federal Reserve"),
        CohabCountry(id: "CA", name: "Canada",           flag: "🇨🇦", currency: "CAD", bankName: "Bank of Canada"),
        CohabCountry(id: "AU", name: "Australia",        flag: "🇦🇺", currency: "AUD", bankName: "Reserve Bank of Australia"),
        CohabCountry(id: "NZ", name: "New Zealand",      flag: "🇳🇿", currency: "NZD", bankName: "Reserve Bank of New Zealand"),
        CohabCountry(id: "JP", name: "Japan",            flag: "🇯🇵", currency: "JPY", bankName: "Bank of Japan"),
        CohabCountry(id: "SG", name: "Singapore",        flag: "🇸🇬", currency: "SGD", bankName: "MAS"),
        CohabCountry(id: "IS", name: "Iceland",          flag: "🇮🇸", currency: "ISK", bankName: "Seðlabanki Íslands"),
    ]

    static func find(code: String) -> CohabCountry? {
        defaults.first { $0.code == code }
    }
}
