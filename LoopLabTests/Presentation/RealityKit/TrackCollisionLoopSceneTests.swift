//
//  TrackCollisionLoopSceneTests.swift
//  LoopLabTests
//

import RealityKit
import Testing
@testable import LoopLab

@Suite("Closed-loop RealityKit collision presentation")
@MainActor
struct TrackCollisionLoopSceneTests {
    @Test("scene uses one non-rendering static drive surface")
    func sceneUsesOneStaticDriveSurface() async throws {
        let assembly = try Phase0CollisionLoop.makeAssembly()
        let scene = try await TrackCollisionLoopScene(
            assembly: assembly
        )
        let surface = scene.collisionSurface
        let collision = try #require(
            surface.components[CollisionComponent.self]
        )
        let body = try #require(
            surface.components[PhysicsBodyComponent.self]
        )

        #expect(surface.name == TrackCollisionSurfaceFactory.entityName)
        #expect(collision.shapes.count == 1)
        #expect(
            collision.filter.group == Phase0CollisionGroups.trackSurface
        )
        #expect(body.mode == .static)
        #expect(surface.components.has(ModelComponent.self) == false)

        for entity in scene.trackEntities {
            #expect(entity.components.has(CollisionComponent.self) == false)
            #expect(
                entity.components.has(PhysicsBodyComponent.self) == false
            )
        }
    }

    @Test("scene generates one static track and one probe per seam")
    func sceneMirrorsAssembly() async throws {
        let assembly = try Phase0CollisionLoop.makeAssembly()
        let scene = try await TrackCollisionLoopScene(
            assembly: assembly
        )

        #expect(scene.root.name == TrackCollisionLoopScene.rootEntityName)
        #expect(
            scene.root.components.has(PhysicsSimulationComponent.self)
        )
        #expect(scene.trackEntities.count == assembly.pieces.count)
        #expect(scene.seamProbes.count == assembly.connections.count)
        #expect(
            scene.root.children.count
                == assembly.pieces.count + assembly.connections.count + 2
        )

        for piece in assembly.pieces {
            #expect(
                scene.root.findEntity(
                    named: TrackCollisionLoopScene.placedEntityName(
                        for: piece.id
                    )
                ) != nil
            )
        }
    }

    @Test("controller target is an unobstructed capture surface above the track")
    func controllerTargetCoversTrack() async throws {
        let assembly = try Phase0CollisionLoop.makeAssembly()
        let scene = try await TrackCollisionLoopScene(
            assembly: assembly
        )
        let target = scene.controllerInputTarget
        let collision = try #require(
            target.components[CollisionComponent.self]
        )
        let inputTarget = try #require(
            target.components[InputTargetComponent.self]
        )
        let shape = try #require(collision.shapes.first)

        var trackBounds = BoundingBox.empty
        for entity in scene.trackEntities {
            trackBounds.formUnion(
                entity.visualBounds(relativeTo: scene.root)
            )
        }

        let localCaptureBounds = shape.bounds
        let captureBounds = BoundingBox(
            min: localCaptureBounds.min + target.position,
            max: localCaptureBounds.max + target.position
        )

        #expect(
            target.name == TrackCollisionLoopScene.controllerInputTargetName
        )
        #expect(inputTarget.allowedInputTypes.contains(.indirect))
        #expect(collision.mode == .trigger)
        #expect(
            collision.filter == CollisionFilter(group: [], mask: [])
        )
        #expect(target.components.has(ModelComponent.self) == false)
        #expect(target.components.has(PhysicsBodyComponent.self) == false)
        #expect(captureBounds.min.x < trackBounds.min.x)
        #expect(captureBounds.max.x > trackBounds.max.x)
        #expect(captureBounds.min.y > trackBounds.max.y)
        #expect(captureBounds.min.z < trackBounds.min.z)
        #expect(captureBounds.max.z > trackBounds.max.z)
    }

    @Test("seam probes use continuous dynamic collision")
    func probesUseContinuousCollision() async throws {
        let assembly = try Phase0CollisionLoop.makeAssembly()
        let scene = try await TrackCollisionLoopScene(
            assembly: assembly
        )

        for (index, probe) in scene.seamProbes.enumerated() {
            let body = try #require(
                probe.components[PhysicsBodyComponent.self]
            )
            let motion = try #require(
                probe.components[PhysicsMotionComponent.self]
            )

            #expect(
                probe.name
                    == "\(TrackCollisionLoopScene.seamProbeNamePrefix)\(index)"
            )
            #expect(probe.components.has(CollisionComponent.self))
            #expect(body.mode == .dynamic)
            #expect(body.isContinuousCollisionDetectionEnabled)
            #expect(length(motion.linearVelocity) > 0)
        }
    }

    private func approximatelyEqual(
        _ lhs: SIMD3<Float>,
        _ rhs: SIMD3<Float>,
        tolerance: Float = 0.0001
    ) -> Bool {
        length(lhs - rhs) <= tolerance
    }
}
