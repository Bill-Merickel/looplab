//
//  VehicleHarnessSceneTests.swift
//  LoopLabTests
//

import RealityKit
import Testing
@testable import LoopLab

@Suite("Shared RealityKit vehicle harness")
@MainActor
struct VehicleHarnessSceneTests {
    @Test("harness uses one vehicle and omits completed seam probes")
    func harnessUsesOneVehicle() async throws {
        let assembly = try Phase0CollisionLoop.makeAssembly()
        let scene = try await makeScene(assembly: assembly)

        #expect(scene.trackScene.seamProbes.isEmpty)
        #expect(
            scene.root.children.count
                == assembly.pieces.count + 2
        )
        #expect(
            scene.root.findEntity(
                named: GrayBoxVehicleEntityFactory.entityName
            ) === scene.vehicle
        )
    }

    @Test("reset restores the canonical pose and clears motion")
    func resetRestoresStablePose() async throws {
        let scene = try await makeScene()
        scene.vehicle.position = SIMD3(1, -1, 2)
        scene.vehicle.components.set(
            PhysicsMotionComponent(
                linearVelocity: SIMD3(1, 2, 3),
                angularVelocity: SIMD3(4, 5, 6)
            )
        )

        scene.reset()
        let state = scene.state(contactCount: 0)

        #expect(
            state.pose.isApproximatelyEqual(
                to: Phase0VehicleComparison.startPose
            )
        )
        #expect(state.linearVelocity == .zero)
        #expect(state.angularVelocity == .zero)
    }

    @Test("controller actuations reuse the same presentation entity")
    func controllerActuationsReusePresentation() async throws {
        let scene = try await makeScene()
        let vehicle = scene.vehicle
        let target = TrackTransform(position: SIMD3(0, 0.1, 0))

        scene.perform(
            .actuate(
                .constrained(
                    pose: target,
                    linearVelocity: .zero,
                    angularVelocity: .zero
                )
            )
        )
        let constrainedBody = try #require(
            scene.vehicle.components[PhysicsBodyComponent.self]
        )
        scene.perform(
            .actuate(
                .forces(force: .zero, torque: .zero)
            )
        )
        let forceBody = try #require(
            scene.vehicle.components[PhysicsBodyComponent.self]
        )

        #expect(scene.vehicle === vehicle)
        #expect(constrainedBody.mode == .kinematic)
        #expect(forceBody.mode == .dynamic)
    }

    private func makeScene(
        assembly: TrackAssembly? = nil
    ) async throws -> VehicleHarnessScene {
        try await VehicleHarnessScene(
            assembly: assembly ?? Phase0CollisionLoop.makeAssembly(),
            configuration: Phase0VehicleComparison.configuration,
            startPose: Phase0VehicleComparison.startPose
        )
    }
}
