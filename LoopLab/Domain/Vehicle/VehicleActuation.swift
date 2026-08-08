//
//  VehicleActuation.swift
//  LoopLab
//

/// Controller output interpreted by the shared RealityKit vehicle adapter.
nonisolated enum VehicleActuation: Equatable, Sendable {
    case none
    case forces(force: SIMD3<Float>, torque: SIMD3<Float>)
    case constrained(
        pose: TrackTransform,
        linearVelocity: SIMD3<Float>,
        angularVelocity: SIMD3<Float>
    )
}
