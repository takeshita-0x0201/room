import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var state
    @AppStorage(SettingsKey.displayMode) private var displayModeRaw = DisplayMode.percentage.rawValue
    @AppStorage(SettingsKey.showMemory) private var showMemory = true
    @AppStorage(SettingsKey.showStorage) private var showStorage = true
    @AppStorage(SettingsKey.refreshInterval) private var refreshInterval = 5
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            // 失敗しても UI を実状態に合わせる（下の再読込が正）
                        }
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
            }

            Section("Menu Bar") {
                Toggle("Show Memory", isOn: $showMemory)
                Toggle("Show Storage", isOn: $showStorage)

                Picker("Display", selection: $displayModeRaw) {
                    ForEach(DisplayMode.allCases, id: \.rawValue) { mode in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(mode.title)
                            Text(preview(for: mode))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)

                Picker("Refresh Interval", selection: $refreshInterval) {
                    Text("5 sec").tag(5)
                    Text("10 sec").tag(10)
                    Text("30 sec").tag(30)
                }
                .pickerStyle(.radioGroup)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// メニューバープレビュー（要件 §19: 各モードの見え方を表示）
    private func preview(for mode: DisplayMode) -> String {
        "◇  ▦\(MenuBarText.memoryValue(state.memory, mode: mode))  ▱\(MenuBarText.storageValue(state.storage, mode: mode))"
    }
}
