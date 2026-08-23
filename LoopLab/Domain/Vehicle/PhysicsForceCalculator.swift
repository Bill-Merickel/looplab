//
//  PhysicsForceCalculator.swift
//  LoopLab
//

import simd

/// Deterministic arcade-force math with no RealityKit dependency.
nonisolated struct PhysicsForceCalculator: Sendable {
    let tuning: PhysicsForceConfiguration

    init(tuning: PhysicsForceConfiguration) {
        precondition(tuning.hasValidValues)
        self.tuning = tuning
    }

    func calculate(
        context: VehicleControllerContext
    ) -> PhysicsForceCalculation {
        guard context.surface.isGrounded else {
            return .zero
        }

        let surfaceUp = context.surface.normal
        let vehicleForward = context.state.pose.transform(
            direction: SIMD3(0, 0, 1)
        )
        let forward = normalizedOrFallback(
            vehicleForward - surfaceUp * simd_dot(vehicleForward, surfaceUp),
            fallback: vehicleForward
        )
        let right = normalizedOrFallback(
            simd_cross(surfaceUp, forward),
            fallback: context.state.pose.transform(
                direction: SIMD3(1, 0, 0)
            )
        )
        let velocity = context.state.linearVelocity
        let forwardSpeed = simd_dot(velocity, forward)
        let lateralSpeed = simd_dot(velocity, right)
        let longitudinalIntent = context.input.longitudinalIntent

        let driveForce = makeDriveForce(
            intent: longitudinalIntent,
            forward: forward,
            forwardSpeed: forwardSpeed,
            configuration: context.configuration
        )
        let brakingForce = makeBrakingForce(
            intent: longitudinalIntent,
            forward: forward,
            forwardSpeed: forwardSpeed,
            configuration: context.configuration,
            deltaTime: Float(context.timing.deltaTime)
        )
        let lateralGripForce = makeLateralGripForce(
            right: right,
            lateralSpeed: lateralSpeed,
            configuration: context.configuration
        )
        let groundingForce = makeGroundingForce(
            surfaceUp: surfaceUp,
            speed: simd_length(velocity),
            configuration: context.configuration
        )
        let steeringResponse = makeSteeringResponse(
            speed: abs(forwardSpeed),
            maximumSpeed: context.configuration.maximumForwardSpeed
        )
        let steeringTorque = makeSteeringTorque(
            context: context,
            surfaceUp: surfaceUp,
            forwardSpeed: forwardSpeed,
            response: steeringResponse
        )
        let stabilityTorque = makeStabilityTorque(
            context: context,
            surfaceUp: surfaceUp
        )

        return PhysicsForceCalculation(
            driveForce: driveForce,
            brakingForce: brakingForce,
            lateralGripForce: lateralGripForce,
            groundingForce: groundingForce,
            steeringTorque: steeringTorque,
            stabilityTorque: stabilityTorque,
            forwardSpeed: forwardSpeed,
            lateralSpeed: lateralSpeed,
            steeringResponse: steeringResponse
        )
    }

    private func makeDriveForce(
        intent: VehicleLongitudinalIntent,
        forward: SIMD3<Float>,
        forwardSpeed: Float,
        configuration: VehicleConfiguration
    ) -> SIMD3<Float> {
        guard case let .drive(amount) = intent,
              forwardSpeed < configuration.maximumForwardSpeed else {
            return .zero
        }
        return forward
            * configuration.mass
            * configuration.driveAcceleration
            * amount
    }

    private func makeBrakingForce(
        intent: VehicleLongitudinalIntent,
        forward: SIMD3<Float>,
        forwardSpeed: Float,
        configuration: VehicleConfiguration,
        deltaTime: Float
    ) -> SIMD3<Float> {
        switch intent {
        case let .brakeReverse(amount):
            if forwardSpeed > 0.05 {
                return -forward
                    * configuration.mass
                    * configuration.brakingDeceleration
                    * amount
            }
            guard forwardSpeed > -configuration.maximumReverseSpeed else {
                return .zero
            }
            return -forward
                * configuration.mass
                * configuration.driveAcceleration
                * amount
        case let .brakeToStop(amount):
            return makeStoppingForce(
                amount: amount,
                forward: forward,
                forwardSpeed: forwardSpeed,
                configuration: configuration,
                deltaTime: deltaTime
            )
        case .coast, .drive:
            return .zero
        }
    }

    private func makeStoppingForce(
        amount: Float,
        forward: SIMD3<Float>,
        forwardSpeed: Float,
        configuration: VehicleConfiguration,
        deltaTime: Float
    ) -> SIMD3<Float> {
        guard abs(forwardSpeed) > 0.000_001 else {
            return .zero
        }
        let maximumMagnitude = configuration.mass
            * configuration.brakingDeceleration
            * amount
        let stoppingMagnitude = configuration.mass
            * abs(forwardSpeed)
            / max(deltaTime, 0.000_001)
        let magnitude = min(maximumMagnitude, stoppingMagnitude)
        return forward * (forwardSpeed > 0 ? -magnitude : magnitude)
    }

    private func makeLateralGripForce(
        right: SIMD3<Float>,
        lateralSpeed: Float,
        configuration: VehicleConfiguration
    ) -> SIMD3<Float> {
        let desiredMagnitude = -lateralSpeed
            * configuration.mass
            * tuning.lateralGripRate
        let maximumMagnitude = configuration.mass
            * tuning.maximumLateralAcceleration
        return right * clamp(
            desiredMagnitude,
            minimum: -maximumMagnitude,
            maximum: maximumMagnitude
        )
    }

    private func makeGroundingForce(
        surfaceUp: SIMD3<Float>,
        speed: Float,
        configuration: VehicleConfiguration
    ) -> SIMD3<Float> {
        let acceleration = tuning.groundingAcceleration
            + speed * speed * tuning.speedGroundingCoefficient
        return -surfaceUp * configuration.mass * acceleration
    }

    private func makeSteeringResponse(
        speed: Float,
        maximumSpeed: Float
    ) -> Float {
        let lowSpeedResponse = clamp(
            (speed - tuning.minimumSteeringSpeed)
                / (tuning.fullSteeringSpeed - tuning.minimumSteeringSpeed),
            minimum: 0,
            maximum: 1
        )
        let normalizedSpeed = clamp(
            speed / maximumSpeed,
            minimum: 0,
            maximum: 1
        )
        let highSpeedResponse = 1
            - normalizedSpeed * (1 - tuning.highSpeedSteeringFraction)
        return lowSpeedResponse * highSpeedResponse
    }

    private func makeSteeringTorque(
        context: VehicleControllerContext,
        surfaceUp: SIMD3<Float>,
        forwardSpeed: Float,
        response: Float
    ) -> SIMD3<Float> {
        let direction: Float = forwardSpeed < -0.05 ? -1 : 1
        let targetRate = context.input.steering
            * context.configuration.maximumSteeringRate
            * response
            * direction
        let currentRate = simd_dot(
            context.state.angularVelocity,
            surfaceUp
        )
        let torque = clamp(
            (targetRate - currentRate) * tuning.steeringTorqueGain,
            minimum: -tuning.maximumSteeringTorque,
            maximum: tuning.maximumSteeringTorque
        )
        return surfaceUp * torque
    }

    private func makeStabilityTorque(
        context: VehicleControllerContext,
        surfaceUp: SIMD3<Float>
    ) -> SIMD3<Float> {
        let vehicleUp = normalizedOrFallback(
            context.state.pose.transform(direction: SIMD3(0, 1, 0)),
            fallback: surfaceUp
        )
        let rollPitchVelocity = context.state.angularVelocity
            - surfaceUp
                * simd_dot(context.state.angularVelocity, surfaceUp)
        return simd_cross(vehicleUp, surfaceUp)
                * tuning.stabilityTorqueGain
            - rollPitchVelocity * tuning.rollPitchDamping
    }

    private func normalizedOrFallback(
        _ value: SIMD3<Float>,
        fallback: SIMD3<Float>
    ) -> SIMD3<Float> {
        let magnitude = simd_length(value)
        guard magnitude.isFinite, magnitude > 0.000_001 else {
            return simd_normalize(fallback)
        }
        return value / magnitude
    }

    private func clamp(
        _ value: Float,
        minimum: Float,
        maximum: Float
    ) -> Float {
        min(maximum, max(minimum, value))
    }
}
