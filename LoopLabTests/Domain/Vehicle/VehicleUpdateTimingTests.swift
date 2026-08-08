//
//  VehicleUpdateTimingTests.swift
//  LoopLabTests
//

import Foundation
import Testing
@testable import LoopLab

@Suite("Shared vehicle update timing")
struct VehicleUpdateTimingTests {
    @Test("valid frame delta advances shared elapsed time")
    func validFrameDeltaAdvancesTime() {
        let configuration = Phase0VehicleComparison.timing
        let frameDeltaTime = TimeInterval(1.0 / 60.0)
        let timing = configuration.makeTiming(
            frameDeltaTime: frameDeltaTime,
            stepIndex: 4,
            elapsedTime: 0.5
        )

        #expect(timing.stepIndex == 4)
        #expect(abs(timing.deltaTime - frameDeltaTime) < 0.000_000_001)
        #expect(
            abs(timing.elapsedTime - (0.5 + frameDeltaTime))
                < 0.000_000_001
        )
    }

    @Test(
        "invalid frame deltas use the nominal update",
        arguments: [TimeInterval.zero, -.infinity, .infinity, .nan]
    )
    func invalidFrameDeltaUsesNominal(frameDeltaTime: TimeInterval) {
        let configuration = Phase0VehicleComparison.timing
        let timing = configuration.makeTiming(
            frameDeltaTime: frameDeltaTime,
            stepIndex: 0,
            elapsedTime: 0
        )

        #expect(timing.deltaTime == configuration.nominalDeltaTime)
    }

    @Test("long frames are capped for both controller approaches")
    func longFramesAreCapped() {
        let configuration = Phase0VehicleComparison.timing
        let timing = configuration.makeTiming(
            frameDeltaTime: 1,
            stepIndex: 0,
            elapsedTime: 0
        )

        #expect(timing.deltaTime == configuration.maximumDeltaTime)
    }
}
