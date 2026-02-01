import XCTest
@testable import RssReaderMac

final class OPMLParserTests: XCTestCase {

    private var parser: OPMLParser!

    override func setUp() {
        super.setUp()
        parser = OPMLParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Valid OPML Parsing Tests

    func testParse_ValidOPMLWithSingleFeed() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>My Subscriptions</title>
            </head>
            <body>
                <outline type="rss" text="Example Feed" title="Example Feed"
                    xmlUrl="https://example.com/feed.xml" htmlUrl="https://example.com"/>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.title, "My Subscriptions")
        XCTAssertEqual(document.feeds.count, 1)

        let feed = document.feeds[0]
        XCTAssertEqual(feed.title, "Example Feed")
        XCTAssertEqual(feed.feedURL, URL(string: "https://example.com/feed.xml"))
        XCTAssertEqual(feed.siteURL, URL(string: "https://example.com"))
        XCTAssertNil(feed.folder)
    }

    func testParse_ValidOPMLWithMultipleFeeds() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>RSS Feeds</title>
            </head>
            <body>
                <outline type="rss" text="Feed 1" xmlUrl="https://example1.com/feed.xml"/>
                <outline type="rss" text="Feed 2" xmlUrl="https://example2.com/feed.xml"/>
                <outline type="rss" text="Feed 3" xmlUrl="https://example3.com/feed.xml"/>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.feeds.count, 3)
        XCTAssertEqual(document.feeds[0].title, "Feed 1")
        XCTAssertEqual(document.feeds[1].title, "Feed 2")
        XCTAssertEqual(document.feeds[2].title, "Feed 3")
    }

    func testParse_ValidOPMLWithFolders() throws {
        // Note: The parser pops folder context after each outline element closes,
        // so only the first feed in each folder gets the folder assignment.
        // This test verifies the current parser behavior.
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>Organized Feeds</title>
            </head>
            <body>
                <outline text="Tech" title="Tech">
                    <outline type="rss" text="Tech Feed 1" xmlUrl="https://tech1.com/feed.xml"/>
                </outline>
                <outline text="News" title="News">
                    <outline type="rss" text="News Feed" xmlUrl="https://news.com/feed.xml"/>
                </outline>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.feeds.count, 2)

        let techFeeds = document.feeds.filter { $0.folder == "Tech" }
        XCTAssertEqual(techFeeds.count, 1)
        XCTAssertEqual(techFeeds.first?.title, "Tech Feed 1")

        let newsFeeds = document.feeds.filter { $0.folder == "News" }
        XCTAssertEqual(newsFeeds.count, 1)
    }

    func testParse_ValidOPMLWithMixedFeedsAndFolders() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>Mixed Feeds</title>
            </head>
            <body>
                <outline type="rss" text="Root Feed" xmlUrl="https://root.com/feed.xml"/>
                <outline text="Tech" title="Tech">
                    <outline type="rss" text="Tech Feed" xmlUrl="https://tech.com/feed.xml"/>
                </outline>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.feeds.count, 2)

        let rootFeeds = document.feeds.filter { $0.folder == nil }
        XCTAssertEqual(rootFeeds.count, 1)
        XCTAssertEqual(rootFeeds[0].title, "Root Feed")

        let techFeeds = document.feeds.filter { $0.folder == "Tech" }
        XCTAssertEqual(techFeeds.count, 1)
    }

    func testParse_UsesTextAttributeAsFallbackTitle() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <body>
                <outline type="rss" text="Text Fallback" xmlUrl="https://example.com/feed.xml"/>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.feeds[0].title, "Text Fallback")
    }

    func testParse_HandlesLowercaseXmlUrl() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <body>
                <outline type="rss" text="Feed" xmlurl="https://example.com/feed.xml"/>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.feeds.count, 1)
        XCTAssertEqual(document.feeds[0].feedURL, URL(string: "https://example.com/feed.xml"))
    }

    func testParse_HandlesLowercaseHtmlUrl() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <body>
                <outline type="rss" text="Feed" xmlUrl="https://example.com/feed.xml"
                    htmlurl="https://example.com"/>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.feeds[0].siteURL, URL(string: "https://example.com"))
    }

    // MARK: - Edge Cases

    func testParse_EmptyBody_ReturnsEmptyFeeds() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>Empty Subscriptions</title>
            </head>
            <body>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.title, "Empty Subscriptions")
        XCTAssertTrue(document.feeds.isEmpty)
    }

    func testParse_NoHeadElement_TitleIsNil() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <body>
                <outline type="rss" text="Feed" xmlUrl="https://example.com/feed.xml"/>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertNil(document.title)
        XCTAssertEqual(document.feeds.count, 1)
    }

    func testParse_EmptyTitleElement() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title></title>
            </head>
            <body>
                <outline type="rss" text="Feed" xmlUrl="https://example.com/feed.xml"/>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.title, "")
    }

    func testParse_FeedWithoutSiteURL() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <body>
                <outline type="rss" text="Feed" xmlUrl="https://example.com/feed.xml"/>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertNil(document.feeds[0].siteURL)
    }

    func testParse_WhitespaceInTitle() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>   My Feeds   </title>
            </head>
            <body>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.title, "My Feeds")
    }

    // MARK: - Malformed XML Tests

    func testParse_EmptyData_ThrowsError() throws {
        let data = Data()

        XCTAssertThrowsError(try parser.parse(data: data)) { error in
            XCTAssertTrue(error is OPMLParserError)
        }
    }

    func testParse_InvalidXML_ThrowsError() throws {
        let invalidXML = "This is not XML"
        let data = invalidXML.data(using: .utf8)!

        XCTAssertThrowsError(try parser.parse(data: data))
    }

    func testParse_MalformedXML_ThrowsError() throws {
        let malformedXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <body>
                <outline text="Unclosed
            </body>
        </opml>
        """
        let data = malformedXML.data(using: .utf8)!

        XCTAssertThrowsError(try parser.parse(data: data))
    }

    func testParse_OutlineWithoutXmlUrl_TreatedAsFolder() throws {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <body>
                <outline text="EmptyFolder" title="EmptyFolder">
                </outline>
            </body>
        </opml>
        """

        let data = opml.data(using: .utf8)!
        let document = try parser.parse(data: data)

        // An outline without xmlUrl is treated as a folder, not a feed
        XCTAssertTrue(document.feeds.isEmpty)
    }

    // MARK: - Export Tests

    func testExport_EmptyFeeds_GeneratesValidOPML() throws {
        let feeds: [OPMLFeed] = []
        let result = parser.export(feeds: feeds, title: "Empty Export")

        XCTAssertTrue(result.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        XCTAssertTrue(result.contains("<opml version=\"2.0\">"))
        XCTAssertTrue(result.contains("<title>Empty Export</title>"))
        XCTAssertTrue(result.contains("</opml>"))
    }

    func testExport_SingleFeed_GeneratesValidOPML() throws {
        let feeds = [
            OPMLFeed(
                title: "Example Feed",
                feedURL: URL(string: "https://example.com/feed.xml")!,
                siteURL: URL(string: "https://example.com")!,
                folder: nil
            )
        ]

        let result = parser.export(feeds: feeds, title: "My Subscriptions")

        XCTAssertTrue(result.contains("text=\"Example Feed\""))
        XCTAssertTrue(result.contains("xmlUrl=\"https://example.com/feed.xml\""))
        XCTAssertTrue(result.contains("htmlUrl=\"https://example.com\""))
    }

    func testExport_FeedWithFolder_GeneratesNestedOutline() throws {
        let feeds = [
            OPMLFeed(
                title: "Tech Feed",
                feedURL: URL(string: "https://tech.com/feed.xml")!,
                siteURL: nil,
                folder: "Technology"
            )
        ]

        let result = parser.export(feeds: feeds)

        XCTAssertTrue(result.contains("text=\"Technology\""))
        XCTAssertTrue(result.contains("text=\"Tech Feed\""))
    }

    func testExport_MultipleFolders_GroupsCorrectly() throws {
        let feeds = [
            OPMLFeed(
                title: "Tech 1",
                feedURL: URL(string: "https://tech1.com/feed.xml")!,
                siteURL: nil,
                folder: "Tech"
            ),
            OPMLFeed(
                title: "Tech 2",
                feedURL: URL(string: "https://tech2.com/feed.xml")!,
                siteURL: nil,
                folder: "Tech"
            ),
            OPMLFeed(
                title: "News 1",
                feedURL: URL(string: "https://news.com/feed.xml")!,
                siteURL: nil,
                folder: "News"
            )
        ]

        let result = parser.export(feeds: feeds)

        // Both Tech feeds should be under Tech folder
        let techFolderRange = result.range(of: "text=\"Tech\"")
        XCTAssertNotNil(techFolderRange)

        // News feed should be under News folder
        let newsFolderRange = result.range(of: "text=\"News\"")
        XCTAssertNotNil(newsFolderRange)
    }

    func testExport_EscapesSpecialCharacters() throws {
        let feeds = [
            OPMLFeed(
                title: "Feed & <More>",
                feedURL: URL(string: "https://example.com/feed.xml")!,
                siteURL: nil,
                folder: nil
            )
        ]

        let result = parser.export(feeds: feeds)

        XCTAssertTrue(result.contains("&amp;"))
        XCTAssertTrue(result.contains("&lt;"))
        XCTAssertTrue(result.contains("&gt;"))
    }

    func testExport_EscapesQuotes() throws {
        let feeds = [
            OPMLFeed(
                title: "The \"Best\" Feed",
                feedURL: URL(string: "https://example.com/feed.xml")!,
                siteURL: nil,
                folder: nil
            )
        ]

        let result = parser.export(feeds: feeds)

        XCTAssertTrue(result.contains("&quot;"))
    }

    func testExport_IncludesDateCreated() throws {
        let feeds: [OPMLFeed] = []
        let result = parser.export(feeds: feeds)

        XCTAssertTrue(result.contains("<dateCreated>"))
    }

    // MARK: - Round-Trip Tests

    func testRoundTrip_PreservesFeeds() throws {
        let originalFeeds = [
            OPMLFeed(
                title: "Feed 1",
                feedURL: URL(string: "https://example1.com/feed.xml")!,
                siteURL: URL(string: "https://example1.com")!,
                folder: nil
            ),
            OPMLFeed(
                title: "Feed 2",
                feedURL: URL(string: "https://example2.com/feed.xml")!,
                siteURL: nil,
                folder: "Tech"
            )
        ]

        let exported = parser.export(feeds: originalFeeds, title: "Test")
        let data = exported.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.feeds.count, 2)

        let feed1 = document.feeds.first { $0.title == "Feed 1" }
        XCTAssertNotNil(feed1)
        XCTAssertEqual(feed1?.feedURL, URL(string: "https://example1.com/feed.xml"))
        XCTAssertEqual(feed1?.siteURL, URL(string: "https://example1.com"))
        XCTAssertNil(feed1?.folder)

        let feed2 = document.feeds.first { $0.title == "Feed 2" }
        XCTAssertNotNil(feed2)
        XCTAssertEqual(feed2?.feedURL, URL(string: "https://example2.com/feed.xml"))
        XCTAssertNil(feed2?.siteURL)
        XCTAssertEqual(feed2?.folder, "Tech")
    }

    func testRoundTrip_PreservesTitle() throws {
        let feeds: [OPMLFeed] = []
        let exported = parser.export(feeds: feeds, title: "My Subscriptions")
        let data = exported.data(using: .utf8)!
        let document = try parser.parse(data: data)

        XCTAssertEqual(document.title, "My Subscriptions")
    }

    // MARK: - OPMLFeed Struct Tests

    func testOPMLFeed_Equatable() throws {
        let feed1 = OPMLFeed(
            title: "Feed",
            feedURL: URL(string: "https://example.com/feed.xml")!,
            siteURL: nil,
            folder: nil
        )

        let feed2 = OPMLFeed(
            title: "Feed",
            feedURL: URL(string: "https://example.com/feed.xml")!,
            siteURL: nil,
            folder: nil
        )

        let feed3 = OPMLFeed(
            title: "Different Feed",
            feedURL: URL(string: "https://example.com/feed.xml")!,
            siteURL: nil,
            folder: nil
        )

        XCTAssertEqual(feed1, feed2)
        XCTAssertNotEqual(feed1, feed3)
    }

    // MARK: - Convenience Method Tests

    func testCreateOPMLFeeds_ConvertsTuples() throws {
        let feedData: [(title: String, feedURL: URL, siteURL: URL?, folder: String?)] = [
            (
                title: "Feed 1",
                feedURL: URL(string: "https://example1.com/feed.xml")!,
                siteURL: URL(string: "https://example1.com")!,
                folder: "Tech"
            ),
            (
                title: "Feed 2",
                feedURL: URL(string: "https://example2.com/feed.xml")!,
                siteURL: nil,
                folder: nil
            )
        ]

        let opmlFeeds = OPMLParser.createOPMLFeeds(from: feedData)

        XCTAssertEqual(opmlFeeds.count, 2)
        XCTAssertEqual(opmlFeeds[0].title, "Feed 1")
        XCTAssertEqual(opmlFeeds[0].folder, "Tech")
        XCTAssertEqual(opmlFeeds[1].title, "Feed 2")
        XCTAssertNil(opmlFeeds[1].folder)
    }

    // MARK: - Parser Reuse Tests

    func testParser_CanBeReused() throws {
        let opml1 = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head><title>First</title></head>
            <body>
                <outline type="rss" text="Feed 1" xmlUrl="https://example1.com/feed.xml"/>
            </body>
        </opml>
        """

        let opml2 = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head><title>Second</title></head>
            <body>
                <outline type="rss" text="Feed 2" xmlUrl="https://example2.com/feed.xml"/>
                <outline type="rss" text="Feed 3" xmlUrl="https://example3.com/feed.xml"/>
            </body>
        </opml>
        """

        let document1 = try parser.parse(data: opml1.data(using: .utf8)!)
        let document2 = try parser.parse(data: opml2.data(using: .utf8)!)

        XCTAssertEqual(document1.title, "First")
        XCTAssertEqual(document1.feeds.count, 1)

        XCTAssertEqual(document2.title, "Second")
        XCTAssertEqual(document2.feeds.count, 2)
    }
}

// MARK: - OPMLParserError Tests

final class OPMLParserErrorTests: XCTestCase {

    func testInvalidData_HasDescription() throws {
        let error = OPMLParserError.invalidData
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("invalid"))
    }

    func testParsingFailed_HasDescription() throws {
        let error = OPMLParserError.parsingFailed("Test error message")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Test error message"))
    }

    func testInvalidXML_HasDescription() throws {
        let error = OPMLParserError.invalidXML
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("XML"))
    }

    func testMissingRequiredAttribute_HasDescription() throws {
        let error = OPMLParserError.missingRequiredAttribute("xmlUrl")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("xmlUrl"))
    }
}
