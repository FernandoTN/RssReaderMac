# RssReaderMac Implementation Plan

> **For Claude:** This is the SOURCE OF TRUTH for implementation. If you lose context, return here and check the STATUS section to see where you left off. Use parallel agents for independent tasks.

**Goal:** Build a complete, functional RSS reader for macOS with SwiftUI, SwiftData, and iCloud sync.

**Architecture:** Three-column NavigationSplitView with SwiftData models synced via CloudKit. Feed parsing via FeedKit, content extraction via SwiftSoup.

**Tech Stack:** Swift 5.9, SwiftUI, SwiftData, CloudKit, FeedKit (SPM), SwiftSoup (SPM)

---

## STATUS TRACKER

> **UPDATE THIS SECTION** after each phase completes. Mark tasks with:
> - ⬜ Not started
> - 🔄 In progress
> - ✅ Completed
> - ❌ Blocked

### Phase 1: Project Setup
| Task | Status | Agent | Notes |
|------|--------|-------|-------|
| 1.1 Create Xcode project structure | ✅ | a0f9852 | macOS 14.0 target (required for @Observable) |
| 1.2 Add SPM dependencies | ✅ | a0f9852 | FeedKit 9.1.2, SwiftSoup 2.6.0 |
| 1.3 Create folder structure | ✅ | a0f9852 | All directories created |
| 1.4 Add sample OPML | ⬜ | - | Pending |

### Phase 2: Data Models
| Task | Status | Agent | Notes |
|------|--------|-------|-------|
| 2.1 Feed model | ✅ | aaa6704 | With cascade delete |
| 2.2 Article model | ✅ | aaa6704 | With isRead, isStarred |
| 2.3 SmartFolder model | ✅ | aaa6704 | With FilterRule struct |
| 2.4 Model container setup | ✅ | aaa6704 | CloudKit configured |

### Phase 3: Services
| Task | Status | Agent | Notes |
|------|--------|-------|-------|
| 3.1 FeedParser service | ✅ | aeb4eaa | RSS, Atom, JSON support |
| 3.2 OPMLParser service | ✅ | aeb4eaa | Import/export with folders |
| 3.3 ContentExtractor service | ✅ | ade83d7 | SwiftSoup with markdown output |
| 3.4 FeedRefreshManager | ✅ | ade83d7 | Background refresh with progress |

### Phase 4: Views - Sidebar
| Task | Status | Agent | Notes |
|------|--------|-------|-------|
| 4.1 SidebarView | ✅ | ab2f764 | With folders, context menus |
| 4.2 SmartFolderRow | ✅ | ab2f764 | Label with SF Symbol |
| 4.3 FeedRow | ✅ | ab2f764 | AsyncImage, unread badge |
| 4.4 AddFeedSheet | ✅ | ab2f764 | With FeedParser validation |

### Phase 5: Views - Article List
| Task | Status | Agent | Notes |
|------|--------|-------|-------|
| 5.1 ArticleListView | ✅ | aa2463c | Filtering by SidebarItem |
| 5.2 ArticleRow | ✅ | aa2463c | HTML stripping, context menu |
| 5.3 ArticleListToolbar | ✅ | aa2463c | Refresh, Mark All Read |

### Phase 6: Views - Reader
| Task | Status | Agent | Notes |
|------|--------|-------|-------|
| 6.1 ReaderView | ✅ | a145c6f | Reader mode, ContentExtractor |
| 6.2 ReaderToolbar | ✅ | a145c6f | Star, read, share |
| 6.3 EmptyReaderView | ✅ | a145c6f | Placeholder view |

### Phase 7: Main App Shell
| Task | Status | Agent | Notes |
|------|--------|-------|-------|
| 7.1 ContentView (3-column) | ✅ | add748e | NavigationSplitView, notifications |
| 7.2 App entry point | ✅ | add748e | With onboarding toggle |
| 7.3 Menu commands | ✅ | add748e | Import/Export/Refresh |
| 7.4 Keyboard shortcuts | ✅ | add748e | j/k/r/s/Return |

### Phase 8: First Launch & Polish
| Task | Status | Agent | Notes |
|------|--------|-------|-------|
| 8.1 WelcomeView | ✅ | a2c54d0 | Three options, OPML import |
| 8.2 SampleFeeds.opml | ✅ | a2c54d0 | 10 popular tech blogs |
| 8.3 App icon | ⬜ | - | Using SF Symbol for now |

### Phase 9: Testing
| Task | Status | Agent | Notes |
|------|--------|-------|-------|
| 9.1 Model tests | ✅ | ac62360 | 41 tests passing |
| 9.2 Service tests | ✅ | ac62360 | 34 tests passing |
| 9.3 Integration tests | ⬜ | - | Skipped for v1 |

### Phase 10: Review & Commit
| Task | Status | Agent | Notes |
|------|--------|-------|-------|
| 10.1 Code review | ✅ | a1e0272 | Fixed 13 missing files in project |
| 10.2 Final commit | ✅ | orchestrator | bc883c2 pushed to main |

---

## PHASE 1: PROJECT SETUP

### Task 1.1: Create Xcode Project Structure

**Goal:** Create the base Xcode project with correct settings.

**Files to create:**
```
RssReaderMac/
├── RssReaderMac.xcodeproj/
│   └── project.pbxproj
├── RssReaderMac/
│   ├── RssReaderMacApp.swift
│   ├── ContentView.swift
│   ├── Info.plist
│   └── RssReaderMac.entitlements
└── RssReaderMacTests/
    └── RssReaderMacTests.swift
```

