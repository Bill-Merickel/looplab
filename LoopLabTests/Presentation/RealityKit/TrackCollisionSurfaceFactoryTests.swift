//
//  TrackCollisionSurfaceFactoryTests.swift
//  LoopLabTests
//

import simd
import Testing
@testable import LoopLab

@Suite("Unified track collision surface")
@MainActor
struct TrackCollisionSurfaceFactoryTests {
    @Test("every connected seam is one shared mesh edge")
    func everySeamIsWelded() throws {
        let assembly = try Phase0CollisionLoop.makeAssembly()
        let mesh = try TrackCollisionSurfaceFactory.meshData(for: assembly)

        for connection in assembly.connections {
            let endpoints = try assembly.directedEndpoints(for: connection)
            let (piece, socket) = try assembly.resolve(endpoints.exit)
            let definition = try #require(
                TrackPieceCatalog.definition(for: piece.kind)
            )
            let socketWorld = piece.transform.concatenating(
                socket.localTransform
            )
            let right = simd_normalize(
                socketWorld.transform(direction: SIMD3(1, 0, 0))
            )
            let halfWidth = definition.laneWidth / 2
            let firstPosition = socketWorld.position - right * halfWidth
            let secondPosition = socketWorld.position + right * halfWidth
            let firstIndex = try vertexIndex(
                nearest: firstPosition,
                in: mesh.positions
            )
            let secondIndex = try vertexIndex(
                nearest: secondPosition,
                in: mesh.positions
            )

            #expect(
                triangleCount(
                    sharingEdge: firstIndex,
                    secondIndex,
                    indices: mesh.triangleIndices
                ) == 2,
                "A connected seam must be shared by its two adjacent decks."
            )
        }
    }

    @Test("surface contains top faces only")
    func surfaceContainsTopFacesOnly() throws {
        let assembly = try Phase0CollisionLoop.makeAssembly()
        let mesh = try TrackCollisionSurfaceFactory.meshData(for: assembly)

        #expect(mesh.positions.isEmpty == false)
        #expect(mesh.triangleIndices.isEmpty == false)
        #expect(mesh.triangleIndices.count.isMultiple(of: 3))
        #expect(mesh.positions.allSatisfy { abs($0.y) <= 0.0001 })
    }

    private func vertexIndex(
        nearest position: SIMD3<Float>,
        in positions: [SIMD3<Float>]
    ) throws -> UInt32 {
        let match = positions.enumerated().min {
            simd_distance($0.element, position)
                < simd_distance($1.element, position)
        }
        let nearest = try #require(match)
        try #require(
            simd_distance(nearest.element, position) <= 0.0001,
            "The seam endpoint must exist in the collision mesh."
        )
        return UInt32(nearest.offset)
    }

    private func triangleCount(
        sharingEdge first: UInt32,
        _ second: UInt32,
        indices: [UInt32]
    ) -> Int {
        indices.chunks(ofCount: 3).count { triangle in
            triangle.contains(first) && triangle.contains(second)
        }
    }
}

private extension Array {
    func chunks(ofCount count: Int) -> [[Element]] {
        stride(from: 0, to: self.count, by: count).map {
            Array(self[$0..<Swift.min($0 + count, self.count)])
        }
    }
}
