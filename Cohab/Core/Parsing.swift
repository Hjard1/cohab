import Foundation

// MARK: - Shared amount parsing

/// Tolerant parser for user-typed amounts: accepts "10 000", "10.000,50",
/// "10000,50" and "10000.50". (Naively stripping commas turned "10,5" into
/// 105 and rejected thousands with spaces — Norwegian users type comma as
/// the decimal separator.)
func parseExpenseAmount(_ s: String) -> Double {
    var t = s.trimmingCharacters(in: .whitespaces)
        .replacingOccurrences(of: "\u{00A0}", with: "")
        .replacingOccurrences(of: "\u{202F}", with: "")
        .replacingOccurrences(of: " ", with: "")
    if t.contains(",") && t.contains(".") {
        // Norwegian convention: dot = thousands separator, comma = decimal
        t = t.replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
    } else if t.contains(",") {
        t = t.replacingOccurrences(of: ",", with: ".")
    }
    return Double(t) ?? 0
}

/// Locale identifier for number grouping, derived from the household's
/// country — amounts read the way the user's country expects even when the
/// phone runs in another language. Mirrors ContractGenerator's docLocale map.
func groupingLocaleIdentifier(forCountry country: String) -> String {
    switch country {
    case "NO":          return "nb_NO"
    case "SE":          return "sv_SE"
    case "DK":          return "da_DK"
    case "FI":          return "fi_FI"
    case "DE", "AT", "CH": return "de_DE"
    case "FR":          return "fr_FR"
    case "ES":          return "es_ES"
    case "US":          return "en_US"
    default:            return "en_GB"
    }
}

/// Groups an amount with the household's country conventions
/// ("2 500 000" for NO/SE, "2.500.000" for DE, "2,500,000" for US/GB).
func fmtGroupedAmount(_ v: Double, country: String) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.maximumFractionDigits = 0
    f.locale = Locale(identifier: groupingLocaleIdentifier(forCountry: country))
    return f.string(from: NSNumber(value: v.rounded())) ?? "0"
}
