import SwiftUI
import SwiftData

/// The main sidebar view showing smart folders and feeds
struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Feed.title) private var feeds: [Feed]
    @Query(sort: \SmartFolder.name) private var smartFolders: [SmartFolder]

    @Binding var selectedItem: SidebarItem?

    @State private var isShowingAddFeedSheet = false

    /// Groups feeds by folder for organized display
    private var feedsByFolder: [(folder: String?, feeds: [Feed])] {
        let grouped = Dictionary(grouping: feeds) { $0.folder }
        var result: [(folder: String?, feeds: [Feed])] = []

        // Add feeds without folder first
        if let unfoldered = grouped[nil] {
            result.append((folder: nil, feeds: unfoldered.sorted { $0.title < $1.title }))
        }

        // Add foldered feeds
        let folders = grouped.keys
            .compactMap { $0 }
            .sorted()

        for folder in folders {
            if let folderFeeds = grouped[folder] {
                result.append((folder: folder, feeds: folderFeeds.sorted { $0.title < $1.title }))
            }
        }

        return result
    }

    var body: some View {
        List(selection: $selectedItem) {
            smartFoldersSection
            feedsSection
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingAddFeedSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Feed")
            }
        }
        .sheet(isPresented: $isShowingAddFeedSheet) {
            AddFeedSheet()
        }
    }

    private var smartFoldersSection: some View {
        Section("Smart Folders") {
            SmartFolderRow(item: .all)
                .tag(SidebarItem.all)

            SmartFolderRow(item: .unread)
                .tag(SidebarItem.unread)

            SmartFolderRow(item: .starred)
                .tag(SidebarItem.starred)

            SmartFolderRow(item: .today)
                .tag(SidebarItem.today)

            ForEach(smartFolders) { folder in
                SmartFolderRow(item: .smartFolder(folder))
                    .tag(SidebarItem.smartFolder(folder))
            }
        }
    }

    private var feedsSection: some View {
        Section("Feeds") {
            ForEach(feedsByFolder, id: \.folder) { group in
                if let folder = group.folder {
                    DisclosureGroup(folder) {
                        feedRows(for: group.feeds)
                    }
                } else {
                    feedRows(for: group.feeds)
                }
            }
        }
    }

    @ViewBuilder
    private func feedRows(for feeds: [Feed]) -> some View {
        ForEach(feeds) { feed in
            FeedRow(
                feed: feed,
                onMarkAllRead: { markAllRead(feed: feed) },
                onCopyURL: { copyFeedURL(feed: feed) },
                onDelete: { deleteFeed(feed) }
            )
            .tag(SidebarItem.feed(feed))
        }
        .onDelete { indexSet in
            deleteFeeds(at: indexSet, from: feeds)
        }
    }

    private func markAllRead(feed: Feed) {
        for article in feed.articles {
            article.isRead = true
        }
        try? modelContext.save()
    }

    private func copyFeedURL(feed: Feed) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(feed.feedURL.absoluteString, forType: .string)
    }

    private func deleteFeed(_ feed: Feed) {
        if selectedItem == .feed(feed) {
            selectedItem = nil
        }
        modelContext.delete(feed)
        try? modelContext.save()
    }

    private func deleteFeeds(at indexSet: IndexSet, from feeds: [Feed]) {
        for index in indexSet {
            let feed = feeds[index]
            deleteFeed(feed)
        }
    }
}

#Preview {
    @Previewable @State var selectedItem: SidebarItem? = .all

    SidebarView(selectedItem: $selectedItem)
        .modelContainer(for: [Feed.self, Article.self, SmartFolder.self], inMemory: true)
}
