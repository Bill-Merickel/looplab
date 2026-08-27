//
//  Phase0VehicleComparison.swift
//  LoopLab
//

/// Canonical start pose and tuning inputs for the Phase 0 controller comparison.
nonisolated enum Phase0VehicleComparison {
    /// Controller selected by the completed Phase 0 comparison.
    static let selectedController = VehicleControllerKind.constraintAssisted

    static let configuration = VehicleConfiguration(
        id: .init(rawValue: "phase-0-gray-box-vehicle"),
        version: 1,
        dimensions: VehicleDimensions(
            width: 0.18,
            height: 0.10,
            length: 0.30
        ),
        mass: 0.18,
        centerOfMass: SIMD3(0, -0.025, 0),
        maximumForwardSpeed: 3,
        maximumReverseSpeed: 1,
        driveAcceleration: 4,
        brakingDeceleration: 6,
        maximumSteeringRate: 3
    )

    static let startPose = TrackTransform(
        position: SIMD3(0, 0.065, -0.28)
    )

    static let timing = VehicleTimingConfiguration(
        nominalDeltaTime: 1 / 90,
        maximumDeltaTime: 1 / 15
    )

    static let physicsForce = PhysicsForceConfiguration(
        surfaceProbeLength: 0.18,
        maximumGroundedDistance: 0.095,
        surfaceProbeInset: 0.65,
        lateralGripRate: 8,
        maximumLateralAcceleration: 9,
        minimumSteeringSpeed: 0.05,
        fullSteeringSpeed: 0.5,
        highSpeedSteeringFraction: 0.6,
        steeringTorqueGain: 0.018,
        maximumSteeringTorque: 0.03,
        groundingAcceleration: 2,
        speedGroundingCoefficient: 0.35,
        stabilityTorqueGain: 0.025,
        rollPitchDamping: 0.004
    )

    static let constraintAssisted = ConstraintAssistedConfiguration(
        rideHeight: 0.065,
        coastingDeceleration: 0.35,
        lateralGripRate: 8,
        minimumSteeringSpeed: 0.05,
        fullSteeringSpeed: 0.5,
        highSpeedSteeringFraction: 0.65,
        airborneGravity: 9.81
    )

    static let recovery = VehicleRecoveryPolicy(
        minimumHeight: -0.5,
        maximumDistanceFromStart: 4,
        maximumUngroundedDuration: 1.5,
        maximumStalledDuration: 3,
        minimumMovementSpeed: 0.05,
        minimumDriveInput: 0.5
    )

    static let run = VehicleComparisonRun(
        id: "phase-0-controller-comparison-v1",
        courseID: Phase0CollisionLoop.courseID,
        targetConsecutiveLoops: 3,
        maximumDuration: 120
    )
}
