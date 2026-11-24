import Foundation
import Combine

struct MacroCursorPulse: Identifiable, Equatable {
    let id = UUID()
    let x: Double
    let y: Double
    let endX: Double
    let endY: Double
    let kind: MacroActionKind
    let label: String
    let timestamp: Date = Date()
}

@MainActor
final class MacroEngine: ObservableObject {
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var activeMacroId: UUID?
    @Published private(set) var activeMacroName: String = ""
    @Published private(set) var currentStepIndex: Int?
    @Published private(set) var currentIteration: Int = 0
    @Published private(set) var totalIterations: Int = 0
    @Published private(set) var latestPulse: MacroCursorPulse?
    @Published private(set) var executionLog: [String] = []

    private var runTask: Task<Void, Never>?

    func start(
        macro: MacroProfile,
        hapticsEnabled: Bool,
        bleBridge: BLEBridgeService? = nil
    ) {
        stop()
        guard !macro.steps.isEmpty else { return }

        isRunning = true
        isPaused = false
        activeMacroId = macro.id
        activeMacroName = macro.name
        currentIteration = 0
        totalIterations = macro.isInfiniteLoop ? 0 : macro.repeatCount
        appendLog("Started '\(macro.name)' (\(macro.steps.count) steps)")

        runTask = Task { [weak self] in
            guard let self else { return }
            let speed = max(macro.speedMultiplier, 0.25)
            var iteration = 0

            while !Task.isCancelled {
                iteration += 1
                self.currentIteration = iteration

                for (index, step) in macro.steps.enumerated() {
                    if Task.isCancelled { break }
                    await self.waitWhilePaused()
                    if Task.isCancelled { break }

                    self.currentStepIndex = index
                    self.latestPulse = MacroCursorPulse(
                        x: step.startX,
                        y: step.startY,
                        endX: step.endX,
                        endY: step.endY,
                        kind: step.kind,
                        label: step.label
                    )

                    self.appendLog("Pass \(iteration) • Step \(index + 1): \(step.label) (\(step.kind.rawValue))")

                    switch step.kind {
                    case .hapticCue:
                        HapticService.shared.impact(.heavy, enabled: hapticsEnabled)
                    case .tap, .longPress, .swipe:
                        HapticService.shared.impact(.light, enabled: hapticsEnabled)
                        if let bleBridge, bleBridge.connectionState == .connected {
                            bleBridge.sendMacroStep(step)
                        }
                    case .bleHIDCommand:
                        if let bleBridge, bleBridge.connectionState == .connected {
                            bleBridge.sendMacroStep(step)
                        } else {
                            self.appendLog("BLE HID skipped (no external hardware bridge connected)")
                        }
                    case .delay:
                        break
                    }

                    let scaledDurationNs = UInt64(Double(step.durationMs) / speed * 1_000_000)
                    if scaledDurationNs > 0 {
                        try? await Task.sleep(nanoseconds: scaledDurationNs)
                    }

                    let scaledDelayNs = UInt64(Double(step.delayAfterMs) / speed * 1_000_000)
                    if scaledDelayNs > 0 {
                        try? await Task.sleep(nanoseconds: scaledDelayNs)
                    }
                }

                if Task.isCancelled { break }
                if !macro.isInfiniteLoop && iteration >= macro.repeatCount {
                    break
                }

                let loopDelayNs = UInt64(Double(macro.loopDelayMs) / speed * 1_000_000)
                if loopDelayNs > 0 {
                    try? await Task.sleep(nanoseconds: loopDelayNs)
                }
            }

            self.finishRun()
        }
    }

    func togglePause() {
        guard isRunning else { return }
        isPaused.toggle()
        appendLog(isPaused ? "Paused macro playback" : "Resumed macro playback")
    }

    func stop() {
        runTask?.cancel()
        runTask = nil
        if isRunning {
            appendLog("Stopped '\(activeMacroName)'")
        }
        finishRun()
    }

    func clearLog() {
        executionLog.removeAll()
    }

    private func waitWhilePaused() async {
        while isPaused && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    private func finishRun() {
        isRunning = false
        isPaused = false
        activeMacroId = nil
        currentStepIndex = nil
    }

    private func appendLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SS"
        let line = "[\(formatter.string(from: Date()))] \(message)"
        executionLog.insert(line, at: 0)
        if executionLog.count > 40 {
            executionLog.removeLast(executionLog.count - 40)
        }
    }
}
