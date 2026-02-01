import Foundation
import SwiftData

@Model
final class SmartFolder {
    var id: UUID
    var name: String
    var rules: [FilterRule]

    init(name: String, rules: [FilterRule] = []) {
        self.id = UUID()
        self.name = name
        self.rules = rules
    }
}

struct FilterRule: Codable, Hashable {
    enum Field: String, Codable, CaseIterable {
        case title
        case author
        case content
        case feedTitle
    }

    enum Operator: String, Codable, CaseIterable {
        case contains
        case notContains
        case equals
        case notEquals
        case startsWith
        case endsWith
    }

    var field: Field
    var `operator`: Operator
    var value: String

    init(field: Field, operator: Operator, value: String) {
        self.field = field
        self.operator = `operator`
        self.value = value
    }

    func matches(article: Article) -> Bool {
        let fieldValue: String
        switch field {
        case .title:
            fieldValue = article.title
        case .author:
            fieldValue = article.author ?? ""
        case .content:
            fieldValue = article.content ?? ""
        case .feedTitle:
            fieldValue = article.feed?.title ?? ""
        }

        let lowercasedField = fieldValue.lowercased()
        let lowercasedValue = value.lowercased()

        switch `operator` {
        case .contains:
            return lowercasedField.contains(lowercasedValue)
        case .notContains:
            return !lowercasedField.contains(lowercasedValue)
        case .equals:
            return lowercasedField == lowercasedValue
        case .notEquals:
            return lowercasedField != lowercasedValue
        case .startsWith:
            return lowercasedField.hasPrefix(lowercasedValue)
        case .endsWith:
            return lowercasedField.hasSuffix(lowercasedValue)
        }
    }
}
