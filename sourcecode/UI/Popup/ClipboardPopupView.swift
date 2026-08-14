import SwiftUI
import AppKit

struct ClipboardPopupView: View {
    @ObservedObject var viewModel: ClipboardPopupViewModel
    @State private var filter: FilterMode = .all
    @FocusState private var searchFocused: Bool
    var onClose: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            TypeFilterBar(
                filter: $filter,
                onClose: onClose,
                onSearchTap: {
                    withAnimation(Theme.quickAnimation) {
                        viewModel.isSearchActive = true
                    }
                    DispatchQueue.main.async {
                        searchFocused = true
                    }
                },
                onCalendarTap: {
                    withAnimation(Theme.quickAnimation) {
                        viewModel.isCalendarOpen.toggle()
                    }
                },
                hasDateFilter: viewModel.selectedDate != nil
            )
            
            if viewModel.isSearchActive {
                searchBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            if viewModel.isCalendarOpen {
                calendarBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Divider().opacity(0.35)
            
            ZStack {
                let list = viewModel.items(matching: filter)
                if list.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(list) { item in
                                ItemRowView(
                                    item: item,
                                    onPaste: { viewModel.paste(item) },
                                    onPasteWithoutFormatting: { viewModel.pasteWithoutFormatting(item) },
                                    onTogglePin: { viewModel.togglePin(item) },
                                    onDelete: { viewModel.delete(item) }
                                )
                                .onDrag { viewModel.makeDraggingItem(for: item) }
                            }
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 5)
                        .animation(Theme.animation, value: filter)
                        .animation(Theme.animation, value: viewModel.searchText)
                        .animation(Theme.animation, value: viewModel.selectedDate)
                    }
                }
            }
            .frame(minHeight: 160)
        }
        .frame(minWidth: 320, idealWidth: Theme.popupWidth, maxWidth: 560)
        .frame(minHeight: 220, maxHeight: 700)
        .background(LiquidGlassBackground())
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 10)
        .onChange(of: searchFocused) { _, focused in
            if !focused && viewModel.searchText.isEmpty {
                withAnimation(Theme.quickAnimation) {
                    viewModel.isSearchActive = false
                }
            }
        }
        .onChange(of: viewModel.isSearchActive) { _, active in
            if active {
                DispatchQueue.main.async {
                    searchFocused = true
                }
            }
        }
        .onChange(of: viewModel.searchFocusToken) { _, _ in
            DispatchQueue.main.async {
                searchFocused = true
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(L("search.placeholder"), text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .focused($searchFocused)
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            Button {
                withAnimation(Theme.quickAnimation) {
                    viewModel.searchText = ""
                    viewModel.isSearchActive = false
                    searchFocused = false
                }
            } label: {
                Text(L("search.cancel"))
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.04))
    }
    
    private var calendarBar: some View {
        VStack(spacing: 8) {
            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.selectedDate ?? Date() },
                    set: { viewModel.selectedDate = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .frame(maxHeight: 280)
            
            HStack {
                if viewModel.selectedDate != nil {
                    Button(L("calendar.clear")) {
                        viewModel.clearDateFilter()
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button(L("calendar.done")) {
                    withAnimation(Theme.quickAnimation) {
                        viewModel.isCalendarOpen = false
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .padding(.top, 4)
        .background(Color.primary.opacity(0.03))
    }
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: viewModel.searchText.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.secondary)
            Text(viewModel.searchText.isEmpty ? L("popup.empty") : L("search.noResults"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct LiquidGlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = Theme.cornerRadius
        view.layer?.masksToBounds = true
        if #available(macOS 15.0, *) {
            view.material = .popover
        }
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.state = .active
    }
}
