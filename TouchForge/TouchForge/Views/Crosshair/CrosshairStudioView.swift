import SwiftUI

enum CrosshairBackdrop: String, CaseIterable, Identifiable {
    case darkGrid = "Dark Grid"
    case daylight = "Daylight"
    case forest = "Forest"
    case desert = "Desert"

    var id: String { rawValue }
}

struct CrosshairStudioView: View {
    @EnvironmentObject private var store: AppStore
    @State private var backdrop: CrosshairBackdrop = .darkGrid

    private var crosshairBinding: Binding<CrosshairConfig> {
        Binding(
            get: { store.activeProfile.crosshair },
            set: { store.updateCrosshair($0) }
        )
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { store.activeProfile.crosshair.color.swiftUIColor },
            set: { newColor in
                var cfg = store.activeProfile.crosshair
                cfg.color = CodableColor(color: newColor)
                store.updateCrosshair(cfg)
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    previewStage
                    stylePickerSection
                    geometryControlsSection
                    appearanceSection
                    positionSection
                    iosOverlayNoteCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(store.t("crosshair.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.syncPiPHUD()
                        store.pipHUD.togglePiP()
                    } label: {
                        Label("PiP", systemImage: store.pipHUD.isPiPActive ? "pip.exit" : "pip.enter")
                    }
                    .disabled(!store.pipHUD.isPiPSupported)
                }
            }
        }
    }

    private var previewStage: some View {
        VStack(spacing: 10) {
            ZStack {
                backdropView
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                CrosshairRenderer(config: store.activeProfile.crosshair)
                    .frame(height: 220)

                VStack {
                    HStack {
                        Text(store.activeProfile.name)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                        Spacer()
                        Text("X: \(Int(store.activeProfile.crosshair.offsetX))  Y: \(Int(store.activeProfile.crosshair.offsetY))")
                            .font(.caption2.monospaced())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    Spacer()
                }
                .padding(12)
            }

            Picker("Preview Backdrop", selection: $backdrop) {
                ForEach(CrosshairBackdrop.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var backdropView: some View {
        switch backdrop {
        case .darkGrid:
            ZStack {
                LinearGradient(colors: [Color(white: 0.08), Color(white: 0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Canvas { context, size in
                    var path = Path()
                    let step: CGFloat = 24
                    for x in stride(from: 0, through: size.width, by: step) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for y in stride(from: 0, through: size.height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(path, with: .color(.white.opacity(0.08)), lineWidth: 1)
                }
            }
        case .daylight:
            LinearGradient(colors: [Color.cyan.opacity(0.5), Color.blue.opacity(0.35), Color.white.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        case .forest:
            LinearGradient(colors: [Color(red: 0.11, green: 0.25, blue: 0.16), Color(red: 0.19, green: 0.38, blue: 0.22)], startPoint: .top, endPoint: .bottom)
        case .desert:
            LinearGradient(colors: [Color(red: 0.78, green: 0.64, blue: 0.44), Color(red: 0.62, green: 0.47, blue: 0.29)], startPoint: .top, endPoint: .bottom)
        }
    }

    private var stylePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(store.t("crosshair.enabled"), isOn: crosshairBinding.isEnabled)
                .font(.headline)

            Text(store.t("crosshair.style"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CrosshairStyle.allCases) { style in
                        let selected = store.activeProfile.crosshair.style == style
                        Button {
                            var cfg = store.activeProfile.crosshair
                            cfg.style = style
                            store.updateCrosshair(cfg)
                            HapticService.shared.selection(enabled: store.settings.hapticsEnabled)
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.black.opacity(0.85))
                                        .frame(width: 56, height: 56)
                                    CrosshairRenderer(
                                        config: CrosshairConfig(
                                            isEnabled: true,
                                            style: style,
                                            size: 32,
                                            thickness: 2,
                                            centerGap: 5,
                                            showCenterDot: true,
                                            dotSize: 3.5,
                                            showOutline: true,
                                            opacity: 1,
                                            color: store.activeProfile.crosshair.color
                                        ),
                                        scale: 0.75
                                    )
                                    .frame(width: 48, height: 48)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(selected ? store.settings.accentTheme.color : Color.clear, lineWidth: 2.5)
                                )

                                Text(store.t(style.displayNameKey))
                                    .font(.caption2.weight(selected ? .bold : .regular))
                                    .foregroundStyle(selected ? .primary : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var geometryControlsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sliderRow(title: store.t("crosshair.size"), value: crosshairBinding.size, range: 12...120, unit: "pt")
            sliderRow(title: store.t("crosshair.thickness"), value: crosshairBinding.thickness, range: 1...8, unit: "pt")
            sliderRow(title: store.t("crosshair.gap"), value: crosshairBinding.centerGap, range: 0...24, unit: "pt")

            Toggle("Center Dot", isOn: crosshairBinding.showCenterDot)
            if store.activeProfile.crosshair.showCenterDot {
                sliderRow(title: "Dot Size", value: crosshairBinding.dotSize, range: 2...12, unit: "pt")
            }
            Toggle("High-Contrast Outline", isOn: crosshairBinding.showOutline)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ColorPicker("Reticle Color", selection: colorBinding, supportsOpacity: false)
                .font(.subheadline.weight(.medium))

            HStack(spacing: 12) {
                ForEach([CodableColor.neonGreen, .cyan, .crimson, .amber, .electricBlue, .white], id: \.self) { preset in
                    Button {
                        var cfg = store.activeProfile.crosshair
                        cfg.color = preset
                        store.updateCrosshair(cfg)
                    } label: {
                        Circle()
                            .fill(preset.swiftUIColor)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(store.activeProfile.crosshair.color == preset ? 0.9 : 0.2), lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            sliderRow(title: store.t("crosshair.opacity"), value: crosshairBinding.opacity, range: 0.15...1.0, formatPercent: true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(store.t("crosshair.position"))
                    .font(.headline)
                Spacer()
                Button(store.t("crosshair.resetCenter")) {
                    var cfg = store.activeProfile.crosshair
                    cfg.offsetX = 0
                    cfg.offsetY = 0
                    store.updateCrosshair(cfg)
                }
                .font(.caption.weight(.semibold))
            }

            sliderRow(title: "Horizontal Offset (X)", value: crosshairBinding.offsetX, range: -120...120, unit: "pt")
            sliderRow(title: "Vertical Offset (Y)", value: crosshairBinding.offsetY, range: -120...120, unit: "pt")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var iosOverlayNoteCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
            Text("Standard iOS apps cannot draw a full-screen touch-through overlay on top of third-party games. Your crosshair works natively on TouchForge's practice canvas and can also float as an official Picture-in-Picture (PiP) reference window via the PiP button above.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        unit: String = "",
        formatPercent: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(formatPercent ? "\(Int(value.wrappedValue * 100))%" : "\(Int(value.wrappedValue.rounded())) \(unit)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}
