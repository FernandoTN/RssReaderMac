import Foundation
import FeedKit

// MARK: - Parsed Data Structures

/// Represents a parsed feed with metadata and articles
struct ParsedFeed: Sendable {
    let title: String
    let description: String?
    let siteURL: URL?
    let iconURL: URL?
    let articles: [ParsedArticle]
}

/// Represents a parsed article from a feed
struct ParsedArticle: Sendable {
    let id: String
    let title: String
    let url: URL
    let content: String?
    let summary: String?
    let author: String?
    let publishedDate: Date?
    let imageURL: URL?
}

// MARK: - Feed Parser Errors

enum FeedParserError: LocalizedError {
    case invalidData
    case parsingFailed(String)
    case unsupportedFormat
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "The feed data is invalid or corrupted."
        case .parsingFailed(let message):
            return "Failed to parse feed: \(message)"
        case .unsupportedFormat:
            return "The feed format is not supported."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Feed Parser Actor

/// Actor-based async feed parser supporting RSS, Atom, and JSON feeds
actor FeedParser {

    // MARK: - Public Methods

    /// Parse feed data from raw Data
    /// - Parameter data: The raw feed data
    /// - Returns: A ParsedFeed containing feed metadata and articles
    func parse(data: Data) async throws -> ParsedFeed {
        let parser = FeedKit.FeedParser(data: data)

        return try await withCheckedThrowingContinuation { continuation in
            parser.parseAsync { result in
                switch result {
                case .success(let feed):
                    do {
                        let parsedFeed = try self.convertFeed(feed)
                        continuation.resume(returning: parsedFeed)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: FeedParserError.parsingFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Parse feed from a URL
    /// - Parameter url: The URL of the feed
    /// - Returns: A ParsedFeed containing feed metadata and articles
    func parse(url: URL) async throws -> ParsedFeed {
        let parser = FeedKit.FeedParser(URL: url)

        return try await withCheckedThrowingContinuation { continuation in
            parser.parseAsync { result in
                switch result {
                case .success(let feed):
                    do {
                        let parsedFeed = try self.convertFeed(feed)
                        continuation.resume(returning: parsedFeed)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: FeedParserError.parsingFailed(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func convertFeed(_ feed: FeedKit.Feed) throws -> ParsedFeed {
        switch feed {
        case .rss(let rssFeed):
            return convertRSSFeed(rssFeed)
        case .atom(let atomFeed):
            return convertAtomFeed(atomFeed)
        case .json(let jsonFeed):
            return convertJSONFeed(jsonFeed)
        }
    }

    // MARK: - RSS Feed Conversion

    private func convertRSSFeed(_ feed: RSSFeed) -> ParsedFeed {
        let articles = (feed.items ?? []).compactMap { item -> ParsedArticle? in
            guard let title = item.title ?? item.description?.prefix(100).description,
                  let urlString = item.link,
                  let url = URL(string: urlString) else {
                return nil
            }

            let id = item.guid?.value ?? urlString
            let content = item.content?.contentEncoded ?? item.description
            let summary = item.description
            let author = item.author ?? item.dublinCore?.dcCreator
            let publishedDate = item.pubDate
            let imageURL = extractImageURL(from: item)

            return ParsedArticle(
                id: id,
                title: title,
                url: url,
                content: content,
                summary: summary,
                author: author,
                publishedDate: publishedDate,
                imageURL: imageURL
            )
        }

        let siteURL: URL?
        if let link = feed.link {
            siteURL = URL(string: link)
        } else {
            siteURL = nil
        }

        let iconURL: URL?
        if let imageURLString = feed.image?.url {
            iconURL = URL(string: imageURLString)
        } else {
            iconURL = nil
        }

        return ParsedFeed(
            title: feed.title ?? "Untitled Feed",
            description: feed.description,
            siteURL: siteURL,
            iconURL: iconURL,
            articles: articles
        )
    }

    private func extractImageURL(from item: RSSFeedItem) -> URL? {
        // Try media content first
        if let mediaContent = item.media?.mediaContents?.first,
           let urlString = mediaContent.attributes?.url,
           let url = URL(string: urlString) {
            return url
        }

        // Try media thumbnail
        if let thumbnail = item.media?.mediaThumbnails?.first,
           let urlString = thumbnail.attributes?.url,
           let url = URL(string: urlString) {
            return url
        }

        // Try enclosure
        if let enclosure = item.enclosure,
           let type = enclosure.attributes?.type,
           type.hasPrefix("image/"),
           let urlString = enclosure.attributes?.url,
           let url = URL(string: urlString) {
            return url
        }

        return nil
    }

    // MARK: - Atom Feed Conversion

    private func convertAtomFeed(_ feed: AtomFeed) -> ParsedFeed {
        let articles = (feed.entries ?? []).compactMap { entry -> ParsedArticle? in
            guard let title = entry.title ?? entry.summary?.value?.prefix(100).description else {
                return nil
            }

            // Find the best link (prefer alternate, then any link)
            let link = entry.links?.first(where: { $0.attributes?.rel == "alternate" })
                ?? entry.links?.first

            guard let urlString = link?.attributes?.href,
                  let url = URL(string: urlString) else {
                return nil
            }

            let id = entry.id ?? urlString
            let content = entry.content?.value
            let summary = entry.summary?.value
            let author = entry.authors?.first?.name
            let publishedDate = entry.published ?? entry.updated
            let imageURL = extractImageURL(from: entry)

            return ParsedArticle(
                id: id,
                title: title,
                url: url,
                content: content,
                summary: summary,
                author: author,
                publishedDate: publishedDate,
                imageURL: imageURL
            )
        }

        let siteURL: URL?
        let siteLink = feed.links?.first(where: { $0.attributes?.rel == "alternate" })
            ?? feed.links?.first(where: { $0.attributes?.type == "text/html" })
            ?? feed.links?.first
        if let urlString = siteLink?.attributes?.href {
            siteURL = URL(string: urlString)
        } else {
            siteURL = nil
        }

        let iconURL: URL?
        if let iconString = feed.icon {
            iconURL = URL(string: iconString)
        } else if let logoString = feed.logo {
            iconURL = URL(string: logoString)
        } else {
            iconURL = nil
        }

        return ParsedFeed(
            title: feed.title ?? "Untitled Feed",
            description: feed.subtitle?.value,
            siteURL: siteURL,
            iconURL: iconURL,
            articles: articles
        )
    }

    private func extractImageURL(from entry: AtomFeedEntry) -> URL? {
        // Try media content
        if let mediaContent = entry.media?.mediaContents?.first,
           let urlString = mediaContent.attributes?.url,
           let url = URL(string: urlString) {
            return url
        }

        // Try media thumbnail
        if let thumbnail = entry.media?.mediaThumbnails?.first,
           let urlString = thumbnail.attributes?.url,
           let url = URL(string: urlString) {
            return url
        }

        // Try links with image type
        if let imageLink = entry.links?.first(where: {
            $0.attributes?.type?.hasPrefix("image/") ?? false
        }),
           let urlString = imageLink.attributes?.href,
           let url = URL(string: urlString) {
            return url
        }

        return nil
    }

    // MARK: - JSON Feed Conversion

    private func convertJSONFeed(_ feed: JSONFeed) -> ParsedFeed {
        let articles = (feed.items ?? []).compactMap { item -> ParsedArticle? in
            guard let title = item.title ?? item.summary?.prefix(100).description,
                  let urlString = item.url ?? item.externalUrl,
                  let url = URL(string: urlString) else {
                return nil
            }

            let id = item.id ?? urlString
            let content = item.contentHtml ?? item.contentText
            let summary = item.summary
            let author = item.author?.name ?? feed.author?.name
            let publishedDate = item.datePublished

            let imageURL: URL?
            if let imageString = item.image ?? item.bannerImage {
                imageURL = URL(string: imageString)
            } else {
                imageURL = nil
            }

            return ParsedArticle(
                id: id,
                title: title,
                url: url,
                content: content,
                summary: summary,
                author: author,
                publishedDate: publishedDate,
                imageURL: imageURL
            )
        }

        let siteURL: URL?
        if let homeURLString = feed.homePageURL {
            siteURL = URL(string: homeURLString)
        } else {
            siteURL = nil
        }

        let iconURL: URL?
        if let iconString = feed.icon ?? feed.favicon {
            iconURL = URL(string: iconString)
        } else {
            iconURL = nil
        }

        return ParsedFeed(
            title: feed.title ?? "Untitled Feed",
            description: feed.description,
            siteURL: siteURL,
            iconURL: iconURL,
            articles: articles
        )
    }
}
