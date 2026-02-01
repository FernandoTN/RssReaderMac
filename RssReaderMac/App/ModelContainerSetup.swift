import Foundation
import SwiftData

enum ModelContainerSetup {
    static let schema = Schema([
        Feed.self,
        Article.self,
        SmartFolder.self
    ])

    static func createContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration

        if inMemory {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.rssreader.mac")
            )
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    static func createPreviewContainer() -> ModelContainer {
        do {
            let container = try createContainer(inMemory: true)
            let context = container.mainContext

            // Add sample data for previews
            let sampleFeed = Feed(
                title: "Sample Tech Blog",
                feedURL: URL(string: "https://example.com/feed.xml")!,
                siteURL: URL(string: "https://example.com")!,
                folder: "Technology"
            )

            context.insert(sampleFeed)

            let sampleArticle = Article(
                title: "Getting Started with SwiftUI",
                url: URL(string: "https://example.com/swiftui-intro")!,
                content: "SwiftUI is Apple's modern declarative UI framework...",
                author: "Jane Developer",
                publishedDate: Date(),
                feed: sampleFeed
            )

            context.insert(sampleArticle)

            let smartFolder = SmartFolder(
                name: "Unread Tech",
                rules: [
                    FilterRule(field: .feedTitle, operator: .contains, value: "Tech")
                ]
            )

            context.insert(smartFolder)

            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
