//
//  VehicleSurfaceSampleTests.swift
//  LoopLabTests
//

import Testing
@testable import LoopLab

struct VehicleSurfaceSampleTests {
    @Test("grounded surface normals are normalized")
    func normalIsNormalized() {
        let sample = VehicleSurfaceSample(
            isGrounded: true,
            distance: 0.06,
            normal: SIMD3(0, 2, 0)
        )

        #expect(sample.isGrounded)
        #expect(sample.distance == 0.06)
        #expect(sample.normal == SIMD3(0, 1, 0))
    }

    @Test(
        "invalid samples safely become airborne",
        arguments: [
            SIMD3<Float>.zero,
            SIMD3(.nan, 1, 0),
        ]
    )
    func invalidSampleBecomesAirborne(normal: SIMD3<Float>) {
        let sample = VehicleSurfaceSample(
            isGrounded: true,
            distance: 0.06,
            normal: normal
        )

        #expect(sample == .airborne)
    }

    @Test("grounded samples require a nonnegative finite distance")
    func invalidDistanceBecomesAirborne() {
        let missing = VehicleSurfaceSample(
            isGrounded: true,
            distance: nil,
            normal: SIMD3(0, 1, 0)
        )
        let negative = VehicleSurfaceSample(
            isGrounded: true,
            distance: -0.01,
            normal: SIMD3(0, 1, 0)
        )

        #expect(missing == .airborne)
        #expect(negative == .airborne)
    }
}
