//
//  Phase0VehicleComparison.swift
//  LoopLab
//

/// Canonical start pose and tuning inputs for the Phase 0 controller comparison.
nonisolated enum Phase0VehicleComparison {
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
        maximumSteeringRate: 2.4
    )

    static let startPose = TrackTransform(
        position: SIMD3(0, 0.065, -0.28)
    )

    static let timing = VehicleTimingConfiguration(
        nominalDeltaTime: 1 / 90,
        maximumDeltaTime: 1 / 15
    )

    static let recovery = VehicleRecoveryPolicy(
        minimumHeight: -0.5,
        maximumDistanceFromStart: 4
    )

    static let run = VehicleComparisonRun(
        id: "phase-0-controller-comparison-v1",
        courseID: Phase0CollisionLoop.courseID,
        targetConsecutiveLoops: 3,
        maximumDuration: 120
    )
}