**Commands:**
```bash
cd /Users/fernandotn/Projects/RssReaderMac
# Create Xcode project via xcodegen or manually structured files
```

**Project settings:**
- Bundle ID: `com.fernandotn.RssReaderMac`
- Deployment target: macOS 13.0
- Swift version: 5.9
- Capabilities: iCloud (CloudKit), App Sandbox

---

### Task 1.2: Add SPM Dependencies

**Goal:** Add FeedKit and SwiftSoup via Swift Package Manager.

**File:** `RssReaderMac/Package.swift` (or via Xcode project)

**Dependencies:**
```swift
dependencies: [
    .package(url: "https://github.com/nmdias/FeedKit.git", from: "9.1.2"),
    .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
]
```

---

### Task 1.3: Create Folder Structure

**Goal:** Create all directories for organized code.

**Directories to create:**
```
RssReaderMac/RssReaderMac/
├── App/
├── Models/
├── Views/
│   ├── Sidebar/
│   ├── ArticleList/
│   └── Reader/
├── Services/
└── Resources/
```

---

### Task 1.4: Add Sample OPML

**Goal:** Bundle the HN popular blogs OPML.

**File:** `RssReaderMac/RssReaderMac/Resources/SampleFeeds.opml`

**Content:** The OPML file with ~80 popular tech blogs.

---

## PHASE 2: DATA MODELS

### Task 2.1: Feed Model

**File:** `RssReaderMac/RssReaderMac/Models/Feed.swift`

```swift
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
```

---

### Task 2.2: Article Model

**File:** `RssReaderMac/RssReaderMac/Models/Article.swift`

```swift
import Foundation
import SwiftData

@Model
final class Article {
    var id: UUID
    var title: String
    var articleURL: URL
    var content: String
    var fullContent: String?
    var author: String?
    var publishedDate: Date?
    var isRead: Bool
    var isStarred: Bool

    var feed: Feed?

    init(
        title: String,
        articleURL: URL,
        content: String,
        author: String? = nil,
        publishedDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.articleURL = articleURL
        self.content = content
        self.author = author
        self.publishedDate = publishedDate
        self.isRead = false
        self.isStarred = false
    }
}
```

---

### Task 2.3: SmartFolder Model

**File:** `RssReaderMac/RssReaderMac/Models/SmartFolder.swift`

```swift
import Foundation
import SwiftData

@Model
final class SmartFolder {
    var id: UUID
    var name: String
    var icon: String
    var rulesData: Data?

    var rules: [FilterRule] {
        get {
            guard let data = rulesData else { return [] }
            return (try? JSONDecoder().decode([FilterRule].self, from: data)) ?? []
        }
        set {
            rulesData = try? JSONEncoder().encode(newValue)
        }
    }

    init(name: String, icon: String, rules: [FilterRule] = []) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.rules = rules
    }
}

struct FilterRule: Codable, Hashable {
    enum Field: String, Codable, CaseIterable {
        case title, author, feedName, content
    }

    enum Operator: String, Codable, CaseIterable {
        case contains, notContains, matches
    }

    var field: Field
    var op: Operator
    var value: String

    func matches(article: Article) -> Bool {
        let text: String
        switch field {
        case .title: text = article.title
        case .author: text = article.author ?? ""
        case .feedName: text = article.feed?.title ?? ""
        case .content: text = article.content
        }

        switch op {
        case .contains:
            return text.localizedCaseInsensitiveContains(value)
        case .notContains:
            return !text.localizedCaseInsensitiveContains(value)
        case .matches:
            return (try? Regex(value).firstMatch(in: text)) != nil
        }
    }
}
```

---

### Task 2.4: Model Container Setup

**File:** `RssReaderMac/RssReaderMac/App/ModelContainerSetup.swift`

```swift
import SwiftData
import CloudKit

struct ModelContainerSetup {
    static func create() throws -> ModelContainer {
        let schema = Schema([
            Feed.self,
            Article.self,
            SmartFolder.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.fernandotn.RssReaderMac")
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
```

---

## PHASE 3: SERVICES

### Task 3.1: FeedParser Service

**File:** `RssReaderMac/RssReaderMac/Services/FeedParser.swift`

