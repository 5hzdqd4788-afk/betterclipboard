import Foundation
import AppKit
import ApplicationServices

enum PermissionsManager {
    
    static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }
    
    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    /// Opens System Settings → Privacy & Security → Accessibility
    static func openAccessibilitySettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
