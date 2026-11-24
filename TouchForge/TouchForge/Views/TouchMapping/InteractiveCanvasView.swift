import SwiftUI

struct TouchRipple: Identifiable {
    let id = UUID()
    let point: CGPoint
    let color: Color
}

struct InteractiveCanvasView: View {
    let controls: [VirtualTouchControl]
    let crosshair: CrosshairConfig
    let isTestMode: Bool
    @Binding var selectedControlId: UUID?
    let snapToGrid: Bool
    let gridSize: Int
    let showCoordinates: Bool
    let showRipples: Bool
    let activeControllerButtons: Set<ControllerBinding>
    let latestMacroPulse: MacroCursorPulse?

    let onMoveControl: (VirtualTouchControl, Double, Double) -> Void
    let onResizeControl: (VirtualTouchControl, Double, Double) -> Void
    let onTriggerControl: (VirtualTouchControl) -> Void

    @State private var pressedControlIds: Set<UUID> = []
    @State private var ripples: [TouchRipple] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dark tactical canvas with grid
                canvasBackground(size: geo.size)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isTestMode {
                            selectedControlId = nil
                        }
                    }

                // Active profile crosshair overlay
                CrosshairRenderer(config: crosshair)
                    .frame(width: geo.size.width, height: geo.size.height)

                // Live macro replay visual cursor pulse
                if let pulse = latestMacroPulse {
                    macroPulseOverlay(pulse: pulse, in: geo.size)
                }

                // Touch test ripples
                if showRipples {
                    ForEach(ripples) { ripple in
                        Circle()
                            .stroke(ripple.color.opacity(0.8), lineWidth: 2.5)
                            .frame(width: 64, height: 64)
                            .position(ripple.point)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                // Virtual touch controls
                ForEach(controls) { control in
                    let pos = CGPoint(
                        x: control.normalizedX * geo.size.width,
                        y: control.normalizedY * geo.size.height
                    )
                    let isSelected = !isTestMode && selectedControlId == control.id
                    let isControllerPressed = control.controllerBinding != .none && activeControllerButtons.contains(control.controllerBinding)
                    let isPressed = pressedControlIds.contains(control.id) || isControllerPressed

                    VirtualControlNode(
                        control: control,
                        isSelected: isSelected,
                        isPressed: isPressed,
                        showCoordinates: showCoordinates && !isTestMode
                    )
                    .position(pos)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if isTestMode {
                                    if !pressedControlIds.contains(control.id) {
                                        pressedControlIds.insert(control.id)
                                        onTriggerControl(control)
                                        spawnRipple(at: pos, color: control.fillColor.swiftUIColor)
                                    }
                                } else {
                                    selectedControlId = control.id
                                    guard !control.isLocked else { return }
                                    var targetX = value.location.x
                                    var targetY = value.location.y
                                    if snapToGrid && gridSize > 1 {
                                        let step = CGFloat(gridSize)
                                        targetX = (targetX / step).rounded() * step
                                        targetY = (targetY / step).rounded() * step
                                    }
                                    let nx = min(max(Double(targetX / max(geo.size.width, 1)), 0.05), 0.95)
                                    let ny = min(max(Double(targetY / max(geo.size.height, 1)), 0.05), 0.95)
                                    onMoveControl(control, nx, ny)
                                }
                            }
                            .onEnded { _ in
                                if isTestMode {
                                    pressedControlIds.remove(control.id)
                                }
                            }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { scale in
                                guard !isTestMode, !control.isLocked else { return }
                                selectedControlId = control.id
                                let delta = Double(scale)
                                let newW = min(max(control.width * (0.85 + 0.15 * delta), 44), 170)
                                let newH = min(max(control.height * (0.85 + 0.15 * delta), 44), 170)
                                onResizeControl(control, newW, newH)
                            }
                    )
                }
            }
            .clipped()
        }
    }

    private func canvasBackground(size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.08, blue: 0.12), Color(red: 0.10, green: 0.13, blue: 0.19)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, sz in
                let step = CGFloat(max(gridSize, 12)) * 2
                var path = Path()
                for x in stride(from: 0, through: sz.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: sz.height))
                }
                for y in stride(from: 0, through: sz.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: sz.width, y: y))
                }
                context.stroke(path, with: .color(.white.opacity(0.06)), lineWidth: 1)

                // Center guide axes
                var centerPath = Path()
                centerPath.move(to: CGPoint(x: sz.width / 2, y: 0))
                centerPath.addLine(to: CGPoint(x: sz.width / 2, y: sz.height))
                centerPath.move(to: CGPoint(x: 0, y: sz.height / 2))
                centerPath.addLine(to: CGPoint(x: sz.width, y: sz.height / 2))
                context.stroke(centerPath, with: .color(.cyan.opacity(0.14)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
    }

    @ViewBuilder
    private func macroPulseOverlay(pulse: MacroCursorPulse, in size: CGSize) -> some View {
        let start = CGPoint(x: pulse.x * size.width, y: pulse.y * size.height)
        let end = CGPoint(x: pulse.endX * size.width, y: pulse.endY * size.height)

        ZStack {
            if pulse.kind == .swipe {
                Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                .stroke(Color.purple, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [6, 4]))
            }

            VStack(spacing: 2) {
                Circle()
                    .fill(Color.purple.opacity(0.45))
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                Text(pulse.label)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple, in: Capsule())
            }
            .position(start)
        }
        .allowsHitTesting(false)
    }

    private func spawnRipple(at point: CGPoint, color: Color) {
        guard showRipples else { return }
        let ripple = TouchRipple(point: point, color: color)
        withAnimation(.easeOut(duration: 0.25)) {
            ripples.append(ripple)
        }
        Task {
            try? await Task.sleep(nanoseconds: 280_000_000)
            withAnimation(.easeOut(duration: 0.2)) {
                ripples.removeAll(where: { $0.id == ripple.id })
            }
        }
    }
}

