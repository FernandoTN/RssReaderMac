import SwiftUI
import SwiftData

/// Main reader view for displaying article content.
/// Supports both summary view and full reader mode with extracted content.
struct ReaderView: View {
    @Bindable var article: Article

    @State private var readerMode = false
    @State private var isLoadingFullContent = false
    @State private var loadError: String?

    private let contentExtractor = ContentExtractor()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(article.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .textSelection(.enabled)

                // Metadata
                HStack(spacing: 8) {
                    if let feedTitle = article.feed?.title {
                        Text(feedTitle)
                            .foregroundStyle(.secondary)
                    }

                    if article.author != nil || article.publishedDate != nil {
                        Text("·")
                            .foregroundStyle(.tertiary)
                    }

                    if let author = article.author {
                        Text(author)
                            .foregroundStyle(.secondary)
                    }

                    if let date = article.publishedDate {
                        Text(date, style: .date)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .font(.subheadline)

                Divider()

                // Content
                if isLoadingFullContent {
                    HStack {
                        Spacer()
                        ProgressView("Loading full content...")
                        Spacer()
                    }
                    .padding(.vertical, 40)
                } else if let error = loadError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(error)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Task {
                                await loadFullContent()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    Text(displayContent)
                        .textSelection(.enabled)
                        .lineSpacing(4)
                }

                Divider()

                // Open in Browser link
                Link(destination: article.url) {
                    Label("Open in Browser", systemImage: "safari")
                }
                .padding(.top, 8)
            }
            .padding(32)
            .frame(maxWidth: 700, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            article.isRead = true
        }
        .toolbar {
            ReaderToolbar(
                article: article,
                readerMode: $readerMode,
                onToggleReaderMode: {
                    Task {
                        await handleReaderModeToggle()
                    }
                }
            )
        }
    }

    // MARK: - Private Properties

    private var displayContent: String {
        if readerMode, let fullContent = article.fullContent {
            return fullContent
        } else if let content = article.content {
            return stripBasicHTML(from: content)
        } else {
            return "No content available."
        }
    }

    // MARK: - Private Methods

    private func handleReaderModeToggle() async {
        if !readerMode {
            // Turning on reader mode
            if article.fullContent == nil {
                await loadFullContent()
            }
            readerMode = true
        } else {
            // Turning off reader mode
            readerMode = false
        }
    }

    private func loadFullContent() async {
        isLoadingFullContent = true
        loadError = nil

        do {
            let content = try await contentExtractor.extract(from: article.url)
            await MainActor.run {
                article.fullContent = content
                isLoadingFullContent = false
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                isLoadingFullContent = false
            }
        }
    }

    /// Strips basic HTML tags from content for display in non-reader mode.
    private func stripBasicHTML(from html: String) -> String {
        var result = html

        // Replace common block elements with newlines
        let blockTags = ["</p>", "</div>", "</br>", "<br>", "<br/>", "<br />", "</h1>", "</h2>", "</h3>", "</h4>", "</h5>", "</h6>", "</li>"]
        for tag in blockTags {
            result = result.replacingOccurrences(of: tag, with: "\n", options: .caseInsensitive)
        }

        // Remove all remaining HTML tags
        let tagPattern = "<[^>]+>"
        if let regex = try? NSRegularExpression(pattern: tagPattern, options: .caseInsensitive) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }

        // Decode common HTML entities
        let entities: [(String, String)] = [
            ("&nbsp;", " "),
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&mdash;", "—"),
            ("&ndash;", "–"),
            ("&hellip;", "..."),
            ("&copy;", "©"),
            ("&reg;", "®"),
            ("&trade;", "™")
        ]

        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement, options: .caseInsensitive)
        }

        // Clean up whitespace
        result = result
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }
}

#Preview {
    @Previewable @State var article = Article(
        title: "Sample Article Title That Might Be Quite Long",
        url: URL(string: "https://example.com/article")!,
        content: "<p>This is some <strong>sample</strong> content with HTML tags.</p><p>It has multiple paragraphs and formatting.</p>",
        author: "John Doe",
        publishedDate: Date()
    )

    ReaderView(article: article)
        .modelContainer(for: [Article.self, Feed.self], inMemory: true)
        .frame(width: 800, height: 600)
}
