import SwiftUI

struct MacroEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State var macro: MacroProfile
    @State private var showRecorderAppend = false
    @State private var editingStep: MacroStep?

    var body: some View {
        NavigationStack {
            Form {
                Section("Macro Details") {
                    TextField("Macro Name", text: $macro.name)
                    TextField("Notes", text: $macro.notes)
                    Picker("Controller Trigger", selection: $macro.triggerBinding) {
                        ForEach(ControllerBinding.allCases) { binding in
                            Text(binding.label).tag(binding)
                        }
                    }
                }

                Section("Repeat, Loop & Speed") {
                    Toggle(store.t("macro.infiniteLoop"), isOn: $macro.isInfiniteLoop)

                    if !macro.isInfiniteLoop {
                        Stepper("\(store.t("macro.repeat")): \(macro.repeatCount)×", value: $macro.repeatCount, in: 1...100)
                    }

                    Stepper("\(store.t("macro.loopDelay")): \(macro.loopDelayMs) ms", value: $macro.loopDelayMs, in: 0...5000, step: 50)

                    VStack(alignment: .leading) {
                        HStack {
                            Text(store.t("macro.speed"))
                            Spacer()
                            Text(String(format: "%.2fx", macro.speedMultiplier))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $macro.speedMultiplier, in: 0.25...2.5, step: 0.05)
                    }
                }

                Section {
                    if macro.steps.isEmpty {
                        Text("No steps yet. Add a step or record gestures.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(macro.steps.enumerated()), id: \.element.id) { index, step in
                            let isActiveStep = store.macroEngine.activeMacroId == macro.id && store.macroEngine.currentStepIndex == index
                            Button {
                                editingStep = step
                            } label: {
                                HStack(spacing: 10) {
                                    Text("\(index + 1)")
                                        .font(.caption.monospacedDigit().weight(.bold))
                                        .frame(width: 24, height: 24)
                                        .background(
                                            (isActiveStep ? Color.purple : Color.secondary.opacity(0.2)),
                                            in: Circle()
                                        )
                                        .foregroundStyle(isActiveStep ? .white : .primary)

                                    Image(systemName: step.kind.systemImage)
                                        .foregroundStyle(store.settings.accentTheme.color)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(step.label)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text("\(store.t(step.kind.displayNameKey)) • \(step.durationMs)ms dur • \(step.delayAfterMs)ms wait")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            macro.steps.remove(atOffsets: offsets)
                        }
                        .onMove { source, destination in
                            macro.steps.move(fromOffsets: source, toOffset: destination)
                        }
                    }

                    Menu {
                        ForEach(MacroActionKind.allCases) { kind in
                            Button {
                                let step = MacroStep(
                                    kind: kind,
                                    label: "\(store.t(kind.displayNameKey)) \(macro.steps.count + 1)",
                                    durationMs: kind == .longPress ? 350 : (kind == .delay ? 0 : 60),
                                    delayAfterMs: kind == .delay ? 300 : 120
                                )
                                macro.steps.append(step)
                            } label: {
                                Label(store.t(kind.displayNameKey), systemImage: kind.systemImage)
                            }
                        }
                    } label: {
                        Label("Add Action Step", systemImage: "plus.circle")
                    }

                    Button {
                        showRecorderAppend = true
                    } label: {
                        Label("Record & Append Gestures", systemImage: "record.circle")
                            .foregroundStyle(.red)
                    }
                } header: {
                    HStack {
                        Text("\(store.t("macro.steps")) (\(macro.steps.count))")
                        Spacer()
                        EditButton()
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        store.updateMacro(macro)
                        store.runMacro(macro)
                    } label: {
                        Label("Test Replay Macro", systemImage: "play.fill")
                    }
                    .disabled(macro.steps.isEmpty)
                }
            }
            .navigationTitle("Edit Macro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateMacro(macro)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showRecorderAppend) {
                MacroRecorderSheet(initialName: macro.name) { newSteps, _ in
                    macro.steps.append(contentsOf: newSteps)
                }
            }
            .sheet(item: $editingStep) { step in
                MacroStepInspectorSheet(step: step) { updated in
                    if let idx = macro.steps.firstIndex(where: { $0.id == updated.id }) {
                        macro.steps[idx] = updated
                    }
                }
            }
        }
    }
}

private struct MacroStepInspectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var step: MacroStep
    let onSave: (MacroStep) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Step Action") {
                    TextField("Step Label", text: $step.label)
                    Picker("Kind", selection: $step.kind) {
                        ForEach(MacroActionKind.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                }

                Section("Timing") {
                    Stepper("Duration: \(step.durationMs) ms", value: $step.durationMs, in: 0...5000, step: 20)
                    Stepper("Delay After: \(step.delayAfterMs) ms", value: $step.delayAfterMs, in: 0...10000, step: 25)
                }

                if step.kind == .tap || step.kind == .longPress || step.kind == .swipe {
                    Section("Coordinates (Normalized 0% - 100%)") {
                        VStack(alignment: .leading) {
                            Text("Start X: \(Int(step.startX * 100))%").font(.caption)
                            Slider(value: $step.startX, in: 0...1)
                        }
                        VStack(alignment: .leading) {
                            Text("Start Y: \(Int(step.startY * 100))%").font(.caption)
                            Slider(value: $step.startY, in: 0...1)
                        }
                        if step.kind == .swipe {
                            VStack(alignment: .leading) {
                                Text("End X: \(Int(step.endX * 100))%").font(.caption)
                                Slider(value: $step.endX, in: 0...1)
                            }
                            VStack(alignment: .leading) {
                                Text("End Y: \(Int(step.endY * 100))%").font(.caption)
                                Slider(value: $step.endY, in: 0...1)
                            }
                        }
                    }
                }

                if step.kind == .bleHIDCommand {
                    Section("BLE HID Bridge Payload") {
                        TextField("Command / Key Payload (e.g. SPACE)", text: $step.hidPayload)
                            .autocorrectionDisabled()
                    }
                }
            }
            .navigationTitle("Edit Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(step)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
