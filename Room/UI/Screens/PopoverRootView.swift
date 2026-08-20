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
        .frame(width: 360)
        .onAppear {
            route = .home
            state.isPopoverVisible = true
            state.refreshNow()
        }
        .onDisappear { state.isPopoverVisible = false }
    }
}
