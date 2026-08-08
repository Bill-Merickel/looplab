//
//  VehicleController.swift
//  LoopLab
//

/// Swappable behavior behind the shared input, vehicle, and evaluation harness.
@MainActor
protocol VehicleController: AnyObject {
    var kind: VehicleControllerKind { get }

    func update(context: VehicleControllerContext) -> VehicleActuation
    func reset()
}
