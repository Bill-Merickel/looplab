//
//  Phase0CollisionLoopTests.swift
//  LoopLabTests
//

import simd
import Testing
@testable import LoopLab

@Suite("Phase 0 closed collision loop")
struct Phase0CollisionLoopTests {
    @Test("deterministic assembly is one ordered closed loop")
    func deterministicAssemblyIsClosed() throws {
        let first = try Phase0CollisionLoop.makeAssembly()
        let second = try Phase0CollisionLoop.makeAssembly()
        let ordered = try first.orderedClosedLoop(
            startingAt: Phase0CollisionLoop.startFinishID
        )

        #expect(first.pieces == second.pieces)
        #expect(first.connections == second.connections)
        #expect(first.pieces.count == 6)
        #expect(first.connections.count == 6)
        #expect(ordered == Phase0CollisionLoop.pieceIDs)
        #expect(
            try first.isSingleClosedLoop(
                startingAt: Phase0CollisionLoop.startFinishID
            )
        )
    }

    @Test("every loop socket is occupied exactly once")
    func everySocketIsOccupiedOnce() throws {
        let assembly = try Phase0CollisionLoop.makeAssembly()
        var references: [TrackSocketReference] = []

        for piece in assembly.pieces {
            let definition = try #require(
                TrackPieceCatalog.definition(for: piece.kind)
            )
            for socket in definition.sockets {
                references.append(
                    TrackSocketReference(
                        pieceID: piece.id,
                        socketID: socket.id
                    )
                )
            }
        }

        #expect(references.count == 12)
        for reference in references {
            #expect(assembly.isOccupied(reference))
            #expect(
                assembly.connections.filter {
                    $0.contains(reference)
                }.count == 1
            )
        }
    }

    @Test("every loop seam satisfies the Phase 0 tolerance")
    func seamsMeetTolerance() throws {
        let assembly = try Phase0CollisionLoop.makeAssembly()

        for connection in assembly.connections {
            let measurement = try TrackSeamInspector.measure(
                connection: connection,
                in: assembly
            )
            #expect(measurement.isWithin(.phase0))
        }
    }

    @Test("directed traversal uses socket roles, not connection order")
    func traversalUsesSocketRoles() throws {
        let assembly = try Phase0CollisionLoop.makeAssembly()
        let firstConnection = try #require(assembly.connections.first)
        let endpoints = try assembly.directedEndpoints(
            for: firstConnection
        )

        #expect(firstConnection.source.socketID == .entry)
        #expect(endpoints.exit.pieceID == Phase0CollisionLoop.pieceIDs[0])
        #expect(endpoints.entry.pieceID == Phase0CollisionLoop.pieceIDs[1])
    }

    @Test("an open chain is not reported as a closed loop")
    func openChainIsNotClosed() throws {
        var assembly = TrackAssembly()
        let first = PlacedTrackPiece.ID(rawValue: "open-first")
        let second = PlacedTrackPiece.ID(rawValue: "open-second")
        try assembly.add(
            PlacedTrackPiece(
                id: first,
                kind: .straight,
                transform: .identity
            )
        )
        try assembly.add(
            PlacedTrackPiece(
                id: second,
                kind: .straight,
                transform: .identity
            )
        )
        try assembly.snapAndConnect(
            moving: .init(pieceID: second, socketID: .entry),
            to: .init(pieceID: first, socketID: .exit)
        )

        #expect(try !assembly.isSingleClosedLoop(startingAt: first))
    }

    @Test("aligned closure rejects a visible gap without mutation")
    func alignedClosureRejectsGap() throws {
        var assembly = TrackAssembly()
        let first = PlacedTrackPiece.ID(rawValue: "gap-first")
        let second = PlacedTrackPiece.ID(rawValue: "gap-second")
        try assembly.add(
            PlacedTrackPiece(
                id: first,
                kind: .straight,
                transform: .identity
            )
        )
        try assembly.add(
            PlacedTrackPiece(
                id: second,
                kind: .straight,
                transform: TrackTransform(
                    position: SIMD3(0.2, 0, 0)
                )
            )
        )

        #expect(throws: TrackAssemblyError.misalignedSockets) {
            try assembly.connectAligned(
                .init(pieceID: first, socketID: .exit),
                to: .init(pieceID: second, socketID: .entry)
            )
        }
        #expect(assembly.connections.isEmpty)
    }
}
