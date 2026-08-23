//
//  PhysicsForceCalculation.swift
//  LoopLab
//

/// Inspectable components of one pure physics-force calculation.
nonisolated struct PhysicsForceCalculation: Equatable, Sendable {
    let driveForce: SIMD3<Float>
    let brakingForce: SIMD3<Float>
    let lateralGripForce: SIMD3<Float>
    let groundingForce: SIMD3<Float>
    let steeringTorque: SIMD3<Float>
    let stabilityTorque: SIMD3<Float>
    let forwardSpeed: Float
    let lateralSpeed: Float
    let steeringResponse: Float

    static let zero = PhysicsForceCalculation(
        driveForce: .zero,
        brakingForce: .zero,
        lateralGripForce: .zero,
        groundingForce: .zero,
        steeringTorque: .zero,
        stabilityTorque: .zero,
        forwardSpeed: 0,
        lateralSpeed: 0,
        steeringResponse: 0
    )

    var force: SIMD3<Float> {
        driveForce + brakingForce + lateralGripForce + groundingForce
    }

    var torque: SIMD3<Float> {
        steeringTorque + stabilityTorque
    }
}
