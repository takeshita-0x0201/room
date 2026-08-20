import SwiftUI

@main
struct RoomApp: App {
    init() {
        UserDefaults.standard.register(defaults: [
            SettingsKey.displayMode: "percentage",
            SettingsKey.showMemory: true,
            SettingsKey.showStorage: true,
            SettingsKey.refreshInterval: 5,
        ])
    }

    var body: some Scene {
        MenuBarExtra {
            Text("Room")
                .padding()
        } label: {
            Image(systemName: "cube.transparent")
        }
        .menuBarExtraStyle(.window)
    }
}

enum SettingsKey {
    static let displayMode = "displayMode"
    static let showMemory = "showMemory"
    static let showStorage = "showStorage"
    static let refreshInterval = "refreshInterval"
}
