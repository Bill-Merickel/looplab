//
//  VehicleRecoveryPolicyTests.swift
//  LoopLabTests
//

import Testing
@testable import LoopLab

@Suite("Shared vehicle recovery policy")
struct VehicleRecoveryPolicyTests {
    @Test("stable start state does not request recovery")
    func stableStartDoesNotReset() {
        let startPose = Phase0VehicleComparison.startPose
        let state = VehicleState.resting(at: startPose)

        #expect(
            Phase0VehicleComparison.recovery.resetReason(
                for: state,
                startPose: startPose
            ) == nil
        )
    }

    @Test("falling below the shared course requests recovery")
    func fallingBelowTrackResets() {
        let startPose = Phase0VehicleComparison.startPose
        let state = VehicleState.resting(
            at: TrackTransform(position: SIMD3(0, -1, 0))
        )

        #expect(
            Phase0VehicleComparison.recovery.resetReason(
                for: state,
                startPose: startPose
            ) == .fellBelowTrack
        )
    }

    @Test("leaving shared course bounds requests recovery")
    func leavingBoundsResets() {
        let startPose = Phase0VehicleComparison.startPose
        let state = VehicleState.resting(
            at: TrackTransform(position: SIMD3(5, startPose.position.y, 0))
        )

        #expect(
            Phase0VehicleComparison.recovery.resetReason(
                for: state,
                startPose: startPose
            ) == .leftCourseBounds
        )
    }
}
