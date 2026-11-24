import SwiftUI

struct TouchStudioView: View {
    @EnvironmentObject private var store: AppStore
    @State private var isTestMode = false
    @State private var selectedControlId: UUID?
    @State private var showInspector = false
    @State private var showAddMenu = false
    @State private var tapCount = 0
    @State private var lastTriggeredLabel = "Ready"

    private var selectedControl: VirtualTouchControl? {
        guard let id = selectedControlId else { return nil }
        return store.activeProfile.controls.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar
                InteractiveCanvasView(
                    controls: store.activeProfile.controls,
                    crosshair: store.activeProfile.crosshair,
                    isTestMode: isTestMode,
                    selectedControlId: $selectedControlId,
                    snapToGrid: store.settings.snapToGrid,
                    gridSize: store.settings.gridSize,
                    showCoordinates: store.settings.showCoordinatesOverlay,
                    showRipples: store.settings.showTestRipples,
                    activeControllerButtons: store.controllerService.activeButtons,
                    latestMacroPulse: store.macroEngine.latestPulse,
                    onMoveControl: { control, nx, ny in
                        var updated = control
                        updated.normalizedX = nx
                        updated.normalizedY = ny
                        store.updateControl(updated)
                    },
                    onResizeControl: { control, newW, newH in
                        var updated = control
                        updated.width = min(max(newW, 44), 170)
                        updated.height = min(max(newH, 44), 170)
                        store.updateControl(updated)
                    },
                    onTriggerControl: { control in
                        tapCount += 1
                        lastTriggeredLabel = control.label
                        HapticService.shared.impact(control.haptic, enabled: store.settings.hapticsEnabled)
                        if let macroId = control.linkedMacroId {
                            store.runMacro(id: macroId)
                        }
                    }
                )
                bottomControlBar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(store.t("touch.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(store.profiles) { profile in
                            Button {
                                store.selectProfile(profile.id)
                                selectedControlId = nil
                            } label: {
                                if profile.id == store.activeProfile.id {
                                    Label(profile.name, systemImage: "checkmark")
                                } else {
                                    Text(profile.name)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(store.activeProfile.name)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(VirtualControlType.allCases) { type in
                            Button {
                                addNewControl(of: type)
                            } label: {
                                Label(store.t(type.displayNameKey), systemImage: type.defaultSymbol)
                            }
                        }
                    } label: {
                        Label(store.t("touch.addControl"), systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showInspector) {
                if let control = selectedControl {
                    ControlInspectorSheet(control: control)
                }
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Picker("Mode", selection: $isTestMode) {
                Text(store.t("touch.mode.edit")).tag(false)
                Text(store.t("touch.mode.test")).tag(true)
            }
            .pickerStyle(.segmented)

            if isTestMode {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(.green)
                    Text("\(tapCount) • \(lastTriggeredLabel)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemGroupedBackground), in: Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var bottomControlBar: some View {
        HStack(spacing: 12) {
            if let control = selectedControl, !isTestMode {
                VStack(alignment: .leading, spacing: 2) {
                    Text(control.label)
                        .font(.subheadline.weight(.bold))
                    Text("\(Int(control.width))×\(Int(control.height))pt • \(Int(control.opacity * 100))% opacity")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showInspector = true
                } label: {
                    Label("Customize", systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    store.deleteControl(control.id)
                    selectedControlId = nil
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
            } else if isTestMode {
                HStack {
                    Label("Tap or hold buttons to test layout, haptics, and linked macros.", systemImage: "hand.tap")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if store.macroEngine.isRunning {
                        Button(role: .destructive) {
                            store.macroEngine.stop()
                        } label: {
                            Label(store.t("macro.stop"), systemImage: "stop.fill")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Reset") {
                            tapCount = 0
                            lastTriggeredLabel = "Ready"
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
            } else {
                Label("Tap a button to customize, drag to reposition, or pinch to resize.", systemImage: "hand.draw")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func addNewControl(of type: VirtualControlType) {
        let count = store.activeProfile.controls.count + 1
        let isPad = (type == .dPad || type == .aimPad || type == .swipePad)
        let newControl = VirtualTouchControl(
            label: type == .macroTrigger ? "MACRO \(count)" : "BTN \(count)",
            symbolName: type.defaultSymbol,
            type: type,
            shape: isPad ? .ring : (type == .macroTrigger ? .capsule : .circle),
            normalizedX: 0.5,
            normalizedY: 0.5,
            width: isPad ? 108 : (type == .macroTrigger ? 92 : 68),
            height: isPad ? 108 : (type == .macroTrigger ? 48 : 68),
            opacity: 0.86,
            fillColor: type == .macroTrigger ? .purple : .electricBlue
        )
        store.addControl(newControl)
        selectedControlId = newControl.id
        isTestMode = false
    }
}
