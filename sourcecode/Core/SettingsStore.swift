import Foundation
import AppKit
import Combine
import ServiceManagement

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    enum OpenPositionMode: String, CaseIterable, Identifiable {
        case lastPosition = "lastPosition"
        case screenCorner = "screenCorner"
        
        var id: String { rawValue }
        
        @MainActor
        var title: String {
            switch self {
            case .lastPosition: return L("position.lastPosition.title")
            case .screenCorner: return L("position.screenCorner.title")
            }
        }
        
        @MainActor
        var subtitle: String {
            switch self {
            case .lastPosition: return L("position.lastPosition.subtitle")
            case .screenCorner: return L("position.screenCorner.subtitle")
            }
        }
    }
    
    @Published var openPositionMode: OpenPositionMode {
        didSet { defaults.set(openPositionMode.rawValue, forKey: Keys.openPositionMode) }
    }
    
    /// 0 = unlimited
    @Published var maxHistoryItems: Int {
        didSet { defaults.set(maxHistoryItems, forKey: Keys.maxHistoryItems) }
    }
    
    @Published var autoHideAfterPaste: Bool {
        didSet { defaults.set(autoHideAfterPaste, forKey: Keys.autoHideAfterPaste) }
    }
    
    @Published var doubleCommandEnabled: Bool {
        didSet { defaults.set(doubleCommandEnabled, forKey: Keys.doubleCommandEnabled) }
    }
    
    @Published var doubleCommandInterval: Double {
        didSet { defaults.set(doubleCommandInterval, forKey: Keys.doubleCommandInterval) }
    }
    
    @Published var captureText: Bool {
        didSet { defaults.set(captureText, forKey: Keys.captureText) }
    }
    
    @Published var captureLinks: Bool {
        didSet { defaults.set(captureLinks, forKey: Keys.captureLinks) }
    }
    
    @Published var captureImages: Bool {
        didSet { defaults.set(captureImages, forKey: Keys.captureImages) }
    }
    
    @Published var captureFiles: Bool {
        didSet { defaults.set(captureFiles, forKey: Keys.captureFiles) }
    }
    
    @Published var showTimestamps: Bool {
        didSet { defaults.set(showTimestamps, forKey: Keys.showTimestamps) }
    }
    
    @Published var keepPinnedOnClear: Bool {
        didSet { defaults.set(keepPinnedOnClear, forKey: Keys.keepPinnedOnClear) }
    }
    
    @Published var popupWidth: Double {
        didSet { defaults.set(popupWidth, forKey: Keys.popupWidth) }
    }
    
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }
    
    var lastWindowFrame: NSRect? {
        get {
            guard let dict = defaults.dictionary(forKey: Keys.lastWindowFrame) else { return nil }
            guard let x = dict["x"] as? CGFloat,
                  let y = dict["y"] as? CGFloat,
                  let w = dict["w"] as? CGFloat,
                  let h = dict["h"] as? CGFloat else { return nil }
            return NSRect(x: x, y: y, width: w, height: h)
        }
        set {
            guard let r = newValue else {
                defaults.removeObject(forKey: Keys.lastWindowFrame)
                return
            }
            defaults.set(["x": r.origin.x, "y": r.origin.y, "w": r.size.width, "h": r.size.height],
                         forKey: Keys.lastWindowFrame)
        }
    }
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let openPositionMode = "settings.openPositionMode"
        static let maxHistoryItems = "settings.maxHistoryItems"
        static let autoHideAfterPaste = "settings.autoHideAfterPaste"
        static let doubleCommandEnabled = "settings.doubleCommandEnabled"
        static let doubleCommandInterval = "settings.doubleCommandInterval"
        static let captureText = "settings.captureText"
        static let captureLinks = "settings.captureLinks"
        static let captureImages = "settings.captureImages"
        static let captureFiles = "settings.captureFiles"
        static let showTimestamps = "settings.showTimestamps"
        static let keepPinnedOnClear = "settings.keepPinnedOnClear"
        static let popupWidth = "settings.popupWidth"
        static let launchAtLogin = "settings.launchAtLogin"
        static let lastWindowFrame = "settings.lastWindowFrame"
    }
    
    private init() {
        let rawMode = defaults.string(forKey: Keys.openPositionMode) ?? ""
        if rawMode == "nearTextField" || rawMode.isEmpty {
            openPositionMode = .lastPosition
        } else {
            openPositionMode = OpenPositionMode(rawValue: rawMode) ?? .lastPosition
        }
        maxHistoryItems = defaults.object(forKey: Keys.maxHistoryItems) as? Int ?? 150
        autoHideAfterPaste = defaults.object(forKey: Keys.autoHideAfterPaste) as? Bool ?? true
        doubleCommandEnabled = defaults.object(forKey: Keys.doubleCommandEnabled) as? Bool ?? true
        doubleCommandInterval = defaults.object(forKey: Keys.doubleCommandInterval) as? Double ?? 0.4
        captureText = defaults.object(forKey: Keys.captureText) as? Bool ?? true
        captureLinks = defaults.object(forKey: Keys.captureLinks) as? Bool ?? true
        captureImages = defaults.object(forKey: Keys.captureImages) as? Bool ?? true
        captureFiles = defaults.object(forKey: Keys.captureFiles) as? Bool ?? true
        showTimestamps = defaults.object(forKey: Keys.showTimestamps) as? Bool ?? true
        keepPinnedOnClear = defaults.object(forKey: Keys.keepPinnedOnClear) as? Bool ?? true
        popupWidth = defaults.object(forKey: Keys.popupWidth) as? Double ?? 380
        launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
    }
    
    func resetToDefaults() {
        openPositionMode = .lastPosition
        maxHistoryItems = 150
        autoHideAfterPaste = true
        doubleCommandEnabled = true
        doubleCommandInterval = 0.4
        captureText = true
        captureLinks = true
        captureImages = true
        captureFiles = true
        showTimestamps = true
        keepPinnedOnClear = true
        popupWidth = 380
        launchAtLogin = false
        lastWindowFrame = nil
    }
    
    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Launch at login error: \(error)")
            }
        }
    }
}
