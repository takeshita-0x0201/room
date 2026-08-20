import SwiftUI

/// メニューバー表示（要件 §9）: [Room Icon] [Memory Icon]72 [Storage Icon]68
/// テキストは数値のみ。単位・% は出さない。
struct MenuBarLabel: View {
    @Environment(AppState.self) private var state
    @AppStorage(SettingsKey.displayMode) private var displayModeRaw = DisplayMode.percentage.rawValue
    @AppStorage(SettingsKey.showMemory) private var showMemory = true
    @AppStorage(SettingsKey.showStorage) private var showStorage = true

    var body: some View {
        let mode = DisplayMode(rawValue: displayModeRaw) ?? .percentage
        HStack(spacing: 4) {
            Image(nsImage: RoomIcon.menuBarImage())
            if showMemory {
                Image(systemName: "memorychip")
                Text(MenuBarText.memoryValue(state.memory, mode: mode))
                    .monospacedDigit()
            }
            if showStorage {
                Image(systemName: "internaldrive")
                Text(MenuBarText.storageValue(state.storage, mode: mode))
                    .monospacedDigit()
            }
        }
        .accessibilityLabel(accessibilityText(mode: mode))
    }

    private func accessibilityText(mode: DisplayMode) -> String {
        var parts = ["Room"]
        if showMemory { parts.append("Memory \(MenuBarText.memoryValue(state.memory, mode: mode))") }
        if showStorage { parts.append("Storage \(MenuBarText.storageValue(state.storage, mode: mode))") }
        return parts.joined(separator: ", ")
    }
}
