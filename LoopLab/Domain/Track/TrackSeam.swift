//
//  TrackSeam.swift
//  LoopLab
//

import simd

/// Maximum geometric discontinuities accepted at a Phase 0 snapped seam.
nonisolated struct TrackSeamTolerance: Equatable, Sendable {
    let centerlinePosition: Float
    let surfaceHeight: Float
    let tangentAngleRadians: Float
    let laneEdgePosition: Float

    /// 0.1 mm positional error and approximately 0.057° tangent error.
    static let phase0 = TrackSeamTolerance(
        centerlinePosition: 0.0001,
        surfaceHeight: 0.0001,
        tangentAngleRadians: 0.001,
        laneEdgePosition: 0.0001
    )
}

nonisolated struct TrackSeamMeasurement: Equatable, Sendable {
    let centerlinePositionError: Float
    let surfaceHeightError: Float
    let tangentAngleErrorRadians: Float
    let laneEdgePositionError: Float

    func isWithin(_ tolerance: TrackSeamTolerance) -> Bool {
        centerlinePositionError <= tolerance.centerlinePosition
            && surfaceHeightError <= tolerance.surfaceHeight
            && tangentAngleErrorRadians
                <= tolerance.tangentAngleRadians
            && laneEdgePositionError <= tolerance.laneEdgePosition
    }
}

/// Measures continuity using the same socket frames and lane widths as pieces.
nonisolated enum TrackSeamInspector {
    static func measure(
        connection: TrackConnection,
        in assembly: TrackAssembly
    ) throws -> TrackSeamMeasurement {
        try measure(
            source: connection.source,
            destination: connection.destination,
            in: assembly
        )
    }

    static func measure(
        source: TrackSocketReference,
        destination: TrackSocketReference,
        in assembly: TrackAssembly
    ) throws -> TrackSeamMeasurement {
        let (sourcePiece, sourceSocket) = try assembly.resolve(source)
        let (destinationPiece, destinationSocket) = try assembly.resolve(
            destination
        )
        guard sourceSocket.isCompatible(with: destinationSocket) else {
            throw TrackAssemblyError.incompatibleSockets
        }
        guard
            let sourceDefinition = TrackPieceCatalog.definition(
                for: sourcePiece.kind
            ),
            let destinationDefinition = TrackPieceCatalog.definition(
                for: destinationPiece.kind
            )
        else {
            throw TrackAssemblyError.missingDefinition(sourcePiece.kind)
        }

        let sourceWorld = sourcePiece.transform.concatenating(
            sourceSocket.localTransform
        )
        let destinationWorld = destinationPiece.transform.concatenating(
            destinationSocket.localTransform
        )
        let centerlineError = simd_distance(
            sourceWorld.position,
            destinationWorld.position
        )
        let heightError = abs(
            sourceWorld.position.y - destinationWorld.position.y
        )

        let sourceForward = simd_normalize(
            sourceWorld.transform(direction: SIMD3(0, 0, 1))
        )
        let destinationForward = simd_normalize(
            destinationWorld.transform(direction: SIMD3(0, 0, 1))
        )
        let facingDot = max(
            -1,
            min(1, simd_dot(sourceForward, -destinationForward))
        )
        let tangentError = acos(facingDot)

        let sourceRight = simd_normalize(
            sourceWorld.transform(direction: SIMD3(1, 0, 0))
        )
        let destinationRight = simd_normalize(
            destinationWorld.transform(direction: SIMD3(1, 0, 0))
        )
        let sourceHalfWidth = sourceDefinition.laneWidth / 2
        let destinationHalfWidth = destinationDefinition.laneWidth / 2
        let sourceNegativeEdge =
            sourceWorld.position - sourceRight * sourceHalfWidth
        let sourcePositiveEdge =
            sourceWorld.position + sourceRight * sourceHalfWidth
        let destinationNegativeEdge =
            destinationWorld.position
            - destinationRight * destinationHalfWidth
        let destinationPositiveEdge =
            destinationWorld.position
            + destinationRight * destinationHalfWidth

        let crossedPairing = max(
            simd_distance(
                sourceNegativeEdge,
                destinationPositiveEdge
            ),
            simd_distance(
                sourcePositiveEdge,
                destinationNegativeEdge
            )
        )
        let directPairing = max(
            simd_distance(
                sourceNegativeEdge,
                destinationNegativeEdge
            ),
            simd_distance(
                sourcePositiveEdge,
                destinationPositiveEdge
            )
        )

        return TrackSeamMeasurement(
            centerlinePositionError: centerlineError,
            surfaceHeightError: heightError,
            tangentAngleErrorRadians: tangentError,
            laneEdgePositionError: min(crossedPairing, directPairing)
        )
    }
}
