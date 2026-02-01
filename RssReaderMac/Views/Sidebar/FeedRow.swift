import SwiftUI
import SwiftData

/// A row view for displaying a feed in the sidebar
struct FeedRow: View {
    let feed: Feed
    let onMarkAllRead: () -> Void
    let onCopyURL: () -> Void
    let onDelete: () -> Void

    private var unreadCount: Int {
        feed.articles.filter { !$0.isRead }.count
    }

    var body: some View {
        HStack(spacing: 8) {
            feedIcon

            Text(feed.title)
                .lineLimit(1)

            Spacer()

            if unreadCount > 0 {
                unreadBadge
            }
        }
        .contextMenu {
            Button("Mark All as Read") {
                onMarkAllRead()
            }

            Button("Copy Feed URL") {
                onCopyURL()
            }

            Divider()

            Button("Delete Feed", role: .destructive) {
                onDelete()
            }
        }
    }

    @ViewBuilder
    private var feedIcon: some View {
        if let iconURL = feed.iconURL {
            AsyncImage(url: iconURL) { phase in
                switch phase {
                case .empty:
                    defaultIcon
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                case .failure:
                    defaultIcon
                @unknown default:
                    defaultIcon
                }
            }
            .frame(width: 16, height: 16)
        } else {
            defaultIcon
        }
    }

    private var defaultIcon: some View {
        Image(systemName: "dot.radiowaves.up.forward")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
            .foregroundStyle(.secondary)
    }

    private var unreadBadge: some View {
        Text("\(unreadCount)")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.accentColor)
            .clipShape(Capsule())
    }
}

#Preview {
    let feed = Feed(
        title: "Example Feed",
        feedURL: URL(string: "https://example.com/feed.xml")!,
        siteURL: URL(string: "https://example.com")!
    )

    return List {
        FeedRow(
            feed: feed,
            onMarkAllRead: {},
            onCopyURL: {},
            onDelete: {}
        )
    }
    .listStyle(.sidebar)
    .frame(width: 250)
}
