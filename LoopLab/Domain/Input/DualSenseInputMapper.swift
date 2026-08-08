//
//  DualSenseInputMapper.swift
//  LoopLab
//

/// Raw values read from the explicitly documented DualSense controls.
nonisolated struct DualSenseInputReading: Equatable, Sendable {
    var leftStickX: Float = 0
    var rightTrigger: Float = 0
    var leftTrigger: Float = 0
    var squarePressed = false
    var trianglePressed = false
    var optionsPressed = false
    var crossPressed = false
    var circlePressed = false
}

/// Converts DualSense controls into device-independent semantic input.
nonisolated struct DualSenseInputMapper: Sendable {
    static let steeringDeadZone: Float = 0.12
    static let triggerDeadZone: Float = 0.05

    func map(_ reading: DualSenseInputReading) -> SemanticInputState {
        SemanticInputState(
            steering: applySignedDeadZone(
                reading.leftStickX,
                deadZone: Self.steeringDeadZone
            ),
            throttle: applyUnsignedDeadZone(
                reading.rightTrigger,
                deadZone: Self.triggerDeadZone
            ),
            brakeReverse: applyUnsignedDeadZone(
                reading.leftTrigger,
                deadZone: Self.triggerDeadZone
            ),
            reset: reading.squarePressed,
            changeCamera: reading.trianglePressed,
            pause: reading.optionsPressed,
            confirm: reading.crossPressed,
            cancel: reading.circlePressed
        )
    }

    private func applySignedDeadZone(
        _ value: Float,
        deadZone: Float
    ) -> Float {
        guard value.isFinite else {
            return 0
        }
        let clamped = min(1, max(-1, value))
        let magnitude = abs(clamped)
        guard magnitude > deadZone else {
            return 0
        }
        let scaled = (magnitude - deadZone) / (1 - deadZone)
        return clamped.sign == .minus ? -scaled : scaled
    }

    private func applyUnsignedDeadZone(
        _ value: Float,
        deadZone: Float
    ) -> Float {
        guard value.isFinite else {
            return 0
        }
        let clamped = min(1, max(0, value))
        guard clamped > deadZone else {
            return 0
        }
        return (clamped - deadZone) / (1 - deadZone)
    }
}
