//
//  VehicleControllerHostTests.swift
//  LoopLabTests
//

import Testing
@testable import LoopLab

@Suite("Swappable vehicle controller host")
@MainActor
struct VehicleControllerHostTests {
    @Test("both controllers receive the same shared context")
    func controllersReceiveSameContext() throws {
        let physics = VehicleControllerSpy(kind: .physicsForce)
        let constraint = VehicleControllerSpy(kind: .constraintAssisted)
        let host = VehicleControllerHost(
            controllers: [physics, constraint],
            activeKind: .physicsForce
        )
        let context = makeContext()

        _ = host.update(context: context)
        host.select(.constraintAssisted)
        _ = host.update(context: context)

        #expect(physics.receivedContexts == [context])
        #expect(constraint.receivedContexts == [context])
    }

    @Test("switching controllers preserves each implementation's actuation")
    func switchingPreservesActuation() {
        let physics = VehicleControllerSpy(
            kind: .physicsForce,
            actuation: .forces(
                force: SIMD3(0, 0, 1),
                torque: SIMD3(0, 1, 0)
            )
        )
        let constraint = VehicleControllerSpy(
            kind: .constraintAssisted,
            actuation: .constrained(
                pose: Phase0VehicleComparison.startPose,
                linearVelocity: SIMD3(0, 0, 1),
                angularVelocity: .zero
            )
        )
        let host = VehicleControllerHost(
            controllers: [physics, constraint],
            activeKind: .physicsForce
        )
        let context = makeContext()

        #expect(
            host.update(context: context)
                == physics.actuation
        )
        host.select(.constraintAssisted)
        #expect(
            host.update(context: context)
                == constraint.actuation
        )
    }

    @Test("reset clears both controller implementations")
    func resetClearsBothControllers() {
        let physics = VehicleControllerSpy(kind: .physicsForce)
        let constraint = VehicleControllerSpy(kind: .constraintAssisted)
        let host = VehicleControllerHost(
            controllers: [physics, constraint],
            activeKind: .physicsForce
        )

        host.reset()

        #expect(physics.resetCount == 1)
        #expect(constraint.resetCount == 1)
    }

    private func makeContext() -> VehicleControllerContext {
        VehicleControllerContext(
            state: .resting(at: Phase0VehicleComparison.startPose),
            input: SemanticInputState(
                steering: 0.5,
                throttle: 0.75
            ),
            configuration: Phase0VehicleComparison.configuration,
            timing: VehicleUpdateTiming(
                stepIndex: 4,
                deltaTime: 1 / 90,
                elapsedTime: 1
            )
        )
    }
}
