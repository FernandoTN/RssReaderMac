# RssReaderMac Design

An open-source RSS reader for macOS focused on clean, focused reading.

## Overview

- **Tech Stack**: SwiftUI, SwiftData, CloudKit
- **Target**: macOS 13+
- **License**: MIT
- **Design**: Native Mac look following Apple HIG

## Core Features

1. **Reader Mode** - Clean article view stripping ads/clutter
2. **Smart Folders** - Auto-organize articles by filter rules
3. **iCloud Sync** - Sync feeds and read state across devices
4. **OPML Import/Export** - Standard feed backup/sharing

## Architecture

```
RssReaderMac/
├── RssReaderMac/
│   ├── App/
│   │   └── RssReaderMacApp.swift
│   ├── Models/
│   │   ├── Feed.swift
│   │   ├── Article.swift
│   │   └── SmartFolder.swift
│   ├── Views/
│   │   ├── Sidebar/
│   │   ├── ArticleList/
│   │   └── Reader/
│   ├── Services/
│   │   ├── FeedParser.swift
│   │   ├── ContentExtractor.swift
│   │   └── CloudKitSync.swift
│   └── Resources/
│       └── SampleFeeds.opml
└── RssReaderMacTests/
```

## Data Models

### Feed
```swift
@Model class Feed {
    var title: String
    var url: URL
    var iconURL: URL?
    var lastFetched: Date?
    var articles: [Article]
    var folder: String?
}
```

### Article
```swift
@Model class Article {
    var title: String
    var url: URL
    var content: String
    var fullContent: String?
    var author: String?
    var publishedDate: Date?
    var isRead: Bool
    var isStarred: Bool
    var feed: Feed
}
```

### SmartFolder
```swift
@Model class SmartFolder {
    var name: String
    var icon: String
    var rules: [FilterRule]
}

struct FilterRule: Codable {
    enum Field { case title, author, feedName, content }
    enum Operator { case contains, notContains, matches }
    var field: Field
    var op: Operator
    var value: String
}
```

## UI Layout

Three-column NavigationSplitView:
1. **Sidebar**: Smart folders, feed groups, add/manage feeds
2. **Article List**: Title, date, preview snippet
3. **Reader**: Article content with reader mode toggle

## Key Behaviors

### Content Fetching
- Default: Use RSS content as-is
- Optional: Fetch full page, extract clean text
- Store extracted content for offline reading

### Feed Refresh
- Background refresh every 30 min (configurable)
- Manual refresh via toolbar or ⌘R
- Use ETags for efficient fetching

### iCloud Sync
- SwiftData + CloudKit automatic sync
- Syncs: feeds, read/starred state, smart folder configs
- Article content fetched fresh per device

### Keyboard Shortcuts
- j/k: Next/previous article
- r: Toggle read
- s: Toggle starred
- ⌘R: Refresh feeds
- ⌘I: Import OPML

## First Launch

1. Welcome screen
2. Choose: Import OPML / Start with popular blogs / Start empty
3. Main window opens

## Sample Feeds

Bundle popular HN blogs OPML (~80 feeds) as optional starter pack.
