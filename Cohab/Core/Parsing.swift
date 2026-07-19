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
