//
//  ConstraintAssistedConfiguration.swift
//  LoopLab
//

/// Phase 0 tuning values used only by the constraint-assisted controller.
nonisolated struct ConstraintAssistedConfiguration: Equatable, Sendable {
    let rideHeight: Float
    let coastingDeceleration: Float
    let lateralGripRate: Float
    let minimumSteeringSpeed: Float
    let fullSteeringSpeed: Float
    let highSpeedSteeringFraction: Float
    let airborneGravity: Float

    var hasValidValues: Bool {
        rideHeight.isFinite && rideHeight > 0
            && coastingDeceleration.isFinite
            && coastingDeceleration >= 0
            && lateralGripRate.isFinite && lateralGripRate > 0
            && minimumSteeringSpeed.isFinite && minimumSteeringSpeed >= 0
            && fullSteeringSpeed.isFinite
            && fullSteeringSpeed > minimumSteeringSpeed
            && highSpeedSteeringFraction.isFinite
            && highSpeedSteeringFraction > 0
            && highSpeedSteeringFraction <= 1
            && airborneGravity.isFinite && airborneGravity > 0
    }
}
