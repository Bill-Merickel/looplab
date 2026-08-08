//
//  InputActivity.swift
//  LoopLab
//

/// Device-neutral diagnostic information for one physical input change.
nonisolated struct InputActivity: Equatable, Sendable {
    let controlName: String
    let valueDescription: String

    var description: String {
        "\(controlName): \(valueDescription)"
    }
}
