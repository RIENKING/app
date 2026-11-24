import Foundation
import CoreBluetooth
import Combine

enum BLEConnectionState: String {
    case poweredOff
    case idle
    case scanning
    case connecting
    case connected
    case unauthorized

    var label: String {
        switch self {
        case .poweredOff: return "Bluetooth Off"
        case .idle: return "Not Connected"
        case .scanning: return "Scanning..."
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .unauthorized: return "Permission Denied"
        }
    }
}

struct DiscoveredBridgeDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rssi: Int
}

/// Real CoreBluetooth Central client for optional external HID hardware bridges
/// (e.g., ESP32-S3, nRF52840, or Raspberry Pi Pico W exposing a TouchForge GATT service).
/// Standard iOS apps cannot inject touches into other apps directly; an external Bluetooth HID
/// peripheral is Apple's officially supported hardware pathway.
@MainActor
final class BLEBridgeService: NSObject, ObservableObject {
    static let serviceUUID = CBUUID(string: "7F4A0001-3C8E-4B11-9D32-6E5A12B4C800")
    static let commandCharacteristicUUID = CBUUID(string: "7F4A0002-3C8E-4B11-9D32-6E5A12B4C800")

    @Published private(set) var connectionState: BLEConnectionState = .idle
    @Published private(set) var discoveredDevices: [DiscoveredBridgeDevice] = []
    @Published private(set) var connectedDeviceName: String?
    @Published private(set) var lastPacketHex: String = "—"

    private var centralManager: CBCentralManager?
    private var peripheralsById: [UUID: CBPeripheral] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?

    override init() {
        super.init()
    }

    func ensureInitialized() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func startScan() {
        ensureInitialized()
        guard let centralManager else { return }
        guard centralManager.state == .poweredOn else {
            updateState(from: centralManager.state)
            return
        }
        discoveredDevices.removeAll()
        connectionState = .scanning
        // Scans for nearby peripherals (both dedicated TouchForge bridge UUID and named BLE HID bridges).
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        centralManager?.stopScan()
        if connectionState == .scanning {
            connectionState = .idle
        }
    }

    func connect(to device: DiscoveredBridgeDevice) {
        guard let peripheral = peripheralsById[device.id] else { return }
        stopScan()
        connectionState = .connecting
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
    }

    func disconnect() {
        if let connectedPeripheral {
            centralManager?.cancelPeripheralConnection(connectedPeripheral)
        }
        connectedPeripheral = nil
        commandCharacteristic = nil
        connectedDeviceName = nil
        connectionState = .idle
    }

    func sendMacroStep(_ step: MacroStep) {
        guard connectionState == .connected,
              let peripheral = connectedPeripheral,
              let characteristic = commandCharacteristic else {
            return
        }

        // Compact binary protocol:
        // [0xA5 header, kindByte, startX(0..255), startY(0..255), endX(0..255), endY(0..255), durHi, durLo]
        let kindByte: UInt8 = switch step.kind {
        case .tap: 0x01
        case .longPress: 0x02
        case .swipe: 0x03
        case .delay: 0x04
        case .hapticCue: 0x05
        case .bleHIDCommand: 0x06
        }

        let sx = UInt8(clamping: Int((step.startX * 255.0).rounded()))
        let sy = UInt8(clamping: Int((step.startY * 255.0).rounded()))
        let ex = UInt8(clamping: Int((step.endX * 255.0).rounded()))
        let ey = UInt8(clamping: Int((step.endY * 255.0).rounded()))
        let dur = UInt16(clamping: step.durationMs)
        let durHi = UInt8((dur >> 8) & 0xFF)
        let durLo = UInt8(dur & 0xFF)

        var bytes: [UInt8] = [0xA5, kindByte, sx, sy, ex, ey, durHi, durLo]
        if step.kind == .bleHIDCommand, let payloadData = step.hidPayload.data(using: .utf8) {
            bytes.append(contentsOf: payloadData.prefix(12))
        }

        let data = Data(bytes)
        lastPacketHex = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")

        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)
    }

    private func updateState(from state: CBManagerState) {
        switch state {
        case .poweredOn:
            if connectionState != .connected && connectionState != .connecting {
                connectionState = .idle
            }
        case .poweredOff:
            connectionState = .poweredOff
        case .unauthorized:
            connectionState = .unauthorized
        default:
            connectionState = .idle
        }
    }
}

extension BLEBridgeService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            self.updateState(from: central.state)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
        guard let deviceName = name, !deviceName.isEmpty else { return }

        Task { @MainActor in
            self.peripheralsById[peripheral.identifier] = peripheral
            let item = DiscoveredBridgeDevice(id: peripheral.identifier, name: deviceName, rssi: RSSI.intValue)
            if let idx = self.discoveredDevices.firstIndex(where: { $0.id == item.id }) {
                self.discoveredDevices[idx] = item
            } else {
                self.discoveredDevices.append(item)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.connectionState = .connected
            self.connectedDeviceName = peripheral.name ?? "HID Bridge"
            peripheral.discoverServices([Self.serviceUUID])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.connectionState = .idle
            self.connectedPeripheral = nil
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.connectionState = .idle
            self.connectedPeripheral = nil
            self.commandCharacteristic = nil
            self.connectedDeviceName = nil
        }
    }
}

extension BLEBridgeService: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == Self.serviceUUID {
            peripheral.discoverCharacteristics([Self.commandCharacteristicUUID], for: service)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for char in characteristics where char.uuid == Self.commandCharacteristicUUID {
            Task { @MainActor in
                self.commandCharacteristic = char
            }
        }
    }
}
