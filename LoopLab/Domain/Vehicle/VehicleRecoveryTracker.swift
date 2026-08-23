//
//  VehicleRecoveryTracker.swift
//  LoopLab
//

import Foundation

/// Stateful, renderer-neutral detection for lost-surface and stuck recovery.
nonisolated struct VehicleRecoveryTracker: Equatable, Sendable {
    private(set) var ungroundedDuration: TimeInterval = 0
    private(set) var stalledDuration: TimeInterval = 0

    mutating func resetReason(
        for state: VehicleState,
        input: SemanticInputState,
        timing: VehicleUpdateTiming,
        startPose: TrackTransform,
        policy: VehicleRecoveryPolicy
    ) -> VehicleResetReason? {
        if let immediateReason = policy.resetReason(
            for: state,
            startPose: startPose
        ) {
            reset()
            return immediateReason
        }

        if state.isGrounded {
            ungroundedDuration = 0
        } else {
            ungroundedDuration += timing.deltaTime
        }

        let hasDriveIntent = max(input.throttle, input.brakeReverse)
            >= policy.minimumDriveInput
        if state.isGrounded
            && hasDriveIntent
            && state.speed < policy.minimumMovementSpeed {
            stalledDuration += timing.deltaTime
        } else {
            stalledDuration = 0
        }

        if ungroundedDuration >= policy.maximumUngroundedDuration {
            reset()
            return .lostTrackSurface
        }
        if stalledDuration >= policy.maximumStalledDuration {
            reset()
            return .stuck
        }
        return nil
    }

    mutating func reset() {
        ungroundedDuration = 0
        stalledDuration = 0
    }
}
