import Foundation
import AppKit

actor ClipboardStore {
    static let shared = ClipboardStore()
    
    private let fileManager = FileManager.default
    private var items: [ClipboardItem] = []
    
    private var appSupportURL: URL {
        let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Clipboard", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    private var imagesURL: URL {
        let url = appSupportURL.appendingPathComponent("Images", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    private var databaseURL: URL {
        appSupportURL.appendingPathComponent("history.json")
    }
    
    init() {
        Task { await load() }
    }
    
    func allItems() -> [ClipboardItem] {
        items.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
    
    func add(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { isDuplicate($0, item) }) {
            var existing = items.remove(at: index)
            let now = item.createdAt
            existing.createdAt = now
            var stamps = existing.copyTimestamps
            stamps.insert(now, at: 0)
            var unique: [Date] = []
            for s in stamps {
                if unique.contains(where: { abs($0.timeIntervalSince(s)) < 0.5 }) { continue }
                unique.append(s)
                if unique.count == 3 { break }
            }
            existing.copyTimestamps = unique
            items.insert(existing, at: 0)
            save()
            return
        }
        
        items.insert(item, at: 0)
        enforceLimit()
        save()
    }
    
    private func enforceLimit() {
        let maxItems = UserDefaults.standard.object(forKey: "settings.maxHistoryItems") as? Int ?? 150
        guard maxItems > 0 else { return }
        
        if items.count > maxItems {
            let pinned = items.filter { $0.isPinned }
            var nonPinned = items.filter { !$0.isPinned }
            let allowed = max(0, maxItems - pinned.count)
            if nonPinned.count > allowed {
                let toRemove = nonPinned.suffix(nonPinned.count - allowed)
                for item in toRemove {
                    removeImageIfNeeded(item)
                }
                nonPinned = Array(nonPinned.prefix(allowed))
                items = pinned + nonPinned
            }
        }
    }
    
    func togglePin(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isPinned.toggle()
        save()
    }
    
    func toggleFavorite(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isFavorite.toggle()
        save()
    }
    
    func delete(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items.remove(at: index)
        removeImageIfNeeded(item)
        save()
    }
    
    func clearHistory(keepPinned: Bool = true) {
        if keepPinned {
            let toRemove = items.filter { !$0.isPinned }
            for item in toRemove { removeImageIfNeeded(item) }
            items = items.filter { $0.isPinned }
        } else {
            for item in items { removeImageIfNeeded(item) }
            items.removeAll()
        }
        save()
    }
    
    func clearHistory(from start: Date, to end: Date, keepPinned: Bool) {
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        let endDay = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: end)) ?? end
        
        let shouldRemove: (ClipboardItem) -> Bool = { item in
            if keepPinned && item.isPinned { return false }
            return item.createdAt >= startDay && item.createdAt < endDay
        }
        
        for item in items where shouldRemove(item) {
            removeImageIfNeeded(item)
        }
        items.removeAll(where: shouldRemove)
        save()
    }
    
    func saveImage(_ image: NSImage) -> String? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        let filename = UUID().uuidString + ".png"
        let url = imagesURL.appendingPathComponent(filename)
        do {
            try pngData.write(to: url)
            return filename
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    func loadImage(filename: String) -> NSImage? {
        NSImage(contentsOf: imagesURL.appendingPathComponent(filename))
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: databaseURL, options: .atomic)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
    
    private func load() {
        guard fileManager.fileExists(atPath: databaseURL.path) else { return }
        do {
            let data = try Data(contentsOf: databaseURL)
            items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
            items = []
        }
    }
    
    private func removeImageIfNeeded(_ item: ClipboardItem) {
        guard let filename = item.imageFilename else { return }
        try? fileManager.removeItem(at: imagesURL.appendingPathComponent(filename))
    }
    
    private func isDuplicate(_ a: ClipboardItem, _ b: ClipboardItem) -> Bool {
        if a.type != b.type { return false }
        switch a.type {
        case .text, .link, .rtf:
            return a.textContent == b.textContent
        case .image:
            return false
        case .file:
            return a.fileURLs == b.fileURLs
        }
    }
}
