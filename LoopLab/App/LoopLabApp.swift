//
//  LoopLabApp.swift
//  LoopLab
//
//  Created by Bill Merickel on 7/19/26.
//

import SwiftUI

@main
struct LoopLabApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appModel)
                .onAppear {
                    appModel.input.start()
                }
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            TrackPreviewImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceDidAppear()
                }
                .onDisappear {
                    appModel.immersiveSpaceDidDisappear()
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
