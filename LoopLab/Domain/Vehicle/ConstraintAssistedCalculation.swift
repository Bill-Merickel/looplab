//
//  ConstraintAssistedCalculation.swift
//  LoopLab
//

/// Inspectable result of one pure constraint-assisted vehicle calculation.
nonisolated struct ConstraintAssistedCalculation: Equatable, Sendable {
    let pose: TrackTransform
    let linearVelocity: SIMD3<Float>
    let angularVelocity: SIMD3<Float>
    let forwardSpeed: Float
    let lateralSpeed: Float
    let steeringResponse: Float
    let yawRate: Float
}