private struct VirtualControlNode: View {
    let control: VirtualTouchControl
    let isSelected: Bool
    let isPressed: Bool
    let showCoordinates: Bool

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                shapeFill
                VStack(spacing: 2) {
                    Image(systemName: control.symbolName)
                        .font(.system(size: min(control.width, control.height) * 0.28, weight: .semibold))
                    Text(control.label)
                        .font(.system(size: max(9, min(control.width, control.height) * 0.16), weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if control.controllerBinding != .none {
                        Text(control.controllerBinding.label)
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.black.opacity(0.45), in: Capsule())
                    }
                }
                .foregroundStyle(control.textColor.swiftUIColor)
                .padding(6)
            }
            .frame(width: control.width, height: control.height)
            .opacity(isPressed ? 1.0 : control.opacity)
            .scaleEffect(isPressed ? 0.91 : 1.0)
            .overlay(selectionRing)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)

            if showCoordinates && isSelected {
                Text("\(Int(control.normalizedX * 100))%, \(Int(control.normalizedY * 100))%")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.7), in: Capsule())
            }
        }
    }

    @ViewBuilder
    private var shapeFill: some View {
        let baseColor = control.fillColor.swiftUIColor
        switch control.shape {
        case .circle:
            Circle()
                .fill(baseColor.opacity(0.42))
                .overlay(Circle().stroke(baseColor, lineWidth: control.borderWidth))
        case .roundedRect:
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(baseColor.opacity(0.42))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(baseColor, lineWidth: control.borderWidth))
        case .capsule:
            Capsule()
                .fill(baseColor.opacity(0.42))
                .overlay(Capsule().stroke(baseColor, lineWidth: control.borderWidth))
        case .ring:
            Circle()
                .fill(baseColor.opacity(0.16))
                .overlay(Circle().stroke(baseColor, style: StrokeStyle(lineWidth: max(2.5, control.borderWidth), dash: [8, 4])))
        }
    }

    @ViewBuilder
    private var selectionRing: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: control.shape == .circle || control.shape == .ring ? control.width / 2 : 16)
                .stroke(Color.yellow, style: StrokeStyle(lineWidth: 2.5, dash: [5, 3]))
                .padding(-4)
        }
    }
}
