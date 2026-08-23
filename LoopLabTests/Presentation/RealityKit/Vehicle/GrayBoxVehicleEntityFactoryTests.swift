//
//  GrayBoxVehicleEntityFactoryTests.swift
//  LoopLabTests
//

import RealityKit
import Testing
@testable import LoopLab

@Suite("Reusable gray-box vehicle presentation")
@MainActor
struct GrayBoxVehicleEntityFactoryTests {
    @Test("vehicle uses shared dimensions, mass, and center of mass")
    func vehicleUsesSharedConfiguration() throws {
        let configuration = Phase0VehicleComparison.configuration
        let vehicle = GrayBoxVehicleEntityFactory.makeEntity(
            configuration: configuration
        )
        let collision = try #require(
            vehicle.components[CollisionComponent.self]
        )
        let shape = try #require(collision.shapes.first)
        let body = try #require(
            vehicle.components[PhysicsBodyComponent.self]
        )

        #expect(vehicle.name == GrayBoxVehicleEntityFactory.entityName)
        #expect(shape.bounds.extents == configuration.dimensions.collisionSize)
        #expect(body.massProperties.mass == configuration.mass)
        #expect(
            body.massProperties.centerOfMass.position
                == configuration.centerOfMass
        )
        #expect(body.mode == .dynamic)
        #expect(body.isContinuousCollisionDetectionEnabled)
        #expect(body.linearDamping == 0.08)
        #expect(body.angularDamping == 0.2)
        #expect(collision.filter.group == Phase0CollisionGroups.vehicle)
        #expect(
            collision.filter.mask
                == Phase0CollisionGroups.trackSurface
        )
        #expect(
            vehicle.findEntity(
                named: GrayBoxVehicleEntityFactory.chassisName
            ) != nil
        )
        #expect(
            vehicle.findEntity(
                named: GrayBoxVehicleEntityFactory.forwardMarkerName
            ) != nil
        )
    }
}
