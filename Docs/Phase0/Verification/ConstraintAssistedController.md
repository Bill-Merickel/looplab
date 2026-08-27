# Phase 0 constraint-assisted controller verification

## Prototype contract

- The shared semantic input, course, gray-box vehicle, start pose, surface
  probes, telemetry, timing, and recovery policy remain unchanged from Step 5.
- **Constraint Assisted** is the selected default after the Phase 0 comparison.
  Selecting either controller resets the same vehicle entity and changes its
  physics body between kinematic and dynamic mode.
- Pure calculations integrate forward speed, braking/reverse, coasting, and
  speed-sensitive steering without importing RealityKit.
- R2 alone accelerates, L2 alone brakes and then reverses, and holding both
  triggers brakes either direction to a stop without initiating reverse.
- While grounded, the controller maintains the configured ride height, aligns
  the vehicle with the sampled surface normal, and supplies a kinematic linear
  velocity. Steering is pose-driven, so static collision impulses cannot alter
  the requested heading or speed at a track-piece seam.
- Lateral velocity is retained and damped rather than discarded immediately,
  allowing controlled slip while constraining it from growing without limit.
- Without a valid surface sample, the controller stops accepting drive input
  and applies a deterministic downward velocity until the shared recovery
  tracker resets the vehicle.
- The physics-force controller uses the same pedal arbitration. Its recorded
  angled-seam limitation otherwise remains unchanged so both approaches can be
  compared on the same baseline.

This remains a Phase 0 comparison prototype. The decision to carry Constraint
Assisted into Phase 1 is recorded in
[`ADR-0003`](../../ArchitectureDecisions/0003-use-constraint-assisted-vehicle-controller.md).
It does not add wheel or suspension simulation, implement checkpoints or lap
timing, or resolve the underlying static-mesh seam behavior for dynamic bodies.

## Automated verification

Run the exact build and test commands documented in
[`AGENTS.md`](../../../AGENTS.md). Focused Swift
Testing coverage verifies:

- forward acceleration and maximum speed;
- braking and reverse behavior;
- simultaneous-trigger braking and hold-at-rest behavior;
- speed-sensitive forward and reverse steering;
- retention and damping of lateral slip;
- ride-height and surface-normal constraints;
- airborne gravity without drive input;
- valid Phase 0 constraint tuning;
- registration in the default shared harness; and
- reuse of the same RealityKit vehicle in kinematic and dynamic modes.

## Simulator smoke check

- [x] Enter Track Preview and confirm the HUD reports **Constraint Assisted**.
- [x] Select **Switch Controller** and confirm the HUD reports
      **Physics Force** after one controller-change reset.
- [x] Hold R2 and confirm the vehicle accelerates rather than remaining at the
      start pose.
- [x] Hold R2 while steering and confirm heading and speed update together.
- [x] Hold L2 while moving forward to brake, then continue holding it to
      reverse.
- [x] With each controller, hold R2 and L2 together while moving forward and in
      reverse. Confirm the vehicle brakes to `0 m/s`, remains stopped while both
      stay held, and only reverses after releasing R2.
- [x] Switch between both controllers several times. Confirm each switch uses
      the same vehicle and course and produces exactly one reset.
- [x] Use **Reset Vehicle** and confirm the canonical pose and zero motion are
      restored.

## Physical Apple Vision Pro and DualSense check

- [x] Repeat the updated simulator smoke check on the recorded visionOS 26.5
      device.
- [x] Sweep gaze across the vehicle, both track halves, oval center, and course
      margin while accelerating and steering. Confirm input remains active.
- [x] Compare acceleration, braking, reverse, and low/high-speed steering with
      **Physics Force** using similar DualSense inputs.
- [x] Cross every seam in both directions while driving straight. Confirm no
      seam changes heading or produces a distinct HUD speed drop.
- [x] Cross every seam in both directions at shallow and steeper angles. The
      Step 5 failure was an unintended yaw change followed by speed falling to
      nearly `0 m/s`; confirm whether **Constraint Assisted** avoids both
      symptoms.
- [x] Enter a curve with sideways velocity. Confirm some slip remains visible
      and decreases progressively rather than disappearing instantly or
      increasing without limit.
- [x] Drive completely off the course. Confirm the vehicle falls and the shared
      lost-surface recovery restores the stable start pose.
- [x] Complete three consecutive controlled loops within 120 seconds without a
      manual reset, unintended yaw change, seam-related stop, or loss of input.
- [x] Attempt the same three-loop run with **Physics Force** and record whether
      the angled-seam limitation prevents reliable completion.

## Comparison record

Record physical results before changing either controller's tuning.

| Criterion | Physics Force | Constraint Assisted |
| --- | --- | --- |
| Acceleration and braking feel | Passed | Passed |
| Low/high-speed steering | Passed | Passed |
| Lateral-slip behavior | Blocked by angled-seam issue | Passed |
| Straight seam reliability | Passed | Passed |
| Angled seam reliability | Failed: yaw and near-zero speed | Passed |
| Off-track recovery | Passed | Passed |
| Three consecutive loops | Not reliable: angled-seam issue | Passed |
| Typical HUD update time | Passed | Passed |

Capture the adjacent piece names, approach direction, approximate HUD speed,
and whether heading changed for every failed seam crossing.
