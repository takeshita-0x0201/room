import SwiftUI

@main
struct RoomApp: App {
    @State private var appState: AppState

    init() {
        UserDefaults.standard.register(defaults: [
            SettingsKey.displayMode: DisplayMode.percentage.rawValue,
            SettingsKey.showMemory: true,
            SettingsKey.showStorage: true,
            SettingsKey.refreshInterval: 5,
        ])
        _appState = State(initialValue: AppState())
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView()
                .environment(appState)
        } label: {
            MenuBarLabel()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}

enum SettingsKey {
    static let displayMode = "displayMode"
    static let showMemory = "showMemory"
    static let showStorage = "showStorage"
    static let refreshInterval = "refreshInterval"
}
