import Foundation
import SwiftUI

enum AppAppearance: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var displayNameKey: String {
        switch self {
        case .system: return "settings.appearance.system"
        case .light: return "settings.appearance.light"
        case .dark: return "settings.appearance.dark"
        }
    }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case vietnamese = "vi"
    case spanish = "es"
    case japanese = "ja"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        case .spanish: return "Español"
        case .japanese: return "日本語"
        case .simplifiedChinese: return "简体中文"
        }
    }
}

enum AccentTheme: String, Codable, CaseIterable, Identifiable {
    case blue
    case emerald
    case orange
    case purple
    case rose

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return Color(red: 0.15, green: 0.50, blue: 1.0)
        case .emerald: return Color(red: 0.10, green: 0.76, blue: 0.48)
        case .orange: return Color(red: 1.0, green: 0.48, blue: 0.14)
        case .purple: return Color(red: 0.58, green: 0.34, blue: 0.98)
        case .rose: return Color(red: 0.95, green: 0.25, blue: 0.44)
        }
    }
}

struct AppSettings: Codable, Equatable {
    var appearance: AppAppearance = .system
    var language: AppLanguage = .english
    var accentTheme: AccentTheme = .blue
    var hapticsEnabled: Bool = true
    var snapToGrid: Bool = true
    var gridSize: Int = 16
    var showCoordinatesOverlay: Bool = true
    var autoConnectBLEBridge: Bool = false
    var showTestRipples: Bool = true
}
