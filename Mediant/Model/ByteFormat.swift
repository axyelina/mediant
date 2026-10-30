import Foundation

enum ByteFormat {
    private static let units = ["KB", "MB", "GB", "TB"]
    private static let russianUnits = ["КБ", "МБ", "ГБ", "ТБ"]

    /// Decimal (1000-based) size like "4.2 MB" in the given locale; "—" when the size is unknown.
    /// KB has no decimals, MB and larger have one. Russian uses its own units ("4,2 МБ").
    static func string(_ bytes: Int64?, locale: Locale = .current) -> String {
        guard let bytes else { return "—" }
        var value = Double(max(bytes, 0)) / 1000
        var unit = 0
        while value >= 999.95, unit < units.count - 1 {
            value /= 1000
            unit += 1
        }
        let digits = unit == 0 ? 0 : 1
        let number = value.formatted(.number.precision(.fractionLength(digits)).locale(locale))
        let names = locale.language.languageCode == .russian ? russianUnits : units
        return "\(number) \(names[unit])"
    }
}

