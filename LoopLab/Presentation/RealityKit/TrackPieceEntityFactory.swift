//
//  TrackPieceEntityFactory.swift
//  LoopLab
//

import Foundation
import RealityKit
import UIKit
import simd

/// Builds gray-box RealityKit entities from renderer-independent definitions.
@MainActor
enum TrackPieceEntityFactory {
    private static let curveSegmentCount = 24

    static func makeEntity(
        for definition: TrackPieceDefinition
    ) throws -> Entity {
        let root = Entity()
        root.name = entityName(for: definition.kind)

        switch definition.geometry {
        case let .straight(length, deckThickness):
            root.addChild(
                makeBox(
                    name: "deck",
                    size: SIMD3(
                        definition.laneWidth,
                        deckThickness,
                        length
                    ),
                    position: SIMD3(0, -deckThickness / 2, 0),
                    material: deckMaterial
                )
            )

        case let .leftCurve(
            centerlineRadius,
            sweepAngle,
            deckThickness
        ):
            let mesh = try makeCurveMesh(
                centerlineRadius: centerlineRadius,
                laneWidth: definition.laneWidth,
                sweepAngle: sweepAngle,
                deckThickness: deckThickness
            )
            let deck = ModelEntity(mesh: mesh, materials: [deckMaterial])
            deck.name = "deck"
            root.addChild(deck)

        case let .startFinish(
            length,
            deckThickness,
            markerWidth
        ):
            addStartFinishDeck(
                to: root,
                length: length,
                laneWidth: definition.laneWidth,
                deckThickness: deckThickness,
                markerWidth: markerWidth
            )
        }

        return root
    }

    static func entityName(for kind: TrackPieceKind) -> String {
        "track-piece-\(kind.rawValue)"
    }

    private static var deckMaterial: SimpleMaterial {
        SimpleMaterial(
            color: .gray,
            roughness: 0.85,
            isMetallic: false
        )
    }

    private static var markerMaterial: SimpleMaterial {
        SimpleMaterial(
            color: .white,
            roughness: 0.9,
            isMetallic: false
        )
    }

