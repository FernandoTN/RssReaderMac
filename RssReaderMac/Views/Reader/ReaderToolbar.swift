import SwiftUI

/// Toolbar content for the reader view providing quick access to
/// reader mode toggle, star, read status, and sharing functionality.
struct ReaderToolbar: ToolbarContent {
    @Bindable var article: Article
    @Binding var readerMode: Bool
    var onToggleReaderMode: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup {
            // Reader mode toggle
            Button {
                onToggleReaderMode()
            } label: {
                Label(
                    readerMode ? "Show Summary" : "Reader Mode",
                    systemImage: readerMode ? "doc.richtext" : "doc.plaintext"
                )
            }
            .help(readerMode ? "Show original summary" : "Load full article content")

            // Star toggle
            Button {
                article.isStarred.toggle()
            } label: {
                Label(
                    article.isStarred ? "Unstar" : "Star",
                    systemImage: article.isStarred ? "star.fill" : "star"
                )
            }
            .help(article.isStarred ? "Remove from starred" : "Add to starred")

            // Read toggle
            Button {
                article.isRead.toggle()
            } label: {
                Label(
                    article.isRead ? "Mark as Unread" : "Mark as Read",
                    systemImage: article.isRead ? "circle.fill" : "circle"
                )
            }
            .help(article.isRead ? "Mark as unread" : "Mark as read")

            // Share link
            ShareLink(item: article.url) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .help("Share article link")
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var readerMode = false

        var body: some View {
            let article = Article(
                title: "Sample Article",
                url: URL(string: "https://example.com/article")!,
                isRead: false,
                isStarred: true
            )

            NavigationStack {
                Text("Preview Content")
                    .toolbar {
                        ReaderToolbar(
                            article: article,
                            readerMode: $readerMode,
                            onToggleReaderMode: {
                                readerMode.toggle()
                            }
                        )
                    }
            }
        }
    }

    return PreviewWrapper()
        .frame(width: 600, height: 400)
}
