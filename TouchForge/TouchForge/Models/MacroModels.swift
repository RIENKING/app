import Foundation

enum MacroActionKind: String, Codable, CaseIterable, Identifiable {
    case tap
    case longPress
    case swipe
    case delay
    case hapticCue
    case bleHIDCommand

    var id: String { rawValue }

    var displayNameKey: String {
        switch self {
        case .tap: return "macro.action.tap"
        case .longPress: return "macro.action.longPress"
        case .swipe: return "macro.action.swipe"
        case .delay: return "macro.action.delay"
        case .hapticCue: return "macro.action.haptic"
        case .bleHIDCommand: return "macro.action.ble"
        }
    }

    var systemImage: String {
        switch self {
        case .tap: return "hand.tap"
        case .longPress: return "hand.point.up.left"
        case .swipe: return "hand.draw"
        case .delay: return "clock"
        case .hapticCue: return "waveform.path"
        case .bleHIDCommand: return "antenna.radiowaves.left.and.right"
        }
    }
}

struct MacroStep: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var kind: MacroActionKind
    var label: String

    /// Normalized coordinates (0.0 ... 1.0) on the target canvas.
    var startX: Double
    var startY: Double
    var endX: Double
    var endY: Double

    /// Duration of the gesture itself in milliseconds (e.g., hold time or swipe duration).
    var durationMs: Int

    /// Delay after this step completes, in milliseconds.
    var delayAfterMs: Int

    /// Optional HID key/command payload when using an external BLE HID bridge.
    var hidPayload: String

    init(
        id: UUID = UUID(),
        kind: MacroActionKind,
        label: String = "",
        startX: Double = 0.5,
        startY: Double = 0.5,
        endX: Double = 0.5,
        endY: Double = 0.5,
        durationMs: Int = 80,
        delayAfterMs: Int = 120,
        hidPayload: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.label = label.isEmpty ? kind.rawValue.capitalized : label
        self.startX = min(max(startX, 0), 1)
        self.startY = min(max(startY, 0), 1)
        self.endX = min(max(endX, 0), 1)
        self.endY = min(max(endY, 0), 1)
        self.durationMs = max(0, durationMs)
        self.delayAfterMs = max(0, delayAfterMs)
        self.hidPayload = hidPayload
    }
}

struct MacroProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var notes: String
    var steps: [MacroStep]

    /// Number of times to repeat when `isInfiniteLoop` is false (1 ... 100).
    var repeatCount: Int
    var isInfiniteLoop: Bool

    /// Delay between loop iterations in milliseconds.
    var loopDelayMs: Int

    /// Playback speed multiplier (0.25 ... 2.5).
    var speedMultiplier: Double

    /// Optional hardware controller binding to trigger this macro.
    var triggerBinding: ControllerBinding

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        steps: [MacroStep] = [],
        repeatCount: Int = 1,
        isInfiniteLoop: Bool = false,
        loopDelayMs: Int = 250,
        speedMultiplier: Double = 1.0,
        triggerBinding: ControllerBinding = .none,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.steps = steps
        self.repeatCount = min(max(repeatCount, 1), 100)
        self.isInfiniteLoop = isInfiniteLoop
        self.loopDelayMs = max(0, loopDelayMs)
        self.speedMultiplier = min(max(speedMultiplier, 0.25), 2.5)
        self.triggerBinding = triggerBinding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var estimatedSinglePassMs: Int {
        let raw = steps.reduce(0) { $0 + $1.durationMs + $1.delayAfterMs }
        return Int(Double(raw) / max(speedMultiplier, 0.25))
    }
}
