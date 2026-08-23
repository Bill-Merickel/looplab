//
//  SemanticInputState.swift
//  LoopLab
//

/// Device-independent controls consumed by gameplay and navigation systems.
nonisolated struct SemanticInputState: Equatable, Sendable {
    let steering: Float
    let throttle: Float
    let brakeReverse: Float
    let reset: Bool
    let changeCamera: Bool
    let pause: Bool
    let confirm: Bool
    let cancel: Bool

    static let neutral = SemanticInputState()

    init(
        steering: Float = 0,
        throttle: Float = 0,
        brakeReverse: Float = 0,
        reset: Bool = false,
        changeCamera: Bool = false,
        pause: Bool = false,
        confirm: Bool = false,
        cancel: Bool = false
    ) {
        self.steering = Self.clamp(steering, minimum: -1, maximum: 1)
        self.throttle = Self.clamp(throttle, minimum: 0, maximum: 1)
        self.brakeReverse = Self.clamp(
            brakeReverse,
            minimum: 0,
            maximum: 1
        )
        self.reset = reset
        self.changeCamera = changeCamera
        self.pause = pause
        self.confirm = confirm
        self.cancel = cancel
    }

    private static func clamp(
        _ value: Float,
        minimum: Float,
        maximum: Float
    ) -> Float {
        guard value.isFinite else {
            return 0
        }
        return min(maximum, max(minimum, value))
    }

    var longitudinalIntent: VehicleLongitudinalIntent {
        if throttle > 0, brakeReverse > 0 {
            return .brakeToStop(amount: brakeReverse)
        }
        if throttle > 0 {
            return .drive(amount: throttle)
        }
        if brakeReverse > 0 {
            return .brakeReverse(amount: brakeReverse)
        }
        return .coast
    }
}

/// Mutually exclusive pedal behavior shared by every vehicle controller.
nonisolated enum VehicleLongitudinalIntent: Equatable, Sendable {
    case coast
    case drive(amount: Float)
    case brakeReverse(amount: Float)
    case brakeToStop(amount: Float)
}
