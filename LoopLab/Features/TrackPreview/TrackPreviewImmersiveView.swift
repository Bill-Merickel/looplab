//
//  TrackPreviewImmersiveView.swift
//  LoopLab
//
//  Created by Bill Merickel on 7/19/26.
//

import SwiftUI
import RealityKit
import GameController

struct TrackPreviewImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @State private var harness = VehicleHarnessSession()
    @State private var runtime: VehicleHarnessRuntime?

    var body: some View {
        RealityView { content, attachments in
            do {
                let assembly = try Phase0CollisionLoop.makeAssembly()
                let scene = try await VehicleHarnessScene(
                    assembly: assembly,
                    configuration: harness.configuration,
                    startPose: harness.startPose
                )
                content.add(scene.root)
                let runtime = VehicleHarnessRuntime(
                    scene: scene,
                    session: harness
                )
                runtime.start(content: content) {
                    appModel.input.state
                }
                self.runtime = runtime

                if let instructions = attachments.entity(
                    for: "vehicle-harness"
                ) {
                    instructions.position = SIMD3(0, 0.05, -1.1)
                    content.add(instructions)
                }
            } catch {
                assertionFailure(
                    "Unable to create the collision loop prototype: \(error)"
                )
            }
        } attachments: {
            Attachment(id: "vehicle-harness") {
                VehicleHarnessHUD(
                    harness: harness,
                    input: appModel.input
                )
            }
        }
        .handlesGameControllerEvents(matching: .gamepad)
        .onDisappear {
            runtime?.stop()
            runtime = nil
        }
    }
}

#Preview(immersionStyle: .mixed) {
    TrackPreviewImmersiveView()
        .environment(AppModel())
}
