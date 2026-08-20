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
        if showMemory {
            parts.append(spoken("Memory", value: MenuBarText.memoryValue(state.memory, mode: mode), mode: mode))
        }
        if showStorage {
            parts.append(spoken("Storage", value: MenuBarText.storageValue(state.storage, mode: mode), mode: mode))
        }
        return parts.joined(separator: ", ")
    }

    /// 表示モードの意味を音声でも区別できるようにする（"5.6G" だけでは Free か Used か不明）
    private func spoken(_ label: String, value: String, mode: DisplayMode) -> String {
        switch mode {
        case .percentage: "\(label) \(value) percent used"
        case .free: "\(label) \(value) free"
        case .used: "\(label) \(value) used"
        }
    }
}
