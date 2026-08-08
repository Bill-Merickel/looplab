# Phase 0 discovery record

Updated: 2026-07-23

## Product and spatial baseline

- Product vision and experience flow: [`plan.md`](../../plan.md)
- Presentation: one mixed immersive space entered from a SwiftUI window.
- Prototype scale: tabletop-first, using the existing `0.35` preview scale.
- Content: offline procedural gray-box track pieces.

## Development environment

- Xcode: 26.6 (`17F113`)
- Apple Swift: 6.3.3
- visionOS SDK: 26.5
- LoopLab deployment target: visionOS 26.5
- Physical Apple Vision Pro: available
- DualSense controller: available
- Device visionOS version: 26.5

## Capability assumptions

- RealityKit entities generated from domain definitions remain presentation
  state rather than the track model.
- Targeted SwiftUI spatial drag gestures use RealityKit
  `InputTargetComponent` and interaction-only collision shapes. Compilation is
  verified; simulator and physical-device manipulation still require smoke
  testing.
- Exact snapping is resolved with renderer-independent `simd` transforms.
- Drive-surface collision is generated from domain geometry recipes. Automated
  checks cover loop topology, collision configuration, and seam tolerances;
  physical-device motion acceptance is recorded in
  [`CollisionLoopVerification.md`](CollisionLoopVerification.md).
- GameController discovery and explicit DualSense mappings are implemented
  behind the semantic input boundary. Automated checks cover dead zones,
  clamping, connection transitions, and stuck-input prevention. Physical input
  delivery, gaze coverage, reconnection, and perceived latency are verified in
  [`DualSenseVerification.md`](DualSenseVerification.md).
- The shared vehicle harness keeps controller input, configuration, timing,
  recovery, presentation, and instrumentation constant while swapping the two
  Phase 0 controller approaches. Its repeatable comparison configuration and
  smoke checks are recorded in
  [`VehicleHarnessVerification.md`](VehicleHarnessVerification.md).
