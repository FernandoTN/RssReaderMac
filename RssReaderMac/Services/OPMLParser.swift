import Foundation

// MARK: - OPML Data Structures

/// Represents a feed entry from an OPML file
struct OPMLFeed: Sendable, Equatable {
    let title: String
    let feedURL: URL
    let siteURL: URL?
    let folder: String?
}

/// Represents the result of parsing an OPML file
struct OPMLDocument: Sendable {
    let title: String?
    let feeds: [OPMLFeed]
}

// MARK: - OPML Parser Errors

enum OPMLParserError: LocalizedError {
    case invalidData
    case parsingFailed(String)
    case invalidXML
    case missingRequiredAttribute(String)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "The OPML data is invalid or corrupted."
        case .parsingFailed(let message):
            return "Failed to parse OPML: \(message)"
        case .invalidXML:
            return "The file is not valid XML."
        case .missingRequiredAttribute(let attribute):
            return "Missing required attribute: \(attribute)"
        }
    }
}

// MARK: - OPML Parser

/// Parser for OPML (Outline Processor Markup Language) files
/// Used for importing and exporting feed subscriptions
final class OPMLParser: NSObject, XMLParserDelegate, @unchecked Sendable {

    // MARK: - Properties

    private var feeds: [OPMLFeed] = []
    private var documentTitle: String?
    private var currentFolder: String?
    private var folderStack: [String] = []
    private var parsingError: Error?
    private var isInHead = false
    private var isInTitle = false
    private var currentTitleText = ""

    // MARK: - Public Methods

    /// Parse OPML data from raw Data
    /// - Parameter data: The raw OPML data
    /// - Returns: An OPMLDocument containing the parsed feeds
    func parse(data: Data) throws -> OPMLDocument {
        reset()

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false
        parser.shouldResolveExternalEntities = false

        guard parser.parse() else {
            if let error = parsingError {
                throw error
            }
            throw OPMLParserError.invalidXML
        }

        return OPMLDocument(title: documentTitle, feeds: feeds)
    }

    /// Parse OPML from a file URL
    /// - Parameter url: The file URL of the OPML file
    /// - Returns: An OPMLDocument containing the parsed feeds
    func parse(url: URL) throws -> OPMLDocument {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }

    /// Export feeds to OPML format
    /// - Parameters:
    ///   - feeds: The feeds to export
    ///   - title: The title for the OPML document
    /// - Returns: The OPML data as a string
    func export(feeds: [OPMLFeed], title: String = "RSS Subscriptions") -> String {
        var opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>\(escapeXML(title))</title>
                <dateCreated>\(formatRFC822Date(Date()))</dateCreated>
            </head>
            <body>

        """

        // Group feeds by folder
        let groupedFeeds = Dictionary(grouping: feeds) { $0.folder ?? "" }

        // First, output feeds without folders
        if let rootFeeds = groupedFeeds[""] {
            for feed in rootFeeds {
                opml += "        \(outlineElement(for: feed))\n"
            }
        }

        // Then output folder groups
        for (folder, folderFeeds) in groupedFeeds.sorted(by: { $0.key < $1.key }) {
            guard !folder.isEmpty else { continue }

            opml += "        <outline text=\"\(escapeXML(folder))\" title=\"\(escapeXML(folder))\">\n"
            for feed in folderFeeds {
                opml += "            \(outlineElement(for: feed))\n"
            }
            opml += "        </outline>\n"
        }

        opml += """
            </body>
        </opml>
        """

        return opml
    }

    /// Export feeds to OPML and save to a file
    /// - Parameters:
    ///   - feeds: The feeds to export
    ///   - url: The file URL to save to
    ///   - title: The title for the OPML document
    func export(feeds: [OPMLFeed], to url: URL, title: String = "RSS Subscriptions") throws {
        let opmlString = export(feeds: feeds, title: title)
        try opmlString.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Private Methods

    private func reset() {
        feeds = []
        documentTitle = nil
        currentFolder = nil
        folderStack = []
        parsingError = nil
        isInHead = false
        isInTitle = false
        currentTitleText = ""
    }

    private func outlineElement(for feed: OPMLFeed) -> String {
        var attributes = [
            "type=\"rss\"",
            "text=\"\(escapeXML(feed.title))\"",
            "title=\"\(escapeXML(feed.title))\"",
            "xmlUrl=\"\(escapeXML(feed.feedURL.absoluteString))\""
        ]

        if let siteURL = feed.siteURL {
            attributes.append("htmlUrl=\"\(escapeXML(siteURL.absoluteString))\"")
        }

        return "<outline \(attributes.joined(separator: " \n                    "))/>"
    }

    private func escapeXML(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }

    private func formatRFC822Date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch elementName.lowercased() {
        case "head":
            isInHead = true

        case "title":
            if isInHead {
                isInTitle = true
                currentTitleText = ""
            }

        case "outline":
            handleOutlineElement(attributes: attributeDict)

        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName.lowercased() {
        case "head":
            isInHead = false

        case "title":
            if isInHead && isInTitle {
                documentTitle = currentTitleText.trimmingCharacters(in: .whitespacesAndNewlines)
                isInTitle = false
            }

        case "outline":
            // Pop folder from stack if we're leaving a folder outline
            if !folderStack.isEmpty {
                folderStack.removeLast()
                currentFolder = folderStack.last
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInTitle {
            currentTitleText += string
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        parsingError = OPMLParserError.parsingFailed(parseError.localizedDescription)
    }

    // MARK: - Outline Handling

    private func handleOutlineElement(attributes: [String: String]) {
        // Check if this is a feed (has xmlUrl) or a folder
        if let xmlUrlString = attributes["xmlUrl"] ?? attributes["xmlurl"],
           let feedURL = URL(string: xmlUrlString) {
            // This is a feed
            let title = attributes["title"]
                ?? attributes["text"]
                ?? feedURL.host
                ?? "Untitled Feed"

            let siteURL: URL?
            if let htmlUrlString = attributes["htmlUrl"] ?? attributes["htmlurl"] {
                siteURL = URL(string: htmlUrlString)
            } else {
                siteURL = nil
            }

            let feed = OPMLFeed(
                title: title,
                feedURL: feedURL,
                siteURL: siteURL,
                folder: currentFolder
            )

            feeds.append(feed)
        } else {
            // This is a folder
            let folderName = attributes["title"] ?? attributes["text"]
            if let folderName = folderName {
                folderStack.append(folderName)
                currentFolder = folderName
            }
        }
    }
}

// MARK: - Convenience Extensions

extension OPMLParser {

    /// Create OPMLFeed objects from Feed models for export
    /// - Parameters:
    ///   - feeds: The Feed models to convert
    /// - Returns: An array of OPMLFeed objects ready for export
    static func createOPMLFeeds(from feeds: [(title: String, feedURL: URL, siteURL: URL?, folder: String?)]) -> [OPMLFeed] {
        feeds.map { feed in
            OPMLFeed(
                title: feed.title,
                feedURL: feed.feedURL,
                siteURL: feed.siteURL,
                folder: feed.folder
            )
        }
    }
}
