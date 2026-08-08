//
//  VehicleState.swift
//  LoopLab
//

import simd

/// Runtime state shared by controller implementations and evaluation code.
nonisolated struct VehicleState: Equatable, Sendable {
    let pose: TrackTransform
    let linearVelocity: SIMD3<Float>
    let angularVelocity: SIMD3<Float>
    let isGrounded: Bool
    let contactCount: Int

    static func resting(at pose: TrackTransform) -> VehicleState {
        VehicleState(
            pose: pose,
            linearVelocity: .zero,
            angularVelocity: .zero,
            isGrounded: false,
            contactCount: 0
        )
    }

    var speed: Float {
        simd_length(linearVelocity)
    }

    var hasValidValues: Bool {
        pose.hasValidPose
            && linearVelocity.x.isFinite
            && linearVelocity.y.isFinite
            && linearVelocity.z.isFinite
            && angularVelocity.x.isFinite
            && angularVelocity.y.isFinite
            && angularVelocity.z.isFinite
            && contactCount >= 0
    }
}
