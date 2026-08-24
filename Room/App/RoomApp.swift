import SwiftUI

@main
struct RoomApp: App {
    @AppStorage(SettingsKey.appearance) private var appearanceRaw = AppearanceMode.system.rawValue
    @State private var appState: AppState

    init() {
        UserDefaults.standard.register(defaults: [
            SettingsKey.appearance: AppearanceMode.system.rawValue,
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
                .preferredColorScheme(appearanceMode.colorScheme)
        } label: {
            MenuBarLabel()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
                .preferredColorScheme(appearanceMode.colorScheme)
        }
    }

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }
}

enum SettingsKey {
    static let appearance = "appearance"
    static let displayMode = "displayMode"
    static let showMemory = "showMemory"
    static let showStorage = "showStorage"
    static let refreshInterval = "refreshInterval"
}

private extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
