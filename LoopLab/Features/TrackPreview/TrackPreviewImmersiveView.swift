//
//  TrackPreviewImmersiveView.swift
//  LoopLab
//
//  Created by Bill Merickel on 7/19/26.
//

import SwiftUI
import RealityKit

struct TrackPreviewImmersiveView: View {
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
                }
                .multilineTextAlignment(.center)
                .padding()
                .glassBackgroundEffect()
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    TrackPreviewImmersiveView()
        .environment(AppModel())
}