```swift
import Foundation
import FeedKit

actor FeedParser {
    enum FeedParserError: Error {
        case invalidURL
        case networkError(Error)
        case parseError(String)
    }

    func parse(url: URL) async throws -> ParsedFeed {
        let parser = FeedKit.FeedParser(URL: url)

        return try await withCheckedThrowingContinuation { continuation in
            parser.parseAsync { result in
                switch result {
                case .success(let feed):
                    switch feed {
                    case .rss(let rssFeed):
                        continuation.resume(returning: self.convert(rss: rssFeed, url: url))
                    case .atom(let atomFeed):
                        continuation.resume(returning: self.convert(atom: atomFeed, url: url))
                    case .json(let jsonFeed):
                        continuation.resume(returning: self.convert(json: jsonFeed, url: url))
                    }
                case .failure(let error):
                    continuation.resume(throwing: FeedParserError.parseError(error.localizedDescription))
                }
            }
        }
    }

    private func convert(rss: RSSFeed, url: URL) -> ParsedFeed {
        ParsedFeed(
            title: rss.title ?? url.host ?? "Unknown",
            siteURL: rss.link.flatMap { URL(string: $0) },
            iconURL: rss.image?.url.flatMap { URL(string: $0) },
            articles: rss.items?.compactMap { item in
                guard let title = item.title,
                      let link = item.link,
                      let articleURL = URL(string: link) else { return nil }

                return ParsedArticle(
                    title: title,
                    url: articleURL,
                    content: item.description ?? item.content?.contentEncoded ?? "",
                    author: item.author ?? item.dublinCore?.dcCreator,
                    publishedDate: item.pubDate
                )
            } ?? []
        )
    }

    private func convert(atom: AtomFeed, url: URL) -> ParsedFeed {
        ParsedFeed(
            title: atom.title ?? url.host ?? "Unknown",
            siteURL: atom.links?.first?.attributes?.href.flatMap { URL(string: $0) },
            iconURL: atom.icon.flatMap { URL(string: $0) },
            articles: atom.entries?.compactMap { entry in
                guard let title = entry.title,
                      let link = entry.links?.first?.attributes?.href,
                      let articleURL = URL(string: link) else { return nil }

                return ParsedArticle(
                    title: title,
                    url: articleURL,
                    content: entry.content?.value ?? entry.summary?.value ?? "",
                    author: entry.authors?.first?.name,
                    publishedDate: entry.published ?? entry.updated
                )
            } ?? []
        )
    }

    private func convert(json: JSONFeed, url: URL) -> ParsedFeed {
        ParsedFeed(
            title: json.title ?? url.host ?? "Unknown",
            siteURL: json.homePageURL.flatMap { URL(string: $0) },
            iconURL: json.favicon.flatMap { URL(string: $0) },
            articles: json.items?.compactMap { item in
                guard let title = item.title ?? item.summary,
                      let link = item.url ?? item.externalUrl,
                      let articleURL = URL(string: link) else { return nil }

                return ParsedArticle(
                    title: title,
                    url: articleURL,
                    content: item.contentHtml ?? item.contentText ?? item.summary ?? "",
                    author: item.author?.name,
                    publishedDate: item.datePublished
                )
            } ?? []
        )
    }
}

struct ParsedFeed {
    let title: String
    let siteURL: URL?
    let iconURL: URL?
    let articles: [ParsedArticle]
}

struct ParsedArticle {
    let title: String
    let url: URL
    let content: String
    let author: String?
    let publishedDate: Date?
}
```

---

### Task 3.2: OPMLParser Service

**File:** `RssReaderMac/RssReaderMac/Services/OPMLParser.swift`

```swift
import Foundation

struct OPMLParser {
    struct OPMLFeed {
        let title: String
        let feedURL: URL
        let siteURL: URL?
        let folder: String?
    }

    enum OPMLError: Error {
        case invalidData
        case parseError(String)
    }

    func parse(data: Data) throws -> [OPMLFeed] {
        let parser = OPMLXMLParser(data: data)
        return try parser.parse()
    }

    func parse(url: URL) throws -> [OPMLFeed] {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }

    func export(feeds: [Feed]) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
          <head>
            <title>RssReaderMac Feeds</title>
          </head>
          <body>
        """

        let grouped = Dictionary(grouping: feeds) { $0.folder ?? "" }

        for (folder, folderFeeds) in grouped.sorted(by: { $0.key < $1.key }) {
            if folder.isEmpty {
                for feed in folderFeeds {
                    xml += """
                        <outline type="rss" text="\(escapeXML(feed.title))" title="\(escapeXML(feed.title))" xmlUrl="\(feed.feedURL.absoluteString)"\(feed.siteURL.map { " htmlUrl=\"\($0.absoluteString)\"" } ?? "")/>
                    """
                }
            } else {
                xml += "    <outline text=\"\(escapeXML(folder))\" title=\"\(escapeXML(folder))\">\n"
                for feed in folderFeeds {
                    xml += """
                          <outline type="rss" text="\(escapeXML(feed.title))" title="\(escapeXML(feed.title))" xmlUrl="\(feed.feedURL.absoluteString)"\(feed.siteURL.map { " htmlUrl=\"\($0.absoluteString)\"" } ?? "")/>
                    """
                }
                xml += "    </outline>\n"
            }
        }

        xml += """
          </body>
        </opml>
        """

        return xml
    }

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

private class OPMLXMLParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var feeds: [OPMLParser.OPMLFeed] = []
    private var currentFolder: String?
    private var parseError: Error?

    init(data: Data) {
        self.data = data
    }

    func parse() throws -> [OPMLParser.OPMLFeed] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        if let error = parseError {
            throw error
        }

        return feeds
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        guard elementName == "outline" else { return }

        if let xmlUrl = attributeDict["xmlUrl"],
           let feedURL = URL(string: xmlUrl) {
            let feed = OPMLParser.OPMLFeed(
                title: attributeDict["title"] ?? attributeDict["text"] ?? feedURL.host ?? "Unknown",
                feedURL: feedURL,
                siteURL: attributeDict["htmlUrl"].flatMap { URL(string: $0) },
                folder: currentFolder
            )
            feeds.append(feed)
        } else if attributeDict["xmlUrl"] == nil {
            currentFolder = attributeDict["title"] ?? attributeDict["text"]
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "outline" && currentFolder != nil {
            // Check if this was a folder close - simplified logic
        }
    }
}
```

---

### Task 3.3: ContentExtractor Service

**File:** `RssReaderMac/RssReaderMac/Services/ContentExtractor.swift`

