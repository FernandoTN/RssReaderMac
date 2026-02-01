import Foundation
import SwiftData

@Model
final class Feed {
    var id: UUID
    var title: String
    var feedURL: URL
    var siteURL: URL?
    var iconURL: URL?
    var lastFetched: Date?
    var folder: String?

    @Relationship(deleteRule: .cascade, inverse: \Article.feed)
    var articles: [Article] = []

    init(title: String, feedURL: URL, siteURL: URL? = nil, folder: String? = nil) {
        self.id = UUID()
        self.title = title
        self.feedURL = feedURL
        self.siteURL = siteURL
        self.folder = folder
    }
}
