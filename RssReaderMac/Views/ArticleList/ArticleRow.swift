import SwiftUI
import SwiftData

struct ArticleRow: View {
    @Bindable var article: Article
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                Text(article.title)
                    .font(.headline)
                    .fontWeight(article.isRead ? .regular : .bold)
                    .lineLimit(2)
                    .foregroundStyle(article.isRead ? .secondary : .primary)

                Spacer()

                if article.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }

            HStack(spacing: 4) {
                if let feedTitle = article.feed?.title {
                    Text(feedTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let author = article.author, !author.isEmpty {
                    if article.feed?.title != nil {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let publishedDate = article.publishedDate {
                    Text(publishedDate, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            if let preview = contentPreview {
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                article.isRead.toggle()
            } label: {
                Label(
                    article.isRead ? "Mark as Unread" : "Mark as Read",
                    systemImage: article.isRead ? "circle" : "checkmark.circle"
                )
            }

            Button {
                article.isStarred.toggle()
            } label: {
                Label(
                    article.isStarred ? "Remove Star" : "Add Star",
                    systemImage: article.isStarred ? "star.slash" : "star"
                )
            }

            Divider()

            Button {
                openURL(article.url)
            } label: {
                Label("Open in Browser", systemImage: "safari")
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(article.url.absoluteString, forType: .string)
            } label: {
                Label("Copy Link", systemImage: "link")
            }
        }
    }

    private var contentPreview: String? {
        guard let content = article.content ?? article.fullContent else {
            return nil
        }

        let strippedContent = content.strippingHTMLTags()
        guard !strippedContent.isEmpty else {
            return nil
        }

        return strippedContent
    }
}

private extension String {
    func strippingHTMLTags() -> String {
        guard let data = self.data(using: .utf8) else {
            return self
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "  ", with: " ")
        }

        // Fallback: simple regex-based stripping
        return self
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Article.self, Feed.self, configurations: config)

    let feed = Feed(title: "Sample Feed", feedURL: URL(string: "https://example.com/feed")!)
    let article = Article(
        title: "Sample Article Title That Might Be Long",
        url: URL(string: "https://example.com/article")!,
        content: "<p>This is some sample content with <strong>HTML</strong> tags that should be stripped out for the preview.</p>",
        author: "John Doe",
        publishedDate: Date().addingTimeInterval(-3600),
        isRead: false,
        isStarred: true,
        feed: feed
    )

    container.mainContext.insert(feed)
    container.mainContext.insert(article)

    return List {
        ArticleRow(article: article)
    }
    .modelContainer(container)
    .frame(width: 350)
}
