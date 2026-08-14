import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var rangeFrom = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var rangeTo = Date()
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case general, position, history, capture, appearance, about
        var id: String { rawValue }
        
        @MainActor
        var title: String {
            switch self {
            case .general: return L("settingsTab.general")
            case .position: return L("settingsTab.position")
            case .history: return L("settingsTab.history")
            case .capture: return L("settingsTab.capture")
            case .appearance: return L("settingsTab.appearance")
            case .about: return L("settingsTab.about")
            }
        }
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .position: return "macwindow"
            case .history: return "clock"
            case .capture: return "doc.on.clipboard"
            case .appearance: return "paintbrush"
            case .about: return "info.circle"
            }
        }
    }
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(SettingsTab.allCases) { tab in
                    Button { selectedTab = tab } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon).frame(width: 16)
                            Text(tab.title)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Button(L("settingsTab.resetAll")) {
                    settings.resetToDefaults()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
            .padding(10)
            .frame(width: 160)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .general: generalSection
                    case .position: positionSection
                    case .history: historySection
                    case .capture: captureSection
                    case .appearance: appearanceSection
                    case .about: aboutSection
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 420)
        }
        .frame(width: 640, height: 480)
    }
    
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L("settings.general.header"))
            
            Picker(L("settings.general.language"), selection: $loc.language) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)
            
            Divider()
            
            Toggle(L("settings.general.launchAtLogin"), isOn: $settings.launchAtLogin)
            Toggle(L("settings.general.doubleCommand"), isOn: $settings.doubleCommandEnabled)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(LF("settings.general.doubleCommandInterval", String(format: "%.2f", settings.doubleCommandInterval)))
                    .font(.callout)
                Slider(value: $settings.doubleCommandInterval, in: 0.2...0.8, step: 0.05)
            }
            
            Toggle(L("settings.general.autoHide"), isOn: $settings.autoHideAfterPaste)
        }
    }
    
    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L("settings.position.header"))
            
            Picker(L("settings.position.mode"), selection: $settings.openPositionMode) {
                ForEach(SettingsStore.OpenPositionMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.radioGroup)
            
            Text(settings.openPositionMode.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Divider()
            
            Button(L("settings.position.resetSaved")) {
                settings.lastWindowFrame = nil
            }
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L("settings.history.header"))
            
            VStack(alignment: .leading, spacing: 6) {
                let label: String = settings.maxHistoryItems == 0
                    ? L("settings.history.unlimited")
                    : LF("settings.history.maxItems", "\(settings.maxHistoryItems)")
                Text(label).font(.callout)
                Slider(
                    value: Binding(
                        get: { Double(settings.maxHistoryItems) },
                        set: { settings.maxHistoryItems = Int($0) }
                    ),
                    in: 0...500,
                    step: 10
                )
                Text(L("settings.history.zeroNote"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Toggle(L("settings.history.keepPinned"), isOn: $settings.keepPinnedOnClear)
            Toggle(L("settings.history.showTimestamps"), isOn: $settings.showTimestamps)
            
            Divider()
            
            sectionHeader(L("settings.history.clearRange"))
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("settings.history.from")).font(.caption).foregroundStyle(.secondary)
                    DatePicker("", selection: $rangeFrom, displayedComponents: .date)
                        .labelsHidden()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("settings.history.to")).font(.caption).foregroundStyle(.secondary)
                    DatePicker("", selection: $rangeTo, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            
            Button(L("settings.history.clearRangeButton"), role: .destructive) {
                Task {
                    await ClipboardStore.shared.clearHistory(
                        from: rangeFrom,
                        to: rangeTo,
                        keepPinned: settings.keepPinnedOnClear
                    )
                }
            }
            
            Button(L("settings.history.clearNow"), role: .destructive) {
                Task {
                    await ClipboardStore.shared.clearHistory(keepPinned: settings.keepPinnedOnClear)
                }
            }
        }
    }
    
    private var captureSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L("settings.capture.header"))
            Toggle(L("itemType.text"), isOn: $settings.captureText)
            Toggle(L("itemType.link"), isOn: $settings.captureLinks)
            Toggle(L("itemType.image"), isOn: $settings.captureImages)
            Toggle(L("itemType.file"), isOn: $settings.captureFiles)
            Text(L("settings.capture.note"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L("settings.appearance.header"))
            VStack(alignment: .leading, spacing: 6) {
                Text(LF("settings.appearance.width", "\(Int(settings.popupWidth))"))
                    .font(.callout)
                Slider(value: $settings.popupWidth, in: 300...520, step: 10)
            }
            Text(L("settings.appearance.note"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(L("settings.about.header"))
            
            HStack(spacing: 12) {
                Image(systemName: "clipboard")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("settings.about.appName"))
                        .font(.title2.weight(.semibold))
                    Text(L("settings.about.tagline"))
                        .foregroundStyle(.secondary)
                    Text(L("settings.about.version"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Divider()
            
            Text("ohpoh & co")
                .font(.headline)
            
            Text(L("settings.about.shortcuts"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.title3.weight(.semibold))
    }
}