```swift
import Foundation
import SwiftSoup

actor ContentExtractor {
    enum ExtractionError: Error {
        case networkError(Error)
        case parseError(String)
    }

    func extract(from url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw ExtractionError.parseError("Could not decode HTML")
        }

        return try extractContent(from: html)
    }

    private func extractContent(from html: String) throws -> String {
        let document = try SwiftSoup.parse(html)

        // Remove unwanted elements
        try document.select("script, style, nav, header, footer, aside, .ads, .comments, .sidebar").remove()

        // Try to find article content
        let selectors = [
            "article",
            "[role=main]",
            ".post-content",
            ".article-content",
            ".entry-content",
            ".content",
            "main"
        ]

        for selector in selectors {
            if let article = try document.select(selector).first() {
                return try cleanText(article)
            }
        }

        // Fallback to body
        if let body = document.body() {
            return try cleanText(body)
        }

        throw ExtractionError.parseError("Could not extract content")
    }

    private func cleanText(_ element: Element) throws -> String {
        // Convert to readable text with basic formatting
        var result = ""

        for child in element.children() {
            let tagName = child.tagName()

            switch tagName {
            case "p":
                result += try child.text() + "\n\n"
            case "h1", "h2", "h3", "h4", "h5", "h6":
                result += "## " + (try child.text()) + "\n\n"
            case "ul", "ol":
                for li in try child.select("li") {
                    result += "• " + (try li.text()) + "\n"
                }
                result += "\n"
            case "blockquote":
                result += "> " + (try child.text()) + "\n\n"
            case "pre", "code":
                result += "```\n" + (try child.text()) + "\n```\n\n"
            default:
                let text = try child.text()
                if !text.isEmpty {
                    result += text + "\n\n"
                }
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

---

### Task 3.4: FeedRefreshManager

**File:** `RssReaderMac/RssReaderMac/Services/FeedRefreshManager.swift`

```swift
import Foundation
import SwiftData

@Observable
class FeedRefreshManager {
    private let parser = FeedParser()
    private var refreshTask: Task<Void, Never>?
    private(set) var isRefreshing = false

    func refreshAll(feeds: [Feed], modelContext: ModelContext) async {
        isRefreshing = true
        defer { isRefreshing = false }

        await withTaskGroup(of: Void.self) { group in
            for feed in feeds {
                group.addTask {
                    await self.refresh(feed: feed, modelContext: modelContext)
                }
            }
        }
    }

    func refresh(feed: Feed, modelContext: ModelContext) async {
        do {
            let parsed = try await parser.parse(url: feed.feedURL)

            await MainActor.run {
                feed.lastFetched = Date()

                if feed.title.isEmpty || feed.title == feed.feedURL.host {
                    feed.title = parsed.title
                }

                if feed.siteURL == nil {
                    feed.siteURL = parsed.siteURL
                }

                if feed.iconURL == nil {
                    feed.iconURL = parsed.iconURL
                }

                let existingURLs = Set(feed.articles.map { $0.articleURL })

                for parsedArticle in parsed.articles {
                    if !existingURLs.contains(parsedArticle.url) {
                        let article = Article(
                            title: parsedArticle.title,
                            articleURL: parsedArticle.url,
                            content: parsedArticle.content,
                            author: parsedArticle.author,
                            publishedDate: parsedArticle.publishedDate
                        )
                        article.feed = feed
                        feed.articles.append(article)
                    }
                }
            }
        } catch {
            print("Failed to refresh feed \(feed.title): \(error)")
        }
    }

    func startBackgroundRefresh(interval: TimeInterval = 1800, feeds: @escaping () -> [Feed], modelContext: ModelContext) {
        stopBackgroundRefresh()

        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                await refreshAll(feeds: feeds(), modelContext: modelContext)
            }
        }
    }

    func stopBackgroundRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
