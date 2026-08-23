//
//  ConstraintAssistedCalculator.swift
//  LoopLab
//

import simd

/// Deterministic kinematic vehicle math with no RealityKit dependency.
nonisolated struct ConstraintAssistedCalculator: Sendable {
    let tuning: ConstraintAssistedConfiguration

    init(tuning: ConstraintAssistedConfiguration) {
        precondition(tuning.hasValidValues)
        self.tuning = tuning
    }

    func calculate(
        context: VehicleControllerContext
    ) -> ConstraintAssistedCalculation {
        let deltaTime = Float(context.timing.deltaTime)
        guard context.surface.isGrounded else {
            return makeAirborneCalculation(
                context: context,
                deltaTime: deltaTime
            )
        }

        let surfaceUp = context.surface.normal
        let vehicleForward = context.state.pose.transform(
            direction: SIMD3(0, 0, 1)
        )
        let forward = normalizedOrFallback(
            vehicleForward
                - surfaceUp * simd_dot(vehicleForward, surfaceUp),
            fallback: vehicleForward
        )
        let right = normalizedOrFallback(
            simd_cross(surfaceUp, forward),
            fallback: context.state.pose.transform(
                direction: SIMD3(1, 0, 0)
            )
        )
        let currentForwardSpeed = simd_dot(
            context.state.linearVelocity,
            forward
        )
        let currentLateralSpeed = simd_dot(
            context.state.linearVelocity,
            right
        )
        let forwardSpeed = makeForwardSpeed(
            currentSpeed: currentForwardSpeed,
            input: context.input,
            configuration: context.configuration,
            deltaTime: deltaTime
        )
        let steeringResponse = makeSteeringResponse(
            speed: abs(forwardSpeed),
            maximumSpeed: context.configuration.maximumForwardSpeed
        )
        let travelDirection: Float = forwardSpeed < -0.05 ? -1 : 1
        let yawRate = context.input.steering
            * context.configuration.maximumSteeringRate
            * steeringResponse
            * travelDirection
        let yaw = simd_quatf(
            angle: yawRate * deltaTime,
            axis: surfaceUp
        )
        let constrainedForward = normalizedOrFallback(
            yaw.act(forward),
            fallback: forward
        )
        let constrainedRight = normalizedOrFallback(
            simd_cross(surfaceUp, constrainedForward),
            fallback: right
        )
        let lateralRetention = max(
            0,
            1 - tuning.lateralGripRate * deltaTime
        )
        let lateralSpeed = currentLateralSpeed * lateralRetention
        let linearVelocity = constrainedForward * forwardSpeed
            + constrainedRight * lateralSpeed
        let pose = TrackTransform(
            position: groundedPosition(context: context),
            orientation: orientation(
                forward: constrainedForward,
                up: surfaceUp
            )
        )

        return ConstraintAssistedCalculation(
            pose: pose,
            linearVelocity: linearVelocity,
            angularVelocity: .zero,
            forwardSpeed: forwardSpeed,
            lateralSpeed: lateralSpeed,
            steeringResponse: steeringResponse,
            yawRate: yawRate
        )
    }

    private func makeAirborneCalculation(
        context: VehicleControllerContext,
        deltaTime: Float
    ) -> ConstraintAssistedCalculation {
        let velocity = context.state.linearVelocity
            + SIMD3(0, -tuning.airborneGravity * deltaTime, 0)
        return ConstraintAssistedCalculation(
            pose: context.state.pose,
            linearVelocity: velocity,
            angularVelocity: context.state.angularVelocity,
            forwardSpeed: 0,
            lateralSpeed: 0,
            steeringResponse: 0,
            yawRate: 0
        )
    }

    private func makeForwardSpeed(
        currentSpeed: Float,
        input: SemanticInputState,
        configuration: VehicleConfiguration,
        deltaTime: Float
    ) -> Float {
        var speed = clamp(
            currentSpeed,
            minimum: -configuration.maximumReverseSpeed,
            maximum: configuration.maximumForwardSpeed
        )

        switch input.longitudinalIntent {
        case let .brakeToStop(amount):
            speed = moveTowardZero(
                speed,
                maximumChange: configuration.brakingDeceleration
                    * amount
                    * deltaTime
            )
        case let .brakeReverse(amount):
            if speed > 0.05 {
                speed = max(
                    0,
                    speed
                        - configuration.brakingDeceleration
                        * amount
                        * deltaTime
                )
            } else {
                speed -= configuration.driveAcceleration
                    * amount
                    * deltaTime
            }
        case let .drive(amount):
            speed += configuration.driveAcceleration
                * amount
                * deltaTime
        case .coast:
            speed = moveTowardZero(
                speed,
                maximumChange: tuning.coastingDeceleration * deltaTime
            )
        }

        return clamp(
            speed,
            minimum: -configuration.maximumReverseSpeed,
            maximum: configuration.maximumForwardSpeed
        )
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

    private func groundedPosition(
        context: VehicleControllerContext
    ) -> SIMD3<Float> {
        guard let distance = context.surface.distance else {
            return context.state.pose.position
        }
        var position = context.state.pose.position
        position.y += tuning.rideHeight - distance
        return position
    }

    private func orientation(
        forward: SIMD3<Float>,
        up: SIMD3<Float>
    ) -> simd_quatf {
        let right = normalizedOrFallback(
            simd_cross(up, forward),
            fallback: SIMD3(1, 0, 0)
        )
        let correctedForward = normalizedOrFallback(
            simd_cross(right, up),
            fallback: forward
        )
        return simd_normalize(
            simd_quatf(
                simd_float3x3(right, up, correctedForward)
            )
        )
    }

    private func moveTowardZero(
        _ value: Float,
        maximumChange: Float
    ) -> Float {
        if value > 0 {
            return max(0, value - maximumChange)
        }
        return min(0, value + maximumChange)
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
