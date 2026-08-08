//
//  VehicleControllerKind.swift
//  LoopLab
//

/// The two Phase 0 approaches evaluated through the shared vehicle harness.
nonisolated enum VehicleControllerKind: String, CaseIterable, Sendable {
    case physicsForce = "physics-force"
    case constraintAssisted = "constraint-assisted"

    var displayName: String {
        switch self {
        case .physicsForce:
            "Physics Force"
        case .constraintAssisted:
            "Constraint Assisted"
        }
    }
}
