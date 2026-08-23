//
//  Phase0CollisionGroups.swift
//  LoopLab
//

import RealityKit

/// Keeps vehicle surface probes and physical contacts on explicit layers.
@MainActor
enum Phase0CollisionGroups {
    static let trackSurface = CollisionGroup(rawValue: 1 << 1)
    static let vehicle = CollisionGroup(rawValue: 1 << 2)
}
