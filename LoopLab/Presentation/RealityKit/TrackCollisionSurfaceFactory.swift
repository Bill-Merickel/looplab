//
//  TrackCollisionSurfaceFactory.swift
//  LoopLab
//

import RealityKit
import simd

/// Builds one welded drive surface for a complete track assembly.
///
/// Keeping physics on one top-only mesh prevents the closed end faces of
/// adjacent piece shapes from becoming invisible obstacles at track seams.
@MainActor
enum TrackCollisionSurfaceFactory {
    static let entityName = "track-collision-surface"

    struct MeshData {
        let positions: [SIMD3<Float>]
        let triangleIndices: [UInt32]
    }

    static func makeEntity(
        for assembly: TrackAssembly
    ) async throws -> Entity {
        let data = try meshData(for: assembly)
        var descriptor = MeshDescriptor(name: entityName)
        descriptor.positions = MeshBuffer(data.positions)
        descriptor.primitives = .triangles(data.triangleIndices)

        let mesh = try MeshResource.generate(from: [descriptor])
        let shape = try await ShapeResource.generateStaticMesh(from: mesh)
        let material = PhysicsMaterialResource.generate(
            staticFriction: 0.35,
            dynamicFriction: 0.25,
            restitution: 0
        )
        let entity = Entity()
        entity.name = entityName
        entity.components.set(
            CollisionComponent(
                shapes: [shape],
                filter: CollisionFilter(
                    group: Phase0CollisionGroups.trackSurface,
                    mask: .all
                )
            )
        )
        entity.components.set(
            PhysicsBodyComponent(
                shapes: [shape],
                mass: 1,
                material: material,
                mode: .static
            )
        )
        return entity
    }

    static func meshData(
        for assembly: TrackAssembly
    ) throws -> MeshData {
        var builder = SurfaceMeshBuilder()

        for piece in assembly.pieces {
            guard let definition = TrackPieceCatalog.definition(
                for: piece.kind
            ) else {
                throw TrackAssemblyError.missingDefinition(piece.kind)
            }

            switch definition.geometry {
            case let .straight(length, _),
                 let .startFinish(length, _, _):
                builder.appendStraight(
                    length: length,
                    laneWidth: definition.laneWidth,
                    transform: piece.transform
                )

            case let .leftCurve(centerlineRadius, sweepAngle, _):
                builder.appendCurve(
                    centerlineRadius: centerlineRadius,
                    laneWidth: definition.laneWidth,
                    sweepAngle: sweepAngle,
                    transform: piece.transform
                )
            }
        }

        return MeshData(
            positions: builder.positions,
            triangleIndices: builder.triangleIndices
        )
    }
}

private struct SurfaceMeshBuilder {
    private static let curveSegmentCount = 24
    private static let weldTolerance = TrackSeamTolerance
        .phase0
        .laneEdgePosition

    private(set) var positions: [SIMD3<Float>] = []
    private(set) var triangleIndices: [UInt32] = []

    mutating func appendStraight(
        length: Float,
        laneWidth: Float,
        transform: TrackTransform
    ) {
        let halfWidth = laneWidth / 2
        let halfLength = length / 2
        appendQuad(
            SIMD3(-halfWidth, 0, -halfLength),
            SIMD3(-halfWidth, 0, halfLength),
            SIMD3(halfWidth, 0, halfLength),
            SIMD3(halfWidth, 0, -halfLength),
            transform: transform
        )
    }

    mutating func appendCurve(
        centerlineRadius: Float,
        laneWidth: Float,
        sweepAngle: Float,
        transform: TrackTransform
    ) {
        let innerRadius = centerlineRadius - laneWidth / 2
        let outerRadius = centerlineRadius + laneWidth / 2

        for segment in 0..<Self.curveSegmentCount {
            let startAngle = sweepAngle
                * Float(segment)
                / Float(Self.curveSegmentCount)
            let endAngle = sweepAngle
                * Float(segment + 1)
                / Float(Self.curveSegmentCount)
            appendQuad(
                point(radius: innerRadius, angle: startAngle),
                point(radius: innerRadius, angle: endAngle),
                point(radius: outerRadius, angle: endAngle),
                point(radius: outerRadius, angle: startAngle),
                transform: transform
            )
        }
    }

    private func point(
        radius: Float,
        angle: Float
    ) -> SIMD3<Float> {
        SIMD3(radius * cos(angle), 0, radius * sin(angle))
    }

    private mutating func appendQuad(
        _ a: SIMD3<Float>,
        _ b: SIMD3<Float>,
        _ c: SIMD3<Float>,
        _ d: SIMD3<Float>,
        transform: TrackTransform
    ) {
        let indices = [a, b, c, d].map {
            vertexIndex(for: transform.transform(point: $0))
        }
        triangleIndices.append(contentsOf: [
            indices[0],
            indices[1],
            indices[2],
            indices[0],
            indices[2],
            indices[3],
        ])
    }

    private mutating func vertexIndex(
        for position: SIMD3<Float>
    ) -> UInt32 {
        if let index = positions.firstIndex(where: {
            simd_distance($0, position) <= Self.weldTolerance
        }) {
            return UInt32(index)
        }

        positions.append(position)
        return UInt32(positions.count - 1)
    }
}
