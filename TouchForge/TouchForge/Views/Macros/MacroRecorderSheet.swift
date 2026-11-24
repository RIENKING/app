import SwiftUI

struct MacroRecorderSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var initialName: String = "Recorded Macro"
    let onComplete: ([MacroStep], String) -> Void

    @State private var macroName: String = ""
    @State private var isRecording: Bool = false
    @State private var recordedSteps: [MacroStep] = []
    @State private var touchStartTime: Date?
    @State private var touchStartPoint: CGPoint?
    @State private var lastTouchEndTime: Date?
    @State private var liveDragPoint: CGPoint?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("Macro Name", text: $macroName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                // Live gesture capture pad
                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(red: 0.08, green: 0.10, blue: 0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(isRecording ? Color.red : Color.secondary.opacity(0.35), lineWidth: isRecording ? 3 : 1.5)
                            )

                        // Previously recorded gestures visualized
                        ForEach(Array(recordedSteps.enumerated()), id: \.element.id) { idx, step in
                            let sPt = CGPoint(x: step.startX * geo.size.width, y: step.startY * geo.size.height)
                            let ePt = CGPoint(x: step.endX * geo.size.width, y: step.endY * geo.size.height)

                            if step.kind == .swipe {
                                Path { p in
                                    p.move(to: sPt)
                                    p.addLine(to: ePt)
                                }
                                .stroke(Color.cyan.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            }

                            ZStack {
                                Circle()
                                    .fill(step.kind == .longPress ? Color.orange : Color.blue)
                                    .frame(width: 26, height: 26)
                                Text("\(idx + 1)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                            .position(sPt)
                        }

                        // Active stroke preview
                        if let start = touchStartPoint, let current = liveDragPoint {
                            Path { p in
                                p.move(to: start)
                                p.addLine(to: current)
                            }
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        }

                        if recordedSteps.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: isRecording ? "record.circle.fill" : "hand.draw.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(isRecording ? .red : .secondary)
                                Text(isRecording
                                     ? "Tap, hold, or swipe anywhere on this pad..."
                                     : "Press 'Start Recording' below, then perform your gesture sequence.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.75))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard isRecording else { return }
                                if touchStartTime == nil {
                                    touchStartTime = Date()
                                    touchStartPoint = value.startLocation
                                }
                                liveDragPoint = value.location
                            }
                            .onEnded { value in
                                guard isRecording,
                                      let startTime = touchStartTime,
                                      let startPt = touchStartPoint else { return }

                                let now = Date()
                                let durationMs = max(25, Int(now.timeIntervalSince(startTime) * 1000))
                                let dx = value.location.x - startPt.x
                                let dy = value.location.y - startPt.y
                                let distance = hypot(dx, dy)

                                // Update previous step's delayAfterMs based on real gap
                                if let prevEnd = lastTouchEndTime, !recordedSteps.isEmpty {
                                    let gapMs = max(20, Int(startTime.timeIntervalSince(prevEnd) * 1000))
                                    recordedSteps[recordedSteps.count - 1].delayAfterMs = min(gapMs, 5000)
                                }

                                let kind: MacroActionKind
                                if distance > 24 {
                                    kind = .swipe
                                } else if durationMs >= 280 {
                                    kind = .longPress
                                } else {
                                    kind = .tap
                                }

                                let step = MacroStep(
                                    kind: kind,
                                    label: "\(kind.rawValue.capitalized) \(recordedSteps.count + 1)",
                                    startX: Double(startPt.x / max(geo.size.width, 1)),
                                    startY: Double(startPt.y / max(geo.size.height, 1)),
                                    endX: Double(value.location.x / max(geo.size.width, 1)),
                                    endY: Double(value.location.y / max(geo.size.height, 1)),
                                    durationMs: durationMs,
                                    delayAfterMs: 120
                                )
                                recordedSteps.append(step)
                                HapticService.shared.impact(.light, enabled: store.settings.hapticsEnabled)

                                lastTouchEndTime = now
                                touchStartTime = nil
                                touchStartPoint = nil
                                liveDragPoint = nil
                            }
                    )
                }
                .padding(.horizontal)

                // Recorder controls
                HStack(spacing: 12) {
                    Button {
                        isRecording.toggle()
                        if isRecording {
                            lastTouchEndTime = nil
                        }
                    } label: {
                        Label(isRecording ? "Stop Recording" : "Start Recording",
                              systemImage: isRecording ? "stop.circle.fill" : "record.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isRecording ? .gray : .red)

                    Button("Clear") {
                        recordedSteps.removeAll()
                        lastTouchEndTime = nil
                    }
                    .buttonStyle(.bordered)
                    .disabled(recordedSteps.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .onAppear {
                if macroName.isEmpty {
                    macroName = initialName
                }
            }
            .navigationTitle("Macro Recorder (\(recordedSteps.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let finalName = macroName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? "Recorded Macro"
                            : macroName
                        onComplete(recordedSteps, finalName)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(recordedSteps.isEmpty)
                }
            }
        }
    }
}
