import SwiftUI
import SwiftData

/// Wrapper view that fetches the article for the Reading View window.
struct ReadingViewWindow: View {
    let articleId: UUID?

    @Query private var articles: [Article]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let articleId, let article = articles.first(where: { $0.id == articleId }) {
            ReadingView(article: article)
        } else {
            ContentUnavailableView(
                "Article Not Found",
                systemImage: "doc.questionmark",
                description: Text("The article could not be loaded.")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }
            }
        }
    }
}

/// Dedicated immersive reading view for distraction-free reading.
struct ReadingView: View {
    @Bindable var article: Article
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var isLoadingFullContent = false
    @State private var loadError: String?
    @State private var showFontSettings = false

    private let contentExtractor = ContentExtractor()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(article.title)
                    .font(settings.titleFont)
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
                    .padding(.vertical, 60)
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
                    .padding(.vertical, 60)
                } else {
                    Text(displayContent)
                        .font(settings.bodyFont)
                        .lineSpacing(settings.lineSpacing)
                        .textSelection(.enabled)
                }

                Divider()

                // Open in Browser link
                Link(destination: article.url) {
                    Label("Open in Browser", systemImage: "safari")
                }
                .padding(.top, 8)
            }
            .padding(48)
            .frame(maxWidth: 750, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ReadingViewToolbar(
                article: article,
                showFontSettings: $showFontSettings
            )
        }
        .popover(isPresented: $showFontSettings) {
            FontSettingsView()
                .frame(width: 350, height: 300)
        }
        .task {
            await loadContentIfNeeded()
        }
    }

    // MARK: - Private Properties

    private var displayContent: String {
        if let fullContent = article.fullContent {
            return fullContent
        } else if let content = article.content {
            return stripBasicHTML(from: content)
        } else {
            return "No content available."
        }
    }

    // MARK: - Private Methods

    private func loadContentIfNeeded() async {
        // Auto-load full content for reading view if not already loaded
        if article.fullContent == nil {
            await loadFullContent()
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

    /// Strips basic HTML tags from content for display.
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
    let article = Article(
        title: "Sample Article Title for Reading View",
        url: URL(string: "https://example.com/article")!,
        content: "<p>This is sample content for the reading view.</p><p>It should display in an immersive, distraction-free format with larger padding and customizable fonts.</p>",
        author: "Jane Doe",
        publishedDate: Date()
    )

    ReadingView(article: article)
        .environment(AppSettings())
        .modelContainer(for: [Article.self, Feed.self], inMemory: true)
        .frame(width: 800, height: 600)
}
