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
    let configuration: VehicleConfiguration

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
        self.configuration = configuration
        self.startPose = startPose
        apply(startPose)
        root.addChild(vehicle)
    }

    func state(
        contactCount: Int,
        surface: VehicleSurfaceSample
    ) -> VehicleState {
        let motion = vehicle.components[PhysicsMotionComponent.self]
            ?? PhysicsMotionComponent()
        return VehicleState(
            pose: TrackTransform(
                position: vehicle.position,
                orientation: vehicle.orientation
            ),
            linearVelocity: motion.linearVelocity,
            angularVelocity: motion.angularVelocity,
            isGrounded: surface.isGrounded,
            contactCount: contactCount
        )
    }

    func sampleSurface(
        tuning: PhysicsForceConfiguration
    ) -> VehicleSurfaceSample {
        guard let realityScene = vehicle.scene else {
            return .airborne
        }

        let halfWidth = configuration.dimensions.width / 2
        let halfLength = configuration.dimensions.length / 2
        let inset = tuning.surfaceProbeInset
        let probeOffsets = [
            SIMD3<Float>.zero,
            SIMD3(-halfWidth * inset, 0, -halfLength * inset),
            SIMD3(halfWidth * inset, 0, -halfLength * inset),
            SIMD3(-halfWidth * inset, 0, halfLength * inset),
            SIMD3(halfWidth * inset, 0, halfLength * inset),
        ]
        let hits = probeOffsets.compactMap { offset in
            let origin = vehicle.convert(position: offset, to: root)
            return realityScene.raycast(
                origin: origin,
                direction: SIMD3(0, -1, 0),
                length: tuning.surfaceProbeLength,
                query: .nearest,
                mask: Phase0CollisionGroups.trackSurface,
                relativeTo: root
            ).first
        }
        let groundedHits = hits.filter {
            $0.distance <= tuning.maximumGroundedDistance
        }
        guard groundedHits.isEmpty == false else {
            return .airborne
        }

        let normalSum = groundedHits.reduce(SIMD3<Float>.zero) {
            $0 + $1.normal
        }
        return VehicleSurfaceSample(
            isGrounded: true,
            distance: groundedHits.map(\.distance).min(),
            normal: normalSum
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
        vehicle.clearForcesAndTorques()
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
