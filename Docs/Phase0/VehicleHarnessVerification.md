# Phase 0 shared vehicle harness verification

## Repeatable comparison run

- Configuration ID: `phase-0-gray-box-vehicle`, version `1`
- Course: `phase-0-collision-loop`
- Start pose: `(0, 0.065, -0.28)` in track-local meters, facing `+Z`
- Nominal update interval: `1/90` second
- Maximum accepted frame interval: `1/15` second
- Target: three consecutive closed-loop traversals within 120 seconds
- Input: the shared semantic state produced by the same connected DualSense
- Evaluation: use the same vehicle entity, start pose, recovery thresholds,
  telemetry, and course for both controller approaches

The harness caps unusually long frame intervals but intentionally leaves the
fixed-versus-variable timing decision open until both controller prototypes
have been evaluated.

## Simulator smoke check

- [x] Enter Track Preview and confirm one dark-gray vehicle with a yellow
      forward marker rests on the start/finish straight.
- [x] Confirm the HUD reports speed, update time, grounded state, contacts,
      reset count, active controller, semantic input, and raw controller
      activity.
- [x] Select **Switch Controller** and confirm the active controller changes
      while the course and vehicle presentation remain unchanged.
- [x] Select **Reset Vehicle** and confirm the vehicle returns to the same
      stable start pose with zero visible motion.

## Physical Apple Vision Pro smoke check

- [x] Repeat the simulator checks on the physical device.
- [x] Press the mapped DualSense reset control and confirm one reset occurs per
      press rather than continuously while held.
- [x] Look across the complete track footprint and confirm controller activity
      remains visible in the harness HUD.

Actual driving and three-loop comparison results are recorded in
`ConstraintAssistedControllerVerification.md` now that Steps 5 and 6 provide
both controller implementations.
