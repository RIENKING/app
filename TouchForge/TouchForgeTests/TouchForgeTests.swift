import XCTest
@testable import TouchForge

@MainActor
final class TouchForgeTests: XCTestCase {

    func testDefaultStateContainsStarterProfilesAndMacros() {
        let state = PersistenceService.makeDefaultState()
        XCTAssertGreaterThanOrEqual(state.profiles.count, 3)
        XCTAssertGreaterThanOrEqual(state.macros.count, 3)
        XCTAssertNotNil(state.activeProfileId)
    }

    func testBackupPayloadJSONRoundTrip() throws {
        let original = PersistenceService.makeDefaultState()
        let service = PersistenceService()
        let data = try service.encodeJSON(original)
        let decoded = try service.decodeJSON(TouchForgeBackupPayload.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, original.schemaVersion)
        XCTAssertEqual(decoded.profiles.count, original.profiles.count)
        XCTAssertEqual(decoded.macros.count, original.macros.count)
        XCTAssertEqual(decoded.settings, original.settings)
        XCTAssertEqual(decoded.activeProfileId, original.activeProfileId)
    }

    func testProfileDuplicationGeneratesNewIdentifiers() {
        let state = PersistenceService.makeDefaultState()
        let original = state.profiles[0]
        let copy = original.duplicated()

        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertEqual(copy.controls.count, original.controls.count)
        if let origCtrl = original.controls.first, let copyCtrl = copy.controls.first {
            XCTAssertNotEqual(origCtrl.id, copyCtrl.id)
        }
    }

    func testMacroEstimatedDurationScalesWithSpeed() {
        let macro = MacroProfile(
            name: "Timing Test",
            steps: [
                MacroStep(kind: .tap, label: "A", durationMs: 100, delayAfterMs: 100),
                MacroStep(kind: .tap, label: "B", durationMs: 100, delayAfterMs: 100)
            ],
            speedMultiplier: 2.0
        )
        XCTAssertEqual(macro.estimatedSinglePassMs, 200)
    }

    func testLocalizationReturnsTranslatedStringsAndFallsBackCleanly() {
        XCTAssertEqual(L10n.tr("tab.macros", language: .english), "Macros")
        XCTAssertEqual(L10n.tr("tab.crosshair", language: .vietnamese), "Tâm Ngắm")
        XCTAssertEqual(L10n.tr("tab.settings", language: .japanese), "設定")
        XCTAssertEqual(L10n.tr("nonexistent.key", language: .english), "nonexistent.key")
    }

    func testMacroEngineStartsAndStopsCleanly() async {
        let engine = MacroEngine()
        let macro = MacroProfile(
            name: "Quick Tap",
            steps: [MacroStep(kind: .tap, label: "Tap", durationMs: 20, delayAfterMs: 20)],
            repeatCount: 1
        )
        engine.start(macro: macro, hapticsEnabled: false, bleBridge: nil)
        XCTAssertTrue(engine.isRunning)
        engine.stop()
        XCTAssertFalse(engine.isRunning)
    }
}
