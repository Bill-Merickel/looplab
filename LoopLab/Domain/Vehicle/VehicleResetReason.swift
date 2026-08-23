//
//  VehicleResetReason.swift
//  LoopLab
//

/// Why the shared harness restored the vehicle to its canonical start pose.
nonisolated enum VehicleResetReason: String, Equatable, Sendable {
    case manual
    case controllerChanged
    case fellBelowTrack
    case leftCourseBounds
    case lostTrackSurface
    case stuck
    case invalidState
}
