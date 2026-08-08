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
    @State private var scene: TrackCollisionLoopScene?

    var body: some View {
        RealityView { content, attachments in
            do {
                let assembly = try Phase0CollisionLoop.makeAssembly()
                let scene = try await TrackCollisionLoopScene(
                    assembly: assembly
                )
                content.add(scene.root)
                self.scene = scene

                if let instructions = attachments.entity(
                    for: "collision-instructions"
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
            Attachment(id: "collision-instructions") {
                VStack(spacing: 6) {
                    Text("Closed Collision Loop")
                        .font(.headline)
                    Text("Orange probes exercise all six seams.")
                        .font(.subheadline)
                    Divider()
                    Text(appModel.input.connectionDescription)
                        .font(.caption)
                    Text(inputSummary)
                        .font(.caption.monospacedDigit())
                    Text(actionSummary)
                        .font(.caption)
                    Text(activitySummary)
                        .font(.caption)
                }
                .multilineTextAlignment(.center)
                .padding()
                .glassBackgroundEffect()
            }
        }
        .handlesGameControllerEvents(matching: .gamepad)
    }

    private var inputSummary: String {
        let state = appModel.input.state
        return String(
            format: "Steer %+.2f  Throttle %.2f  Brake %.2f",
            state.steering,
            state.throttle,
            state.brakeReverse
        )
    }

    private var actionSummary: String {
        let state = appModel.input.state
        let activeActions = [
            state.reset ? "Reset" : nil,
            state.changeCamera ? "Camera" : nil,
            state.pause ? "Pause" : nil,
            state.confirm ? "Confirm" : nil,
            state.cancel ? "Cancel" : nil,
        ].compactMap { $0 }

        return activeActions.isEmpty
            ? "Actions —"
            : "Actions \(activeActions.joined(separator: ", "))"
    }

    private var activitySummary: String {
        guard let activity = appModel.input.lastActivity else {
            return "Controller events —"
        }
        return "Event \(appModel.input.activityCount): \(activity.description)"
    }
}

#Preview(immersionStyle: .mixed) {
    TrackPreviewImmersiveView()
        .environment(AppModel())
}
