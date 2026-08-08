//
//  InputSessionTests.swift
//  LoopLabTests
//

import Testing
@testable import LoopLab

@Suite("Semantic input session")
@MainActor
struct InputSessionTests {
    @Test("start is idempotent and forwards connected input")
    func startsAndForwardsInput() {
        let provider = FakeInputProvider()
        let session = InputSession(provider: provider)
        let active = SemanticInputState(
            steering: 0.7,
            throttle: 0.8,
            reset: true
        )

        session.start()
        session.start()
        provider.connect()
        provider.send(active)

        #expect(provider.startCount == 1)
        #expect(session.connection == .connected(deviceName: "Test Pad"))
        #expect(session.state == active)
    }

    @Test("disconnect immediately neutralizes held actions")
    func disconnectNeutralizesInput() {
        let provider = FakeInputProvider()
        let session = InputSession(provider: provider)
        session.start()
        provider.connect()
        provider.send(
            SemanticInputState(
                steering: -1,
                throttle: 1,
                brakeReverse: 1,
                pause: true
            )
        )

        provider.disconnect()

        #expect(session.connection == .disconnected)
        #expect(session.state == .neutral)

        provider.send(SemanticInputState(throttle: 1))
        #expect(session.state == .neutral)
    }

    @Test("reconnection resumes input without restarting")
    func reconnectsWithoutRestart() {
        let provider = FakeInputProvider()
        let session = InputSession(provider: provider)
        session.start()
        provider.connect()
        provider.disconnect()
        provider.connect()
        provider.send(SemanticInputState(brakeReverse: 0.65))

        #expect(provider.startCount == 1)
        #expect(session.connection.isConnected)
        #expect(session.state.brakeReverse == 0.65)
    }

    @Test("every connected input activity remains visible after release")
    func recordsInputActivity() {
        let provider = FakeInputProvider()
        let session = InputSession(provider: provider)
        session.start()
        provider.connect()

        provider.sendActivity(
            InputActivity(
                controlName: "Cross Button",
                valueDescription: "pressed"
            )
        )
        provider.sendActivity(
            InputActivity(
                controlName: "Cross Button",
                valueDescription: "released"
            )
        )

        #expect(session.activityCount == 2)
        #expect(
            session.lastActivity?.description
                == "Cross Button: released"
        )
    }

    @Test("stop clears callbacks and returns to neutral")
    func stopClearsState() {
        let provider = FakeInputProvider()
        let session = InputSession(provider: provider)
        session.start()
        provider.connect()
        provider.send(SemanticInputState(confirm: true))
        provider.sendActivity(
            InputActivity(
                controlName: "Cross Button",
                valueDescription: "pressed"
            )
        )

        session.stop()
        provider.send(SemanticInputState(throttle: 1))
        provider.sendActivity(
            InputActivity(
                controlName: "R2",
                valueDescription: "pressed"
            )
        )

        #expect(provider.stopCount == 1)
        #expect(session.connection == .disconnected)
        #expect(session.state == .neutral)
        #expect(session.lastActivity == nil)
        #expect(session.activityCount == 0)
    }
}

@MainActor
private final class FakeInputProvider: InputProvider {
    var stateDidChange: ((SemanticInputState) -> Void)?
    var connectionDidChange: ((InputConnection) -> Void)?
    var activityDidOccur: ((InputActivity) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func start() {
        startCount += 1
    }

    func stop() {
        stopCount += 1
    }

    func connect() {
        connectionDidChange?(.connected(deviceName: "Test Pad"))
    }

    func disconnect() {
        connectionDidChange?(.disconnected)
    }

    func send(_ state: SemanticInputState) {
        stateDidChange?(state)
    }

    func sendActivity(_ activity: InputActivity) {
        activityDidOccur?(activity)
    }
}
