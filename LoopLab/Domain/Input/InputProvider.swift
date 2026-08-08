//
//  InputProvider.swift
//  LoopLab
//

nonisolated enum InputConnection: Equatable, Sendable {
    case disconnected
    case connected(deviceName: String)

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}

/// Platform-independent source of semantic input and connection changes.
@MainActor
protocol InputProvider: AnyObject {
    var stateDidChange: ((SemanticInputState) -> Void)? { get set }
    var connectionDidChange: ((InputConnection) -> Void)? { get set }
    var activityDidOccur: ((InputActivity) -> Void)? { get set }

    func start()
    func stop()
}
