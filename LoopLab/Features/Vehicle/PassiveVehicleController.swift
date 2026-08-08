//
//  PassiveVehicleController.swift
//  LoopLab
//

/// Step 4 placeholder replaced by the controller implementations in Steps 5–6.
@MainActor
final class PassiveVehicleController: VehicleController {
    let kind: VehicleControllerKind

    init(kind: VehicleControllerKind) {
        self.kind = kind
    }

    func update(context: VehicleControllerContext) -> VehicleActuation {
        .none
    }

    func reset() { }
}
