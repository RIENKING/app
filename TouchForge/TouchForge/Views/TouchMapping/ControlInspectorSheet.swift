import SwiftUI

struct ControlInspectorSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State var control: VirtualTouchControl

    private let symbolOptions = [
        "hand.tap.fill", "flame.fill", "scope", "arrow.up", "figure.stand",
        "bolt.fill", "dpad.fill", "wind", "shield.fill", "star.fill",
        "burst.fill", "figure.run", "gamecontroller.fill", "1.circle.fill", "2.circle.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity & Type") {
                    TextField("Button Label", text: $control.label)

                    Picker("Control Type", selection: $control.type) {
                        ForEach(VirtualControlType.allCases) { type in
                            Text(store.t(type.displayNameKey)).tag(type)
                        }
                    }

                    Picker("Shape", selection: $control.shape) {
                        ForEach(ControlShape.allCases) { shape in
                            Text(store.t(shape.displayNameKey)).tag(shape)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(symbolOptions, id: \.self) { symbol in
                                Button {
                                    control.symbolName = symbol
                                } label: {
                                    Image(systemName: symbol)
                                        .font(.title3)
                                        .frame(width: 38, height: 38)
                                        .background(
                                            control.symbolName == symbol
                                                ? store.settings.accentTheme.color.opacity(0.22)
                                                : Color(.tertiarySystemFill),
                                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Size, Opacity & Appearance") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Width")
                            Spacer()
                            Text("\(Int(control.width)) pt").foregroundStyle(.secondary)
                        }
                        Slider(value: $control.width, in: 44...170)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Height")
                            Spacer()
                            Text("\(Int(control.height)) pt").foregroundStyle(.secondary)
                        }
                        Slider(value: $control.height, in: 44...170)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Opacity / Transparency")
                            Spacer()
                            Text("\(Int(control.opacity * 100))%").foregroundStyle(.secondary)
                        }
                        Slider(value: $control.opacity, in: 0.15...1.0)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Border Width")
                            Spacer()
                            Text(String(format: "%.1f pt", control.borderWidth)).foregroundStyle(.secondary)
                        }
                        Slider(value: $control.borderWidth, in: 0...6, step: 0.5)
                    }

                    ColorPicker("Button Color", selection: Binding(
                        get: { control.fillColor.swiftUIColor },
                        set: { control.fillColor = CodableColor(color: $0) }
                    ), supportsOpacity: false)

                    Toggle("Lock Position & Size", isOn: $control.isLocked)
                }

                Section("Hardware Binding & Macro") {
                    Picker("Controller Button", selection: $control.controllerBinding) {
                        ForEach(ControllerBinding.allCases) { binding in
                            Text(binding.label).tag(binding)
                        }
                    }

                    Picker("Linked Macro", selection: $control.linkedMacroId) {
                        Text("None").tag(UUID?.none)
                        ForEach(store.macros) { macro in
                            Text(macro.name).tag(Optional(macro.id))
                        }
                    }

                    Picker("Haptic Feedback", selection: $control.haptic) {
                        ForEach(HapticIntensity.allCases) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                }

                Section {
                    Button("Center Button on Canvas") {
                        control.normalizedX = 0.5
                        control.normalizedY = 0.5
                    }

                    Button("Delete Button", role: .destructive) {
                        store.deleteControl(control.id)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Customize Button")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateControl(control)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
