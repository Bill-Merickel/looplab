//
//  GameControllerDualSenseProvider.swift
//  LoopLab
//

import Foundation
import GameController

/// GameController adapter for the Phase 0 DualSense mapping.
@MainActor
final class GameControllerDualSenseProvider: InputProvider {
    var stateDidChange: ((SemanticInputState) -> Void)?
    var connectionDidChange: ((InputConnection) -> Void)?
    var activityDidOccur: ((InputActivity) -> Void)?

    private let mapper = DualSenseInputMapper()
    private var activeController: GCController?
    private var observers: [NSObjectProtocol] = []
    private var isStarted = false

    func start() {
        guard !isStarted else {
            return
        }
        isStarted = true

        let center = NotificationCenter.default
        observers = [
            center.addObserver(
                forName: .GCControllerDidConnect,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let controller = notification.object as? GCController
                else {
                    return
                }
                MainActor.assumeIsolated {
                    self?.controllerDidConnect(controller)
                }
            },
            center.addObserver(
                forName: .GCControllerDidDisconnect,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let controller = notification.object as? GCController
                else {
                    return
                }
                MainActor.assumeIsolated {
                    self?.controllerDidDisconnect(controller)
                }
            },
        ]

        if let controller = GCController.controllers().first(
            where: Self.isSupported
        ) {
            activate(controller)
        } else {
            neutralizeAndReportDisconnect()
        }

        GCController.startWirelessControllerDiscovery(
            completionHandler: nil
        )
    }

    func stop() {
        guard isStarted else {
            return
        }
        GCController.stopWirelessControllerDiscovery()
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        clearInputHandler(for: activeController)
        activeController = nil
        neutralizeAndReportDisconnect()
        isStarted = false
    }

    private static func isSupported(_ controller: GCController) -> Bool {
        controller.productCategory == GCProductCategoryDualSense
            && controller.extendedGamepad != nil
    }

    private func controllerDidConnect(_ controller: GCController) {
        guard activeController == nil, Self.isSupported(controller) else {
            return
        }
        activate(controller)
    }

    private func controllerDidDisconnect(_ controller: GCController) {
        guard activeController === controller else {
            return
        }

        clearInputHandler(for: controller)
        activeController = nil
        neutralizeAndReportDisconnect()

        if let replacement = GCController.controllers().first(
            where: Self.isSupported
        ) {
            activate(replacement)
        }
    }

    private func activate(_ controller: GCController) {
        clearInputHandler(for: activeController)
        activeController = controller
        let input = controller.input
        input.queue = .main
        input.inputStateQueueDepth = 20
        input.inputStateAvailableHandler = { [weak self] input in
            MainActor.assumeIsolated {
                self?.consumePendingStates(from: input)
            }
        }

        let name = controller.vendorName ?? "DualSense"
        connectionDidChange?(.connected(deviceName: name))
        publishState(from: input.capture())
    }

    private func consumePendingStates(from input: any GCDevicePhysicalInput) {
        while let state = input.nextInputState() {
            publishState(from: state)

            guard let changedElements = state.changedElements() else {
                continue
            }
            for element in changedElements {
                publishActivity(for: element)
            }
        }
    }

    private func publishState(from input: any GCDevicePhysicalInputState) {
        let reading = DualSenseInputReading(
            leftStickX: input.dpads[.leftThumbstick]?.xAxis.value ?? 0,
            rightTrigger: input.buttons[.rightTrigger]?
                .pressedInput.value ?? 0,
            leftTrigger: input.buttons[.leftTrigger]?
                .pressedInput.value ?? 0,
            squarePressed: input.buttons[.x]?.pressedInput.isPressed ?? false,
            trianglePressed: input.buttons[.y]?.pressedInput.isPressed ?? false,
            optionsPressed: input.buttons[.menu]?
                .pressedInput.isPressed ?? false,
            crossPressed: input.buttons[.a]?.pressedInput.isPressed ?? false,
            circlePressed: input.buttons[.b]?.pressedInput.isPressed ?? false
        )
        stateDidChange?(mapper.map(reading))
    }

    private func publishActivity(for element: any GCPhysicalInputElement) {
        let controlName = element.localizedName
            ?? element.aliases.sorted().first
            ?? "Controller input"
        let valueDescription: String

        if let button = element as? any GCButtonElement {
            valueDescription = button.pressedInput.isPressed
                ? "pressed"
                : "released"
        } else if let directionPad = element as? any GCDirectionPadElement {
            valueDescription = String(
                format: "x %+.2f, y %+.2f",
                directionPad.xAxis.value,
                directionPad.yAxis.value
            )
        } else if let axis = element as? any GCAxisElement {
            valueDescription = String(
                format: "%+.2f",
                axis.absoluteInput?.value ?? 0
            )
        } else {
            valueDescription = "changed"
        }

        activityDidOccur?(
            InputActivity(
                controlName: controlName,
                valueDescription: valueDescription
            )
        )
    }

    private func clearInputHandler(for controller: GCController?) {
        guard let controller else {
            return
        }
        controller.input.inputStateAvailableHandler = nil
    }

    private func neutralizeAndReportDisconnect() {
        stateDidChange?(.neutral)
        connectionDidChange?(.disconnected)
    }
}
