import Foundation

/// The language of the app's own texts, chosen in Settings. iOS dialogs and album names from
/// Photos stay in the phone's language.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en", russian = "ru"

    var id: Self { self }

    /// Written in its own language, so it reads right whatever the app language is.
    var nativeName: String {
        switch self {
        case .english: "English"
        case .russian: "Русский"
        }
    }

    /// The saved choice; without one, the first of the phone's languages the app has; else English.
    static func resolve(saved: String?, preferred: [String]) -> AppLanguage {
        if let saved, let language = AppLanguage(rawValue: saved) { return language }
        for identifier in preferred {
            if let code = Locale(identifier: identifier).language.languageCode?.identifier,
               let language = AppLanguage(rawValue: code) { return language }
        }
        return .english
    }

    /// This language with the phone's region, so numbers and sizes keep the user's format.
    func locale(region: Locale.Region?) -> Locale {
        Locale(identifier: region.map { "\(rawValue)_\($0.identifier)" } ?? rawValue)
    }
}
