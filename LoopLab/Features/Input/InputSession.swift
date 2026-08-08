//
//  InputSession.swift
//  LoopLab
//

import Observation

/// Observable app boundary that prevents stale controller input.
@MainActor
@Observable
final class InputSession {
    private(set) var state = SemanticInputState.neutral
    private(set) var connection = InputConnection.disconnected
    private(set) var lastActivity: InputActivity?
    private(set) var activityCount = 0

    private let provider: any InputProvider
    private var isStarted = false

    init(provider: any InputProvider) {
        self.provider = provider
    }

    var connectionDescription: String {
        switch connection {
        case .disconnected:
            "DualSense not connected"
        case let .connected(deviceName):
            "\(deviceName) connected"
        }
    }

    func start() {
        guard !isStarted else {
            return
        }
        isStarted = true

        provider.stateDidChange = { [weak self] state in
            guard let self, connection.isConnected else {
                return
            }
            self.state = state
        }
        provider.connectionDidChange = { [weak self] connection in
            guard let self else {
                return
            }
            self.connection = connection
            if !connection.isConnected {
                state = .neutral
                lastActivity = nil
                activityCount = 0
            }
        }
        provider.activityDidOccur = { [weak self] activity in
            guard let self, connection.isConnected else {
                return
            }
            lastActivity = activity
            activityCount += 1
        }
        provider.start()
    }

    func stop() {
        guard isStarted else {
            return
        }
        provider.stop()
        provider.stateDidChange = nil
        provider.connectionDidChange = nil
        provider.activityDidOccur = nil
        state = .neutral
        connection = .disconnected
        lastActivity = nil
        activityCount = 0
        isStarted = false
    }
}
