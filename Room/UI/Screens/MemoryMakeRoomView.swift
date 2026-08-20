import SwiftUI

struct MemoryMakeRoomView: View {
    @Binding var route: PopoverRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BackHeader(title: "Make Room — Memory", route: $route, back: .makeRoom)
            Text("Coming soon").foregroundStyle(.secondary)
        }
        .padding(12)
    }
}
