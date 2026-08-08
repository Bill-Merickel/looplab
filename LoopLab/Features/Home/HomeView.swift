//
//  HomeView.swift
//  LoopLab
//
//  Created by Bill Merickel on 7/19/26.
//

import SwiftUI
import GameController

struct HomeView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("LoopLab")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(
                    "Inspect the first procedural track pieces in a mixed "
                        + "immersive-space preview."
                )
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            Label(
                appModel.input.connectionDescription,
                systemImage: appModel.input.connection.isConnected
                    ? "gamecontroller.fill"
                    : "gamecontroller"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            ImmersiveSpaceButton()
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: 420)
        .padding(40)
        .handlesGameControllerEvents(
            matching: .gamepad,
            withOptions: .receivesEventsInView(false)
        )
    }
}

#Preview(windowStyle: .automatic) {
    HomeView()
        .environment(AppModel())
}
