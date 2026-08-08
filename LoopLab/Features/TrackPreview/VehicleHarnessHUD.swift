//
//  VehicleHarnessHUD.swift
//  LoopLab
//

import Foundation
import SwiftUI

struct VehicleHarnessHUD: View {
    let harness: VehicleHarnessSession
    let input: InputSession

    var body: some View {
        VStack(spacing: 6) {
            Text("Shared Vehicle Harness")
                .font(.headline)
            Text("Motion controllers are added in Steps 5 and 6.")
                .font(.caption)
            Divider()
            Text(input.connectionDescription)
                .font(.caption)
            Text(controllerSummary)
                .font(.caption.weight(.semibold))
            Text(motionSummary)
                .font(.caption.monospacedDigit())
            Text(contactSummary)
                .font(.caption.monospacedDigit())
            Text(inputSummary)
                .font(.caption.monospacedDigit())
            Text(activitySummary)
                .font(.caption)
            HStack {
                Button("Switch Controller", action: harness.selectNextController)
                Button("Reset Vehicle", action: harness.requestReset)
            }
            .buttonStyle(.bordered)
        }
        .multilineTextAlignment(.center)
        .padding()
        .glassBackgroundEffect()
    }

    private var controllerSummary: String {
        "Controller: \(harness.activeController.displayName)"
    }

    private var motionSummary: String {
        let telemetry = harness.telemetry
        return String(
            format: "Speed %.2f m/s  Update %.3f ms",
            telemetry.speed,
            updateMilliseconds
        )
    }

    private var contactSummary: String {
        let telemetry = harness.telemetry
        let grounded = telemetry.isGrounded ? "grounded" : "airborne"
        return "\(grounded)  Contacts \(telemetry.contactCount)  Resets \(telemetry.resetCount)"
    }

    private var inputSummary: String {
        let state = harness.telemetry.input
        return String(
            format: "Steer %+.2f  Throttle %.2f  Brake %.2f",
            state.steering,
            state.throttle,
            state.brakeReverse
        )
    }

    private var activitySummary: String {
        guard let activity = input.lastActivity else {
            return "Controller events —"
        }
        return "Event \(input.activityCount): \(activity.description)"
    }

    private var updateMilliseconds: Double {
        let components = harness.telemetry.controllerUpdateDuration.components
        return Double(components.seconds) * 1_000
            + Double(components.attoseconds) / 1_000_000_000_000_000
    }
}
