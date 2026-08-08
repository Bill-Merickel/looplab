//
//  VehicleUpdateTiming.swift
//  LoopLab
//

import Foundation

/// One sanitized simulation update shared by either controller approach.
nonisolated struct VehicleUpdateTiming: Equatable, Sendable {
    let stepIndex: UInt64
    let deltaTime: TimeInterval
    let elapsedTime: TimeInterval
}

/// Bounds frame timing without deciding Phase 0's fixed-versus-variable ADR.
nonisolated struct VehicleTimingConfiguration: Equatable, Sendable {
    let nominalDeltaTime: TimeInterval
    let maximumDeltaTime: TimeInterval

    func makeTiming(
        frameDeltaTime: TimeInterval,
        stepIndex: UInt64,
        elapsedTime: TimeInterval
    ) -> VehicleUpdateTiming {
        let deltaTime: TimeInterval
        if frameDeltaTime.isFinite && frameDeltaTime > 0 {
            deltaTime = min(frameDeltaTime, maximumDeltaTime)
        } else {
            deltaTime = nominalDeltaTime
        }

        return VehicleUpdateTiming(
            stepIndex: stepIndex,
            deltaTime: deltaTime,
            elapsedTime: max(0, elapsedTime) + deltaTime
        )
    }
}
