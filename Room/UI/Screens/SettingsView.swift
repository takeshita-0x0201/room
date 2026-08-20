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

                VStack(alignment: .leading, spacing: 6) {
                    Text("Display")
                    ForEach(DisplayMode.allCases, id: \.rawValue) { mode in
                        displayModeRow(mode)
                    }
                }

                Picker("Refresh Interval", selection: $refreshInterval) {
                    Text("5 sec").tag(5)
                    Text("10 sec").tag(10)
                    Text("30 sec").tag(30)
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func displayModeRow(_ mode: DisplayMode) -> some View {
        let isSelected = displayModeRaw == mode.rawValue
        return Button {
            displayModeRaw = mode.rawValue
        } label: {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                Text(mode.title)
                Spacer()
                previewChip(for: mode)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title)\(isSelected ? ", selected" : "")")
    }

    /// 各モードのプレビューチップ（design-system §9。固定サンプル値）
    private func previewChip(for mode: DisplayMode) -> some View {
        let sample = sampleValues(for: mode)
        return HStack(spacing: 4) {
            Image(nsImage: RoomIcon.menuBarImage(pointSize: 12))
            Image(systemName: "memorychip")
            Text(sample.memory)
            Image(systemName: "internaldrive")
            Text(sample.storage)
        }
        .font(.caption)
        .monospacedDigit()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }

    private func sampleValues(for mode: DisplayMode) -> (memory: String, storage: String) {
        switch mode {
        case .percentage: ("72", "68")
        case .free: ("5.6G", "171G")
        case .used: ("18.4G", "341G")
        }
    }
}
