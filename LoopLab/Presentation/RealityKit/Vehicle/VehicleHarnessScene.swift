//
//  VehicleHarnessScene.swift
//  LoopLab
//

import RealityKit

/// The reusable course and gray-box entity consumed by either controller.
@MainActor
final class VehicleHarnessScene {
    let trackScene: TrackCollisionLoopScene
    let vehicle: ModelEntity
    let startPose: TrackTransform

    var root: Entity {
        trackScene.root
    }

    init(
        assembly: TrackAssembly,
        configuration: VehicleConfiguration,
        startPose: TrackTransform
    ) async throws {
        trackScene = try await TrackCollisionLoopScene(
            assembly: assembly,
            includesSeamProbes: false
        )
        vehicle = GrayBoxVehicleEntityFactory.makeEntity(
            configuration: configuration
        )
        self.startPose = startPose
        apply(startPose)
        root.addChild(vehicle)
    }

    func state(contactCount: Int) -> VehicleState {
        let motion = vehicle.components[PhysicsMotionComponent.self]
            ?? PhysicsMotionComponent()
        return VehicleState(
            pose: TrackTransform(
                position: vehicle.position,
                orientation: vehicle.orientation
            ),
            linearVelocity: motion.linearVelocity,
            angularVelocity: motion.angularVelocity,
            isGrounded: contactCount > 0,
            contactCount: contactCount
        )
    }

    func perform(_ command: VehicleHarnessCommand) {
        switch command {
        case let .actuate(actuation):
            apply(actuation)
        case .reset:
            reset()
        }
    }

    func reset() {
        apply(startPose)
        vehicle.components.set(PhysicsMotionComponent())
    }

    private func apply(_ actuation: VehicleActuation) {
        switch actuation {
        case .none:
            break

        case let .forces(force, torque):
            setPhysicsMode(.dynamic)
            vehicle.addForce(force, relativeTo: root)
            vehicle.addTorque(torque, relativeTo: root)

        case let .constrained(pose, linearVelocity, angularVelocity):
            setPhysicsMode(.kinematic)
            apply(pose)
            vehicle.components.set(
                PhysicsMotionComponent(
                    linearVelocity: linearVelocity,
                    angularVelocity: angularVelocity
                )
            )
        }
    }

    private func apply(_ pose: TrackTransform) {
        vehicle.position = pose.position
        vehicle.orientation = pose.orientation
    }

    private func setPhysicsMode(_ mode: PhysicsBodyMode) {
        guard var body = vehicle.components[PhysicsBodyComponent.self] else {
            return
        }
        body.mode = mode
        vehicle.components.set(body)
    }
}
