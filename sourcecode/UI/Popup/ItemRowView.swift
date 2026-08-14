import SwiftUI
import AppKit

struct ItemRowView: View {
    let item: ClipboardItem
    let onPaste: () -> Void
    let onPasteWithoutFormatting: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    @State private var fullImage: NSImage? = nil
    
    var body: some View {
        Group {
            if item.type == .image {
                imageRow
            } else {
                textRow
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: Theme.itemCornerRadius, style: .continuous)
                .fill(isHovering ? Color.primary.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
        .onTapGesture { onPaste() }
        .onAppear { loadImageIfNeeded() }
        .contextMenu {
            Button(L("context.paste")) { onPaste() }
            Button(L("context.pasteWithoutFormatting")) { onPasteWithoutFormatting() }
            Divider()
            Button(item.isPinned ? L("context.unpin") : L("context.pin")) { onTogglePin() }
            Divider()
            Button(L("context.delete"), role: .destructive) { onDelete() }
        }
    }
    
    private var textRow: some View {
        HStack(alignment: .top, spacing: 10) {
            iconView
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.previewText)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(6)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                if SettingsStore.shared.showTimestamps {
                    Text(item.displayDate)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 4)
            
            pinButton
                .padding(.top, 2)
        }
    }
    
    private var imageRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Group {
                if let fullImage {
                    Image(nsImage: fullImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.primary.opacity(0.06)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(L("item.image"))
                    .font(.system(size: 13, weight: .medium))
                
                if SettingsStore.shared.showTimestamps {
                    Text(item.displayDate)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 4)
            
            pinButton
        }
    }
    
    private var pinButton: some View {
        Button {
            onTogglePin()
        } label: {
            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(item.isPinned ? Color.red : Color.accentColor.opacity(0.85))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isHovering || item.isPinned ? 1.0 : 0.4)
        .help(item.isPinned ? L("context.unpin") : L("context.pin"))
    }
    
    @ViewBuilder
    private var iconView: some View {
        switch item.type {
        case .file:
            Image(systemName: "doc")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primary.opacity(0.06))
        case .link:
            Image(systemName: "link")
                .font(.system(size: 13))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.blue.opacity(0.1))
        default:
            Image(systemName: "text.alignleft")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primary.opacity(0.06))
        }
    }
    
    private func loadImageIfNeeded() {
        guard item.type == .image, let filename = item.imageFilename else { return }
        
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Clipboard/Images", isDirectory: true)
            .appendingPathComponent(filename)
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = NSImage(contentsOf: url) {
                DispatchQueue.main.async {
                    self.fullImage = image
                }
            }
        }
    }
}
