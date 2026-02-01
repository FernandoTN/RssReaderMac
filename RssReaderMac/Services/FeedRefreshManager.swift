import Foundation
import SwiftData
import Observation

/// Observable service for managing feed refresh operations.
/// Handles both manual refresh and background automatic refresh with configurable intervals.
@Observable
final class FeedRefreshManager {

    // MARK: - Properties

    /// The FeedParser instance used to fetch and parse feeds
    private let parser = FeedParser()

    /// Task for background refresh timer
    private var refreshTask: Task<Void, Never>?

    /// Indicates whether a refresh operation is currently in progress
    private(set) var isRefreshing = false

    /// Number of feeds currently being refreshed
    private(set) var refreshingCount = 0

    /// Total number of feeds to refresh in current operation
    private(set) var totalToRefresh = 0

    /// Last error that occurred during refresh, if any
    private(set) var lastError: Error?

    /// Timestamp of the last successful refresh
    private(set) var lastRefreshDate: Date?

    // MARK: - Initialization

    init() {}

    deinit {
        stopBackgroundRefresh()
    }

    // MARK: - Public Methods

    /// Refreshes all provided feeds concurrently
    /// - Parameters:
    ///   - feeds: Array of Feed objects to refresh
    ///   - modelContext: The SwiftData ModelContext for persisting updates
    @MainActor
    func refreshAll(feeds: [Feed], modelContext: ModelContext) async {
        guard !isRefreshing else { return }

        isRefreshing = true
        totalToRefresh = feeds.count
        refreshingCount = 0
        lastError = nil

        defer {
            isRefreshing = false
            refreshingCount = 0
            totalToRefresh = 0
            lastRefreshDate = Date()
        }

        await withTaskGroup(of: Void.self) { group in
            for feed in feeds {
                group.addTask { [weak self] in
                    await self?.refreshSingleFeed(feed: feed, modelContext: modelContext)
                }
            }
        }

        // Save context after all feeds are refreshed
        do {
            try modelContext.save()
        } catch {
            lastError = error
        }
    }

    /// Refreshes a single feed
    /// - Parameters:
    ///   - feed: The Feed object to refresh
    ///   - modelContext: The SwiftData ModelContext for persisting updates
    @MainActor
    func refresh(feed: Feed, modelContext: ModelContext) async {
        isRefreshing = true
        totalToRefresh = 1
        refreshingCount = 0
        lastError = nil

        defer {
            isRefreshing = false
            refreshingCount = 0
            totalToRefresh = 0
            lastRefreshDate = Date()
        }

        await refreshSingleFeed(feed: feed, modelContext: modelContext)

        do {
            try modelContext.save()
        } catch {
            lastError = error
        }
    }

    /// Starts automatic background refresh at the specified interval
    /// - Parameters:
    ///   - interval: Time interval between refreshes in seconds (default: 30 minutes)
    ///   - feeds: Closure that returns the current array of feeds to refresh
    ///   - modelContext: The SwiftData ModelContext for persisting updates
    func startBackgroundRefresh(
        interval: TimeInterval = 1800,
        feeds: @escaping @Sendable () -> [Feed],
        modelContext: ModelContext
    ) {
        stopBackgroundRefresh()

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(interval))

                    guard !Task.isCancelled else { break }

                    let feedsToRefresh = feeds()
                    await self?.refreshAll(feeds: feedsToRefresh, modelContext: modelContext)
                } catch {
                    // Task was cancelled or sleep was interrupted
                    break
                }
            }
        }
    }

    /// Stops the background refresh timer
    func stopBackgroundRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Returns whether background refresh is currently active
    var isBackgroundRefreshActive: Bool {
        refreshTask != nil && !refreshTask!.isCancelled
    }

    /// Returns the refresh progress as a value between 0 and 1
    var refreshProgress: Double {
        guard totalToRefresh > 0 else { return 0 }
        return Double(refreshingCount) / Double(totalToRefresh)
    }

    // MARK: - Private Methods

    @MainActor
    private func refreshSingleFeed(feed: Feed, modelContext: ModelContext) async {
        do {
            let parsed = try await parser.parse(url: feed.feedURL)

            // Update feed metadata
            feed.lastFetched = Date()

            // Update title if it was auto-generated from URL
            if feed.title.isEmpty || feed.title == feed.feedURL.host {
                feed.title = parsed.title
            }

            // Update site URL if not set
            if feed.siteURL == nil {
                feed.siteURL = parsed.siteURL
            }

            // Update icon URL if not set
            if feed.iconURL == nil {
                feed.iconURL = parsed.iconURL
            }

            // Get existing article URLs for deduplication
            let existingURLs = Set(feed.articles.map { $0.url })

            // Add new articles
            for parsedArticle in parsed.articles {
                if !existingURLs.contains(parsedArticle.url) {
                    // Use content if available, fall back to summary, or empty string
                    let articleContent = parsedArticle.content ?? parsedArticle.summary

                    let article = Article(
                        title: parsedArticle.title,
                        url: parsedArticle.url,
                        content: articleContent,
                        author: parsedArticle.author,
                        publishedDate: parsedArticle.publishedDate
                    )
                    article.feed = feed
                    feed.articles.append(article)
                    modelContext.insert(article)
                }
            }

            refreshingCount += 1

        } catch {
            // Log error but don't fail the entire refresh operation
            print("[FeedRefreshManager] Failed to refresh feed '\(feed.title)': \(error.localizedDescription)")
            lastError = error
            refreshingCount += 1
        }
    }
}

// MARK: - FeedRefreshManager Errors

extension FeedRefreshManager {
    enum RefreshError: LocalizedError {
        case noFeeds
        case partialFailure(successCount: Int, failureCount: Int)

        var errorDescription: String? {
            switch self {
            case .noFeeds:
                return "No feeds to refresh"
            case .partialFailure(let success, let failure):
                return "Refreshed \(success) feeds, \(failure) failed"
            }
        }
    }
}
