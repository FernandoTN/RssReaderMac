import SwiftUI

/// Minimal toolbar for the Reading View window.
struct ReadingViewToolbar: ToolbarContent {
    @Bindable var article: Article
    @Binding var showFontSettings: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some ToolbarContent {
        ToolbarItemGroup {
            // Close button
            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark")
            }
            .keyboardShortcut(.escape, modifiers: [])
            .help("Close reading view")

            Spacer()

            // Font settings
            Button {
                showFontSettings.toggle()
            } label: {
                Label("Text Settings", systemImage: "textformat.size")
            }
            .help("Customize text appearance")

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
        @State private var showFontSettings = false

        var body: some View {
            let article = Article(
                title: "Sample Article",
                url: URL(string: "https://example.com/article")!,
                isStarred: true
            )

            NavigationStack {
                Text("Reading View Preview")
                    .toolbar {
                        ReadingViewToolbar(
                            article: article,
                            showFontSettings: $showFontSettings
                        )
                    }
            }
        }
    }

    return PreviewWrapper()
        .frame(width: 600, height: 400)
}
