//
//  VehicleHarnessRuntime.swift
//  LoopLab
//

import RealityKit
import SwiftUI

/// Bridges RealityKit frame/contact events into the renderer-neutral harness.
@MainActor
final class VehicleHarnessRuntime {
    private let scene: VehicleHarnessScene
    private let session: VehicleHarnessSession
    private var subscriptions: [EventSubscription] = []

    init(
        scene: VehicleHarnessScene,
        session: VehicleHarnessSession
    ) {
        self.scene = scene
        self.session = session
    }

    func start(
        content: RealityViewContent,
        input: @escaping @MainActor () -> SemanticInputState
    ) {
        stop()

        subscriptions = [
            content.subscribe(
                to: CollisionEvents.Began.self,
                on: scene.vehicle
            ) { [weak self] _ in
                self?.session.contactBegan()
            },
            content.subscribe(
                to: CollisionEvents.Ended.self,
                on: scene.vehicle
            ) { [weak self] _ in
                self?.session.contactEnded()
            },
            content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
                guard let self else {
                    return
                }
                let surface = scene.sampleSurface(
                    tuning: Phase0VehicleComparison.physicsForce
                )
                let state = scene.state(
                    contactCount: session.contactCount,
                    surface: surface
                )
                let command = session.update(
                    state: state,
                    surface: surface,
                    input: input(),
                    frameDeltaTime: event.deltaTime
                )
                scene.perform(command)
            },
        ]
    }

    func stop() {
        for subscription in subscriptions {
            subscription.cancel()
        }
        subscriptions.removeAll()
    }
}
