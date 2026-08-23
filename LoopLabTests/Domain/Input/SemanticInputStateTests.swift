//
//  SemanticInputStateTests.swift
//  LoopLabTests
//

import Testing
@testable import LoopLab

@Suite("Semantic input state")
struct SemanticInputStateTests {
    @Test("neutral state has no held input")
    func neutralState() {
        #expect(SemanticInputState.neutral == SemanticInputState())
    }

    @Test("analog values are finite and clamped")
    func analogValuesAreClamped() {
        let state = SemanticInputState(
            steering: 4,
            throttle: -2,
            brakeReverse: .infinity
        )

        #expect(state.steering == 1)
        #expect(state.throttle == 0)
        #expect(state.brakeReverse == 0)
    }

    @Test("pedals resolve to one shared longitudinal intent")
    func longitudinalIntent() {
        #expect(
            SemanticInputState.neutral.longitudinalIntent == .coast
        )
        #expect(
            SemanticInputState(throttle: 0.75).longitudinalIntent
                == .drive(amount: 0.75)
        )
        #expect(
            SemanticInputState(brakeReverse: 0.5).longitudinalIntent
                == .brakeReverse(amount: 0.5)
        )
        #expect(
            SemanticInputState(
                throttle: 1,
                brakeReverse: 0.25
            ).longitudinalIntent == .brakeToStop(amount: 0.25)
        )
    }
}
