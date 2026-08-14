import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private var statusItem: NSStatusItem?
    private var popupWindow: ClipboardPopupWindow?
    private var settingsWindow: NSWindow?
    
    private let doubleCommand = DoubleCommandDetector.shared
    private let monitor = ClipboardMonitor.shared
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard")
            button.image?.isTemplate = true
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        popupWindow = ClipboardPopupWindow()
        
        doubleCommand.onDoubleCommand = { [weak self] in
            guard SettingsStore.shared.doubleCommandEnabled else { return }
            self?.togglePopup()
        }
        
        doubleCommand.start()
        
        for delay in [1.0, 2.5, 5.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if !self.doubleCommand.isRunning {
                    self.doubleCommand.restart()
                }
            }
        }
        
        monitor.start()
        
        NotificationCenter.default.addObserver(
            forName: .clipboardDidPaste,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if SettingsStore.shared.autoHideAfterPaste {
                self?.popupWindow?.hide()
            }
        }
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopup()
        }
    }
    
    private func togglePopup() {
        if !doubleCommand.isRunning {
            doubleCommand.restart()
        }
        
        guard let window = popupWindow else { return }
        
        if window.isVisible {
            window.hide()
        } else {
            window.show()
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: L("menu.showHistory"), action: #selector(showHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L("menu.checkUpdates"), action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L("menu.settings"), action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L("menu.quit"), action: #selector(quit), keyEquivalent: "q"))
        
        for item in menu.items {
            item.target = self
        }
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func showHistory() {
        togglePopup()
    }
    
    @objc private func checkForUpdates() {
        UpdateService.shared.checkForUpdates()
    }
    
    @objc private func openSettings() {
        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = L("settings.windowTitle")
            window.contentViewController = hosting
            window.center()
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 560, height: 400)
            
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
