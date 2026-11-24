import Foundation
import AppIntents

/// Official Apple AppIntents integration enabling iPhone Action Button,
/// Back Tap, Siri, and Apple Shortcuts to switch TouchForge profiles or run macros.

struct SwitchProfileIntent: AppIntent {
    static var title: LocalizedStringResource = "Switch TouchForge Profile"
    static var description = IntentDescription("Activates a saved game profile in TouchForge.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Profile Name")
    var profileName: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let ok = AppStore.shared.selectProfile(named: profileName)
        if ok {
            return .result(dialog: "Switched TouchForge profile to \(AppStore.shared.activeProfile.name).")
        } else {
            return .result(dialog: "No TouchForge profile matched '\(profileName)'.")
        }
    }
}

struct RunMacroIntent: AppIntent {
    static var title: LocalizedStringResource = "Run TouchForge Macro"
    static var description = IntentDescription("Runs a saved macro sequence in TouchForge (and forwards to BLE HID bridge if connected).")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Macro Name")
    var macroName: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let ok = AppStore.shared.runMacro(named: macroName)
        if ok {
            return .result(dialog: "Running macro '\(macroName)'.")
        } else {
            return .result(dialog: "No macro matched '\(macroName)'.")
        }
    }
}

struct StopMacroIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Active TouchForge Macro"
    static var description = IntentDescription("Stops any currently looping or running macro in TouchForge.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppStore.shared.macroEngine.stop()
        return .result(dialog: "Stopped active TouchForge macro.")
    }
}

struct TouchForgeShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SwitchProfileIntent(),
            phrases: [
                "Switch profile in \(.applicationName)",
                "Load game profile in \(.applicationName)"
            ],
            shortTitle: "Switch Profile",
            systemImageName: "rectangle.stack.fill"
        )
        AppShortcut(
            intent: RunMacroIntent(),
            phrases: [
                "Run macro in \(.applicationName)",
                "Start macro in \(.applicationName)"
            ],
            shortTitle: "Run Macro",
            systemImageName: "bolt.fill"
        )
        AppShortcut(
            intent: StopMacroIntent(),
            phrases: [
                "Stop macro in \(.applicationName)"
            ],
            shortTitle: "Stop Macro",
            systemImageName: "stop.circle.fill"
        )
    }
}
