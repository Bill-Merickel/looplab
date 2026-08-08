//
//  VehicleDimensions.swift
//  LoopLab
//

/// Renderer-independent gray-box vehicle dimensions in meters.
nonisolated struct VehicleDimensions: Equatable, Sendable {
    let width: Float
    let height: Float
    let length: Float

    var collisionSize: SIMD3<Float> {
        SIMD3(width, height, length)
    }

    var hasPositiveDimensions: Bool {
        width.isFinite && width > 0
            && height.isFinite && height > 0
            && length.isFinite && length > 0
    }
}
