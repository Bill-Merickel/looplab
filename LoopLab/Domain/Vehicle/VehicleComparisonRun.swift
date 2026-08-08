//
//  VehicleComparisonRun.swift
//  LoopLab
//

import Foundation

/// Repeatable course and success criteria used for both controller prototypes.
nonisolated struct VehicleComparisonRun: Equatable, Sendable {
    let id: String
    let courseID: String
    let targetConsecutiveLoops: Int
    let maximumDuration: TimeInterval
}
