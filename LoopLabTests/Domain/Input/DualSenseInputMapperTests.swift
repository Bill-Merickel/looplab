//
//  DualSenseInputMapperTests.swift
//  LoopLabTests
//

import Testing
@testable import LoopLab

@Suite("DualSense semantic mapping")
struct DualSenseInputMapperTests {
    private let mapper = DualSenseInputMapper()

    @Test("steering dead zone removes drift and rescales output")
    func steeringDeadZone() {
        let insidePositive = mapper.map(
            DualSenseInputReading(leftStickX: 0.12)
        )
        let insideNegative = mapper.map(
            DualSenseInputReading(leftStickX: -0.12)
        )
        let halfway = mapper.map(
            DualSenseInputReading(leftStickX: 0.56)
        )

        #expect(insidePositive.steering == 0)
        #expect(insideNegative.steering == 0)
        #expect(approximatelyEqual(halfway.steering, -0.5))
    }

    @Test("left-stick steering direction is inverted")
    func steeringDirection() {
        let stickRight = mapper.map(
            DualSenseInputReading(leftStickX: 1)
        )
        let stickLeft = mapper.map(
            DualSenseInputReading(leftStickX: -1)
        )

        #expect(stickRight.steering == -1)
        #expect(stickLeft.steering == 1)
    }

    @Test("trigger dead zone removes rest noise and rescales output")
    func triggerDeadZone() {
        let atRest = mapper.map(
            DualSenseInputReading(
                rightTrigger: 0.05,
                leftTrigger: 0.05
            )
        )
        let active = mapper.map(
            DualSenseInputReading(
                rightTrigger: 0.525,
                leftTrigger: 0.525
            )
        )

        #expect(atRest.throttle == 0)
        #expect(atRest.brakeReverse == 0)
        #expect(approximatelyEqual(active.throttle, 0.5))
        #expect(approximatelyEqual(active.brakeReverse, 0.5))
    }

    @Test("out-of-range and nonfinite raw values are safe")
    func rawValuesAreSafe() {
        let clamped = mapper.map(
            DualSenseInputReading(
                leftStickX: -3,
                rightTrigger: 4,
                leftTrigger: -.infinity
            )
        )

        #expect(clamped.steering == 1)
        #expect(clamped.throttle == 1)
        #expect(clamped.brakeReverse == 0)
    }

    @Test("DualSense buttons map to documented actions")
    func buttonsMapToActions() {
        let state = mapper.map(
            DualSenseInputReading(
                squarePressed: true,
                trianglePressed: true,
                optionsPressed: true,
                crossPressed: true,
                circlePressed: true
            )
        )

        #expect(state.reset)
        #expect(state.changeCamera)
        #expect(state.pause)
        #expect(state.confirm)
        #expect(state.cancel)
    }

    private func approximatelyEqual(
        _ lhs: Float,
        _ rhs: Float,
        tolerance: Float = 0.0001
    ) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}
