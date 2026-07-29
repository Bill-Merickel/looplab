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
    @Test("every gray-box piece has definition-sized static collision")
    func piecesHaveStaticCollision() async throws {
        for definition in TrackPieceCatalog.phase0 {
            let shape = try await TrackPieceEntityFactory.collisionShape(
                for: definition
            )
            let entity = try await TrackPieceEntityFactory
                .makeCollidableEntity(for: definition)
            let body = try #require(
                entity.components[PhysicsBodyComponent.self]
            )

            #expect(
                entity.components.has(CollisionComponent.self)
            )
            #expect(body.mode == .static)
            #expect(!shape.bounds.isEmpty)
            #expect(
                approximatelyEqual(
                    shape.bounds.min,
                    definition.bounds.minimum
                )
            )
            #expect(
                approximatelyEqual(
                    shape.bounds.max,
                    definition.bounds.maximum
                )
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
        #expect(scene.trackEntities.count == assembly.pieces.count)
        #expect(scene.seamProbes.count == assembly.connections.count)
        #expect(
            scene.root.children.count
                == assembly.pieces.count + assembly.connections.count
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
