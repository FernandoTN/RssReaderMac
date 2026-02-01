import SwiftUI
import SwiftData

/// The main content view with a three-column layout for the RSS reader
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Feed.title) private var feeds: [Feed]
    @Query(sort: \Article.publishedDate, order: .reverse) private var allArticles: [Article]

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedSidebarItem: SidebarItem? = .all
    @State private var selectedArticle: Article?
    @State private var refreshManager = FeedRefreshManager()

    /// Articles filtered based on the current sidebar selection
    private var filteredArticles: [Article] {
        guard let item = selectedSidebarItem else {
            return allArticles
        }

        switch item {
        case .all:
            return allArticles

        case .unread:
            return allArticles.filter { !$0.isRead }

        case .starred:
            return allArticles.filter { $0.isStarred }

        case .today:
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            return allArticles.filter { article in
                guard let publishedDate = article.publishedDate else { return false }
                return publishedDate >= startOfToday
            }

        case .smartFolder(let smartFolder):
            return allArticles.filter { article in
                smartFolder.rules.allSatisfy { rule in
                    rule.matches(article: article)
                }
            }

        case .feed(let feed):
            return allArticles.filter { $0.feed?.id == feed.id }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedItem: $selectedSidebarItem)
        } content: {
            ArticleListView(
                sidebarItem: selectedSidebarItem,
                selectedArticle: $selectedArticle
            )
            .toolbar {
                ArticleListToolbar(
                    onRefresh: {
                        Task {
                            await refreshManager.refreshAll(
                                feeds: feeds,
                                modelContext: modelContext
                            )
                        }
                    },
                    onMarkAllRead: {
                        markAllArticlesAsRead()
                    }
                )
            }
        } detail: {
            if let article = selectedArticle {
                ReaderView(article: article)
            } else {
                EmptyReaderView()
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .articleKeyboardShortcuts(
            selectedArticle: $selectedArticle,
            articles: filteredArticles
        )
        .onAppear {
            startBackgroundRefresh()
        }
        .onDisappear {
            refreshManager.stopBackgroundRefresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshFeeds)) { _ in
            Task {
                await refreshManager.refreshAll(
                    feeds: feeds,
                    modelContext: modelContext
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .importOPML)) { notification in
            if let url = notification.userInfo?["url"] as? URL {
                importFeeds(from: url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportOPML)) { notification in
            if let url = notification.userInfo?["url"] as? URL {
                exportFeeds(to: url)
            }
        }
    }

    // MARK: - Private Methods

    private func startBackgroundRefresh() {
        // Capture feeds in a closure that can be called later
        refreshManager.startBackgroundRefresh(
            interval: 1800, // 30 minutes
            feeds: { [feeds] in feeds },
            modelContext: modelContext
        )
    }

    private func markAllArticlesAsRead() {
        for article in filteredArticles {
            article.isRead = true
        }
        try? modelContext.save()
    }

    private func importFeeds(from url: URL) {
        let parser = OPMLParser()
        do {
            let document = try parser.parse(url: url)
            for opmlFeed in document.feeds {
                // Check if feed already exists
                let existingFeeds = feeds.filter { $0.feedURL == opmlFeed.feedURL }
                guard existingFeeds.isEmpty else { continue }

                let feed = Feed(
                    title: opmlFeed.title,
                    feedURL: opmlFeed.feedURL,
                    siteURL: opmlFeed.siteURL,
                    folder: opmlFeed.folder
                )
                modelContext.insert(feed)
            }
            try? modelContext.save()

            // Refresh newly imported feeds
            Task {
                await refreshManager.refreshAll(
                    feeds: feeds,
                    modelContext: modelContext
                )
            }
        } catch {
            print("Failed to import OPML: \(error.localizedDescription)")
        }
    }

    private func exportFeeds(to url: URL) {
        let parser = OPMLParser()
        let opmlFeeds = feeds.map { feed in
            OPMLFeed(
                title: feed.title,
                feedURL: feed.feedURL,
                siteURL: feed.siteURL,
                folder: feed.folder
            )
        }

        do {
            try parser.export(feeds: opmlFeeds, to: url, title: "RSS Reader Feeds")
        } catch {
            print("Failed to export OPML: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainerSetup.createPreviewContainer())
}
