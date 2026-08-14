//
//  LocalizationManager.swift
//  betterclipboard
//
//  Holds the currently selected UI language and publishes changes so that
//  SwiftUI views update instantly, without needing an app restart.
//

import Foundation
import Combine

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    private enum Keys {
        static let language = "settings.language"
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Keys.language),
           let saved = AppLanguage(rawValue: raw) {
            language = saved
        } else {
            // First launch: guess from the system language, default to English.
            let preferred = Locale.preferredLanguages.first ?? "en"
            language = preferred.hasPrefix("ru") ? .ru : .en
        }
    }
}

/// Shorthand lookup used across the app: `L("settings.general.header")`.
/// Falls back to the key itself if a translation is missing, so a missing
/// entry is obvious in the UI instead of crashing.
@MainActor
func L(_ key: String) -> String {
    Strings.table[key]?[LocalizationManager.shared.language] ?? key
}

/// Same as `L` but with a `String(format:)` pass for interpolated values,
/// e.g. `LF("settings.history.maxItems", "150")`.
@MainActor
func LF(_ key: String, _ args: CVarArg...) -> String {
    let format = L(key)
    return String(format: format, arguments: args)
}
