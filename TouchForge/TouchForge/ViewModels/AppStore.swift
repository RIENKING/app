import Foundation
import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    static let shared = AppStore()

    @Published var profiles: [GameProfile] = []
    @Published var macros: [MacroProfile] = []
    @Published var settings: AppSettings = AppSettings()
    @Published var activeProfileId: UUID?
    @Published var selectedTab: Int = 0
    @Published var toastMessage: String?

    let macroEngine = MacroEngine()
    let controllerService = GameControllerService()
    let bleBridge = BLEBridgeService()
    let pipHUD = PiPHUDService()

    private let persistence: PersistenceService
    private var cancellables = Set<AnyCancellable>()

    init(persistence: PersistenceService = .shared) {
        self.persistence = persistence
        loadInitialState()
        wireHardwareCallbacks()
        syncPiPHUD()
    }

    // MARK: - Localization Helper

    func t(_ key: String) -> String {
        L10n.tr(key, language: settings.language)
    }

    // MARK: - Active Profile

    var activeProfile: GameProfile {
        if let id = activeProfileId, let match = profiles.first(where: { $0.id == id }) {
            return match
        }
        return profiles.first ?? PersistenceService.makeDefaultState().profiles[0]
    }

    var activeProfileIndex: Int? {
        if let id = activeProfileId {
            return profiles.firstIndex(where: { $0.id == id })
        }
        return profiles.isEmpty ? nil : 0
    }

    // MARK: - Persistence

    private func loadInitialState() {
        let state = persistence.loadState()
        self.profiles = state.profiles
        self.macros = state.macros
        self.settings = state.settings
        self.activeProfileId = state.activeProfileId ?? state.profiles.first?.id
    }

    func save() {
        let payload = makeBackupPayload()
        try? persistence.saveState(payload)
        syncPiPHUD()
    }

    func makeBackupPayload() -> TouchForgeBackupPayload {
        TouchForgeBackupPayload(
            schemaVersion: 1,
            exportedAt: Date(),
            profiles: profiles,
            macros: macros,
            settings: settings,
            activeProfileId: activeProfileId
        )
    }

    func restoreBackup(_ payload: TouchForgeBackupPayload) {
        macroEngine.stop()
        profiles = payload.profiles.isEmpty ? PersistenceService.makeDefaultState().profiles : payload.profiles
        macros = payload.macros
        settings = payload.settings
        activeProfileId = payload.activeProfileId ?? profiles.first?.id
        save()
        showToast("Backup restored (\(profiles.count) profiles, \(macros.count) macros)")
    }

    func resetToDefaults() {
        macroEngine.stop()
        let defaults = PersistenceService.makeDefaultState()
        profiles = defaults.profiles
        macros = defaults.macros
        settings = defaults.settings
        activeProfileId = defaults.activeProfileId
        save()
        showToast("Reset to starter defaults")
    }

    // MARK: - Profile Operations

    func selectProfile(_ id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        activeProfileId = id
        HapticService.shared.selection(enabled: settings.hapticsEnabled)
        save()
    }

    func selectProfile(named name: String) -> Bool {
        guard let match = profiles.first(where: { $0.name.localizedCaseInsensitiveContains(name) }) else {
            return false
        }
        selectProfile(match.id)
        return true
    }

    func addProfile(_ profile: GameProfile) {
        profiles.insert(profile, at: 0)
        activeProfileId = profile.id
        save()
        showToast("Created '\(profile.name)'")
    }

    func updateProfile(_ profile: GameProfile) {
        guard let idx = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        var updated = profile
        updated.updatedAt = Date()
        profiles[idx] = updated
        save()
    }

    func duplicateProfile(_ profile: GameProfile) {
        let copy = profile.duplicated()
        profiles.insert(copy, at: 0)
        activeProfileId = copy.id
        save()
        showToast("Duplicated '\(profile.name)'")
    }

    func deleteProfile(_ id: UUID) {
        guard profiles.count > 1 else {
            showToast("At least one profile is required")
            return
        }
        profiles.removeAll(where: { $0.id == id })
        if activeProfileId == id {
            activeProfileId = profiles.first?.id
        }
        save()
    }

    func importProfile(from data: Data) throws -> GameProfile {
        var decoded = try persistence.decodeJSON(GameProfile.self, from: data)
        if profiles.contains(where: { $0.id == decoded.id }) {
            decoded.id = UUID()
        }
        decoded.updatedAt = Date()
        profiles.insert(decoded, at: 0)
        activeProfileId = decoded.id
        save()
        showToast("Imported '\(decoded.name)'")
        return decoded
    }

    // MARK: - Touch Controls on Active Profile

    func addControl(_ control: VirtualTouchControl) {
        guard let idx = activeProfileIndex else { return }
        profiles[idx].controls.append(control)
        profiles[idx].updatedAt = Date()
        HapticService.shared.impact(.light, enabled: settings.hapticsEnabled)
        save()
    }

    func updateControl(_ control: VirtualTouchControl) {
        guard let pIdx = activeProfileIndex,
              let cIdx = profiles[pIdx].controls.firstIndex(where: { $0.id == control.id }) else { return }
        profiles[pIdx].controls[cIdx] = control
        profiles[pIdx].updatedAt = Date()
        save()
    }

    func deleteControl(_ controlId: UUID) {
        guard let pIdx = activeProfileIndex else { return }
        profiles[pIdx].controls.removeAll(where: { $0.id == controlId })
        profiles[pIdx].updatedAt = Date()
        save()
    }

    func updateCrosshair(_ crosshair: CrosshairConfig) {
        guard let pIdx = activeProfileIndex else { return }
        profiles[pIdx].crosshair = crosshair
        profiles[pIdx].updatedAt = Date()
        save()
    }

    // MARK: - Macro Operations

    func addMacro(_ macro: MacroProfile) {
        macros.insert(macro, at: 0)
        save()
        showToast("Saved macro '\(macro.name)'")
    }

    func updateMacro(_ macro: MacroProfile) {
        guard let idx = macros.firstIndex(where: { $0.id == macro.id }) else { return }
        var updated = macro
        updated.updatedAt = Date()
        macros[idx] = updated
        save()
    }

    func duplicateMacro(_ macro: MacroProfile) {
        var copy = macro
        copy.id = UUID()
        copy.name = "\(macro.name) (Copy)"
        copy.steps = macro.steps.map { step in
            var s = step
            s.id = UUID()
            return s
        }
        copy.createdAt = Date()
        copy.updatedAt = Date()
        macros.insert(copy, at: 0)
        save()
    }

    func deleteMacro(_ id: UUID) {
        if macroEngine.activeMacroId == id {
            macroEngine.stop()
        }
        macros.removeAll(where: { $0.id == id })
        save()
    }

    func runMacro(_ macro: MacroProfile) {
        macroEngine.start(
            macro: macro,
            hapticsEnabled: settings.hapticsEnabled,
            bleBridge: bleBridge
        )
        syncPiPHUD()
    }

    func runMacro(id: UUID) {
        guard let macro = macros.first(where: { $0.id == id }) else { return }
        runMacro(macro)
    }

    func runMacro(named name: String) -> Bool {
        guard let macro = macros.first(where: { $0.name.localizedCaseInsensitiveContains(name) }) else {
            return false
        }
        runMacro(macro)
        return true
    }

    // MARK: - Hardware Callbacks & PiP Sync

    private func wireHardwareCallbacks() {
        controllerService.onButtonPressed = { [weak self] binding in
            guard let self else { return }
            HapticService.shared.impact(.light, enabled: self.settings.hapticsEnabled)

            // 1. Trigger any macro directly bound to this controller button
            if let boundMacro = self.macros.first(where: { $0.triggerBinding == binding }) {
                self.runMacro(boundMacro)
                return
            }

            // 2. Or trigger a macro linked to a virtual touch button bound to this controller button
            if let boundControl = self.activeProfile.controls.first(where: { $0.controllerBinding == binding }),
               let macroId = boundControl.linkedMacroId {
                self.runMacro(id: macroId)
            }
        }

        macroEngine.$isRunning
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncPiPHUD()
            }
            .store(in: &cancellables)
    }

    func syncPiPHUD() {
        let macroText = macroEngine.isRunning ? "Running: \(macroEngine.activeMacroName)" : "Idle"
        pipHUD.updateHUD(
            profileName: activeProfile.name,
            crosshair: activeProfile.crosshair,
            macroStatus: macroText
        )
    }

    func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if self.toastMessage == message {
                self.toastMessage = nil
            }
        }
    }
}