```

---

## PHASE 4: VIEWS - SIDEBAR

### Task 4.1: SidebarView

**File:** `RssReaderMac/RssReaderMac/Views/Sidebar/SidebarView.swift`

```swift
import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var feeds: [Feed]
    @Query private var smartFolders: [SmartFolder]

    @Binding var selectedItem: SidebarItem?
    @State private var showingAddFeed = false

    var body: some View {
        List(selection: $selectedItem) {
            Section("Smart Folders") {
                SmartFolderRow(name: "All Articles", icon: "tray.full", item: .all)
                SmartFolderRow(name: "Unread", icon: "circle.fill", item: .unread)
                SmartFolderRow(name: "Starred", icon: "star.fill", item: .starred)
                SmartFolderRow(name: "Today", icon: "calendar", item: .today)

                ForEach(smartFolders) { folder in
                    SmartFolderRow(name: folder.name, icon: folder.icon, item: .smartFolder(folder))
                }
            }

            Section("Feeds") {
                ForEach(groupedFeeds.keys.sorted(), id: \.self) { folder in
                    if folder.isEmpty {
                        ForEach(groupedFeeds[folder] ?? []) { feed in
                            FeedRow(feed: feed, item: .feed(feed))
                        }
                    } else {
                        DisclosureGroup(folder) {
                            ForEach(groupedFeeds[folder] ?? []) { feed in
                                FeedRow(feed: feed, item: .feed(feed))
                            }
                        }
                    }
                }
                .onDelete(perform: deleteFeeds)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem {
                Button(action: { showingAddFeed = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddFeed) {
            AddFeedSheet()
        }
    }

    private var groupedFeeds: [String: [Feed]] {
        Dictionary(grouping: feeds) { $0.folder ?? "" }
    }

    private func deleteFeeds(at offsets: IndexSet) {
        // Handle deletion
    }
}

enum SidebarItem: Hashable {
    case all
    case unread
    case starred
    case today
    case smartFolder(SmartFolder)
    case feed(Feed)
}
```

---

### Task 4.2: SmartFolderRow

**File:** `RssReaderMac/RssReaderMac/Views/Sidebar/SmartFolderRow.swift`

```swift
import SwiftUI

struct SmartFolderRow: View {
    let name: String
    let icon: String
    let item: SidebarItem

    var body: some View {
        Label(name, systemImage: icon)
            .tag(item)
    }
}
```

---

### Task 4.3: FeedRow

**File:** `RssReaderMac/RssReaderMac/Views/Sidebar/FeedRow.swift`

```swift
import SwiftUI

struct FeedRow: View {
    let feed: Feed
    let item: SidebarItem

    var unreadCount: Int {
        feed.articles.filter { !$0.isRead }.count
    }

    var body: some View {
        HStack {
            if let iconURL = feed.iconURL {
                AsyncImage(url: iconURL) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "dot.radiowaves.up.forward")
                }
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Image(systemName: "dot.radiowaves.up.forward")
                    .frame(width: 16, height: 16)
            }

            Text(feed.title)

            Spacer()

            if unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
        }
        .tag(item)
        .contextMenu {
            Button("Mark All as Read") {
                feed.articles.forEach { $0.isRead = true }
            }
            Divider()
            Button("Copy Feed URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(feed.feedURL.absoluteString, forType: .string)
            }
            Divider()
            Button("Delete Feed", role: .destructive) {
                // Handle delete
            }
        }
    }
}
```

---

### Task 4.4: AddFeedSheet

**File:** `RssReaderMac/RssReaderMac/Views/Sidebar/AddFeedSheet.swift`

```swift
import SwiftUI
import SwiftData

struct AddFeedSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var urlString = ""
    @State private var folder = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let parser = FeedParser()

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Feed")
                .font(.headline)

            TextField("Feed URL", text: $urlString)
                .textFieldStyle(.roundedBorder)
                .frame(width: 400)

            TextField("Folder (optional)", text: $folder)
                .textFieldStyle(.roundedBorder)
                .frame(width: 400)

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Add") {
                    addFeed()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(urlString.isEmpty || isLoading)
            }
        }
        .padding(30)
        .frame(width: 450)
    }

    private func addFeed() {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let parsed = try await parser.parse(url: url)

                await MainActor.run {
                    let feed = Feed(
                        title: parsed.title,
                        feedURL: url,
                        siteURL: parsed.siteURL,
                        folder: folder.isEmpty ? nil : folder
                    )
                    feed.iconURL = parsed.iconURL

                    for parsedArticle in parsed.articles {
                        let article = Article(
                            title: parsedArticle.title,
                            articleURL: parsedArticle.url,
                            content: parsedArticle.content,
                            author: parsedArticle.author,
                            publishedDate: parsedArticle.publishedDate
                        )
                        article.feed = feed
                        feed.articles.append(article)
                    }

                    modelContext.insert(feed)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to fetch feed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
```

---

## PHASE 5: VIEWS - ARTICLE LIST

### Task 5.1: ArticleListView

**File:** `RssReaderMac/RssReaderMac/Views/ArticleList/ArticleListView.swift`

```swift
import SwiftUI
import SwiftData

struct ArticleListView: View {
    let sidebarItem: SidebarItem?
    @Binding var selectedArticle: Article?

    @Query private var allArticles: [Article]

    var articles: [Article] {
        guard let item = sidebarItem else { return [] }

        let filtered: [Article]
        switch item {
        case .all:
            filtered = allArticles
        case .unread:
            filtered = allArticles.filter { !$0.isRead }
        case .starred:
            filtered = allArticles.filter { $0.isStarred }
        case .today:
            let calendar = Calendar.current
            filtered = allArticles.filter { article in
                guard let date = article.publishedDate else { return false }
                return calendar.isDateInToday(date)
            }
        case .smartFolder(let folder):
            filtered = allArticles.filter { article in
                folder.rules.allSatisfy { $0.matches(article: article) }
            }
        case .feed(let feed):
            filtered = feed.articles
        }

        return filtered.sorted { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
    }

    var body: some View {
        List(articles, selection: $selectedArticle) { article in
            ArticleRow(article: article)
                .tag(article)
        }
        .listStyle(.inset)
        .frame(minWidth: 300)
    }
}
```

---

### Task 5.2: ArticleRow

**File:** `RssReaderMac/RssReaderMac/Views/ArticleList/ArticleRow.swift`

```swift
import SwiftUI

struct ArticleRow: View {
    @Bindable var article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(article.title)
                    .font(.headline)
                    .fontWeight(article.isRead ? .regular : .bold)
                    .lineLimit(2)

                Spacer()

                if article.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }

            HStack {
                if let feedTitle = article.feed?.title {
                    Text(feedTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let author = article.author {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let date = article.publishedDate {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(article.content.prefix(150).replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button(article.isRead ? "Mark as Unread" : "Mark as Read") {
                article.isRead.toggle()
            }
            Button(article.isStarred ? "Unstar" : "Star") {
                article.isStarred.toggle()
            }
            Divider()
            Button("Open in Browser") {
                NSWorkspace.shared.open(article.articleURL)
            }
            Button("Copy Link") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(article.articleURL.absoluteString, forType: .string)
            }
        }
    }
}
```

---

### Task 5.3: ArticleListToolbar

**File:** `RssReaderMac/RssReaderMac/Views/ArticleList/ArticleListToolbar.swift`

```swift
import SwiftUI

struct ArticleListToolbar: ToolbarContent {
    let onRefresh: () -> Void
    let onMarkAllRead: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh Feeds (⌘R)")

            Button(action: onMarkAllRead) {
                Image(systemName: "checkmark.circle")
            }
            .help("Mark All as Read")
        }
    }
}
```

---

## PHASE 6: VIEWS - READER

### Task 6.1: ReaderView

**File:** `RssReaderMac/RssReaderMac/Views/Reader/ReaderView.swift`

```swift
import SwiftUI

struct ReaderView: View {
    @Bindable var article: Article
    @State private var readerMode = false
    @State private var isLoadingFullContent = false

    private let extractor = ContentExtractor()

    var displayContent: String {
        if readerMode, let fullContent = article.fullContent {
            return fullContent
        }
        return article.content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .textSelection(.enabled)

                    HStack {
                        if let feedTitle = article.feed?.title {
                            Text(feedTitle)
                                .foregroundStyle(.secondary)
                        }

                        if let author = article.author {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(author)
                                .foregroundStyle(.secondary)
                        }

                        if let date = article.publishedDate {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(date, style: .date)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .font(.subheadline)
                }

                Divider()

                // Content
                if isLoadingFullContent {
                    ProgressView("Loading full article...")
                } else {
                    Text(attributedContent)
                        .textSelection(.enabled)
                        .font(.body)
                        .lineSpacing(4)
                }

                // Footer
                Divider()

                Link(destination: article.articleURL) {
                    Label("Open in Browser", systemImage: "safari")
                }
                .font(.subheadline)
            }
            .padding(32)
            .frame(maxWidth: 700, alignment: .leading)
        }
        .frame(minWidth: 400)
        .toolbar {
            ReaderToolbar(
                article: article,
                readerMode: $readerMode,
                onToggleReaderMode: toggleReaderMode
            )
        }
        .onAppear {
            article.isRead = true
        }
    }

    private var attributedContent: AttributedString {
        // Simple HTML stripping - could be enhanced
        let stripped = displayContent.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return AttributedString(stripped)
    }

    private func toggleReaderMode() {
        if !readerMode && article.fullContent == nil {
            loadFullContent()
        }
        readerMode.toggle()
    }

    private func loadFullContent() {
        isLoadingFullContent = true

        Task {
            do {
                let content = try await extractor.extract(from: article.articleURL)
                await MainActor.run {
                    article.fullContent = content
                    isLoadingFullContent = false
                }
            } catch {
                await MainActor.run {
                    isLoadingFullContent = false
                }
            }
        }
    }
}
```

---

### Task 6.2: ReaderToolbar

**File:** `RssReaderMac/RssReaderMac/Views/Reader/ReaderToolbar.swift`

```swift
import SwiftUI

struct ReaderToolbar: ToolbarContent {
    @Bindable var article: Article
    @Binding var readerMode: Bool
    let onToggleReaderMode: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button(action: onToggleReaderMode) {
                Image(systemName: readerMode ? "doc.richtext" : "doc.plaintext")
            }
            .help(readerMode ? "Show Original" : "Reader Mode")

            Button(action: { article.isStarred.toggle() }) {
                Image(systemName: article.isStarred ? "star.fill" : "star")
            }
            .help(article.isStarred ? "Unstar" : "Star")

            Button(action: { article.isRead.toggle() }) {
                Image(systemName: article.isRead ? "circle" : "circle.fill")
            }
            .help(article.isRead ? "Mark as Unread" : "Mark as Read")

            ShareLink(item: article.articleURL)
        }
    }
}
```

---

## PHASE 7: MAIN APP SHELL

### Task 7.1: ContentView (3-column)

**File:** `RssReaderMac/RssReaderMac/ContentView.swift`

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var feeds: [Feed]

    @State private var selectedSidebarItem: SidebarItem? = .all
    @State private var selectedArticle: Article?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    @StateObject private var refreshManager = FeedRefreshManager()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedItem: $selectedSidebarItem)
        } content: {
            ArticleListView(
                sidebarItem: selectedSidebarItem,
                selectedArticle: $selectedArticle
            )
            .toolbar {
                ArticleListToolbar(
                    onRefresh: { Task { await refreshManager.refreshAll(feeds: feeds, modelContext: modelContext) } },
                    onMarkAllRead: markAllRead
                )
            }
        } detail: {
            if let article = selectedArticle {
                ReaderView(article: article)
            } else {
                Text("Select an article")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            refreshManager.startBackgroundRefresh(
                feeds: { feeds },
                modelContext: modelContext
            )
        }
    }

    private func markAllRead() {
        guard let item = selectedSidebarItem else { return }

        switch item {
        case .feed(let feed):
            feed.articles.forEach { $0.isRead = true }
        default:
            break
        }
    }
}
```

