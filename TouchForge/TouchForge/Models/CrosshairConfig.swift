import Foundation

enum CrosshairStyle: String, Codable, CaseIterable, Identifiable {
    case classicCross
    case centerDot
    case circleDot
    case tShape
    case chevron
    case brackets
    case sniperReticle

    var id: String { rawValue }

    var displayNameKey: String {
        switch self {
        case .classicCross: return "crosshair.style.classic"
        case .centerDot: return "crosshair.style.dot"
        case .circleDot: return "crosshair.style.circleDot"
        case .tShape: return "crosshair.style.tShape"
        case .chevron: return "crosshair.style.chevron"
        case .brackets: return "crosshair.style.brackets"
        case .sniperReticle: return "crosshair.style.sniper"
        }
    }
}

struct CrosshairConfig: Codable, Equatable {
    var isEnabled: Bool
    var style: CrosshairStyle
    var size: Double          // 12 ... 120 pt
    var thickness: Double     // 1 ... 8 pt
    var centerGap: Double     // 0 ... 24 pt
    var showCenterDot: Bool
    var dotSize: Double       // 2 ... 12 pt
    var showOutline: Bool
    var opacity: Double       // 0.15 ... 1.0
    var color: CodableColor
    var offsetX: Double       // -120 ... 120 pt from center
    var offsetY: Double       // -120 ... 120 pt from center

    init(
        isEnabled: Bool = true,
        style: CrosshairStyle = .classicCross,
        size: Double = 36,
        thickness: Double = 2.5,
        centerGap: Double = 6,
        showCenterDot: Bool = true,
        dotSize: Double = 4,
        showOutline: Bool = true,
        opacity: Double = 0.92,
        color: CodableColor = .neonGreen,
        offsetX: Double = 0,
        offsetY: Double = 0
    ) {
        self.isEnabled = isEnabled
        self.style = style
        self.size = min(max(size, 12), 120)
        self.thickness = min(max(thickness, 1), 8)
        self.centerGap = min(max(centerGap, 0), 24)
        self.showCenterDot = showCenterDot
        self.dotSize = min(max(dotSize, 2), 12)
        self.showOutline = showOutline
        self.opacity = min(max(opacity, 0.15), 1.0)
        self.color = color
        self.offsetX = min(max(offsetX, -120), 120)
        self.offsetY = min(max(offsetY, -120), 120)
    }
}
