//
//  PhysicsForceConfiguration.swift
//  LoopLab
//

/// Phase 0 tuning values used only by the force-based controller prototype.
nonisolated struct PhysicsForceConfiguration: Equatable, Sendable {
    let surfaceProbeLength: Float
    let maximumGroundedDistance: Float
    let surfaceProbeInset: Float
    let lateralGripRate: Float
    let maximumLateralAcceleration: Float
    let minimumSteeringSpeed: Float
    let fullSteeringSpeed: Float
    let highSpeedSteeringFraction: Float
    let steeringTorqueGain: Float
    let maximumSteeringTorque: Float
    let groundingAcceleration: Float
    let speedGroundingCoefficient: Float
    let stabilityTorqueGain: Float
    let rollPitchDamping: Float

    var hasValidValues: Bool {
        surfaceProbeLength.isFinite && surfaceProbeLength > 0
            && maximumGroundedDistance.isFinite
            && maximumGroundedDistance > 0
            && maximumGroundedDistance < surfaceProbeLength
            && surfaceProbeInset.isFinite
            && surfaceProbeInset > 0 && surfaceProbeInset <= 1
            && lateralGripRate.isFinite && lateralGripRate > 0
            && maximumLateralAcceleration.isFinite
            && maximumLateralAcceleration > 0
            && minimumSteeringSpeed.isFinite && minimumSteeringSpeed >= 0
            && fullSteeringSpeed.isFinite
            && fullSteeringSpeed > minimumSteeringSpeed
            && highSpeedSteeringFraction.isFinite
            && highSpeedSteeringFraction > 0
            && highSpeedSteeringFraction <= 1
            && steeringTorqueGain.isFinite && steeringTorqueGain > 0
            && maximumSteeringTorque.isFinite
            && maximumSteeringTorque > 0
            && groundingAcceleration.isFinite
            && groundingAcceleration >= 0
            && speedGroundingCoefficient.isFinite
            && speedGroundingCoefficient >= 0
            && stabilityTorqueGain.isFinite
            && stabilityTorqueGain >= 0
            && rollPitchDamping.isFinite && rollPitchDamping >= 0
    }
}
