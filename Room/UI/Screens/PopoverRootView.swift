import SwiftUI

enum PopoverRoute {
    case home, processes, makeRoom, memoryMakeRoom, storageMakeRoom
}

struct PopoverRootView: View {
    @Environment(AppState.self) private var state
    @State private var route: PopoverRoute = .home

    var body: some View {
        Group {
            switch route {
            case .home: HomeView(route: $route)
            case .processes: ProcessesView(route: $route)
            case .makeRoom: MakeRoomHubView(route: $route)
            case .memoryMakeRoom: MemoryMakeRoomView(route: $route)
            case .storageMakeRoom: StorageMakeRoomView(route: $route)
            }
        }
        .frame(width: 320)
        // MenuBarExtra keeps its previous window height while navigating. Keep
        // shorter destinations top-aligned inside the home screen's footprint
        // so the system window never exposes an empty translucent region.
        .frame(minHeight: 390, alignment: .top)
        .background(RoomPalette.canvas)
        .onAppear {
            route = .home
            state.isPopoverVisible = true
            state.refreshNow()
        }
        .onDisappear { state.isPopoverVisible = false }
    }
}
