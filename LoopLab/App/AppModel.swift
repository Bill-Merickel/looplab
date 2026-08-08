//
//  AppModel.swift
//  LoopLab
//
//  Created by Bill Merickel on 7/19/26.
//

import Observation

/// Maintains app-wide state
@MainActor
@Observable
final class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    let input: InputSession

    enum ImmersiveSpaceState: Equatable {
        case closed
        case opening
        case open
        case closing
    }

    private(set) var immersiveSpaceState = ImmersiveSpaceState.closed

    init() {
        input = InputSession(
            provider: GameControllerDualSenseProvider()
        )
    }

    init(inputProvider: any InputProvider) {
        input = InputSession(provider: inputProvider)
    }

    var immersiveSpaceButtonLabel: String {
        switch immersiveSpaceState {
        case .closed:
            "Enter Track Preview"
        case .opening:
            "Opening Track Preview…"
        case .open:
            "Exit Track Preview"
        case .closing:
            "Closing Track Preview…"
        }
    }

    var isImmersiveSpaceButtonDisabled: Bool {
        switch immersiveSpaceState {
        case .closed, .open:
            false
        case .opening, .closing:
            true
        }
    }

    @discardableResult
    func beginOpeningImmersiveSpace() -> Bool {
        guard immersiveSpaceState == .closed else {
            return false
        }

        immersiveSpaceState = .opening
        return true
    }

    func immersiveSpaceOpenDidNotComplete() {
        guard immersiveSpaceState == .opening else {
            return
        }

        immersiveSpaceState = .closed
    }

    func immersiveSpaceDidAppear() {
        immersiveSpaceState = .open
    }

    @discardableResult
    func beginClosingImmersiveSpace() -> Bool {
        guard immersiveSpaceState == .open else {
            return false
        }

        immersiveSpaceState = .closing
        return true
    }

    func immersiveSpaceDidDisappear() {
        immersiveSpaceState = .closed
    }
}
