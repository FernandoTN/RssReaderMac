import SwiftUI
import AppKit

// MARK: - Keyboard Shortcuts View Modifier

/// A view modifier that adds keyboard shortcuts for article navigation and actions
struct KeyboardShortcutsModifier: ViewModifier {
    @Binding var selectedArticle: Article?
    let articles: [Article]
    @Environment(\.modelContext) private var modelContext

    func body(content: Content) -> some View {
        content
            .onKeyPress(.downArrow) {
                selectNextArticle()
                return .handled
            }
            .onKeyPress(.upArrow) {
                selectPreviousArticle()
                return .handled
            }
            .onKeyPress("j") {
                selectNextArticle()
                return .handled
            }
            .onKeyPress("k") {
                selectPreviousArticle()
                return .handled
            }
            .onKeyPress("r") {
                toggleRead()
                return .handled
            }
            .onKeyPress("s") {
                toggleStarred()
                return .handled
            }
            .onKeyPress(.return) {
                openInBrowser()
                return .handled
            }
    }

    // MARK: - Private Methods

    private func selectNextArticle() {
        guard !articles.isEmpty else { return }

        if let current = selectedArticle,
           let currentIndex = articles.firstIndex(where: { $0.id == current.id }) {
            let nextIndex = currentIndex + 1
            if nextIndex < articles.count {
                selectedArticle = articles[nextIndex]
            }
        } else {
            selectedArticle = articles.first
        }
    }

    private func selectPreviousArticle() {
        guard !articles.isEmpty else { return }

        if let current = selectedArticle,
           let currentIndex = articles.firstIndex(where: { $0.id == current.id }) {
            let previousIndex = currentIndex - 1
            if previousIndex >= 0 {
                selectedArticle = articles[previousIndex]
            }
        } else {
            selectedArticle = articles.last
        }
    }

    private func toggleRead() {
        guard let article = selectedArticle else { return }
        article.isRead.toggle()
        try? modelContext.save()
    }

    private func toggleStarred() {
        guard let article = selectedArticle else { return }
        article.isStarred.toggle()
        try? modelContext.save()
    }

    private func openInBrowser() {
        guard let article = selectedArticle else { return }
        NSWorkspace.shared.open(article.url)
    }
}

// MARK: - View Extension

extension View {
    /// Adds keyboard shortcuts for article navigation and actions
    /// - Parameters:
    ///   - selectedArticle: Binding to the currently selected article
    ///   - articles: Array of articles for navigation
    /// - Returns: A view with keyboard shortcuts applied
    func articleKeyboardShortcuts(
        selectedArticle: Binding<Article?>,
        articles: [Article]
    ) -> some View {
        self.modifier(
            KeyboardShortcutsModifier(
                selectedArticle: selectedArticle,
                articles: articles
            )
        )
    }
}
