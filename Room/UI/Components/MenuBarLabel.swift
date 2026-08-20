import SwiftUI

/// Menu bar label (requirements §9): [memory glyph]72 [storage glyph]68 — values only,
/// no units or captions. Rendered as ONE composed template image because MenuBarExtra
/// degrades multi-view labels. Falls back to the Room icon alone when both values are hidden.
struct MenuBarLabel: View {
    @Environment(AppState.self) private var state
    @AppStorage(SettingsKey.displayMode) private var displayModeRaw = DisplayMode.percentage.rawValue
    @AppStorage(SettingsKey.showMemory) private var showMemory = true
    @AppStorage(SettingsKey.showStorage) private var showStorage = true

    var body: some View {
        let mode = DisplayMode(rawValue: displayModeRaw) ?? .percentage
        Image(nsImage: MenuBarLabelRenderer.image(
            memory: showMemory ? MenuBarText.memoryValue(state.memory, mode: mode) : nil,
            storage: showStorage ? MenuBarText.storageValue(state.storage, mode: mode) : nil))
            .accessibilityLabel(accessibilityText(mode: mode))
    }

    private func accessibilityText(mode: DisplayMode) -> String {
        var parts = ["Room"]
        if showMemory {
            parts.append(spoken("Memory", value: MenuBarText.memoryValue(state.memory, mode: mode), mode: mode))
        }
        if showStorage {
            parts.append(spoken("Storage", value: MenuBarText.storageValue(state.storage, mode: mode), mode: mode))
        }
        return parts.joined(separator: ", ")
    }

    /// Distinguish the display mode in speech too ("5.6G" alone would not say Free vs. Used)
    private func spoken(_ label: String, value: String, mode: DisplayMode) -> String {
        switch mode {
        case .percentage: "\(label) \(value) percent used"
        case .free: "\(label) \(value) free"
        case .used: "\(label) \(value) used"
        }
    }
}
