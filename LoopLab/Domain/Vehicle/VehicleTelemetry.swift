//
//  VehicleTelemetry.swift
//  LoopLab
//

import Foundation

/// Development-only measurements shared by both controller evaluations.
nonisolated struct VehicleTelemetry: Equatable, Sendable {
    let speed: Float
    let controllerUpdateDuration: Duration
    let frameDeltaTime: TimeInterval
    let isGrounded: Bool
    let contactCount: Int
    let resetCount: Int
    let activeController: VehicleControllerKind
    let input: SemanticInputState

    static func initial(
        activeController: VehicleControllerKind
    ) -> VehicleTelemetry {
        VehicleTelemetry(
            speed: 0,
            controllerUpdateDuration: .zero,
            frameDeltaTime: 0,
            isGrounded: false,
            contactCount: 0,
            resetCount: 0,
            activeController: activeController,
            input: .neutral
        )
    }
}
