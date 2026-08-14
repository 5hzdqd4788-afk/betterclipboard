import Foundation
import AppKit
import ApplicationServices

@MainActor
final class PasteService {
    static let shared = PasteService()
    
    private init() {}
    
    /// Pastes the item normally (preserves formatting when possible)
    func paste(_ item: ClipboardItem) {
        writeToPasteboard(item, plainOnly: false)
        simulatePaste()
    }
    
    /// Pastes without formatting (plain text only)
    func pasteWithoutFormatting(_ item: ClipboardItem) {
        writeToPasteboard(item, plainOnly: true)
        simulatePaste()
    }
    
    // MARK: - Private
    
    private func writeToPasteboard(_ item: ClipboardItem, plainOnly: Bool) {
        let pb = NSPasteboard.general
        pb.clearContents()
        
        switch item.type {
        case .text, .link:
            if let text = item.textContent {
                pb.setString(text, forType: .string)
            }
            
        case .rtf:
            if plainOnly {
                if let text = item.textContent {
                    pb.setString(text, forType: .string)
                }
            } else {
                if let rtf = item.rtfData {
                    pb.setData(rtf, forType: .rtf)
                }
                if let text = item.textContent {
                    pb.setString(text, forType: .string)
                }
            }
            
        case .image:
            if let filename = item.imageFilename {
                // Load image synchronously from disk (safe, no actor isolation needed for file read)
                let imagesURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                    .appendingPathComponent("Clipboard/Images", isDirectory: true)
                let url = imagesURL.appendingPathComponent(filename)
                if let image = NSImage(contentsOf: url) {
                    pb.writeObjects([image])
                }
            }
            
        case .file:
            if let urls = item.fileURLs {
                pb.writeObjects(urls as [NSPasteboardWriting])
            }
        }
    }
    
    private func simulatePaste() {
        // Prefer CGEvent for reliability
        let source = CGEventSource(stateID: .combinedSessionState)
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}
