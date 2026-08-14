//
//  AppLanguage.swift
//  betterclipboard
//
//  Supported UI languages.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case en
    case ru

    var id: String { rawValue }

    /// Name shown in the language picker (always shown in its own language).
    var displayName: String {
        switch self {
        case .en: return "English"
        case .ru: return "Русский"
        }
    }

    /// Locale used for date formatting etc.
    var locale: Locale {
        switch self {
        case .en: return Locale(identifier: "en_US")
        case .ru: return Locale(identifier: "ru_RU")
        }
    }
}
