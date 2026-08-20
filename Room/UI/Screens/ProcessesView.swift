import SwiftUI

struct ProcessesView: View {
    @Binding var route: PopoverRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BackHeader(title: "Processes", route: $route, back: .home)
            Text("Coming soon").foregroundStyle(.secondary)
        }
        .padding(12)
    }
}