---

### Task 7.2: App Entry Point

**File:** `RssReaderMac/RssReaderMac/RssReaderMacApp.swift`

```swift
import SwiftUI
import SwiftData

@main
struct RssReaderMacApp: App {
    @State private var showWelcome = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainerSetup.create()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if showWelcome {
                WelcomeView(showWelcome: $showWelcome)
                    .modelContainer(modelContainer)
            } else {
                ContentView()
                    .modelContainer(modelContainer)
            }
        }
        .commands {
            AppCommands()
        }
    }
}
```

---

### Task 7.3: Menu Commands

**File:** `RssReaderMac/RssReaderMac/App/AppCommands.swift`

```swift
import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Import Feeds...") {
                importOPML()
            }
            .keyboardShortcut("i", modifiers: .command)

            Button("Export Feeds...") {
                exportOPML()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }

        CommandGroup(after: .toolbar) {
            Button("Refresh All Feeds") {
                NotificationCenter.default.post(name: .refreshFeeds, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)
        }
    }

    private func importOPML() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "opml")!]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            NotificationCenter.default.post(name: .importOPML, object: url)
        }
    }

    private func exportOPML() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "opml")!]
        panel.nameFieldStringValue = "feeds.opml"

        if panel.runModal() == .OK, let url = panel.url {
            NotificationCenter.default.post(name: .exportOPML, object: url)
        }
    }
}

extension Notification.Name {
    static let refreshFeeds = Notification.Name("refreshFeeds")
    static let importOPML = Notification.Name("importOPML")
    static let exportOPML = Notification.Name("exportOPML")
}
```

