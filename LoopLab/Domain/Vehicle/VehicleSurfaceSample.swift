//
//  VehicleSurfaceSample.swift
//  LoopLab
//

import simd

/// Renderer-neutral result of probing the course beneath the vehicle.
nonisolated struct VehicleSurfaceSample: Equatable, Sendable {
    let isGrounded: Bool
    let distance: Float?
    let normal: SIMD3<Float>

    static let airborne = VehicleSurfaceSample(
        isGrounded: false,
        distance: nil,
        normal: SIMD3(0, 1, 0)
    )

    init(
        isGrounded: Bool,
        distance: Float?,
        normal: SIMD3<Float>
    ) {
        let hasValidDistance = distance.map {
            $0.isFinite && $0 >= 0
        } ?? false
        let normalLength = simd_length(normal)
        let hasValidNormal = normal.x.isFinite
            && normal.y.isFinite
            && normal.z.isFinite
            && normalLength > 0

        guard isGrounded, hasValidDistance, hasValidNormal else {
            self.isGrounded = false
            self.distance = nil
            self.normal = SIMD3(0, 1, 0)
            return
        }

        self.isGrounded = true
        self.distance = distance
        self.normal = normal / normalLength
    }
}
