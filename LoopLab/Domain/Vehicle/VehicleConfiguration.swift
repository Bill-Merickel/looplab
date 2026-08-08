//
//  VehicleConfiguration.swift
//  LoopLab
//

/// Shared physical and tuning values used by both Phase 0 controllers.
nonisolated struct VehicleConfiguration: Equatable, Sendable {
    nonisolated struct ID: RawRepresentable, Hashable, Sendable {
        let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    let id: ID
    let version: Int
    let dimensions: VehicleDimensions
    let mass: Float
    let centerOfMass: SIMD3<Float>
    let maximumForwardSpeed: Float
    let maximumReverseSpeed: Float
    let driveAcceleration: Float
    let brakingDeceleration: Float
    let maximumSteeringRate: Float

    var hasValidValues: Bool {
        version > 0
            && dimensions.hasPositiveDimensions
            && mass.isFinite && mass > 0
            && centerOfMass.x.isFinite
            && centerOfMass.y.isFinite
            && centerOfMass.z.isFinite
            && maximumForwardSpeed.isFinite && maximumForwardSpeed > 0
            && maximumReverseSpeed.isFinite && maximumReverseSpeed > 0
            && driveAcceleration.isFinite && driveAcceleration > 0
            && brakingDeceleration.isFinite && brakingDeceleration > 0
            && maximumSteeringRate.isFinite && maximumSteeringRate > 0
    }
}
