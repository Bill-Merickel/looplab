//
//  PhysicsForceCalculatorTests.swift
//  LoopLabTests
//

import Testing
import simd
@testable import LoopLab

struct PhysicsForceCalculatorTests {
    private let calculator = PhysicsForceCalculator(
        tuning: Phase0VehicleComparison.physicsForce
    )

    @Test("airborne vehicles receive no artificial actuation")
    func airborneProducesNoActuation() {
        let result = calculator.calculate(
            context: makeContext(
                input: SemanticInputState(
                    steering: 1,
                    throttle: 1,
                    brakeReverse: 1
                ),
                surface: .airborne
            )
        )

        #expect(result == .zero)
    }

    @Test("throttle drives forward until the configured speed limit")
    func throttleDrivesForward() {
        let moving = calculator.calculate(
            context: makeContext(
                input: SemanticInputState(throttle: 1)
            )
        )
        let limited = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(
                    0,
                    0,
                    Phase0VehicleComparison.configuration.maximumForwardSpeed
                ),
                input: SemanticInputState(throttle: 1)
            )
        )

        #expect(moving.driveForce.z > 0)
        #expect(moving.driveForce.x == 0)
        #expect(limited.driveForce == .zero)
    }

    @Test("brake opposes forward motion and becomes reverse at rest")
    func brakeAndReverseUseTheSameSemanticInput() {
        let braking = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(0, 0, 1),
                input: SemanticInputState(brakeReverse: 1)
            )
        )
        let reversing = calculator.calculate(
            context: makeContext(
                input: SemanticInputState(brakeReverse: 1)
            )
        )

        #expect(braking.brakingForce.z < 0)
        #expect(reversing.brakingForce.z < 0)
        #expect(
            abs(braking.brakingForce.z)
                > abs(reversing.brakingForce.z)
        )
    }

    @Test("simultaneous pedals brake either direction and hold at rest")
    func simultaneousPedalsBrakeToStop() {
        let input = SemanticInputState(throttle: 1, brakeReverse: 1)
        let forward = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(0, 0, 1),
                input: input
            )
        )
        let reverse = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(0, 0, -1),
                input: input
            )
        )
        let stopped = calculator.calculate(
            context: makeContext(input: input)
        )

        #expect(forward.driveForce == .zero)
        #expect(forward.brakingForce.z < 0)
        #expect(reverse.driveForce == .zero)
        #expect(reverse.brakingForce.z > 0)
        #expect(stopped.driveForce == .zero)
        #expect(stopped.brakingForce == .zero)
    }

    @Test("steering requires motion and turns toward the input")
    func steeringIsSpeedSensitive() {
        let stopped = calculator.calculate(
            context: makeContext(
                input: SemanticInputState(steering: 1)
            )
        )
        let moving = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(0, 0, 1),
                input: SemanticInputState(steering: 1)
            )
        )

        #expect(stopped.steeringResponse == 0)
        #expect(stopped.steeringTorque == .zero)
        #expect(moving.steeringResponse > 0)
        #expect(moving.steeringTorque.y > 0)
    }

    @Test("maximum-speed steering is reduced for controllability")
    func highSpeedSteeringIsReduced() {
        let medium = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(0, 0, 0.8),
                input: SemanticInputState(steering: 0.5)
            )
        )
        let fast = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(0, 0, 3),
                input: SemanticInputState(steering: 0.5)
            )
        )

        #expect(medium.steeringResponse > fast.steeringResponse)
        #expect(medium.steeringTorque.y > fast.steeringTorque.y)
    }

    @Test("half steering has emphasized authority at moderate speed")
    func moderateSpeedSteeringIsEmphasized() {
        let result = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(0, 0, 0.8),
                input: SemanticInputState(steering: 0.5)
            )
        )
        let emphasizedTorque = Phase0VehicleComparison.physicsForce
            .maximumSteeringTorque * 0.75

        #expect(result.steeringResponse > 0.8)
        #expect(result.steeringTorque.y >= emphasizedTorque)
    }

    @Test("steering direction reverses while backing up")
    func reverseSteeringChangesDirection() {
        let result = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(0, 0, -0.8),
                input: SemanticInputState(steering: 1)
            )
        )

        #expect(result.steeringResponse > 0)
        #expect(result.steeringTorque.y < 0)
    }

    @Test("lateral grip opposes slip and respects its acceleration limit")
    func lateralGripOpposesAndClampsSlip() {
        let result = calculator.calculate(
            context: makeContext(velocity: SIMD3(100, 0, 1))
        )
        let maximumForce = Phase0VehicleComparison.configuration.mass
            * Phase0VehicleComparison.physicsForce.maximumLateralAcceleration

        #expect(result.lateralGripForce.x < 0)
        #expect(
            abs(abs(result.lateralGripForce.x) - maximumForce)
                < 0.000_001
        )
    }

    @Test("grounding and stability act toward a sampled surface")
    func groundingAndStabilityFollowSurface() {
        let tiltedPose = TrackTransform(
            orientation: simd_quatf(
                angle: 0.2,
                axis: SIMD3(0, 0, 1)
            )
        )
        let result = calculator.calculate(
            context: makeContext(pose: tiltedPose)
        )

        #expect(result.groundingForce.y < 0)
        #expect(result.stabilityTorque.z < 0)
    }

    private func makeContext(
        pose: TrackTransform = Phase0VehicleComparison.startPose,
        velocity: SIMD3<Float> = .zero,
        input: SemanticInputState = .neutral,
        surface: VehicleSurfaceSample = VehicleSurfaceSample(
            isGrounded: true,
            distance: 0.065,
            normal: SIMD3(0, 1, 0)
        )
    ) -> VehicleControllerContext {
        VehicleControllerContext(
            state: VehicleState(
                pose: pose,
                linearVelocity: velocity,
                angularVelocity: .zero,
                isGrounded: surface.isGrounded,
                contactCount: surface.isGrounded ? 1 : 0
            ),
            surface: surface,
            input: input,
            configuration: Phase0VehicleComparison.configuration,
            timing: VehicleUpdateTiming(
                stepIndex: 0,
                deltaTime: 1 / 90,
                elapsedTime: 0
            )
        )
    }
}
