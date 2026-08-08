//
//  VehicleControllerContext.swift
//  LoopLab
//

/// The complete renderer-neutral input supplied to either vehicle controller.
nonisolated struct VehicleControllerContext: Equatable, Sendable {
    let state: VehicleState
    let input: SemanticInputState
    let configuration: VehicleConfiguration
    let timing: VehicleUpdateTiming
}
