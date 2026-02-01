import SwiftUI

/// A row view for displaying a smart folder or built-in filter in the sidebar
struct SmartFolderRow: View {
    let item: SidebarItem

    var body: some View {
        Label(item.displayName, systemImage: item.iconName)
    }
}

#Preview {
    List {
        SmartFolderRow(item: .all)
        SmartFolderRow(item: .unread)
        SmartFolderRow(item: .starred)
        SmartFolderRow(item: .today)
    }
    .listStyle(.sidebar)
    .frame(width: 200)
}
