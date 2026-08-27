# ADR-0003: Use the constraint-assisted vehicle controller

- Status: Accepted
- Date: 2026-08-23
- Phase: Phase 0

## Context

Phase 0 compared physics-force and constraint-assisted controllers through the
same harness, vehicle configuration, gray-box course, start pose, DualSense
input, surface probes, timing sanitation, telemetry, and recovery policy. Both
approaches passed acceleration, braking, reverse, steering, straight-seam, and
off-track recovery checks on Apple Vision Pro. Only Constraint Assisted passed
the complete angled-seam, lateral-slip, and repeatable three-loop criteria.

| Criterion | Physics Force | Constraint Assisted |
| --- | --- | --- |
| Acceleration and braking feel | Passed | Passed |
| Low/high-speed steering | Passed | Passed |
| Lateral-slip behavior | Blocked by angled-seam issue | Passed |
| Straight seam reliability | Passed | Passed |
| Angled seam reliability | Failed: unintended yaw and near-zero speed | Passed |
| Off-track recovery | Passed | Passed |
| Three consecutive loops | Not reliable: angled-seam issue | Passed |
| Typical HUD update time | Passed | Passed |

The physics-force vehicle could catch a seam when crossing at an angle, rotate
unexpectedly, and lose nearly all speed. Geometry refinements improved straight
crossings but did not eliminate that physical-device failure. The
constraint-assisted controller crossed the same seams at shallow and steeper
angles without the heading or speed discontinuity and provided better control.

## Decision

Use the constraint-assisted controller as the default vehicle foundation for
Phase 1. Its pure calculator owns grounded pose, forward speed, steering, and
lateral-slip damping; RealityKit supplies presentation, collision queries, and
kinematic motion.

Keep the physics-force implementation available as a Phase 0 reference while
the Phase 1 controller is developed. Do not spend additional Phase 1 time tuning
the dynamic prototype unless a new requirement depends on solver-driven vehicle
response.

Continue using the existing sanitized frame deltas for this prototype. The
production simulation-step choice is a separate decision formally deferred in
[`ADR-0005`](0005-defer-simulation-step-selection.md).

## Consequences

- The app opens the track preview with Constraint Assisted selected.
- Connected-piece seams do not hand grounded heading or speed authority to
  rigid-body collision impulses.
- Vehicle behavior stays deterministic for the same state, input, surface
  sample, configuration, and time step.
- Barrier impacts, jumps, airborne transitions, and other desired physical
  reactions must be modeled deliberately rather than inherited from a dynamic
  rigid body.
- Replay determinism is not yet guaranteed. The measurements required before
  choosing input-only replay or a simulation step are recorded in ADR-0005.
- The shared controller protocol and harness remain useful for regression
  comparison and future experiments.

## Alternatives considered

- Selecting Physics Force would preserve emergent rigid-body reactions but
  accept an unresolved seam failure in the primary Phase 1 path.
- Continuing to tune both approaches would delay the first playable without
  new acceptance evidence.
- Removing Physics Force immediately would discard a useful comparison fixture
  before the selected controller has completed Phase 1 race integration.

## Evidence

- [Physics-force verification](../Phase0/Verification/PhysicsForceController.md)
- [Constraint-assisted verification](../Phase0/Verification/ConstraintAssistedController.md)
- [Shared comparison harness](../Phase0/Verification/VehicleHarness.md)
