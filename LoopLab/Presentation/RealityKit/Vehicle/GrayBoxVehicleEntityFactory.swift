//
//  GrayBoxVehicleEntityFactory.swift
//  LoopLab
//

import RealityKit
import UIKit

/// Builds the single procedural vehicle shared by both Phase 0 controllers.
@MainActor
enum GrayBoxVehicleEntityFactory {
    static let entityName = "phase-0-gray-box-vehicle"
    static let chassisName = "gray-box-chassis"
    static let forwardMarkerName = "gray-box-forward-marker"

    static func makeEntity(
        configuration: VehicleConfiguration
    ) -> ModelEntity {
        precondition(configuration.hasValidValues)

        let root = ModelEntity()
        root.name = entityName

        let collisionShape = ShapeResource.generateBox(
            size: configuration.dimensions.collisionSize
        )
        root.components.set(
            CollisionComponent(shapes: [collisionShape])
        )

        let physicsMaterial = PhysicsMaterialResource.generate(
            staticFriction: 0.55,
            dynamicFriction: 0.4,
            restitution: 0
        )
        var body = PhysicsBodyComponent(
            shapes: [collisionShape],
            mass: configuration.mass,
            material: physicsMaterial,
            mode: .dynamic
        )
        body.massProperties.centerOfMass.position = configuration.centerOfMass
        body.isContinuousCollisionDetectionEnabled = true
        root.components.set(body)
        root.components.set(PhysicsMotionComponent())

        let chassis = ModelEntity(
            mesh: .generateBox(size: configuration.dimensions.collisionSize),
            materials: [
                SimpleMaterial(
                    color: .darkGray,
                    roughness: 0.8,
                    isMetallic: false
                ),
            ]
        )
        chassis.name = chassisName
        root.addChild(chassis)

        let markerSize = SIMD3<Float>(
            configuration.dimensions.width * 0.65,
            0.008,
            configuration.dimensions.length * 0.18
        )
        let marker = ModelEntity(
            mesh: .generateBox(size: markerSize),
            materials: [
                SimpleMaterial(
                    color: .systemYellow,
                    roughness: 0.8,
                    isMetallic: false
                ),
            ]
        )
        marker.name = forwardMarkerName
        marker.position = SIMD3(
            0,
            configuration.dimensions.height / 2 + markerSize.y / 2,
            configuration.dimensions.length * 0.28
        )
        root.addChild(marker)

        return root
    }
}
