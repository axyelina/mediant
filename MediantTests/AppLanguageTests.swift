import Foundation
import Testing
@testable import Mediant

struct AppLanguageTests {
    @Test func savedChoiceWins() {
        #expect(AppLanguage.resolve(saved: "ru", preferred: ["en-US"]) == .russian)
        #expect(AppLanguage.resolve(saved: "en", preferred: ["ru-RU"]) == .english)
    }

    @Test func withoutAChoiceFollowsThePhone() {
        #expect(AppLanguage.resolve(saved: nil, preferred: ["ru-RU", "en-US"]) == .russian)
        #expect(AppLanguage.resolve(saved: nil, preferred: ["en-GB"]) == .english)
    }

    @Test func takesTheFirstPhoneLanguageTheAppHas() {
        #expect(AppLanguage.resolve(saved: nil, preferred: ["de-DE", "ru-RU"]) == .russian)
    }

    @Test func otherwiseEnglish() {
        #expect(AppLanguage.resolve(saved: nil, preferred: ["de-DE", "fr-FR"]) == .english)
        #expect(AppLanguage.resolve(saved: "xx", preferred: []) == .english)
    }

    @Test func localeKeepsThePhoneRegion() {
        // Numbers and sizes keep the user's format ("20,5 MB" in Russia) in either language.
        #expect(AppLanguage.english.locale(region: Locale.Region("RU")).identifier == "en_RU")
        #expect(AppLanguage.russian.locale(region: nil).identifier == "ru")
    }

    @Test func namesAreInTheirOwnLanguage() {
        #expect(AppLanguage.english.nativeName == "English")
        #expect(AppLanguage.russian.nativeName == "Русский")
    }
}

@MainActor
struct AppLanguageSettingTests {
    @Test func choiceIsRemembered() {
        let defaults = UserDefaults(suiteName: "language-\(UUID().uuidString)")!
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("lang-\(UUID().uuidString)")
        let model = AppModel(library: FakePhotoLibrary(), storeURL: folder.appendingPathComponent("d.json"),
                             defaults: defaults)
        model.language = .russian
        let again = AppModel(library: FakePhotoLibrary(), storeURL: folder.appendingPathComponent("d.json"),
                             defaults: defaults)
        #expect(again.language == .russian)
    }
}

/// The compiled String Catalog: Russian texts and plural forms.
struct RussianCatalogTests {
    let ru = Bundle(path: Bundle.main.path(forResource: "ru", ofType: "lproj") ?? "")
    let locale = Locale(identifier: "ru")

    func text(_ key: String) -> String {
        ru?.localizedString(forKey: key, value: "missing", table: nil) ?? "no ru.lproj"
    }

    @Test func plainTexts() {
        #expect(text("Trash") == "Корзина")
        #expect(text("Settings") == "Настройки")
        #expect(text("Undo") == "Отменить")
    }

    @Test func albumPlurals() {
        let format = text("%lld albums · ")
        #expect(String(format: format, locale: locale, 1) == "1 альбом · ")
        #expect(String(format: format, locale: locale, 3) == "3 альбома · ")
        #expect(String(format: format, locale: locale, 5) == "5 альбомов · ")
        #expect(String(format: format, locale: locale, 21) == "21 альбом · ")
    }

    @Test func itemPlurals() {
        let format = text("%lld items · ")
        #expect(String(format: format, locale: locale, 1) == "1 объект · ")
        #expect(String(format: format, locale: locale, 2) == "2 объекта · ")
        #expect(String(format: format, locale: locale, 11) == "11 объектов · ")
    }

    @Test func deletedLabelHasNoNumber() {
        // The progress card shows the number above the label.
        let format = text("items deleted %lld")
        #expect(String(format: format, locale: locale, 1) == "объект удалён")
        #expect(String(format: format, locale: locale, 4) == "объекта удалено")
        #expect(String(format: format, locale: locale, 7) == "объектов удалено")
    }
}
