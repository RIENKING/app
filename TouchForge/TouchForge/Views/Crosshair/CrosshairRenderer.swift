import SwiftUI

struct CrosshairRenderer: View {
    let config: CrosshairConfig
    var scale: CGFloat = 1.0

    var body: some View {
        if config.isEnabled {
            Canvas { context, size in
                let center = CGPoint(
                    x: size.width / 2 + CGFloat(config.offsetX) * scale,
                    y: size.height / 2 + CGFloat(config.offsetY) * scale
                )
                let arm = CGFloat(config.size / 2.0) * scale
                let gap = CGFloat(config.centerGap) * scale
                let lineW = max(1.0, CGFloat(config.thickness) * scale)
                let dotD = max(2.0, CGFloat(config.dotSize) * scale)
                let mainColor = config.color.swiftUIColor.opacity(config.opacity)
                let outlineColor = Color.black.opacity(min(0.85, config.opacity))

                func strokePath(_ path: Path) {
                    if config.showOutline {
                        context.stroke(
                            path,
                            with: .color(outlineColor),
                            style: StrokeStyle(lineWidth: lineW + 2.0 * scale, lineCap: .round, lineJoin: .round)
                        )
                    }
                    context.stroke(
                        path,
                        with: .color(mainColor),
                        style: StrokeStyle(lineWidth: lineW, lineCap: .round, lineJoin: .round)
                    )
                }

                var path = Path()

                switch config.style {
                case .classicCross:
                    path.move(to: CGPoint(x: center.x - arm, y: center.y))
                    path.addLine(to: CGPoint(x: center.x - gap, y: center.y))
                    path.move(to: CGPoint(x: center.x + gap, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + arm, y: center.y))
                    path.move(to: CGPoint(x: center.x, y: center.y - arm))
                    path.addLine(to: CGPoint(x: center.x, y: center.y - gap))
                    path.move(to: CGPoint(x: center.x, y: center.y + gap))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + arm))
                    strokePath(path)

                case .centerDot:
                    break

                case .circleDot:
                    let rect = CGRect(x: center.x - arm, y: center.y - arm, width: arm * 2, height: arm * 2)
                    path.addEllipse(in: rect)
                    strokePath(path)

                case .tShape:
                    path.move(to: CGPoint(x: center.x - arm, y: center.y))
                    path.addLine(to: CGPoint(x: center.x - gap, y: center.y))
                    path.move(to: CGPoint(x: center.x + gap, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + arm, y: center.y))
                    path.move(to: CGPoint(x: center.x, y: center.y + gap))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + arm))
                    strokePath(path)

                case .chevron:
                    path.move(to: CGPoint(x: center.x - arm * 0.75, y: center.y + arm * 0.55))
                    path.addLine(to: CGPoint(x: center.x, y: center.y - arm * 0.25))
                    path.addLine(to: CGPoint(x: center.x + arm * 0.75, y: center.y + arm * 0.55))
                    strokePath(path)

                case .brackets:
                    let b = arm * 0.85
                    let leg = arm * 0.38
                    // Left bracket
                    path.move(to: CGPoint(x: center.x - b + leg, y: center.y - b))
                    path.addLine(to: CGPoint(x: center.x - b, y: center.y - b))
                    path.addLine(to: CGPoint(x: center.x - b, y: center.y + b))
                    path.addLine(to: CGPoint(x: center.x - b + leg, y: center.y + b))
                    // Right bracket
                    path.move(to: CGPoint(x: center.x + b - leg, y: center.y - b))
                    path.addLine(to: CGPoint(x: center.x + b, y: center.y - b))
                    path.addLine(to: CGPoint(x: center.x + b, y: center.y + b))
                    path.addLine(to: CGPoint(x: center.x + b - leg, y: center.y + b))
                    strokePath(path)

                case .sniperReticle:
                    let ring = CGRect(x: center.x - arm, y: center.y - arm, width: arm * 2, height: arm * 2)
                    path.addEllipse(in: ring)
                    path.move(to: CGPoint(x: center.x - arm * 1.25, y: center.y))
                    path.addLine(to: CGPoint(x: center.x - gap, y: center.y))
                    path.move(to: CGPoint(x: center.x + gap, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + arm * 1.25, y: center.y))
                    path.move(to: CGPoint(x: center.x, y: center.y - arm * 1.25))
                    path.addLine(to: CGPoint(x: center.x, y: center.y - gap))
                    path.move(to: CGPoint(x: center.x, y: center.y + gap))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + arm * 1.25))
                    // Mil-dot ticks
                    for tick in [0.45, 0.72] {
                        let d = arm * tick
                        let tickHalf = max(2.0, 4.0 * scale)
                        path.move(to: CGPoint(x: center.x - tickHalf, y: center.y + d))
                        path.addLine(to: CGPoint(x: center.x + tickHalf, y: center.y + d))
                    }
                    strokePath(path)
                }

                if config.showCenterDot || config.style == .centerDot {
                    let dotRect = CGRect(x: center.x - dotD / 2, y: center.y - dotD / 2, width: dotD, height: dotD)
                    if config.showOutline {
                        let outRect = dotRect.insetBy(dx: -1.2 * scale, dy: -1.2 * scale)
                        context.fill(Path(ellipseIn: outRect), with: .color(outlineColor))
                    }
                    context.fill(Path(ellipseIn: dotRect), with: .color(mainColor))
                }
            }
            .allowsHitTesting(false)
        }
    }
}
