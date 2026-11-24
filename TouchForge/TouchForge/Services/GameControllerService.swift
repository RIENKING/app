import Foundation
import GameController
import Combine

@MainActor
final class GameControllerService: ObservableObject {
    @Published private(set) var connectedControllerName: String?
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var activeButtons: Set<ControllerBinding> = []
    @Published private(set) var leftStick: CGPoint = .zero
    @Published private(set) var rightStick: CGPoint = .zero
    @Published private(set) var lastInputSummary: String = "No controller connected"

    var onButtonPressed: ((ControllerBinding) -> Void)?

    private var connectObserver: NSObjectProtocol?
    private var disconnectObserver: NSObjectProtocol?

    init() {
        setupObservers()
        refreshControllers()
    }

    deinit {
        if let connectObserver {
            NotificationCenter.default.removeObserver(connectObserver)
        }
        if let disconnectObserver {
            NotificationCenter.default.removeObserver(disconnectObserver)
        }
    }

    private func setupObservers() {
        connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshControllers()
            }
        }

        disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshControllers()
            }
        }
    }

    func refreshControllers() {
        guard let controller = GCController.controllers().first else {
            connectedControllerName = nil
            isConnected = false
            activeButtons.removeAll()
            leftStick = .zero
            rightStick = .zero
            lastInputSummary = "No controller connected"
            return
        }

        connectedControllerName = controller.vendorName ?? "MFi / Bluetooth Controller"
        isConnected = true
        lastInputSummary = "Ready: \(connectedControllerName ?? "Controller")"
        bindExtendedGamepad(controller)
    }

    private func bindExtendedGamepad(_ controller: GCController) {
        guard let gamepad = controller.extendedGamepad else { return }

        bindButton(gamepad.buttonA, as: .buttonA)
        bindButton(gamepad.buttonB, as: .buttonB)
        bindButton(gamepad.buttonX, as: .buttonX)
        bindButton(gamepad.buttonY, as: .buttonY)
        bindButton(gamepad.leftShoulder, as: .leftShoulder)
        bindButton(gamepad.rightShoulder, as: .rightShoulder)
        bindButton(gamepad.leftTrigger, as: .leftTrigger)
        bindButton(gamepad.rightTrigger, as: .rightTrigger)
        if let l3 = gamepad.leftThumbstickButton {
            bindButton(l3, as: .leftThumbstickButton)
        }
        if let r3 = gamepad.rightThumbstickButton {
            bindButton(r3, as: .rightThumbstickButton)
        }
        bindButton(gamepad.dpad.up, as: .dpadUp)
        bindButton(gamepad.dpad.down, as: .dpadDown)
        bindButton(gamepad.dpad.left, as: .dpadLeft)
        bindButton(gamepad.dpad.right, as: .dpadRight)

        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, x, y in
            Task { @MainActor in
                self?.leftStick = CGPoint(x: CGFloat(x), y: CGFloat(y))
            }
        }

        gamepad.rightThumbstick.valueChangedHandler = { [weak self] _, x, y in
            Task { @MainActor in
                self?.rightStick = CGPoint(x: CGFloat(x), y: CGFloat(y))
            }
        }
    }

    private func bindButton(_ input: GCControllerButtonInput, as binding: ControllerBinding) {
        input.pressedChangedHandler = { [weak self] _, _, pressed in
            Task { @MainActor in
                guard let self else { return }
                if pressed {
                    self.activeButtons.insert(binding)
                    self.lastInputSummary = "Pressed: \(binding.label)"
                    self.onButtonPressed?(binding)
                } else {
                    self.activeButtons.remove(binding)
                }
            }
        }
    }
}
