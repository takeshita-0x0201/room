import SwiftUI

struct PopoverRootView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Text("Room")
            .padding()
            .frame(width: 300)
            .onAppear { state.isPopoverVisible = true; state.refreshNow() }
            .onDisappear { state.isPopoverVisible = false }
    }
}
