import ServiceManagement
import SwiftUI

struct SettingsView: View {
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
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)

                LabeledContent("Preview") {
                    HStack(spacing: 4) {
                        Image(nsImage: RoomIcon.menuBarImage())
                        Image(systemName: "memorychip")
                        Text(sampleValues.memory)
                        Image(systemName: "internaldrive")
                        Text(sampleValues.storage)
                    }
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                }

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

    /// プレビューは固定サンプル値（要件 §19。実測値だと切替の意図が伝わりにくい）
    private var sampleValues: (memory: String, storage: String) {
        switch DisplayMode(rawValue: displayModeRaw) ?? .percentage {
        case .percentage: ("72", "68")
        case .free: ("5.6G", "171G")
        case .used: ("18.4G", "341G")
        }
    }
}
