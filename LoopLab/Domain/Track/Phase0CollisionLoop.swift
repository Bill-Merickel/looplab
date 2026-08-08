//
//  Phase0CollisionLoop.swift
//  LoopLab
//

/// Deterministic snapped loop used by the Phase 0 collision prototypes.
nonisolated enum Phase0CollisionLoop {
    static let courseID = "phase-0-collision-loop"
    static let startFinishID = PlacedTrackPiece.ID(
        rawValue: "loop-start-finish"
    )
    static let pieceIDs: [PlacedTrackPiece.ID] = [
        startFinishID,
        .init(rawValue: "loop-curve-1"),
        .init(rawValue: "loop-curve-2"),
        .init(rawValue: "loop-straight"),
        .init(rawValue: "loop-curve-3"),
        .init(rawValue: "loop-curve-4"),
    ]

    static func makeAssembly() throws -> TrackAssembly {
        let sequence: [(PlacedTrackPiece.ID, TrackPieceKind)] = [
            (pieceIDs[0], .startFinish),
            (pieceIDs[1], .leftCurve),
            (pieceIDs[2], .leftCurve),
            (pieceIDs[3], .straight),
            (pieceIDs[4], .leftCurve),
            (pieceIDs[5], .leftCurve),
        ]
        var assembly = TrackAssembly()

        for (index, element) in sequence.enumerated() {
            try assembly.add(
                PlacedTrackPiece(
                    id: element.0,
                    kind: element.1,
                    transform: .identity
                )
            )

            guard index > 0 else {
                continue
            }
            let previousID = sequence[index - 1].0
            try assembly.snapAndConnect(
                moving: TrackSocketReference(
                    pieceID: element.0,
                    socketID: .entry
                ),
                to: TrackSocketReference(
                    pieceID: previousID,
                    socketID: .exit
                )
            )
        }

        let finalID = sequence[sequence.count - 1].0
        try assembly.connectAligned(
            TrackSocketReference(
                pieceID: finalID,
                socketID: .exit
            ),
            to: TrackSocketReference(
                pieceID: startFinishID,
                socketID: .entry
            )
        )

        return assembly
    }
}
