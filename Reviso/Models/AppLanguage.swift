import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case traditionalChinese = "zh-Hant"

    var displayName: String {
        switch self {
        case .english: "English"
        case .traditionalChinese: "繁體中文"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}
