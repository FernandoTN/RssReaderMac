import SwiftUI
import SwiftData

struct ArticleListView: View {
    let sidebarItem: SidebarItem?
    @Binding var selectedArticle: Article?

    @Query(sort: \Article.publishedDate, order: .reverse) private var allArticles: [Article]

    private var filteredArticles: [Article] {
        guard let item = sidebarItem else {
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
        List(filteredArticles, id: \.id, selection: $selectedArticle) { article in
            ArticleRow(article: article)
                .tag(article)
        }
        .frame(minWidth: 300)
        .listStyle(.inset)
        .overlay {
            if filteredArticles.isEmpty {
                ContentUnavailableView {
                    Label("No Articles", systemImage: "doc.text")
                } description: {
                    Text(emptyStateMessage)
                }
            }
        }
    }

    private var emptyStateMessage: String {
        guard let item = sidebarItem else {
            return "Select a feed or folder to view articles."
        }

        switch item {
        case .all:
            return "No articles yet. Add a feed to get started."
        case .unread:
            return "No unread articles."
        case .starred:
            return "No starred articles."
        case .today:
            return "No articles from today."
        case .smartFolder:
            return "No articles match the folder rules."
        case .feed:
            return "No articles in this feed."
        }
    }
}

#Preview {
    ArticleListView(sidebarItem: .all, selectedArticle: .constant(nil))
        .modelContainer(for: [Article.self, Feed.self, SmartFolder.self], inMemory: true)
}
