import Foundation
import AppKit
import Combine

@MainActor
final class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()
    
    @Published private(set) var lastChangeCount: Int = 0
    
    private var timer: Timer?
    private let pasteboard = NSPasteboard.general
    private let store = ClipboardStore.shared
    
    private init() {}
    
    func start() {
        lastChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.checkForChanges() }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount
        Task { await processPasteboard() }
    }
    
    private func processPasteboard() async {
        let settings = SettingsStore.shared
        
        if settings.captureImages, let image = NSImage(pasteboard: pasteboard) {
            let filename = await store.saveImage(image)
            let item = ClipboardItem(
                id: UUID(), type: .image, textContent: nil, rtfData: nil,
                imageFilename: filename, fileURLs: nil, createdAt: Date(),
                isPinned: false, isFavorite: false, sourceApp: currentFrontmostAppName()
            )
            await store.add(item)
            return
        }
        
        if settings.captureFiles,
           let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !urls.isEmpty, urls.allSatisfy({ $0.isFileURL }) {
            let item = ClipboardItem(
                id: UUID(), type: .file, textContent: nil, rtfData: nil,
                imageFilename: nil, fileURLs: urls, createdAt: Date(),
                isPinned: false, isFavorite: false, sourceApp: currentFrontmostAppName()
            )
            await store.add(item)
            return
        }
        
        if settings.captureText, let rtf = pasteboard.data(forType: .rtf) {
            let plain = pasteboard.string(forType: .string)
            let item = ClipboardItem(
                id: UUID(), type: .rtf, textContent: plain, rtfData: rtf,
                imageFilename: nil, fileURLs: nil, createdAt: Date(),
                isPinned: false, isFavorite: false, sourceApp: currentFrontmostAppName()
            )
            await store.add(item)
            return
        }
        
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            let isURL = isLink(trimmed)
            
            if isURL && !settings.captureLinks { return }
            if !isURL && !settings.captureText { return }
            
            let type: ClipboardItemType = isURL ? .link : .text
            let item = ClipboardItem(
                id: UUID(), type: type, textContent: string, rtfData: nil,
                imageFilename: nil, fileURLs: nil, createdAt: Date(),
                isPinned: false, isFavorite: false, sourceApp: currentFrontmostAppName()
            )
            await store.add(item)
        }
    }
    
    private func isLink(_ string: String) -> Bool {
        guard let url = URL(string: string),
              let scheme = url.scheme?.lowercased() else { return false }
        return ["http", "https", "ftp", "mailto", "file"].contains(scheme)
    }
    
    private func currentFrontmostAppName() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }
}
