import Foundation

/// Represents the different selection states in the sidebar
enum SidebarItem: Hashable {
    case all
    case unread
    case starred
    case today
    case smartFolder(SmartFolder)
    case feed(Feed)

    var displayName: String {
        switch self {
        case .all:
            return "All Articles"
        case .unread:
            return "Unread"
        case .starred:
            return "Starred"
        case .today:
            return "Today"
        case .smartFolder(let folder):
            return folder.name
        case .feed(let feed):
            return feed.title
        }
    }

    var iconName: String {
        switch self {
        case .all:
            return "tray.full"
        case .unread:
            return "circle.fill"
        case .starred:
            return "star.fill"
        case .today:
            return "calendar"
        case .smartFolder:
            return "folder.badge.gearshape"
        case .feed:
            return "dot.radiowaves.up.forward"
        }
    }
}
