import SwiftUI
import AppKit

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the user requests to refresh all feeds
    static let refreshFeeds = Notification.Name("refreshFeeds")

    /// Posted when the user requests to import feeds from OPML
    static let importOPML = Notification.Name("importOPML")

    /// Posted when the user requests to export feeds to OPML
    static let exportOPML = Notification.Name("exportOPML")
}

// MARK: - App Commands

/// Menu commands for the RSS Reader app
struct AppCommands: Commands {
    var body: some Commands {
        // File menu additions
        CommandGroup(after: .newItem) {
            Button("Import Feeds...") {
                showImportPanel()
            }
            .keyboardShortcut("i", modifiers: .command)

            Button("Export Feeds...") {
                showExportPanel()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Divider()
        }

        // View menu additions
        CommandGroup(after: .toolbar) {
            Button("Refresh All Feeds") {
                NotificationCenter.default.post(name: .refreshFeeds, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)

            Divider()
        }
    }

    // MARK: - Private Methods

    private func showImportPanel() {
        let panel = NSOpenPanel()
        panel.title = "Import OPML"
        panel.message = "Select an OPML file to import feeds from"
        panel.allowedContentTypes = [.init(filenameExtension: "opml")!, .xml]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            NotificationCenter.default.post(
                name: .importOPML,
                object: nil,
                userInfo: ["url": url]
            )
        }
    }

    private func showExportPanel() {
        let panel = NSSavePanel()
        panel.title = "Export OPML"
        panel.message = "Choose where to save your feeds"
        panel.allowedContentTypes = [.init(filenameExtension: "opml")!]
        panel.nameFieldStringValue = "feeds.opml"
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            NotificationCenter.default.post(
                name: .exportOPML,
                object: nil,
                userInfo: ["url": url]
            )
        }
    }
}
