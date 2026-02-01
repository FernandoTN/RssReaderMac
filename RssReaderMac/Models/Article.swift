import Foundation
import SwiftData

@Model
final class Article {
    var id: UUID
    var title: String
    var url: URL
    var content: String?
    var fullContent: String?
    var author: String?
    var publishedDate: Date?
    var isRead: Bool
    var isStarred: Bool

    var feed: Feed?

    init(
        title: String,
        url: URL,
        content: String? = nil,
        fullContent: String? = nil,
        author: String? = nil,
        publishedDate: Date? = nil,
        isRead: Bool = false,
        isStarred: Bool = false,
        feed: Feed? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.content = content
        self.fullContent = fullContent
        self.author = author
        self.publishedDate = publishedDate
        self.isRead = isRead
        self.isStarred = isStarred
        self.feed = feed
    }
}