---

### Task 7.4: Keyboard Shortcuts

**File:** `RssReaderMac/RssReaderMac/App/KeyboardShortcuts.swift`

```swift
import SwiftUI

struct KeyboardShortcutsModifier: ViewModifier {
    @Binding var selectedArticle: Article?
    let articles: [Article]

    func body(content: Content) -> some View {
        content
            .onKeyPress("j") {
                selectNextArticle()
                return .handled
            }
            .onKeyPress("k") {
                selectPreviousArticle()
                return .handled
            }
            .onKeyPress("r") {
                selectedArticle?.isRead.toggle()
                return .handled
            }
            .onKeyPress("s") {
                selectedArticle?.isStarred.toggle()
                return .handled
            }
            .onKeyPress(.return) {
                if let article = selectedArticle {
                    NSWorkspace.shared.open(article.articleURL)
                }
                return .handled
            }
    }

    private func selectNextArticle() {
        guard let current = selectedArticle,
              let index = articles.firstIndex(of: current),
              index + 1 < articles.count else { return }
        selectedArticle = articles[index + 1]
    }

    private func selectPreviousArticle() {
        guard let current = selectedArticle,
              let index = articles.firstIndex(of: current),
              index > 0 else { return }
        selectedArticle = articles[index - 1]
    }
}

extension View {
    func keyboardShortcuts(selectedArticle: Binding<Article?>, articles: [Article]) -> some View {
        modifier(KeyboardShortcutsModifier(selectedArticle: selectedArticle, articles: articles))
    }
}
```

---

## PHASE 8: FIRST LAUNCH & POLISH

### Task 8.1: WelcomeView

**File:** `RssReaderMac/RssReaderMac/Views/Onboarding/WelcomeView.swift`

```swift
import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showWelcome: Bool

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "dot.radiowaves.up.forward")
                .font(.system(size: 64))
                .foregroundStyle(.accent)

            Text("Welcome to RssReaderMac")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("A clean, focused RSS reader for macOS")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                Button(action: importOPML) {
                    Label("Import My Feeds", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: loadSampleFeeds) {
                    Label("Start with Popular Blogs", systemImage: "star")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(action: startEmpty) {
                    Text("Start Empty")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .frame(width: 280)
        }
        .padding(48)
        .frame(width: 500, height: 450)
    }

    private func importOPML() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "opml")!]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            loadOPML(from: url)
        }
    }

    private func loadOPML(from url: URL) {
        do {
            let parser = OPMLParser()
            let feeds = try parser.parse(url: url)

            for opmlFeed in feeds {
                let feed = Feed(
                    title: opmlFeed.title,
                    feedURL: opmlFeed.feedURL,
                    siteURL: opmlFeed.siteURL,
                    folder: opmlFeed.folder
                )
                modelContext.insert(feed)
            }

            finishOnboarding()
        } catch {
            print("Failed to import OPML: \(error)")
        }
    }

    private func loadSampleFeeds() {
        guard let url = Bundle.main.url(forResource: "SampleFeeds", withExtension: "opml") else {
            startEmpty()
            return
        }
        loadOPML(from: url)
    }

    private func startEmpty() {
        finishOnboarding()
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        showWelcome = false
    }
}
```

---

### Task 8.2: Sample OPML File

**File:** `RssReaderMac/RssReaderMac/Resources/SampleFeeds.opml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head>
    <title>Popular Tech Blogs</title>
  </head>
  <body>
    <outline text="Blogs" title="Blogs">
      <outline type="rss" text="simonwillison.net" title="simonwillison.net" xmlUrl="https://simonwillison.net/atom/everything/" htmlUrl="https://simonwillison.net"/>
      <outline type="rss" text="Daring Fireball" title="Daring Fireball" xmlUrl="https://daringfireball.net/feeds/main" htmlUrl="https://daringfireball.net"/>
      <outline type="rss" text="Paul Graham" title="Paul Graham" xmlUrl="http://www.aaronsw.com/2002/feeds/pgessays.rss" htmlUrl="https://paulgraham.com"/>
      <outline type="rss" text="Overreacted" title="Overreacted" xmlUrl="https://overreacted.io/rss.xml" htmlUrl="https://overreacted.io"/>
      <outline type="rss" text="Krebs on Security" title="Krebs on Security" xmlUrl="https://krebsonsecurity.com/feed/" htmlUrl="https://krebsonsecurity.com"/>
      <outline type="rss" text="The Old New Thing" title="The Old New Thing" xmlUrl="https://devblogs.microsoft.com/oldnewthing/feed" htmlUrl="https://devblogs.microsoft.com/oldnewthing"/>
      <outline type="rss" text="Pluralistic" title="Pluralistic" xmlUrl="https://pluralistic.net/feed/" htmlUrl="https://pluralistic.net"/>
      <outline type="rss" text="Gwern" title="Gwern" xmlUrl="https://gwern.substack.com/feed" htmlUrl="https://gwern.net"/>
      <outline type="rss" text="matklad" title="matklad" xmlUrl="https://matklad.github.io/feed.xml" htmlUrl="https://matklad.github.io"/>
      <outline type="rss" text="Rachel by the Bay" title="Rachel by the Bay" xmlUrl="https://rachelbythebay.com/w/atom.xml" htmlUrl="https://rachelbythebay.com"/>
    </outline>
  </body>
</opml>
```

