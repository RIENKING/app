import SwiftUI

struct MacroListView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showRecorder = false
    @State private var editingMacro: MacroProfile?
    @State private var showExecutionLog = false

    var body: some View {
        NavigationStack {
            List {
                if store.macroEngine.isRunning {
                    activePlaybackSection
                }

                Section {
                    Button {
                        showRecorder = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "record.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.t("macro.record"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Tap, hold, or swipe on the live capture pad to record coordinates and real timing.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Saved Macro Profiles (\(store.macros.count))") {
                    if store.macros.isEmpty {
                        ContentUnavailableView(
                            "No Macros Yet",
                            systemImage: "bolt.slash",
                            description: Text("Tap + to build a custom macro or use Record Gestures to capture touch sequences.")
                        )
                    } else {
                        ForEach(store.macros) { macro in
                            macroRow(macro)
                        }
                        .onDelete { offsets in
                            for idx in offsets {
                                store.deleteMacro(store.macros[idx].id)
                            }
                        }
                    }
                }

                if !store.macroEngine.executionLog.isEmpty {
                    Section {
                        DisclosureGroup("Execution Log (\(store.macroEngine.executionLog.count))", isExpanded: $showExecutionLog) {
                            ForEach(store.macroEngine.executionLog.prefix(12), id: \.self) { entry in
                                Text(entry)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            Button("Clear Log", role: .destructive) {
                                store.macroEngine.clearLog()
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle(store.t("macro.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let newMacro = MacroProfile(
                            name: "Macro \(store.macros.count + 1)",
                            steps: [
                                MacroStep(kind: .tap, label: "Step 1", startX: 0.5, startY: 0.5, durationMs: 60, delayAfterMs: 120)
                            ]
                        )
                        store.addMacro(newMacro)
                        editingMacro = newMacro
                    } label: {
                        Label(store.t("macro.new"), systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showRecorder) {
                MacroRecorderSheet { recordedSteps, name in
                    let macro = MacroProfile(
                        name: name,
                        notes: "Recorded \(recordedSteps.count) gestures on capture pad.",
                        steps: recordedSteps
                    )
                    store.addMacro(macro)
                }
            }
            .sheet(item: $editingMacro) { macro in
                MacroEditorView(macro: macro)
            }
        }
    }

    private var activePlaybackSection: some View {
        Section("Live Macro Playback") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "bolt.circle.fill")
                        .foregroundStyle(.purple)
                    Text(store.macroEngine.activeMacroName)
                        .font(.headline)
                    Spacer()
                    if let stepIdx = store.macroEngine.currentStepIndex {
                        Text("Step \(stepIdx + 1)")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.purple.opacity(0.18), in: Capsule())
                    }
                }

                HStack {
                    Text(store.macroEngine.totalIterations == 0
                         ? "Loop pass #\(store.macroEngine.currentIteration) (∞)"
                         : "Pass \(store.macroEngine.currentIteration) of \(store.macroEngine.totalIterations)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        store.macroEngine.togglePause()
                    } label: {
                        Label(
                            store.macroEngine.isPaused ? store.t("macro.resume") : store.t("macro.pause"),
                            systemImage: store.macroEngine.isPaused ? "play.fill" : "pause.fill"
                        )
                        .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        store.macroEngine.stop()
                    } label: {
                        Label(store.t("macro.stop"), systemImage: "stop.fill")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func macroRow(_ macro: MacroProfile) -> some View {
        let isRunningThis = store.macroEngine.isRunning && store.macroEngine.activeMacroId == macro.id

        return HStack(spacing: 12) {
            Button {
                editingMacro = macro
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(macro.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if macro.isInfiniteLoop {
                            Image(systemName: "infinity")
                                .font(.caption)
                                .foregroundStyle(.purple)
                        }
                    }

                    HStack(spacing: 10) {
                        Label("\(macro.steps.count) steps", systemImage: "list.bullet")
                        Label("\(macro.estimatedSinglePassMs) ms", systemImage: "timer")
                        if macro.triggerBinding != .none {
                            Label(macro.triggerBinding.label, systemImage: "gamecontroller")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                if isRunningThis {
                    store.macroEngine.stop()
                } else {
                    store.runMacro(macro)
                }
            } label: {
                Image(systemName: isRunningThis ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isRunningThis ? .red : store.settings.accentTheme.color)
            }
            .buttonStyle(.plain)
        }
        .swipeActions(edge: .leading) {
            Button {
                store.duplicateMacro(macro)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            .tint(.blue)
        }
    }
}
