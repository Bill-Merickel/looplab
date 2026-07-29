//
//  TrackAssemblyGraph.swift
//  LoopLab
//

/// Directed traversal derived from entry and exit socket roles.
nonisolated extension TrackAssembly {
    func directedEndpoints(
        for connection: TrackConnection
    ) throws -> (
        exit: TrackSocketReference,
        entry: TrackSocketReference
    ) {
        let (_, sourceSocket) = try resolve(connection.source)
        let (_, destinationSocket) = try resolve(connection.destination)

        if sourceSocket.role == .exit && destinationSocket.role == .entry {
            return (connection.source, connection.destination)
        }
        if sourceSocket.role == .entry && destinationSocket.role == .exit {
            return (connection.destination, connection.source)
        }

        throw TrackAssemblyError.incompatibleSockets
    }

    func orderedClosedLoop(
        startingAt start: PlacedTrackPiece.ID
    ) throws -> [PlacedTrackPiece.ID]? {
        guard piece(withID: start) != nil else {
            throw TrackAssemblyError.missingPiece(start)
        }
        guard !pieces.isEmpty, connections.count == pieces.count else {
            return nil
        }

        var ordered: [PlacedTrackPiece.ID] = []
        var visited: Set<PlacedTrackPiece.ID> = []
        var current = start

        for _ in pieces.indices {
            guard visited.insert(current).inserted else {
                return nil
            }
            ordered.append(current)

            let outgoing = try connections.compactMap { connection in
                let endpoints = try directedEndpoints(for: connection)
                return endpoints.exit.pieceID == current
                    ? endpoints.entry.pieceID
                    : nil
            }
            guard outgoing.count == 1, let next = outgoing.first else {
                return nil
            }
            current = next
        }

        guard current == start, visited.count == pieces.count else {
            return nil
        }
        return ordered
    }

    func isSingleClosedLoop(
        startingAt start: PlacedTrackPiece.ID
    ) throws -> Bool {
        try orderedClosedLoop(startingAt: start) != nil
    }
}
