import SwiftUI
import SwiftData

/// A sheet view for adding a new RSS feed
struct AddFeedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var feedURLString: String = ""
    @State private var folder: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private let feedParser = FeedParser()

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            formContent

            Divider()

            footerView
        }
        .frame(width: 400)
        .fixedSize(horizontal: true, vertical: true)
    }

    private var headerView: some View {
        Text("Add Feed")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
    }

    private var formContent: some View {
        Form {
            TextField("Feed URL", text: $feedURLString, prompt: Text("https://example.com/feed.xml"))
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)

            TextField("Folder (optional)", text: $folder, prompt: Text("e.g., Technology"))
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var footerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.trailing, 8)
            }

            Button("Add") {
                Task {
                    await addFeed()
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(feedURLString.isEmpty || isLoading)
        }
        .padding()
    }

    @MainActor
    private func addFeed() async {
        errorMessage = nil
        isLoading = true

        defer {
            isLoading = false
        }

        // Normalize the URL
        var urlString = feedURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }

        guard let feedURL = URL(string: urlString) else {
            errorMessage = "Please enter a valid URL."
            return
        }

        do {
            let parsedFeed = try await feedParser.parse(url: feedURL)

            // Create the feed model
            let feed = Feed(
                title: parsedFeed.title,
                feedURL: feedURL,
                siteURL: parsedFeed.siteURL,
                folder: folder.isEmpty ? nil : folder
            )
            feed.iconURL = parsedFeed.iconURL
            feed.lastFetched = Date()

            // Create article models
            for parsedArticle in parsedFeed.articles {
                let article = Article(
                    title: parsedArticle.title,
                    url: parsedArticle.url,
                    content: parsedArticle.content ?? parsedArticle.summary,
                    author: parsedArticle.author,
                    publishedDate: parsedArticle.publishedDate,
                    feed: feed
                )
                feed.articles.append(article)
            }

            modelContext.insert(feed)
            try modelContext.save()

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AddFeedSheet()
        .modelContainer(for: [Feed.self, Article.self], inMemory: true)
}
