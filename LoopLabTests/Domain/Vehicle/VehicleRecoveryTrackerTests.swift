//
//  VehicleRecoveryTrackerTests.swift
//  LoopLabTests
//

import Foundation
import Testing
@testable import LoopLab

struct VehicleRecoveryTrackerTests {
    @Test("brief airtime is allowed before lost-surface recovery")
    func briefAirtimeDoesNotReset() {
        var tracker = VehicleRecoveryTracker()

        let reason = tracker.resetReason(
            for: makeState(isGrounded: false),
            input: .neutral,
            timing: makeTiming(
                deltaTime: Phase0VehicleComparison.recovery
                    .maximumUngroundedDuration / 2
            ),
            startPose: Phase0VehicleComparison.startPose,
            policy: Phase0VehicleComparison.recovery
        )

        #expect(reason == nil)
        #expect(tracker.ungroundedDuration > 0)
    }

    @Test("continuous loss of the track surface requests recovery")
    func lostSurfaceResets() {
        var tracker = VehicleRecoveryTracker()
        let deltaTime = Phase0VehicleComparison.recovery
            .maximumUngroundedDuration / 2

        #expect(
            tracker.resetReason(
                for: makeState(isGrounded: false),
                input: .neutral,
                timing: makeTiming(deltaTime: deltaTime),
                startPose: Phase0VehicleComparison.startPose,
                policy: Phase0VehicleComparison.recovery
            ) == nil
        )
        #expect(
            tracker.resetReason(
                for: makeState(isGrounded: false),
                input: .neutral,
                timing: makeTiming(deltaTime: deltaTime),
                startPose: Phase0VehicleComparison.startPose,
                policy: Phase0VehicleComparison.recovery
            ) == .lostTrackSurface
        )
        #expect(tracker.ungroundedDuration == 0)
    }

    @Test("ground contact clears accumulated airtime")
    func groundingClearsAirtime() {
        var tracker = VehicleRecoveryTracker()

        _ = tracker.resetReason(
            for: makeState(isGrounded: false),
            input: .neutral,
            timing: makeTiming(deltaTime: 1),
            startPose: Phase0VehicleComparison.startPose,
            policy: Phase0VehicleComparison.recovery
        )
        _ = tracker.resetReason(
            for: makeState(isGrounded: true),
            input: .neutral,
            timing: makeTiming(deltaTime: 0.1),
            startPose: Phase0VehicleComparison.startPose,
            policy: Phase0VehicleComparison.recovery
        )

        #expect(tracker.ungroundedDuration == 0)
    }

    @Test("sustained drive input without movement requests stuck recovery")
    func stalledUnderDriveResets() {
        var tracker = VehicleRecoveryTracker()
        let policy = Phase0VehicleComparison.recovery
        let deltaTime = policy.maximumStalledDuration / 3
        var reason: VehicleResetReason?

        for _ in 0..<3 {
            reason = tracker.resetReason(
                for: makeState(isGrounded: true),
                input: SemanticInputState(throttle: 1),
                timing: makeTiming(deltaTime: deltaTime),
                startPose: Phase0VehicleComparison.startPose,
                policy: policy
            )
        }

        #expect(reason == .stuck)
        #expect(tracker.stalledDuration == 0)
    }

    @Test("stationary neutral input is not considered stuck")
    func stationaryWithoutDriveDoesNotReset() {
        var tracker = VehicleRecoveryTracker()
        let policy = Phase0VehicleComparison.recovery

        let reason = tracker.resetReason(
            for: makeState(isGrounded: true),
            input: .neutral,
            timing: makeTiming(
                deltaTime: policy.maximumStalledDuration * 2
            ),
            startPose: Phase0VehicleComparison.startPose,
            policy: policy
        )

        #expect(reason == nil)
        #expect(tracker.stalledDuration == 0)
    }

    private func makeState(isGrounded: Bool) -> VehicleState {
        VehicleState(
            pose: Phase0VehicleComparison.startPose,
            linearVelocity: .zero,
            angularVelocity: .zero,
            isGrounded: isGrounded,
            contactCount: isGrounded ? 1 : 0
        )
    }

    private func makeTiming(
        deltaTime: TimeInterval
    ) -> VehicleUpdateTiming {
        VehicleUpdateTiming(
            stepIndex: 0,
            deltaTime: deltaTime,
            elapsedTime: deltaTime
        )
    }
}
