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
}
