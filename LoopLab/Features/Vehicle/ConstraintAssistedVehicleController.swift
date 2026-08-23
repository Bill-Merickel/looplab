//
//  ConstraintAssistedVehicleController.swift
//  LoopLab
//

/// Step 6 implementation behind the shared vehicle-controller contract.
@MainActor
final class ConstraintAssistedVehicleController: VehicleController {
    let kind = VehicleControllerKind.constraintAssisted

    private let calculator: ConstraintAssistedCalculator

    init(
        tuning: ConstraintAssistedConfiguration = Phase0VehicleComparison
            .constraintAssisted
    ) {
        calculator = ConstraintAssistedCalculator(tuning: tuning)
    }

    func update(context: VehicleControllerContext) -> VehicleActuation {
        let calculation = calculator.calculate(context: context)
        return .constrained(
            pose: calculation.pose,
            linearVelocity: calculation.linearVelocity,
            angularVelocity: calculation.angularVelocity
        )
    }

    func reset() { }
}
