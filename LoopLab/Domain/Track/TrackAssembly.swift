//
//  TrackAssembly.swift
//  LoopLab
//

import simd

nonisolated enum TrackAssemblyError: Error, Equatable {
    case duplicatePieceID(PlacedTrackPiece.ID)
    case missingPiece(PlacedTrackPiece.ID)
    case missingDefinition(TrackPieceKind)
    case missingSocket(TrackSocketReference)
    case selfConnection
    case incompatibleSockets
    case occupiedSocket(TrackSocketReference)
    case movingPieceAlreadyConnected(PlacedTrackPiece.ID)
    case misalignedSockets
    case invalidTransform
    case invalidSnapDistance
}

nonisolated struct TrackSnapCandidate: Equatable, Sendable {
    let source: TrackSocketReference
    let destination: TrackSocketReference
    let transform: TrackTransform
    let distance: Float
}

/// Mutable prototype assembly that owns placed-piece and connection data.
///
/// RealityKit entities are generated from this state and are never stored here.
nonisolated struct TrackAssembly: Sendable {
    private(set) var pieces: [PlacedTrackPiece] = []
    private(set) var connections: [TrackConnection] = []

    func piece(withID id: PlacedTrackPiece.ID) -> PlacedTrackPiece? {
        pieces.first { $0.id == id }
    }

    func isOccupied(_ reference: TrackSocketReference) -> Bool {
        connections.contains { $0.contains(reference) }
    }

    mutating func add(_ piece: PlacedTrackPiece) throws {
        guard self.piece(withID: piece.id) == nil else {
            throw TrackAssemblyError.duplicatePieceID(piece.id)
        }
        guard piece.transform.hasValidPose else {
            throw TrackAssemblyError.invalidTransform
        }
        guard TrackPieceCatalog.definition(for: piece.kind) != nil else {
            throw TrackAssemblyError.missingDefinition(piece.kind)
        }

        pieces.append(piece)
    }

    mutating func moveUnconnectedPiece(
        id: PlacedTrackPiece.ID,
        to transform: TrackTransform
    ) throws {
        guard transform.hasValidPose else {
            throw TrackAssemblyError.invalidTransform
        }
        guard let index = pieces.firstIndex(where: { $0.id == id }) else {
            throw TrackAssemblyError.missingPiece(id)
        }
        guard !connections.contains(where: { $0.contains(pieceID: id) }) else {
            throw TrackAssemblyError.movingPieceAlreadyConnected(id)
        }

        pieces[index] = pieces[index].placing(at: transform)
    }

    func snappedTransform(
        moving source: TrackSocketReference,
        to destination: TrackSocketReference
    ) throws -> TrackTransform {
        let resolved = try validateConnection(
            source: source,
            to: destination
        )
        guard !connections.contains(
            where: { $0.contains(pieceID: source.pieceID) }
        ) else {
            throw TrackAssemblyError.movingPieceAlreadyConnected(
                source.pieceID
            )
        }

        return TrackSnapResolver.snappedTransform(
            sourceSocket: resolved.sourceSocket,
            destinationPieceTransform: resolved.destinationPiece.transform,
            destinationSocket: resolved.destinationSocket
        )
    }

    mutating func snapAndConnect(
        moving source: TrackSocketReference,
        to destination: TrackSocketReference
    ) throws {
        let transform = try snappedTransform(
            moving: source,
            to: destination
        )
        let connection: TrackConnection

        do {
            connection = try TrackConnection(
                source: source,
                destination: destination
            )
        } catch {
            throw TrackAssemblyError.selfConnection
        }

        guard let index = pieces.firstIndex(
            where: { $0.id == source.pieceID }
        ) else {
            throw TrackAssemblyError.missingPiece(source.pieceID)
        }

        pieces[index] = pieces[index].placing(at: transform)
        connections.append(connection)
    }

    /// Connects sockets that are already aligned without moving either piece.
    ///
    /// This is used to close a loop after its final piece has been snapped into
    /// place through its other socket.
    mutating func connectAligned(
        _ source: TrackSocketReference,
        to destination: TrackSocketReference,
        tolerance: TrackSeamTolerance = .phase0
    ) throws {
        _ = try validateConnection(source: source, to: destination)
        let measurement = try TrackSeamInspector.measure(
            source: source,
            destination: destination,
            in: self
        )
        guard measurement.isWithin(tolerance) else {
            throw TrackAssemblyError.misalignedSockets
        }

        let connection: TrackConnection
        do {
            connection = try TrackConnection(
                source: source,
                destination: destination
            )
        } catch {
            throw TrackAssemblyError.selfConnection
        }
        connections.append(connection)
    }

    func nearestSnapCandidate(
        moving source: TrackSocketReference,
        within maximumDistance: Float
    ) throws -> TrackSnapCandidate? {
        guard maximumDistance >= 0, maximumDistance.isFinite else {
            throw TrackAssemblyError.invalidSnapDistance
        }

        let (sourcePiece, sourceSocket) = try resolve(source)
        guard !isOccupied(source) else {
            throw TrackAssemblyError.occupiedSocket(source)
        }
        guard !connections.contains(
            where: { $0.contains(pieceID: source.pieceID) }
        ) else {
            throw TrackAssemblyError.movingPieceAlreadyConnected(
                source.pieceID
            )
        }

        let sourceWorld = sourcePiece.transform.concatenating(
            sourceSocket.localTransform
        )
        var nearest: TrackSnapCandidate?

        for piece in pieces where piece.id != source.pieceID {
            guard let definition = TrackPieceCatalog.definition(
                for: piece.kind
            ) else {
                throw TrackAssemblyError.missingDefinition(piece.kind)
            }

            for socket in definition.sockets
            where sourceSocket.isCompatible(with: socket) {
                let destination = TrackSocketReference(
                    pieceID: piece.id,
                    socketID: socket.id
                )
                guard !isOccupied(destination) else {
                    continue
                }

                let destinationWorld = piece.transform.concatenating(
                    socket.localTransform
                )
                let distance = simd_distance(
                    sourceWorld.position,
                    destinationWorld.position
                )
                guard distance <= maximumDistance else {
                    continue
                }

                let candidate = TrackSnapCandidate(
                    source: source,
                    destination: destination,
                    transform: TrackSnapResolver.snappedTransform(
                        sourceSocket: sourceSocket,
                        destinationPieceTransform: piece.transform,
                        destinationSocket: socket
                    ),
                    distance: distance
                )

                if nearest == nil || distance < nearest!.distance {
                    nearest = candidate
                }
            }
        }

        return nearest
    }

    private func validateConnection(
        source: TrackSocketReference,
        to destination: TrackSocketReference
    ) throws -> (
        sourcePiece: PlacedTrackPiece,
        sourceSocket: TrackSocket,
        destinationPiece: PlacedTrackPiece,
        destinationSocket: TrackSocket
    ) {
        guard source.pieceID != destination.pieceID else {
            throw TrackAssemblyError.selfConnection
        }

        let (sourcePiece, sourceSocket) = try resolve(source)
        let (destinationPiece, destinationSocket) = try resolve(destination)

        guard sourceSocket.isCompatible(with: destinationSocket) else {
            throw TrackAssemblyError.incompatibleSockets
        }
        guard !isOccupied(source) else {
            throw TrackAssemblyError.occupiedSocket(source)
        }
        guard !isOccupied(destination) else {
            throw TrackAssemblyError.occupiedSocket(destination)
        }

        return (
            sourcePiece,
            sourceSocket,
            destinationPiece,
            destinationSocket
        )
    }

    func resolve(
        _ reference: TrackSocketReference
    ) throws -> (PlacedTrackPiece, TrackSocket) {
        guard let piece = piece(withID: reference.pieceID) else {
            throw TrackAssemblyError.missingPiece(reference.pieceID)
        }
        guard let definition = TrackPieceCatalog.definition(
            for: piece.kind
        ) else {
            throw TrackAssemblyError.missingDefinition(piece.kind)
        }
        guard let socket = definition.socket(withID: reference.socketID) else {
            throw TrackAssemblyError.missingSocket(reference)
        }

        return (piece, socket)
    }
}
