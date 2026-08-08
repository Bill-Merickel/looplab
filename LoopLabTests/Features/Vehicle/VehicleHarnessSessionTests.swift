//
//  VehicleHarnessSessionTests.swift
//  LoopLabTests
//

import Foundation
import Testing
@testable import LoopLab

@Suite("Shared vehicle harness session")
@MainActor
struct VehicleHarnessSessionTests {
    @Test("held reset input produces one edge-triggered reset")
    func resetInputIsEdgeTriggered() {
        let harness = VehicleHarnessSession()
        let state = VehicleState.resting(at: harness.startPose)
        let resetInput = SemanticInputState(reset: true)

        #expect(
            harness.update(
                state: state,
                input: resetInput,
                frameDeltaTime: 1 / 90
            ) == .reset(.manual)
        )
        #expect(
            harness.update(
                state: state,
                input: resetInput,
                frameDeltaTime: 1 / 90
            ) == .actuate(.none)
        )
        #expect(harness.telemetry.resetCount == 1)
    }

    @Test("controller selection changes only the behavior and requests reset")
    func controllerSelectionRequestsReset() {
        let harness = VehicleHarnessSession()
        let state = VehicleState.resting(at: harness.startPose)

        harness.selectNextController()
        let command = harness.update(
            state: state,
            input: .neutral,
            frameDeltaTime: 1 / 90
        )

        #expect(harness.activeController == .constraintAssisted)
        #expect(command == .reset(.controllerChanged))
        #expect(harness.telemetry.resetCount == 1)
    }

    @Test("telemetry records shared state, contacts, timing, and input")
    func telemetryRecordsSharedValues() {
        let harness = VehicleHarnessSession()
        let frameDeltaTime = TimeInterval(1.0 / 60.0)
        let input = SemanticInputState(
            steering: -0.5,
            throttle: 0.8
        )
        let state = VehicleState(
            pose: harness.startPose,
            linearVelocity: SIMD3(0, 0, 2),
            angularVelocity: .zero,
            isGrounded: true,
            contactCount: 2
        )

        _ = harness.update(
            state: state,
            input: input,
            frameDeltaTime: frameDeltaTime
        )

        #expect(harness.telemetry.speed == 2)
        #expect(
            abs(harness.telemetry.frameDeltaTime - frameDeltaTime)
                < 0.000_000_001
        )
        #expect(harness.telemetry.isGrounded)
        #expect(harness.telemetry.contactCount == 2)
        #expect(harness.telemetry.input == input)
        #expect(harness.telemetry.activeController == .physicsForce)
    }

    @Test("contact tracking cannot become negative")
    func contactCountCannotBecomeNegative() {
        let harness = VehicleHarnessSession()

        harness.contactEnded()
        harness.contactBegan()
        harness.contactBegan()
        harness.contactEnded()

        #expect(harness.contactCount == 1)
    }
}
