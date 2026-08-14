import SwiftUI
import AppKit

@main
struct ClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        // Sparkle: start updater once at launch
        UpdateService.shared.start()
        
        statusItemController = StatusItemController()
        statusItemController?.setup()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let alreadyPrompted = UserDefaults.standard.bool(forKey: "didPromptAccessibility")
            if !AccessibilityHelper.isTrusted && !alreadyPrompted {
                UserDefaults.standard.set(true, forKey: "didPromptAccessibility")
                self.showAccessibilityPrompt()
            }
        }
    }
    
    @MainActor
    private func showAccessibilityPrompt() {
        let alert = NSAlert()
        alert.messageText = L("permission.title")
        alert.informativeText = L("permission.body")
        alert.addButton(withTitle: L("permission.openSettings"))
        alert.addButton(withTitle: L("permission.later"))
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            AccessibilityHelper.requestTrust()
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        ClipboardMonitor.shared.stop()
        DoubleCommandDetector.shared.stop()
    }
}
