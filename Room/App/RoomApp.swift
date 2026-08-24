import AppKit
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
                .roomAppearance(appearanceMode)
        } label: {
            MenuBarLabel()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
                .roomAppearance(appearanceMode)
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

extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var applicationAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    @MainActor
    func applyToApplication() {
        NSApp.appearance = applicationAppearance
    }
}

private struct RoomAppearanceModifier: ViewModifier {
    let mode: AppearanceMode

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(mode.colorScheme)
            .onAppear { mode.applyToApplication() }
            .onChange(of: mode) { _, newMode in
                newMode.applyToApplication()
            }
    }
}

private extension View {
    func roomAppearance(_ mode: AppearanceMode) -> some View {
        modifier(RoomAppearanceModifier(mode: mode))
    }
}
