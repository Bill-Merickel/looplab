# Phase 0 completion record

- Status: Ready for final Phase 0 decision PR
- Date: 2026-08-26
- Device baseline: Apple Vision Pro, visionOS 26.5, DualSense

## Deliverables

| Deliverable | Evidence |
| --- | --- |
| Product, SDK, device, and spatial baseline | [Discovery record](Discovery.md) |
| SwiftUI window-to-immersive-space flow | [ADR-0001](../ArchitectureDecisions/0001-use-tabletop-mixed-immersive-presentation.md) |
| Renderer-independent pieces and exact socket snapping | [ADR-0002](../ArchitectureDecisions/0002-use-domain-authored-track-pieces.md) |
| Closed gray-box loop and collision seams | [Collision verification](CollisionLoopVerification.md) |
| Semantic DualSense input | [DualSense verification](DualSenseVerification.md) |
| Shared controller comparison harness | [Harness verification](VehicleHarnessVerification.md) |
| Physics-force controller | [Physics-force verification](PhysicsForceControllerVerification.md) |
| Constraint-assisted controller | [Constraint verification](ConstraintAssistedControllerVerification.md) |
| Selected vehicle approach | [ADR-0003](../ArchitectureDecisions/0003-use-constraint-assisted-vehicle-controller.md) |

## Exit criteria

- A gray-box vehicle completed three consecutive loops on a physical Apple
  Vision Pro using the selected constraint-assisted controller.
- Socket-snapped pieces form a validated directed loop, and straight and angled
  seam crossings pass with the selected controller.
- DualSense acceleration, braking, reverse, simultaneous-trigger braking,
  steering, reset, reconnection, and gaze-area delivery were verified on device.
- The shared recovery path restores the canonical start pose after leaving the
  course.
- Domain behavior and RealityKit integration are covered by the repository's
  Swift Testing suite.

## Accepted decisions and formal deferrals

1. Use a tabletop-first mixed immersive space entered from a SwiftUI window.
2. Keep track pieces and sockets in the domain, generate presentation entities,
   and build one welded top-only collision surface for an assembled course.
3. Carry the constraint-assisted controller into Phase 1 as the default vehicle
   foundation.
4. Defer the supported maximum track footprint until Phase 1 editor constraints
   and physical-device performance can be measured
   ([ADR-0004](../ArchitectureDecisions/0004-defer-maximum-track-footprint.md)).
5. Defer fixed-versus-variable simulation timing until lap timing and replay
   tests can measure consistency
   ([ADR-0005](../ArchitectureDecisions/0005-defer-simulation-step-selection.md)).

## Final automated verification

The commands recorded in [`AGENTS.md`](../../AGENTS.md) were run from the
repository root after applying the Step 7 decision:

```sh
xcodebuild -project LoopLab.xcodeproj -scheme LoopLab -configuration Debug -destination 'generic/platform=visionOS' -derivedDataPath /tmp/LoopLabDerivedData CODE_SIGNING_ALLOWED=NO build
```

Result: passed.

```sh
xcodebuild -project LoopLab.xcodeproj -scheme LoopLab -configuration Debug -destination 'platform=visionOS Simulator,name=Apple Vision Pro,OS=26.5' -derivedDataPath /tmp/LoopLabDerivedData CODE_SIGNING_ALLOWED=NO test
```

Result: 105 tests passed, representing 110 expanded invocations, with zero
failures or skips.

`git diff --check` also passed.

## Known limitations and deferred work

- The retained physics-force prototype can still yaw and lose speed when it
  crosses a track seam at an angle.
- Maximum track footprint and simulation timing are formally deferred by
  ADR-0004 and ADR-0005 rather than treated as Phase 0 production constraints.
- Constraint-assisted barrier response, jumps, and airborne handling need Phase
  1 gameplay rules and tuning.
- Final artwork, complete vehicle physics, checkpoints, lap timing, persistence,
  and online services remain outside Phase 0.

After this decision branch is merged and `main` is clean, Phase 1 can begin with
the selected spatial, track-authoring, collision, input, and vehicle foundations
without further Phase 0 prototype work.
