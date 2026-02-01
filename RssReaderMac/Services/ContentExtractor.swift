import Foundation
import SwiftSoup

/// Actor-based service for extracting clean article content from web pages.
/// Uses SwiftSoup to parse HTML and extract the main content while removing
/// navigation, ads, scripts, and other non-content elements.
actor ContentExtractor {

    // MARK: - Error Types

    enum ExtractionError: LocalizedError {
        case networkError(Error)
        case parseError(String)
        case invalidEncoding
        case noContentFound

        var errorDescription: String? {
            switch self {
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .parseError(let message):
                return "Parse error: \(message)"
            case .invalidEncoding:
                return "Could not decode HTML content"
            case .noContentFound:
                return "Could not find article content"
            }
        }
    }

    // MARK: - Content Selectors

    /// Selectors to try when looking for main article content, in order of preference
    private let contentSelectors = [
        "article",
        "[role=main]",
        ".post-content",
        ".article-content",
        ".entry-content",
        ".post-body",
        ".article-body",
        ".story-body",
        ".content-body",
        ".markdown-body",
        ".blog-post-content",
        "#article-content",
        "#post-content",
        "#main-content",
        ".content",
        "main"
    ]

    /// Selectors for elements that should be removed
    private let removeSelectors = [
        "script",
        "style",
        "nav",
        "header",
        "footer",
        "aside",
        "noscript",
        "iframe",
        "form",
        ".ads",
        ".ad",
        ".advertisement",
        ".social-share",
        ".share-buttons",
        ".comments",
        ".comment-section",
        ".sidebar",
        ".related-posts",
        ".related-articles",
        ".newsletter",
        ".subscription",
        ".popup",
        ".modal",
        "[role=navigation]",
        "[role=banner]",
        "[role=complementary]",
        "[aria-hidden=true]"
    ]

    // MARK: - Public Methods

    /// Extracts clean article content from a URL
    /// - Parameter url: The URL to extract content from
    /// - Returns: Clean text content with basic markdown formatting
    func extract(from url: URL) async throws -> String {
        let (data, response) = try await fetchData(from: url)

        // Try to determine encoding from response
        let encoding = determineEncoding(from: response, data: data)

        guard let html = String(data: data, encoding: encoding) else {
            throw ExtractionError.invalidEncoding
        }

        return try extractContent(from: html)
    }

    /// Extracts clean article content from raw HTML string
    /// - Parameter html: The HTML string to parse
    /// - Returns: Clean text content with basic markdown formatting
    func extract(from html: String) throws -> String {
        return try extractContent(from: html)
    }

    // MARK: - Private Methods

    private func fetchData(from url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw ExtractionError.networkError(error)
        }
    }

    private func determineEncoding(from response: URLResponse, data: Data) -> String.Encoding {
        // Try to get encoding from HTTP response
        if let httpResponse = response as? HTTPURLResponse,
           let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
            if contentType.lowercased().contains("utf-8") {
                return .utf8
            } else if contentType.lowercased().contains("iso-8859-1") || contentType.lowercased().contains("latin1") {
                return .isoLatin1
            }
        }

        // Try to detect from HTML meta tag
        if let htmlString = String(data: data.prefix(2048), encoding: .ascii) {
            let lowercased = htmlString.lowercased()
            if lowercased.contains("charset=utf-8") || lowercased.contains("charset=\"utf-8\"") {
                return .utf8
            } else if lowercased.contains("charset=iso-8859-1") {
                return .isoLatin1
            }
        }

        // Default to UTF-8
        return .utf8
    }

    private func extractContent(from html: String) throws -> String {
        let document: Document
        do {
            document = try SwiftSoup.parse(html)
        } catch {
            throw ExtractionError.parseError("Failed to parse HTML: \(error.localizedDescription)")
        }

        // Remove unwanted elements
        do {
            let combinedSelector = removeSelectors.joined(separator: ", ")
            try document.select(combinedSelector).remove()
        } catch {
            // Continue even if some selectors fail
        }

        // Try to find article content using various selectors
        for selector in contentSelectors {
            do {
                if let article = try document.select(selector).first() {
                    let content = try cleanAndFormatElement(article)
                    if !content.isEmpty && content.count > 100 {
                        return content
                    }
                }
            } catch {
                continue
            }
        }

        // Fallback to body content
        if let body = document.body() {
            do {
                let content = try cleanAndFormatElement(body)
                if !content.isEmpty {
                    return content
                }
            } catch {
                throw ExtractionError.parseError("Failed to extract body content")
            }
        }

        throw ExtractionError.noContentFound
    }

    private func cleanAndFormatElement(_ element: Element) throws -> String {
        var result = ""

        try processElement(element, into: &result)

        // Clean up excessive whitespace
        result = result
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }

    private func processElement(_ element: Element, into result: inout String) throws {
        for node in element.getChildNodes() {
            if let textNode = node as? TextNode {
                let text = textNode.text().trimmingCharacters(in: .whitespaces)
                if !text.isEmpty {
                    result += text + " "
                }
            } else if let childElement = node as? Element {
                try processChildElement(childElement, into: &result)
            }
        }
    }

    private func processChildElement(_ element: Element, into result: inout String) throws {
        let tagName = element.tagName().lowercased()

        switch tagName {
        case "p":
            let text = try element.text().trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                result += text + "\n\n"
            }

        case "h1":
            let text = try element.text().trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                result += "# " + text + "\n\n"
            }

        case "h2":
            let text = try element.text().trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                result += "## " + text + "\n\n"
            }

        case "h3":
            let text = try element.text().trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                result += "### " + text + "\n\n"
            }

        case "h4", "h5", "h6":
            let text = try element.text().trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                result += "#### " + text + "\n\n"
            }

        case "ul":
            for li in try element.select("> li") {
                let text = try li.text().trimmingCharacters(in: .whitespaces)
                if !text.isEmpty {
                    result += "- " + text + "\n"
                }
            }
            result += "\n"

        case "ol":
            var index = 1
            for li in try element.select("> li") {
                let text = try li.text().trimmingCharacters(in: .whitespaces)
                if !text.isEmpty {
                    result += "\(index). " + text + "\n"
                    index += 1
                }
            }
            result += "\n"

        case "blockquote":
            let text = try element.text().trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                let lines = text.components(separatedBy: .newlines)
                for line in lines {
                    result += "> " + line + "\n"
                }
                result += "\n"
            }

        case "pre":
            let text = try element.text()
            if !text.isEmpty {
                result += "```\n" + text + "\n```\n\n"
            }

        case "code":
            // Check if inside a pre block (already handled)
            if element.parent()?.tagName().lowercased() != "pre" {
                let text = try element.text()
                if !text.isEmpty {
                    result += "`" + text + "`"
                }
            }

        case "br":
            result += "\n"

        case "hr":
            result += "\n---\n\n"

        case "a":
            let text = try element.text().trimmingCharacters(in: .whitespaces)
            let href = try element.attr("href")
            if !text.isEmpty {
                if !href.isEmpty && !href.hasPrefix("#") && !href.hasPrefix("javascript:") {
                    result += "[\(text)](\(href))"
                } else {
                    result += text
                }
            }

        case "strong", "b":
            let text = try element.text().trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                result += "**" + text + "**"
            }

        case "em", "i":
            let text = try element.text().trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                result += "*" + text + "*"
            }

        case "img":
            let alt = try element.attr("alt")
            let src = try element.attr("src")
            if !src.isEmpty {
                let altText = alt.isEmpty ? "image" : alt
                result += "![\(altText)](\(src))\n\n"
            }

        case "figure":
            try processElement(element, into: &result)

        case "figcaption":
            let text = try element.text().trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                result += "*" + text + "*\n\n"
            }

        case "div", "section", "article", "main", "span":
            // Process children for container elements
            try processElement(element, into: &result)

        case "table":
            // Simple table handling - just extract text
            let text = try element.text().trimmingCharacters(in: .whitespaces)
            if !text.isEmpty {
                result += text + "\n\n"
            }

        default:
            // For unknown elements, try to get text content
            if element.children().isEmpty {
                let text = try element.text().trimmingCharacters(in: .whitespaces)
                if !text.isEmpty {
                    result += text + " "
                }
            } else {
                try processElement(element, into: &result)
            }
        }
    }
}
