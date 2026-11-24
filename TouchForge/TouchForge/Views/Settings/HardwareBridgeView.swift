import SwiftUI

struct HardwareBridgeView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Optional External Hardware Workflow", systemImage: "cpu.fill")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text("Standard iOS apps are sandboxed and cannot inject touches directly into other games. If you want macro sequences or remapped controller buttons to act inside third-party games without jailbreak, pair an external Bluetooth HID bridge (such as an ESP32-S3, nRF52840, or Raspberry Pi Pico W) that presents itself to iOS as an official Bluetooth HID Mouse/Keyboard/AssistiveTouch pointer.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Connection Status") {
                HStack {
                    Text("BLE Status")
                    Spacer()
                    Text(store.bleBridge.connectionState.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(store.bleBridge.connectionState == .connected ? .green : .secondary)
                }

                if let name = store.bleBridge.connectedDeviceName {
                    HStack {
                        Text("Connected Bridge")
                        Spacer()
                        Text(name).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Last Packet (Hex)")
                        Spacer()
                        Text(store.bleBridge.lastPacketHex)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    Button("Send Test Tap Packet") {
                        store.bleBridge.sendMacroStep(
                            MacroStep(kind: .tap, label: "Ping", startX: 0.5, startY: 0.5, durationMs: 50, delayAfterMs: 0)
                        )
                    }

                    Button("Disconnect Bridge", role: .destructive) {
                        store.bleBridge.disconnect()
                    }
                } else {
                    Button {
                        if store.bleBridge.connectionState == .scanning {
                            store.bleBridge.stopScan()
                        } else {
                            store.bleBridge.startScan()
                        }
                    } label: {
                        Label(
                            store.bleBridge.connectionState == .scanning ? "Stop Scanning" : "Scan for Nearby BLE Bridges",
                            systemImage: "dot.radiowaves.left.and.right"
                        )
                    }
                }
            }

            if !store.bleBridge.discoveredDevices.isEmpty {
                Section("Discovered Bluetooth Devices") {
                    ForEach(store.bleBridge.discoveredDevices) { device in
                        Button {
                            store.bleBridge.connect(to: device)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(device.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text("RSSI: \(device.rssi) dBm")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("Connect")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            Section("Open GATT Protocol Specification") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Service UUID:")
                        .font(.caption.weight(.semibold))
                    Text(BLEBridgeService.serviceUUID.uuidString)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Command Characteristic UUID:")
                        .font(.caption.weight(.semibold))
                        .padding(.top, 4)
                    Text(BLEBridgeService.commandCharacteristicUUID.uuidString)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)

                    Text("Packet Format (8+ bytes):")
                        .font(.caption.weight(.semibold))
                        .padding(.top, 4)
                    Text("[0xA5, kind, startX, startY, endX, endY, durHi, durLo, ...optionalUTF8]")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("BLE HID Bridge")
        .navigationBarTitleDisplayMode(.inline)
    }
}
