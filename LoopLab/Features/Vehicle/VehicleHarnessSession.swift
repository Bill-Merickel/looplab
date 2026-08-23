//
//  VehicleHarnessSession.swift
//  LoopLab
//

import Foundation
import Observation

/// Observable orchestration shared by both Phase 0 controller prototypes.
@MainActor
@Observable
final class VehicleHarnessSession {
    let configuration: VehicleConfiguration
    let comparisonRun: VehicleComparisonRun
    let startPose: TrackTransform

    private(set) var telemetry: VehicleTelemetry
    private(set) var lastResetReason: VehicleResetReason?
    private(set) var contactCount = 0

    private let timingConfiguration: VehicleTimingConfiguration
    private let recoveryPolicy: VehicleRecoveryPolicy
    private let controllerHost: VehicleControllerHost
    private var pendingResetReason: VehicleResetReason?
    private var previousResetInput = false
    private var stepIndex: UInt64 = 0
    private var elapsedTime: TimeInterval = 0
    private var recoveryTracker = VehicleRecoveryTracker()

    init(
        configuration: VehicleConfiguration = Phase0VehicleComparison.configuration,
        comparisonRun: VehicleComparisonRun = Phase0VehicleComparison.run,
        startPose: TrackTransform = Phase0VehicleComparison.startPose,
        timingConfiguration: VehicleTimingConfiguration = Phase0VehicleComparison.timing,
        recoveryPolicy: VehicleRecoveryPolicy = Phase0VehicleComparison.recovery,
        controllers: [any VehicleController]? = nil,
        activeController: VehicleControllerKind = .physicsForce
    ) {
        precondition(configuration.hasValidValues)
        precondition(recoveryPolicy.hasValidValues)
        self.configuration = configuration
        self.comparisonRun = comparisonRun
        self.startPose = startPose
        self.timingConfiguration = timingConfiguration
        self.recoveryPolicy = recoveryPolicy
        let registeredControllers = controllers ?? [
            PhysicsForceVehicleController(),
            PassiveVehicleController(kind: .constraintAssisted),
        ]
        controllerHost = VehicleControllerHost(
            controllers: registeredControllers,
            activeKind: activeController
        )
        telemetry = .initial(activeController: activeController)
    }

    var activeController: VehicleControllerKind {
        controllerHost.activeKind
    }

    func requestReset() {
        pendingResetReason = .manual
    }

    func selectNextController() {
        let kinds = VehicleControllerKind.allCases
        guard let currentIndex = kinds.firstIndex(of: activeController) else {
            return
        }
        let nextIndex = kinds.index(after: currentIndex)
        controllerHost.select(
            nextIndex == kinds.endIndex ? kinds[0] : kinds[nextIndex]
        )
        pendingResetReason = .controllerChanged
    }

    func contactBegan() {
        contactCount += 1
    }

    func contactEnded() {
        contactCount = max(0, contactCount - 1)
    }

    func update(
        state: VehicleState,
        surface: VehicleSurfaceSample,
        input: SemanticInputState,
        frameDeltaTime: TimeInterval
    ) -> VehicleHarnessCommand {
        let timing = timingConfiguration.makeTiming(
            frameDeltaTime: frameDeltaTime,
            stepIndex: stepIndex,
            elapsedTime: elapsedTime
        )
        stepIndex += 1
        elapsedTime = timing.elapsedTime

        let resetPressed = input.reset && previousResetInput == false
        previousResetInput = input.reset
        let resetReason = pendingResetReason
            ?? (resetPressed ? .manual : nil)
            ?? recoveryTracker.resetReason(
                for: state,
                input: input,
                timing: timing,
                startPose: startPose,
                policy: recoveryPolicy
            )

        if let resetReason {
            pendingResetReason = nil
            controllerHost.reset()
            recoveryTracker.reset()
            contactCount = 0
            lastResetReason = resetReason
            telemetry = VehicleTelemetry(
                speed: 0,
                controllerUpdateDuration: .zero,
                frameDeltaTime: timing.deltaTime,
                isGrounded: false,
                contactCount: 0,
                resetCount: telemetry.resetCount + 1,
                activeController: activeController,
                input: input
            )
            return .reset(resetReason)
        }

        let context = VehicleControllerContext(
            state: state,
            surface: surface,
            input: input,
            configuration: configuration,
            timing: timing
        )
        let start = ContinuousClock.now
        let actuation = controllerHost.update(context: context)
        let updateDuration = start.duration(to: .now)

        telemetry = VehicleTelemetry(
            speed: state.speed,
            controllerUpdateDuration: updateDuration,
            frameDeltaTime: timing.deltaTime,
            isGrounded: state.isGrounded,
            contactCount: state.contactCount,
            resetCount: telemetry.resetCount,
            activeController: activeController,
            input: input
        )
        return .actuate(actuation)
    }
}
