import Foundation
import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
final class ClipboardPopupViewModel: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published var searchText: String = ""
    @Published var isSearchActive: Bool = false
    @Published var selectedDate: Date? = nil
    @Published var isCalendarOpen: Bool = false
    /// Bumped whenever search field must grab keyboard focus
    @Published var searchFocusToken: Int = 0
    
    private let store = ClipboardStore.shared
    private let pasteService = PasteService.shared
    
    init() {
        Task { await refresh() }
    }
    
    func refresh() async {
        items = await store.allItems()
    }
    
    var filteredItems: [ClipboardItem] {
        var result = items
        
        if let day = selectedDate {
            let cal = Calendar.current
            result = result.filter { cal.isDate($0.createdAt, inSameDayAs: day) }
        }
        
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            result = result.filter {
                ($0.textContent?.localizedCaseInsensitiveContains(q) ?? false)
                || ($0.fileURLs?.contains(where: { $0.lastPathComponent.localizedCaseInsensitiveContains(q) }) ?? false)
            }
        }
        
        return result
    }
    
    func items(matching filter: FilterMode) -> [ClipboardItem] {
        let base = filteredItems
        switch filter {
        case .all: return base
        case .pinned: return base.filter { $0.isPinned }
        case .type(let type): return base.filter { $0.type == type }
        }
    }
    
    func paste(_ item: ClipboardItem) {
        pasteService.paste(item)
        NotificationCenter.default.post(name: .clipboardDidPaste, object: nil)
    }
    
    func pasteWithoutFormatting(_ item: ClipboardItem) {
        pasteService.pasteWithoutFormatting(item)
        NotificationCenter.default.post(name: .clipboardDidPaste, object: nil)
    }
    
    func togglePin(_ item: ClipboardItem) {
        Task {
            await store.togglePin(id: item.id)
            await refresh()
        }
    }
    
    func toggleFavorite(_ item: ClipboardItem) {
        Task {
            await store.toggleFavorite(id: item.id)
            await refresh()
        }
    }
    
    func delete(_ item: ClipboardItem) {
        Task {
            await store.delete(id: item.id)
            await refresh()
        }
    }
    
    func clearDateFilter() {
        selectedDate = nil
        isCalendarOpen = false
    }

    func requestSearchFocus() {
        searchFocusToken += 1
    }
    
    func makeDraggingItem(for item: ClipboardItem) -> NSItemProvider {
        switch item.type {
        case .text, .link, .rtf:
            let text = item.textContent ?? ""
            return NSItemProvider(object: text as NSString)
            
        case .image:
            if let filename = item.imageFilename {
                let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                    .appendingPathComponent("Clipboard/Images", isDirectory: true)
                    .appendingPathComponent(filename)
                if let image = NSImage(contentsOf: url) {
                    return NSItemProvider(object: image)
                }
            }
            return NSItemProvider()
            
        case .file:
            if let urls = item.fileURLs, let first = urls.first {
                return NSItemProvider(contentsOf: first) ?? NSItemProvider()
            }
            return NSItemProvider()
        }
    }
}

extension Notification.Name {
    static let clipboardDidPaste = Notification.Name("clipboardDidPaste")
}