---

## PHASE 9: TESTING

### Task 9.1: Model Tests

**File:** `RssReaderMac/RssReaderMacTests/ModelTests.swift`

```swift
import XCTest
import SwiftData
@testable import RssReaderMac

final class ModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([Feed.self, Article.self, SmartFolder.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    func testFeedCreation() throws {
        let feed = Feed(title: "Test Feed", feedURL: URL(string: "https://example.com/feed")!)
        context.insert(feed)

        let descriptor = FetchDescriptor<Feed>()
        let feeds = try context.fetch(descriptor)

        XCTAssertEqual(feeds.count, 1)
        XCTAssertEqual(feeds.first?.title, "Test Feed")
    }

    func testArticleFeedRelationship() throws {
        let feed = Feed(title: "Test Feed", feedURL: URL(string: "https://example.com/feed")!)
        let article = Article(title: "Test Article", articleURL: URL(string: "https://example.com/1")!, content: "Content")
        article.feed = feed
        feed.articles.append(article)

        context.insert(feed)

        XCTAssertEqual(feed.articles.count, 1)
        XCTAssertEqual(feed.articles.first?.title, "Test Article")
    }

    func testFilterRuleMatches() {
        let article = Article(title: "Swift Tips", articleURL: URL(string: "https://example.com/1")!, content: "Learn Swift")

        let rule = FilterRule(field: .title, op: .contains, value: "Swift")
        XCTAssertTrue(rule.matches(article: article))

        let rule2 = FilterRule(field: .title, op: .notContains, value: "Python")
        XCTAssertTrue(rule2.matches(article: article))
    }
}
```

---

### Task 9.2: Service Tests

**File:** `RssReaderMac/RssReaderMacTests/ServiceTests.swift`

```swift
import XCTest
@testable import RssReaderMac

final class ServiceTests: XCTestCase {
    func testOPMLParsing() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
          <head><title>Test</title></head>
          <body>
            <outline type="rss" text="Test Feed" xmlUrl="https://example.com/feed" htmlUrl="https://example.com"/>
          </body>
        </opml>
        """

        let parser = OPMLParser()
        let feeds = try parser.parse(data: opml.data(using: .utf8)!)

        XCTAssertEqual(feeds.count, 1)
        XCTAssertEqual(feeds.first?.title, "Test Feed")
        XCTAssertEqual(feeds.first?.feedURL.absoluteString, "https://example.com/feed")
    }

    func testOPMLExport() {
        let feed = Feed(title: "Test Feed", feedURL: URL(string: "https://example.com/feed")!)
        feed.siteURL = URL(string: "https://example.com")

        let parser = OPMLParser()
        let exported = parser.export(feeds: [feed])

        XCTAssertTrue(exported.contains("Test Feed"))
        XCTAssertTrue(exported.contains("https://example.com/feed"))
    }
}
```

---

## PHASE 10: REVIEW & COMMIT

### Task 10.1: Code Review Checklist

- [ ] All files compile without errors
- [ ] SwiftData models have proper relationships
- [ ] Views follow SwiftUI best practices
- [ ] Keyboard shortcuts work
- [ ] OPML import/export works
- [ ] Reader mode toggle works
- [ ] iCloud sync configured correctly

---

### Task 10.2: Final Commit

```bash
git add -A
git commit -m "feat: complete RSS reader implementation

- SwiftUI three-column interface
- SwiftData models with CloudKit sync
- Feed parsing with FeedKit
- Reader mode with content extraction
- OPML import/export
- Smart folders with filter rules
- Keyboard navigation (j/k/r/s)
- Background feed refresh
- Welcome onboarding flow"

git push origin main
```

---

## AGENT DISPATCH GUIDE

### Parallel Batch 1: Foundation (4 agents)
- Agent A: Task 1.1-1.4 (Project setup)
- Agent B: Task 2.1-2.4 (Data models)
- Agent C: Task 3.1-3.2 (Feed/OPML parsers)
- Agent D: Task 3.3-3.4 (Content extractor, refresh manager)

### Parallel Batch 2: Views (3 agents)
- Agent E: Task 4.1-4.4 (Sidebar views)
- Agent F: Task 5.1-5.3 (Article list views)
- Agent G: Task 6.1-6.2 (Reader views)

### Parallel Batch 3: Integration (2 agents)
- Agent H: Task 7.1-7.4 (App shell, commands, shortcuts)
- Agent I: Task 8.1-8.2 (Onboarding, sample data)

### Parallel Batch 4: Quality (2 agents)
- Agent J: Task 9.1-9.2 (Unit tests)
- Agent K: Task 10.1 (Code review)

### Final: Single Agent
- Task 10.2: Final commit and push
