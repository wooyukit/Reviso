import Testing
import Foundation
@testable import Reviso

@Suite(.serialized)
struct LanguageManagerTests {

    @Test func appLanguage_allCases_areTwo() {
        #expect(AppLanguage.allCases.count == 2)
        #expect(AppLanguage.allCases.contains(.english))
        #expect(AppLanguage.allCases.contains(.traditionalChinese))
    }

    @Test func appLanguage_rawValues() {
        #expect(AppLanguage.english.rawValue == "en")
        #expect(AppLanguage.traditionalChinese.rawValue == "zh-Hant")
    }

    @Test func appLanguage_displayName() {
        #expect(AppLanguage.english.displayName == "English")
        #expect(AppLanguage.traditionalChinese.displayName == "繁體中文")
    }

    @Test func appLanguage_locale() {
        #expect(AppLanguage.english.locale.identifier == "en")
        #expect(AppLanguage.traditionalChinese.locale.identifier == "zh-Hant")
    }

    @Test func languageManager_defaultsToEnglish() {
        UserDefaults.standard.removeObject(forKey: "appLanguage")
        let manager = LanguageManager()
        #expect(manager.currentLanguage == .english)
    }

    @Test func languageManager_persistsSelection() {
        UserDefaults.standard.removeObject(forKey: "appLanguage")
        let manager = LanguageManager()
        manager.currentLanguage = .traditionalChinese

        let manager2 = LanguageManager()
        #expect(manager2.currentLanguage == .traditionalChinese)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "appLanguage")
    }

    @Test func languageManager_localeMatchesLanguage() {
        UserDefaults.standard.removeObject(forKey: "appLanguage")
        let manager = LanguageManager()
        #expect(manager.locale.identifier == "en")

        manager.currentLanguage = .traditionalChinese
        #expect(manager.locale.identifier == "zh-Hant")

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "appLanguage")
    }
}
