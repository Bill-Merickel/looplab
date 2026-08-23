//
//  ConstraintAssistedCalculatorTests.swift
//  LoopLabTests
//

import Testing
import simd
@testable import LoopLab

struct ConstraintAssistedCalculatorTests {
    private let calculator = ConstraintAssistedCalculator(
        tuning: Phase0VehicleComparison.constraintAssisted
    )

    @Test("throttle accelerates forward without exceeding the speed limit")
    func throttleAcceleratesAndClampsSpeed() {
        let accelerating = calculator.calculate(
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

        #expect(accelerating.forwardSpeed > 0)
        #expect(accelerating.linearVelocity.z > 0)
        #expect(
            limited.forwardSpeed
                == Phase0VehicleComparison.configuration.maximumForwardSpeed
        )
    }

    @Test("brake opposes forward motion and becomes reverse at rest")
    func brakeAndReverseUseTheSameInput() {
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

        #expect(braking.forwardSpeed < 1)
        #expect(braking.forwardSpeed >= 0)
        #expect(reversing.forwardSpeed < 0)
        #expect(reversing.linearVelocity.z < 0)
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

        #expect(forward.forwardSpeed < 1)
        #expect(forward.forwardSpeed >= 0)
        #expect(reverse.forwardSpeed > -1)
        #expect(reverse.forwardSpeed <= 0)
        #expect(stopped.forwardSpeed == 0)
        #expect(stopped.linearVelocity == .zero)
    }

    @Test("coasting reduces speed without changing travel direction")
    func coastingReducesSpeed() {
        let result = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(0, 0, 1)
            )
        )

        #expect(result.forwardSpeed > 0)
        #expect(result.forwardSpeed < 1)
    }

    @Test("steering updates heading and reverses direction while backing up")
    func steeringFollowsTravelDirection() {
        let forward = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(0, 0, 1),
                input: SemanticInputState(steering: 1)
            )
        )
        let reverse = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(0, 0, -0.8),
                input: SemanticInputState(steering: 1)
            )
        )
        let forwardHeading = forward.pose.transform(
            direction: SIMD3(0, 0, 1)
        )

        #expect(forward.steeringResponse > 0)
        #expect(forward.yawRate > 0)
        #expect(forwardHeading.x > 0)
        #expect(reverse.yawRate < 0)
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
        #expect(medium.yawRate > fast.yawRate)
    }

    @Test("constraint preserves some slip while damping lateral speed")
    func lateralSlipIsDamped() {
        let result = calculator.calculate(
            context: makeContext(
                velocity: SIMD3(1, 0, 1)
            )
        )

        #expect(result.lateralSpeed > 0)
        #expect(result.lateralSpeed < 1)
        #expect(result.linearVelocity.x > 0)
    }

    @Test("grounded pose follows ride height and sampled surface normal")
    func groundingConstrainsPose() {
        let normal = simd_normalize(SIMD3<Float>(0, 1, 0.2))
        let result = calculator.calculate(
            context: makeContext(
                surface: VehicleSurfaceSample(
                    isGrounded: true,
                    distance: 0.08,
                    normal: normal
                )
            )
        )
        let vehicleUp = result.pose.transform(
            direction: SIMD3(0, 1, 0)
        )

        #expect(
            approximatelyEqual(
                result.pose.position.y,
                Phase0VehicleComparison.startPose.position.y - 0.015
            )
        )
        #expect(simd_dot(vehicleUp, normal) > 0.999)
        #expect(result.angularVelocity == .zero)
    }

    @Test("airborne vehicle falls without accepting drive input")
    func airborneUsesBallisticVelocity() {
        let context = makeContext(
            velocity: SIMD3(0.2, 0, 0.8),
            input: SemanticInputState(
                steering: 1,
                throttle: 1
            ),
            surface: .airborne
        )
        let result = calculator.calculate(context: context)

        #expect(result.pose == context.state.pose)
        #expect(result.linearVelocity.x == 0.2)
        #expect(result.linearVelocity.z == 0.8)
        #expect(result.linearVelocity.y < 0)
        #expect(result.steeringResponse == 0)
        #expect(result.yawRate == 0)
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
                deltaTime: 0.1,
                elapsedTime: 0.1
            )
        )
    }

    private func approximatelyEqual(
        _ lhs: Float,
        _ rhs: Float,
        tolerance: Float = 0.0001
    ) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}
