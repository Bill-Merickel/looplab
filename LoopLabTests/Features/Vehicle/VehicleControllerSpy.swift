//
//  VehicleControllerSpy.swift
//  LoopLabTests
//

@testable import LoopLab

@MainActor
final class VehicleControllerSpy: VehicleController {
    let kind: VehicleControllerKind
    let actuation: VehicleActuation
    private(set) var receivedContexts: [VehicleControllerContext] = []
    private(set) var resetCount = 0

    init(
        kind: VehicleControllerKind,
        actuation: VehicleActuation = .none
    ) {
        self.kind = kind
        self.actuation = actuation
    }

    func update(context: VehicleControllerContext) -> VehicleActuation {
        receivedContexts.append(context)
        return actuation
    }

    func reset() {
        resetCount += 1
    }
}
