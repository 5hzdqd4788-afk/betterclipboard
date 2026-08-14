import Foundation
import AppKit

enum ClipboardItemType: String, Codable, CaseIterable, Identifiable {
    case text
    case link
    case image
    case file
    case rtf
    
    var id: String { rawValue }
    
    @MainActor
    var displayName: String {
        switch self {
        case .text: return L("itemType.text")
        case .link: return L("itemType.link")
        case .image: return L("itemType.image")
        case .file: return L("itemType.file")
        case .rtf: return L("itemType.rtf")
        }
    }
    
    var systemImage: String {
        switch self {
        case .text: return "text.alignleft"
        case .link: return "link"
        case .image: return "photo"
        case .file: return "doc"
        case .rtf: return "doc.richtext"
        }
    }
}

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    let type: ClipboardItemType
    let textContent: String?
    let rtfData: Data?
    let imageFilename: String?
    let fileURLs: [URL]?
    var createdAt: Date
    /// Up to 3 most recent copy times (newest first)
    var copyTimestamps: [Date]
    var isPinned: Bool
    var isFavorite: Bool
    let sourceApp: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, textContent, rtfData, imageFilename, fileURLs
        case createdAt, copyTimestamps, isPinned, isFavorite, sourceApp
    }
    
    init(
        id: UUID,
        type: ClipboardItemType,
        textContent: String?,
        rtfData: Data?,
        imageFilename: String?,
        fileURLs: [URL]?,
        createdAt: Date,
        isPinned: Bool,
        isFavorite: Bool,
        sourceApp: String?,
        copyTimestamps: [Date]? = nil
    ) {
        self.id = id
        self.type = type
        self.textContent = textContent
        self.rtfData = rtfData
        self.imageFilename = imageFilename
        self.fileURLs = fileURLs
        self.createdAt = createdAt
        self.copyTimestamps = copyTimestamps ?? [createdAt]
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.sourceApp = sourceApp
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        type = try c.decode(ClipboardItemType.self, forKey: .type)
        textContent = try c.decodeIfPresent(String.self, forKey: .textContent)
        rtfData = try c.decodeIfPresent(Data.self, forKey: .rtfData)
        imageFilename = try c.decodeIfPresent(String.self, forKey: .imageFilename)
        fileURLs = try c.decodeIfPresent([URL].self, forKey: .fileURLs)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        copyTimestamps = try c.decodeIfPresent([Date].self, forKey: .copyTimestamps) ?? [createdAt]
        isPinned = try c.decode(Bool.self, forKey: .isPinned)
        isFavorite = try c.decode(Bool.self, forKey: .isFavorite)
        sourceApp = try c.decodeIfPresent(String.self, forKey: .sourceApp)
    }
    
    @MainActor
    var previewText: String {
        if let text = textContent, !text.isEmpty { return text }
        if let urls = fileURLs, let first = urls.first { return first.lastPathComponent }
        if type == .image { return L("item.image") }
        return ""
    }
    
    @MainActor
    var displayDate: String {
        let times = Array(copyTimestamps.prefix(3))
        guard !times.isEmpty else { return formatOne(createdAt) }
        return times.map { formatOne($0) }.joined(separator: " · ")
    }
    
    @MainActor
    private func formatOne(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.language.locale
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "\(L("item.yesterday")) \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "d MMM HH:mm"
            return formatter.string(from: date)
        }
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}
