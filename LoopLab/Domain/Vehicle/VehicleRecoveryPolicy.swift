//
//  VehicleRecoveryPolicy.swift
//  LoopLab
//

import Foundation
import simd

/// Shared automatic-recovery thresholds used during controller comparisons.
nonisolated struct VehicleRecoveryPolicy: Equatable, Sendable {
    let minimumHeight: Float
    let maximumDistanceFromStart: Float
    let maximumUngroundedDuration: TimeInterval
    let maximumStalledDuration: TimeInterval
    let minimumMovementSpeed: Float
    let minimumDriveInput: Float

    var hasValidValues: Bool {
        minimumHeight.isFinite
            && maximumDistanceFromStart.isFinite
            && maximumDistanceFromStart > 0
            && maximumUngroundedDuration.isFinite
            && maximumUngroundedDuration > 0
            && maximumStalledDuration.isFinite
            && maximumStalledDuration > 0
            && minimumMovementSpeed.isFinite
            && minimumMovementSpeed >= 0
            && minimumDriveInput.isFinite
            && minimumDriveInput >= 0 && minimumDriveInput <= 1
    }

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
