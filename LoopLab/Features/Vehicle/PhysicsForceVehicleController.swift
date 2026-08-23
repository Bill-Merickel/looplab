//
//  PhysicsForceVehicleController.swift
//  LoopLab
//

/// Step 5 implementation behind the shared vehicle-controller contract.
@MainActor
final class PhysicsForceVehicleController: VehicleController {
    let kind = VehicleControllerKind.physicsForce

    private let calculator: PhysicsForceCalculator

    init(
        tuning: PhysicsForceConfiguration = Phase0VehicleComparison.physicsForce
    ) {
        calculator = PhysicsForceCalculator(tuning: tuning)
    }

    func update(context: VehicleControllerContext) -> VehicleActuation {
        let calculation = calculator.calculate(context: context)
        return .forces(
            force: calculation.force,
            torque: calculation.torque
        )
    }

    func reset() { }
}