    private static func makeBox(
        name: String,
        size: SIMD3<Float>,
        position: SIMD3<Float>,
        material: SimpleMaterial
    ) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: size)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        entity.position = position
        return entity
    }

    private static func addStartFinishDeck(
        to root: Entity,
        length: Float,
        laneWidth: Float,
        deckThickness: Float,
        markerWidth: Float
    ) {
        let sideLength = (length - markerWidth) / 2
        let sideOffset = (markerWidth + sideLength) / 2
        let deckSize = SIMD3(laneWidth, deckThickness, sideLength)
        let deckY = -deckThickness / 2

        root.addChild(
            makeBox(
                name: "deck-entry-side",
                size: deckSize,
                position: SIMD3(0, deckY, -sideOffset),
                material: deckMaterial
            )
        )
        root.addChild(
            makeBox(
                name: "start-finish-marker",
                size: SIMD3(laneWidth, deckThickness, markerWidth),
                position: SIMD3(0, deckY, 0),
                material: markerMaterial
            )
        )
        root.addChild(
            makeBox(
                name: "deck-exit-side",
                size: deckSize,
                position: SIMD3(0, deckY, sideOffset),
                material: deckMaterial
            )
        )
    }

    private static func makeCurveMesh(
        centerlineRadius: Float,
        laneWidth: Float,
        sweepAngle: Float,
        deckThickness: Float
    ) throws -> MeshResource {
        let innerRadius = centerlineRadius - laneWidth / 2
        let outerRadius = centerlineRadius + laneWidth / 2
        let topY: Float = 0
        let bottomY = -deckThickness
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        func point(radius: Float, angle: Float, y: Float) -> SIMD3<Float> {
            SIMD3(radius * cos(angle), y, radius * sin(angle))
        }

        func appendQuad(
            _ a: SIMD3<Float>,
            _ b: SIMD3<Float>,
            _ c: SIMD3<Float>,
            _ d: SIMD3<Float>,
            normal: SIMD3<Float>
        ) {
            let baseIndex = UInt32(positions.count)
            positions.append(contentsOf: [a, b, c, d])
            normals.append(contentsOf: Array(repeating: normal, count: 4))
            indices.append(contentsOf: [
                baseIndex,
                baseIndex + 1,
                baseIndex + 2,
                baseIndex,
                baseIndex + 2,
                baseIndex + 3,
            ])
        }

        for segment in 0..<curveSegmentCount {
            let startAngle = sweepAngle
                * Float(segment)
                / Float(curveSegmentCount)
            let endAngle = sweepAngle
                * Float(segment + 1)
                / Float(curveSegmentCount)
            let middleAngle = (startAngle + endAngle) / 2

            let innerStartTop = point(
                radius: innerRadius,
                angle: startAngle,
                y: topY
            )
            let innerEndTop = point(
                radius: innerRadius,
                angle: endAngle,
                y: topY
            )
            let outerStartTop = point(
                radius: outerRadius,
                angle: startAngle,
                y: topY
            )
            let outerEndTop = point(
                radius: outerRadius,
                angle: endAngle,
                y: topY
            )
            let innerStartBottom = point(
                radius: innerRadius,
                angle: startAngle,
                y: bottomY
            )
            let innerEndBottom = point(
                radius: innerRadius,
                angle: endAngle,
                y: bottomY
            )
            let outerStartBottom = point(
                radius: outerRadius,
                angle: startAngle,
                y: bottomY
            )
            let outerEndBottom = point(
                radius: outerRadius,
                angle: endAngle,
                y: bottomY
            )

            appendQuad(
                innerStartTop,
                innerEndTop,
                outerEndTop,
                outerStartTop,
                normal: SIMD3(0, 1, 0)
            )
            appendQuad(
                innerStartBottom,
                outerStartBottom,
                outerEndBottom,
                innerEndBottom,
                normal: SIMD3(0, -1, 0)
            )

            let radialNormal = SIMD3(
                cos(middleAngle),
                0,
                sin(middleAngle)
            )
            appendQuad(
                outerStartTop,
                outerEndTop,
                outerEndBottom,
                outerStartBottom,
                normal: radialNormal
            )
            appendQuad(
                innerStartTop,
                innerStartBottom,
                innerEndBottom,
                innerEndTop,
                normal: -radialNormal
            )
        }

        let startInnerTop = point(radius: innerRadius, angle: 0, y: topY)
        let startOuterTop = point(radius: outerRadius, angle: 0, y: topY)
        let startInnerBottom = point(
            radius: innerRadius,
            angle: 0,
            y: bottomY
        )
        let startOuterBottom = point(
            radius: outerRadius,
            angle: 0,
            y: bottomY
        )
        appendQuad(
            startInnerTop,
            startOuterTop,
            startOuterBottom,
            startInnerBottom,
            normal: SIMD3(0, 0, -1)
        )

        let endInnerTop = point(
            radius: innerRadius,
            angle: sweepAngle,
            y: topY
        )
        let endOuterTop = point(
            radius: outerRadius,
            angle: sweepAngle,
            y: topY
        )
        let endInnerBottom = point(
            radius: innerRadius,
            angle: sweepAngle,
            y: bottomY
        )
        let endOuterBottom = point(
            radius: outerRadius,
            angle: sweepAngle,
            y: bottomY
        )
        let endNormal = SIMD3(-sin(sweepAngle), 0, cos(sweepAngle))
        appendQuad(
            endInnerTop,
            endInnerBottom,
            endOuterBottom,
            endOuterTop,
            normal: endNormal
        )

        var descriptor = MeshDescriptor(name: "left-curve-deck")
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)
        descriptor.materials = .allFaces(0)

        return try MeshResource.generate(from: [descriptor])
    }
}
