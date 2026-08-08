//
//  VehicleControllerHost.swift
//  LoopLab
//

/// Selects one controller without changing its inputs or runtime environment.
@MainActor
final class VehicleControllerHost {
    private let controllers: [VehicleControllerKind: any VehicleController]
    private(set) var activeKind: VehicleControllerKind

    init(
        controllers: [any VehicleController],
        activeKind: VehicleControllerKind
    ) {
        self.controllers = Dictionary(
            uniqueKeysWithValues: controllers.map { ($0.kind, $0) }
        )
        precondition(
            self.controllers[activeKind] != nil,
            "The active vehicle controller must be registered."
        )
        self.activeKind = activeKind
    }

    func select(_ kind: VehicleControllerKind) {
        precondition(
            controllers[kind] != nil,
            "A selected vehicle controller must be registered."
        )
        activeKind = kind
    }

    func update(context: VehicleControllerContext) -> VehicleActuation {
        guard let controller = controllers[activeKind] else {
            preconditionFailure("The active vehicle controller was removed.")
        }
        return controller.update(context: context)
    }

    func reset() {
        for controller in controllers.values {
            controller.reset()
        }
    }
}
