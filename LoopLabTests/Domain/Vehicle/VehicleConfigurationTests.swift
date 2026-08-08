//
//  VehicleConfigurationTests.swift
//  LoopLabTests
//

import Testing
@testable import LoopLab

@Suite("Shared vehicle configuration")
struct VehicleConfigurationTests {
    @Test("Phase 0 configuration is valid and fits the shared lane")
    func phase0ConfigurationIsValid() {
        let configuration = Phase0VehicleComparison.configuration

        #expect(configuration.hasValidValues)
        #expect(configuration.dimensions.width < TrackPieceCatalog.laneWidth)
        #expect(configuration.id.rawValue == "phase-0-gray-box-vehicle")
        #expect(configuration.version == 1)
    }

    @Test("comparison run uses the collision loop and shared success target")
    func comparisonRunIsRepeatable() {
        let run = Phase0VehicleComparison.run

        #expect(run.courseID == Phase0CollisionLoop.courseID)
        #expect(run.targetConsecutiveLoops == 3)
        #expect(run.maximumDuration == 120)
    }
}
