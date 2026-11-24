import Foundation
import SwiftUI
import UIKit

// MARK: - Serializable Color

struct CodableColor: Codable, Equatable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            self.red = Double(r)
            self.green = Double(g)
            self.blue = Double(b)
            self.alpha = Double(a)
        } else {
            self.red = 0.2
            self.green = 0.55
            self.blue = 1.0
            self.alpha = 1.0
        }
    }

    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    static let electricBlue = CodableColor(red: 0.16, green: 0.52, blue: 1.0)
    static let neonGreen = CodableColor(red: 0.18, green: 0.85, blue: 0.45)
    static let crimson = CodableColor(red: 0.96, green: 0.26, blue: 0.34)
    static let amber = CodableColor(red: 1.0, green: 0.68, blue: 0.14)
    static let purple = CodableColor(red: 0.65, green: 0.36, blue: 0.98)
    static let cyan = CodableColor(red: 0.12, green: 0.82, blue: 0.94)
    static let white = CodableColor(red: 1.0, green: 1.0, blue: 1.0)
}

// MARK: - Virtual Touch Control

enum VirtualControlType: String, Codable, CaseIterable, Identifiable {
    case tapButton
    case holdButton
    case swipePad
    case dPad
    case aimPad
    case macroTrigger

    var id: String { rawValue }

    var displayNameKey: String {
        switch self {
        case .tapButton: return "control.type.tap"
        case .holdButton: return "control.type.hold"
        case .swipePad: return "control.type.swipe"
        case .dPad: return "control.type.dpad"
        case .aimPad: return "control.type.aim"
        case .macroTrigger: return "control.type.macro"
        }
    }

    var defaultSymbol: String {
        switch self {
        case .tapButton: return "hand.tap.fill"
        case .holdButton: return "hand.point.up.left.fill"
        case .swipePad: return "arrow.up.and.down.and.arrow.left.and.right"
        case .dPad: return "dpad.fill"
        case .aimPad: return "scope"
        case .macroTrigger: return "bolt.fill"
        }
    }
}

enum ControlShape: String, Codable, CaseIterable, Identifiable {
    case circle
    case roundedRect
    case capsule
    case ring

    var id: String { rawValue }

    var displayNameKey: String {
        switch self {
        case .circle: return "control.shape.circle"
        case .roundedRect: return "control.shape.rounded"
        case .capsule: return "control.shape.capsule"
        case .ring: return "control.shape.ring"
        }
    }
}

enum ControllerBinding: String, Codable, CaseIterable, Identifiable {
    case none
    case buttonA
    case buttonB
    case buttonX
    case buttonY
    case leftShoulder
    case rightShoulder
    case leftTrigger
    case rightTrigger
    case leftThumbstickButton
    case rightThumbstickButton
    case dpadUp
    case dpadDown
    case dpadLeft
    case dpadRight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .buttonA: return "A / Cross"
        case .buttonB: return "B / Circle"
        case .buttonX: return "X / Square"
        case .buttonY: return "Y / Triangle"
        case .leftShoulder: return "L1 / LB"
        case .rightShoulder: return "R1 / RB"
        case .leftTrigger: return "L2 / LT"
        case .rightTrigger: return "R2 / RT"
        case .leftThumbstickButton: return "L3"
        case .rightThumbstickButton: return "R3"
        case .dpadUp: return "D-Pad Up"
        case .dpadDown: return "D-Pad Down"
        case .dpadLeft: return "D-Pad Left"
        case .dpadRight: return "D-Pad Right"
        }
    }
}

enum HapticIntensity: String, Codable, CaseIterable, Identifiable {
    case none
    case light
    case medium
    case heavy

    var id: String { rawValue }
}

struct VirtualTouchControl: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var label: String
    var symbolName: String
    var type: VirtualControlType
    var shape: ControlShape

    /// Normalized coordinates (0.0 ... 1.0) so layouts adapt cleanly across iPhone screen sizes and orientations.
    var normalizedX: Double
    var normalizedY: Double

    /// Base diameter/width in points (44 ... 160).
    var width: Double
    var height: Double

    /// Opacity of the button fill & chrome (0.15 ... 1.0).
    var opacity: Double
    var borderWidth: Double
    var fillColor: CodableColor
    var textColor: CodableColor

    /// Optional hardware controller binding & macro link.
    var controllerBinding: ControllerBinding
    var linkedMacroId: UUID?
    var haptic: HapticIntensity
    var isLocked: Bool

    init(
        id: UUID = UUID(),
        label: String,
        symbolName: String? = nil,
        type: VirtualControlType = .tapButton,
        shape: ControlShape = .circle,
        normalizedX: Double = 0.5,
        normalizedY: Double = 0.5,
        width: Double = 68,
        height: Double = 68,
        opacity: Double = 0.85,
        borderWidth: Double = 2.0,
        fillColor: CodableColor = .electricBlue,
        textColor: CodableColor = .white,
        controllerBinding: ControllerBinding = .none,
        linkedMacroId: UUID? = nil,
        haptic: HapticIntensity = .medium,
        isLocked: Bool = false
    ) {
        self.id = id
        self.label = label
        self.symbolName = symbolName ?? type.defaultSymbol
        self.type = type
        self.shape = shape
        self.normalizedX = min(max(normalizedX, 0.04), 0.96)
        self.normalizedY = min(max(normalizedY, 0.04), 0.96)
        self.width = min(max(width, 40), 180)
        self.height = min(max(height, 40), 180)
        self.opacity = min(max(opacity, 0.12), 1.0)
        self.borderWidth = min(max(borderWidth, 0), 6)
        self.fillColor = fillColor
        self.textColor = textColor
        self.controllerBinding = controllerBinding
        self.linkedMacroId = linkedMacroId
        self.haptic = haptic
        self.isLocked = isLocked
    }
}
