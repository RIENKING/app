import Foundation

final class PersistenceService {
    static let shared = PersistenceService()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    private var storageURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let folder = appSupport.appendingPathComponent("TouchForge", isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent("state_v1.json")
    }

    func loadState() -> TouchForgeBackupPayload {
        if let data = try? Data(contentsOf: storageURL),
           let decoded = try? decoder.decode(TouchForgeBackupPayload.self, from: data),
           !decoded.profiles.isEmpty {
            return decoded
        }
        return Self.makeDefaultState()
    }

    func saveState(_ payload: TouchForgeBackupPayload) throws {
        let data = try encoder.encode(payload)
        try data.write(to: storageURL, options: [.atomic])
    }

    func encodeJSON<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }

    func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }

    static func makeDefaultState() -> TouchForgeBackupPayload {
        let quickBurstMacroId = UUID()
        let slideCancelMacroId = UUID()
        let comboCastMacroId = UUID()

        let macros: [MacroProfile] = [
            MacroProfile(
                id: quickBurstMacroId,
                name: "3-Round Burst Tap",
                notes: "Fires three crisp controlled taps with 90ms spacing.",
                steps: [
                    MacroStep(kind: .tap, label: "Shot 1", startX: 0.84, startY: 0.62, durationMs: 45, delayAfterMs: 90),
                    MacroStep(kind: .tap, label: "Shot 2", startX: 0.84, startY: 0.62, durationMs: 45, delayAfterMs: 90),
                    MacroStep(kind: .tap, label: "Shot 3", startX: 0.84, startY: 0.62, durationMs: 45, delayAfterMs: 120)
                ],
                repeatCount: 1,
                isInfiniteLoop: false,
                loopDelayMs: 250,
                speedMultiplier: 1.0,
                triggerBinding: .rightShoulder
            ),
            MacroProfile(
                id: slideCancelMacroId,
                name: "Slide & Jump Cancel",
                notes: "Crouch tap followed by sprint swipe and jump tap.",
                steps: [
                    MacroStep(kind: .tap, label: "Crouch", startX: 0.78, startY: 0.82, durationMs: 60, delayAfterMs: 110),
                    MacroStep(kind: .swipe, label: "Forward Sprint", startX: 0.20, startY: 0.72, endX: 0.20, endY: 0.50, durationMs: 140, delayAfterMs: 80),
                    MacroStep(kind: .tap, label: "Jump", startX: 0.88, startY: 0.76, durationMs: 55, delayAfterMs: 100)
                ],
                repeatCount: 1,
                isInfiniteLoop: false,
                loopDelayMs: 300,
                speedMultiplier: 1.0,
                triggerBinding: .buttonB
            ),
            MacroProfile(
                id: comboCastMacroId,
                name: "MOBA 3-Skill Combo",
                notes: "Chains Skill 1 -> Skill 2 -> Ultimate with precise cast delays.",
                steps: [
                    MacroStep(kind: .tap, label: "Skill 1", startX: 0.72, startY: 0.80, durationMs: 50, delayAfterMs: 140),
                    MacroStep(kind: .tap, label: "Skill 2", startX: 0.80, startY: 0.66, durationMs: 50, delayAfterMs: 180),
                    MacroStep(kind: .tap, label: "Ultimate", startX: 0.88, startY: 0.54, durationMs: 70, delayAfterMs: 120),
                    MacroStep(kind: .hapticCue, label: "Combo Complete", durationMs: 20, delayAfterMs: 50)
                ],
                repeatCount: 1,
                isInfiniteLoop: false,
                loopDelayMs: 400,
                speedMultiplier: 1.0,
                triggerBinding: .buttonY
            )
        ]

        let fpsProfile = GameProfile(
            name: "FPS Tactical Pro",
            gameTitle: "Tactical Shooter",
            genre: .fps,
            notes: "4-finger claw & controller-ready layout with precision green crosshair.",
            controls: [
                VirtualTouchControl(label: "MOVE", symbolName: "dpad.fill", type: .dPad, shape: .ring, normalizedX: 0.18, normalizedY: 0.72, width: 116, height: 116, opacity: 0.78, fillColor: .electricBlue, controllerBinding: .leftThumbstickButton),
                VirtualTouchControl(label: "FIRE", symbolName: "flame.fill", type: .holdButton, shape: .circle, normalizedX: 0.84, normalizedY: 0.62, width: 82, height: 82, opacity: 0.88, fillColor: .crimson, controllerBinding: .rightTrigger),
                VirtualTouchControl(label: "ADS", symbolName: "scope", type: .holdButton, shape: .circle, normalizedX: 0.72, normalizedY: 0.52, width: 68, height: 68, opacity: 0.85, fillColor: .amber, controllerBinding: .leftTrigger),
                VirtualTouchControl(label: "JUMP", symbolName: "arrow.up", type: .tapButton, shape: .circle, normalizedX: 0.88, normalizedY: 0.78, width: 62, height: 62, opacity: 0.82, fillColor: .neonGreen, controllerBinding: .buttonA),
                VirtualTouchControl(label: "CROUCH", symbolName: "figure.stand", type: .tapButton, shape: .circle, normalizedX: 0.76, normalizedY: 0.82, width: 60, height: 60, opacity: 0.82, fillColor: .cyan, controllerBinding: .buttonB),
                VirtualTouchControl(label: "BURST", symbolName: "bolt.fill", type: .macroTrigger, shape: .capsule, normalizedX: 0.84, normalizedY: 0.36, width: 86, height: 48, opacity: 0.90, fillColor: .purple, controllerBinding: .rightShoulder, linkedMacroId: quickBurstMacroId)
            ],
            crosshair: CrosshairConfig(
                isEnabled: true,
                style: .classicCross,
                size: 38,
                thickness: 2.5,
                centerGap: 6,
                showCenterDot: true,
                dotSize: 4,
                showOutline: true,
                opacity: 0.92,
                color: .neonGreen
            )
        )

        let mobaProfile = GameProfile(
            name: "MOBA Quick-Cast",
            gameTitle: "Arena MOBA",
            genre: .moba,
            notes: "Fast arc layout for 3 abilities, basic attack, and combo macro trigger.",
            controls: [
                VirtualTouchControl(label: "JOY", symbolName: "dpad.fill", type: .dPad, shape: .ring, normalizedX: 0.17, normalizedY: 0.74, width: 112, height: 112, opacity: 0.76, fillColor: .cyan),
                VirtualTouchControl(label: "ATK", symbolName: "burst.fill", type: .tapButton, shape: .circle, normalizedX: 0.86, normalizedY: 0.80, width: 82, height: 82, opacity: 0.90, fillColor: .crimson, controllerBinding: .buttonA),
                VirtualTouchControl(label: "S1", symbolName: "1.circle.fill", type: .tapButton, shape: .circle, normalizedX: 0.72, normalizedY: 0.80, width: 64, height: 64, opacity: 0.86, fillColor: .electricBlue, controllerBinding: .buttonX),
                VirtualTouchControl(label: "S2", symbolName: "2.circle.fill", type: .tapButton, shape: .circle, normalizedX: 0.78, normalizedY: 0.64, width: 64, height: 64, opacity: 0.86, fillColor: .electricBlue, controllerBinding: .buttonB),
                VirtualTouchControl(label: "ULT", symbolName: "star.fill", type: .tapButton, shape: .circle, normalizedX: 0.88, normalizedY: 0.52, width: 68, height: 68, opacity: 0.90, fillColor: .amber, controllerBinding: .rightShoulder),
                VirtualTouchControl(label: "COMBO", symbolName: "bolt.fill", type: .macroTrigger, shape: .capsule, normalizedX: 0.64, normalizedY: 0.62, width: 88, height: 48, opacity: 0.92, fillColor: .purple, controllerBinding: .buttonY, linkedMacroId: comboCastMacroId)
            ],
            crosshair: CrosshairConfig(
                isEnabled: true,
                style: .circleDot,
                size: 30,
                thickness: 2.0,
                centerGap: 4,
                showCenterDot: true,
                dotSize: 4,
                showOutline: true,
                opacity: 0.85,
                color: .cyan
            )
        )

        let rpgProfile = GameProfile(
            name: "Action RPG Dodge",
            gameTitle: "Open World RPG",
            genre: .actionRPG,
            notes: "Clean exploration and dodge/counter layout with minimal reticle.",
            controls: [
                VirtualTouchControl(label: "MOVE", symbolName: "dpad.fill", type: .dPad, shape: .ring, normalizedX: 0.18, normalizedY: 0.74, width: 108, height: 108, opacity: 0.72, fillColor: .electricBlue),
                VirtualTouchControl(label: "ATTACK", symbolName: "bolt.horizontal.fill", type: .tapButton, shape: .circle, normalizedX: 0.84, normalizedY: 0.74, width: 78, height: 78, opacity: 0.85, fillColor: .amber, controllerBinding: .buttonX),
                VirtualTouchControl(label: "DODGE", symbolName: "wind", type: .tapButton, shape: .circle, normalizedX: 0.70, normalizedY: 0.78, width: 66, height: 66, opacity: 0.85, fillColor: .neonGreen, controllerBinding: .buttonB),
                VirtualTouchControl(label: "SLIDE", symbolName: "figure.run", type: .macroTrigger, shape: .capsule, normalizedX: 0.82, normalizedY: 0.52, width: 84, height: 48, opacity: 0.88, fillColor: .purple, linkedMacroId: slideCancelMacroId)
            ],
            crosshair: CrosshairConfig(
                isEnabled: true,
                style: .centerDot,
                size: 18,
                thickness: 2,
                centerGap: 0,
                showCenterDot: true,
                dotSize: 6,
                showOutline: true,
                opacity: 0.80,
                color: .white
            )
        )

        return TouchForgeBackupPayload(
            schemaVersion: 1,
            exportedAt: Date(),
            profiles: [fpsProfile, mobaProfile, rpgProfile],
            macros: macros,
            settings: AppSettings(),
            activeProfileId: fpsProfile.id
        )
    }
}
