# Phase 0 physics-force controller verification

## Prototype contract

- The shared semantic input, course, gray-box vehicle, start pose, telemetry,
  timing, and reset commands remain unchanged from Step 4.
- A localized `PhysicsSimulationComponent` treats the tabletop course as a
  meter-based simulation even though its presentation root is visually scaled.
- Five downward probes sample only the track collision group. A valid nearby
  hit supplies grounded state and an averaged surface normal to the controller.
- The physical course is one welded, top-only static collision mesh. Visible
  piece boundaries therefore contain no closed end faces that can catch the
  vehicle at an otherwise flush socket connection.
- An invisible input surface sits above and extends beyond the complete course,
  keeping gamepad delivery active while the player looks across the track,
  vehicle, oval center, or surrounding margin.
- Pure calculations produce forward drive, braking/reverse, speed-sensitive
  steering torque, limited lateral grip, grounding force, and roll/pitch
  stability torque. RealityKit only applies the resulting force and torque.
- Phase 0 steering reaches useful authority earlier, targets a higher yaw rate,
  and retains more authority near top speed while still requiring movement and
  reducing its response as speed rises.
- The shared recovery tracker permits brief airtime, then resets a vehicle that
  loses the surface or remains stuck under sustained drive input. Existing
  fallen, out-of-bounds, invalid-state, manual, and controller-change resets
  remain in force.
- The chamfered gray-box collision hull reduces the chance of its lower leading
  edges catching on already-validated piece boundaries without changing the
  visible vehicle or the shared vehicle dimensions.

This remains a tuning prototype. It does not add wheel simulation, suspension
animation, race rules, checkpoints, final vehicle art, or production effects.

## Automated verification

Run the exact build and test commands documented in
[`AGENTS.md`](../../../AGENTS.md). Focused Swift
Testing coverage verifies:

- surface-sample validation and normalization;
- throttle, braking, reverse, and speed limits;
- speed-sensitive steering and reverse steering direction;
- lateral-grip direction and slip limiting;
- grounding and stability forces;
- airborne behavior;
- lost-surface and stuck recovery state transitions; and
- RealityKit physics layers, damping, continuous collision detection, and the
  localized simulation component.

## Simulator smoke check

- [x] Enter Track Preview and confirm the HUD identifies **Physics Force** as
      the active controller.
- [x] Confirm the vehicle settles at the canonical start pose and the HUD
      reports `grounded` without repeated resets.
- [x] Hold R2 and confirm speed increases; release it and confirm the vehicle
      coasts rather than teleporting or being pose-driven.
- [x] Use **Reset Vehicle** and confirm pose and motion return to the canonical
      start state.
- [x] During the Step 5 baseline, switch to **Constraint Assisted** and confirm
      the same course, vehicle, HUD, and reset flow remain in place while its
      controller implementation was still passive.

## Physical Apple Vision Pro and DualSense check

- [x] Hold R2 to accelerate forward. Confirm the HUD throttle value and vehicle
      response update continuously while sweeping gaze across both track
      halves, the vehicle, the oval center, and the margin around the course.
- [x] While continuing to hold R2, move the left stick left and right. Confirm
      the HUD steering value changes and the moving vehicle turns in the same
      direction without dropping throttle.
- [x] At moderate speed, hold the stick halfway left or right and confirm the
      vehicle's heading changes clearly rather than only drifting a few degrees.
- [x] Compare a similar stick deflection at low and high speed. Confirm steering
      remains responsive at low speed and becomes less abrupt near top speed.
- [x] Hold L2 while moving forward to brake, then continue holding it after the
      vehicle stops to reverse. Confirm both transitions remain controllable.
- [ ] Drive across every piece boundary in both directions. Confirm no boundary
      stops, launches, or visibly rotates the vehicle.
- [ ] Enter a curve with some sideways velocity. Confirm the car can slip but
      lateral motion is damped rather than growing without limit.
- [x] Drive off the course and confirm automatic recovery returns the vehicle to
      the stable start pose with zero residual motion.
- [x] Complete at least one controlled loop. The three-consecutive-loop result
      is recorded only after Step 6 provides the comparison controller.

## Known limitation

On physical Apple Vision Pro testing, crossing a track-piece seam at an angle
can abruptly rotate the vehicle to an unintended heading and reduce its speed
to nearly `0 m/s`. Straight seam crossings remain reliable. This issue blocks
completion of the angled/seam and lateral-slip checks above and must be
evaluated again with the Step 6 constraint-assisted controller.

Record any failed seam, control combination, visible instability, reset loop,
or unusually high controller update time before changing tuning values.
