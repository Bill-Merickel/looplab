//
//  VehicleRecoveryPolicy.swift
//  LoopLab
//

import simd

/// Shared automatic-recovery thresholds used during controller comparisons.
nonisolated struct VehicleRecoveryPolicy: Equatable, Sendable {
    let minimumHeight: Float
    let maximumDistanceFromStart: Float

    func resetReason(
        for state: VehicleState,
        startPose: TrackTransform
    ) -> VehicleResetReason? {
        guard state.hasValidValues else {
            return .invalidState
        }
        guard state.pose.position.y >= minimumHeight else {
            return .fellBelowTrack
        }
        guard simd_distance(
            state.pose.position,
            startPose.position
        ) <= maximumDistanceFromStart else {
            return .leftCourseBounds
        }
        return nil
    }
}
