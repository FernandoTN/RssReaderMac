import SwiftUI

struct ArticleListToolbar: ToolbarContent {
    let onRefresh: () -> Void
    let onMarkAllRead: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button(action: onRefresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .help("Refresh feeds")

            Button(action: onMarkAllRead) {
                Label("Mark All as Read", systemImage: "checkmark.circle")
            }
            .help("Mark all articles as read")
        }
    }
}

#Preview {
    NavigationStack {
        Text("Article List Content")
            .toolbar {
                ArticleListToolbar(
                    onRefresh: { print("Refresh tapped") },
                    onMarkAllRead: { print("Mark all read tapped") }
                )
            }
    }
}
