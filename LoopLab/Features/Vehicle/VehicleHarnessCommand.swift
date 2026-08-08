//
//  VehicleHarnessCommand.swift
//  LoopLab
//

/// The action the RealityKit adapter performs for one harness update.
nonisolated enum VehicleHarnessCommand: Equatable, Sendable {
    case actuate(VehicleActuation)
    case reset(VehicleResetReason)
}
