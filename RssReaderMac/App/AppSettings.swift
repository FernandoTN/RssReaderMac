import SwiftUI

/// Observable settings model for font customization with @AppStorage persistence.
@Observable
final class AppSettings {
    /// Available font family options
    enum FontFamily: String, CaseIterable, Identifiable {
        case system = "system"
        case serif = "Georgia"
        case sansSerif = "Helvetica Neue"
        case monospace = "Menlo"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return "System"
            case .serif: return "Serif"
            case .sansSerif: return "Sans-serif"
            case .monospace: return "Monospace"
            }
        }
    }

    // MARK: - Stored Properties

    /// The selected font family
    var fontFamily: String {
        get {
            access(keyPath: \.fontFamily)
            return UserDefaults.standard.string(forKey: "fontFamily") ?? FontFamily.system.rawValue
        }
        set {
            withMutation(keyPath: \.fontFamily) {
                UserDefaults.standard.set(newValue, forKey: "fontFamily")
            }
        }
    }

    /// The font size in points
    var fontSize: Double {
        get {
            access(keyPath: \.fontSize)
            let value = UserDefaults.standard.double(forKey: "fontSize")
            return value > 0 ? value : 16
        }
        set {
            withMutation(keyPath: \.fontSize) {
                UserDefaults.standard.set(newValue, forKey: "fontSize")
            }
        }
    }

    /// The line spacing in points
    var lineSpacing: Double {
        get {
            access(keyPath: \.lineSpacing)
            let value = UserDefaults.standard.double(forKey: "lineSpacing")
            return value > 0 ? value : 4
        }
        set {
            withMutation(keyPath: \.lineSpacing) {
                UserDefaults.standard.set(newValue, forKey: "lineSpacing")
            }
        }
    }

    // MARK: - Computed Properties

    /// The selected font family as an enum
    var selectedFontFamily: FontFamily {
        get { FontFamily(rawValue: fontFamily) ?? .system }
        set { fontFamily = newValue.rawValue }
    }

    /// Computed body font based on settings
    var bodyFont: Font {
        switch selectedFontFamily {
        case .system:
            return .system(size: fontSize)
        case .serif:
            return .custom("Georgia", size: fontSize)
        case .sansSerif:
            return .custom("Helvetica Neue", size: fontSize)
        case .monospace:
            return .custom("Menlo", size: fontSize)
        }
    }

    /// Computed title font (larger than body)
    var titleFont: Font {
        let titleSize = fontSize * 1.75
        switch selectedFontFamily {
        case .system:
            return .system(size: titleSize, weight: .bold)
        case .serif:
            return .custom("Georgia", size: titleSize).weight(.bold)
        case .sansSerif:
            return .custom("Helvetica Neue", size: titleSize).weight(.bold)
        case .monospace:
            return .custom("Menlo", size: titleSize).weight(.bold)
        }
    }

    // MARK: - Initialization

    init() {}
}
