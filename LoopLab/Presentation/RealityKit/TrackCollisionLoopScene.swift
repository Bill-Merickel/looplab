//
//  TrackCollisionLoopScene.swift
//  LoopLab
//

import RealityKit
import UIKit

/// Static track collision plus one small dynamic probe for every loop seam.
///
/// The probes are intentionally simple Phase 0 diagnostics, not vehicles.
@MainActor
final class TrackCollisionLoopScene {
    static let rootEntityName = "phase-0-collision-loop"
    static let seamProbeNamePrefix = "seam-probe-"

    let root: Entity
    let trackEntities: [Entity]
    let seamProbes: [Entity]

    init(assembly: TrackAssembly) async throws {
        let root = Entity()
        root.name = Self.rootEntityName
        root.scale = SIMD3(repeating: 0.35)
        root.position = SIMD3(0.28, -0.45, -1.2)

        var trackEntities: [Entity] = []
        for piece in assembly.pieces {
            guard let definition = TrackPieceCatalog.definition(
                for: piece.kind
            ) else {
                throw TrackAssemblyError.missingDefinition(piece.kind)
            }

            let entity = try await TrackPieceEntityFactory
                .makeCollidableEntity(for: definition)
            entity.name = Self.placedEntityName(for: piece.id)
            Self.apply(piece.transform, to: entity)
            root.addChild(entity)
            trackEntities.append(entity)
        }

        var seamProbes: [Entity] = []
        for (index, connection) in assembly.connections.enumerated() {
            let endpoints = try assembly.directedEndpoints(
                for: connection
            )
            let (piece, socket) = try assembly.resolve(endpoints.exit)
            let socketWorld = piece.transform.concatenating(
                socket.localTransform
            )
            let direction = simd_normalize(
                socketWorld.transform(direction: SIMD3(0, 0, 1))
            )
            let probe = Self.makeSeamProbe(
                index: index,
                position: socketWorld.position
                    - direction * 0.14
                    + SIMD3(0, 0.055, 0),
                velocity: direction * 0.45
            )
            root.addChild(probe)
            seamProbes.append(probe)
        }

        self.root = root
        self.trackEntities = trackEntities
        self.seamProbes = seamProbes
    }

    static func placedEntityName(
        for id: PlacedTrackPiece.ID
    ) -> String {
        "collision-track-piece-\(id.rawValue)"
    }

    private static func makeSeamProbe(
        index: Int,
        position: SIMD3<Float>,
        velocity: SIMD3<Float>
    ) -> ModelEntity {
        let radius: Float = 0.045
        let shape = ShapeResource.generateSphere(radius: radius)
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(
            color: .init(red: 0.95, green: 0.45, blue: 0.08, alpha: 1),
            roughness: 0.75,
            isMetallic: false
        )
        let probe = ModelEntity(mesh: mesh, materials: [material])
        probe.name = "\(seamProbeNamePrefix)\(index)"
        probe.position = position
        probe.components.set(CollisionComponent(shapes: [shape]))

        let physicsMaterial = PhysicsMaterialResource.generate(
            staticFriction: 0.05,
            dynamicFriction: 0.03,
            restitution: 0
        )
        var body = PhysicsBodyComponent(
            shapes: [shape],
            mass: 0.04,
            material: physicsMaterial,
            mode: .dynamic
        )
        body.isContinuousCollisionDetectionEnabled = true
        probe.components.set(body)
        probe.components.set(
            PhysicsMotionComponent(linearVelocity: velocity)
        )
        return probe
    }

    private static func apply(
        _ transform: TrackTransform,
        to entity: Entity
    ) {
        entity.position = transform.position
        entity.orientation = transform.orientation
    }
}
