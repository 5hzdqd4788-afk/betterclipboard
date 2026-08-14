import SwiftUI
import AppKit

enum FilterMode: Equatable, CaseIterable {
    case all
    case pinned
    case type(ClipboardItemType)
    
    static var allCases: [FilterMode] {
        [.all, .pinned, .type(.text), .type(.link), .type(.image), .type(.file)]
    }
    
    var systemImage: String {
        switch self {
        case .all: return "square.stack.3d.up"
        case .pinned: return "pin.fill"
        case .type(.text): return "text.alignleft"
        case .type(.link): return "link"
        case .type(.image): return "photo"
        case .type(.file): return "doc"
        case .type(.rtf): return "doc.richtext"
        }
    }
    
    var key: String {
        switch self {
        case .all: return "all"
        case .pinned: return "pinned"
        case .type(let type): return "type.\(type.rawValue)"
        }
    }

    @MainActor
    var help: String {
        switch self {
        case .all: return L("filter.all")
        case .pinned: return L("filter.pinned")
        case .type(.text): return L("itemType.text")
        case .type(.link): return L("itemType.link")
        case .type(.image): return L("itemType.image")
        case .type(.file): return L("itemType.file")
        case .type(.rtf): return L("filter.rtf")
        }
    }
}

struct TypeFilterBar: View {
    @Binding var filter: FilterMode
    var onClose: (() -> Void)?
    var onSearchTap: (() -> Void)?
    var onCalendarTap: (() -> Void)?
    var hasDateFilter: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            Button {
                onClose?()
            } label: {
                Circle()
                    .fill(Color(red: 1.0, green: 0.35, blue: 0.35))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.black.opacity(0.55))
                    )
            }
            .buttonStyle(.plain)
            .help(L("filter.close"))
            .padding(.trailing, 4)
            
            ForEach(FilterMode.allCases, id: \.key) { mode in
                FilterChip(
                    systemImage: mode.systemImage,
                    isSelected: filter == mode
                ) {
                    withAnimation(Theme.animation) { filter = mode }
                }
                .help(mode.help)
            }
            
            Spacer(minLength: 4)
            
            Button {
                onSearchTap?()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.primary.opacity(0.06)))
                    .foregroundStyle(Color.primary.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help(L("search.button"))
            
            Button {
                onCalendarTap?()
            } label: {
                Image(systemName: hasDateFilter ? "calendar.badge.checkmark" : "calendar")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(hasDateFilter
                            ? Color.accentColor.opacity(0.22)
                            : Color.primary.opacity(0.06))
                    )
                    .foregroundStyle(hasDateFilter ? Color.accentColor : Color.primary.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help(L("calendar.button"))
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(height: 44)
        .background(WindowDragArea())
    }
}

private struct FilterChip: View {
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.06))
                )
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary.opacity(0.7))
                .scaleEffect(isSelected ? 1.08 : 1.0)
                .animation(Theme.quickAnimation, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragNSView() }
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class DragNSView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
