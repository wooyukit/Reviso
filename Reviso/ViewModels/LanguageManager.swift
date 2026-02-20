import Foundation

@Observable
final class LanguageManager {
    private static let storageKey = "appLanguage"

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.storageKey)
        }
    }

    var locale: Locale {
        currentLanguage.locale
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey)
        currentLanguage = saved.flatMap(AppLanguage.init(rawValue:)) ?? .english
    }
}
