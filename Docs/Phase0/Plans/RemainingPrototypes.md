# Phase 0 remaining technical prototypes plan

> Status: Completed; retained as a historical implementation record.

## Outcome

Complete the work that remains after the Phase 0 foundation:

- demonstrate exact socket-based track-piece snapping;
- assemble a closed gray-box loop with reliable collision seams;
- connect and safely handle a DualSense controller;
- compare physics-force and constraint-assisted vehicle controllers; and
- record the architecture decisions supported by the prototypes.

Phase 0 is complete when a car can repeatedly drive the loop on a physical
Apple Vision Pro, seams do not cause frequent catches or launches, and a
DualSense provides acceptable control latency.

## Completed baseline

The merged foundation provides the window-to-immersive-space flow,
renderer-independent track and socket definitions, three procedural gray-box
pieces, a tabletop preview, focused tests, and reproducible commands in
[`AGENTS.md`](../../../AGENTS.md).

## Constraints

- Stay offline and gray-box.
- Keep domain data authoritative; RealityKit entities are generated views.
- Keep placed-track, snapping, input, and vehicle behavior independent of
  SwiftUI and RealityKit where practical.
- Use meters, a right-handed coordinate system, `+Y` up, and `+Z` forward.
- Build only enough interaction to evaluate the prototypes.
- Do not add a full editor, persistence, race rules, online services, final
  artwork, or production vehicle physics.
- Exercise both vehicle approaches through the same input, configuration,
  course, reset, and instrumentation contracts.
- Merge each verified slice into `main` before starting its dependent slice.

## Preflight record

Before feature work, add a short discovery note that:

- links to the product vision and experience flow in
  [`plan.md`](../../../plan.md);
- confirms mixed immersive space and tabletop scale as the baseline;
- records Xcode, Swift, visionOS SDK, device OS, and DualSense versions;
- confirms the physical device and controller are available for exit testing;
  and
- lists RealityKit or GameController assumptions that require a focused spike.

## Implementation sequence

### 1. Exact track-piece snapping

Branch: `feat/phase-0-track-snapping`

- Add renderer-independent placed-piece, socket-reference, connection, and
  transform types.
- Implement one deterministic snap transform that aligns compatible sockets
  with opposing outward directions.
- Reject self-connections, incompatible sockets, and occupied sockets without
  mutating the assembly.
- Add a minimal immersive interaction for moving one piece, highlighting a
  compatible socket, previewing the snap, and committing it.
- Generate socket markers from domain poses; do not store entities as model
  state.
- Test transform composition, alignment tolerances, compatibility, occupancy,
  and repeatability.

Acceptance: the preview and committed transform agree, valid sockets align
within a documented tolerance, and invalid snaps leave the assembly unchanged
on the simulator and physical device.

### 2. Closed loop and collision seams

Branch: `feat/phase-0-collision-loop`

- Add the smallest connection graph needed to traverse pieces and recognize
  one directed closed loop.
- Build a deterministic loop by reusing definitions and snap transforms rather
  than hand-placing RealityKit entities.
- Generate simplified static collision geometry from the same measurements as
  the visible decks.
- Test graph closure, collision contracts, and seam continuity at centerlines,
  surfaces, tangents, and lane edges.
- Traverse every seam with a simple test body before adding a vehicle
  controller.

Acceptance: the loop closes through compatible sockets, automated seams stay
within documented tolerances, and repeated device traversal does not produce
frequent catches, tunneling, or launches.

### 3. Semantic input and DualSense

Branch: `feat/phase-0-dualsense-input`

- Define a GameController-independent `InputProvider` and semantic state for
  steering, throttle, brake/reverse, reset, camera, pause, confirm, and cancel.
- Implement explicit DualSense mappings and connection observation.
- Clamp analog values, apply a documented dead zone, and neutralize held
  actions immediately on disconnect.
- Keep SwiftUI and spatial controls available for essential navigation.
- Test mapping, clamping, dead zones, connection changes, and stuck-input
  prevention with a fake provider.

Acceptance: DualSense can connect before or during the immersive session,
disconnect never leaves active input, reconnection does not require an app
restart, and physical-device response is adequate for controller evaluation.

### 4. Shared vehicle harness

Branch: `feat/phase-0-vehicle-harness`

- Define shared vehicle state, configuration, controller, timing, and
  reset/recovery contracts.
- Feed both controllers the same semantic input and create one reusable
  gray-box vehicle and start pose.
- Add development instrumentation for speed, update time, grounded state,
  contacts, resets, active controller, and input.
- Define one repeatable comparison run and tuning configuration.

Acceptance: implementations can be swapped without changing the input, course,
vehicle presentation, or evaluation code, and reset restores a stable pose.

### 5. Physics-force controller

Branch: `feat/phase-0-physics-force-controller`

Prototype surface sampling, drive and braking forces, speed-sensitive steering,
lateral grip, grounding assistance, and reset detection. Unit-test pure
calculations and state transitions; evaluate RealityKit behavior on the shared
course.

### 6. Constraint-assisted controller

Branch: `feat/phase-0-constraint-controller`

Implement a kinematic or constraint-assisted prototype behind the same
contracts, using the same inputs, configuration ranges, update timing, vehicle
dimensions, reset rules, and course.

Both controller branches remain tunable gray-box experiments. They do not add
race timing, checkpoints, car selection, or final effects.

### 7. Compare and record decisions

Branch: `docs/phase-0-prototype-decisions`

Compare both controllers on the physical device using the same loop and
DualSense. Record loop completion, seam failures, handling, recovery, update
cost, visible stability, input responsiveness, reconnect behavior, comfort,
and replay-consistency risks.

Create short architecture decisions for:

- [window, volume, and immersive-space responsibilities](../../ArchitectureDecisions/0001-use-tabletop-mixed-immersive-presentation.md);
- [tabletop scale and maximum footprint](../../ArchitectureDecisions/0004-defer-maximum-track-footprint.md), formally deferred beyond Phase 0;
- [fixed versus variable simulation timing](../../ArchitectureDecisions/0005-defer-simulation-step-selection.md), formally deferred until lap and replay measurement;
- [the selected vehicle-controller approach](../../ArchitectureDecisions/0003-use-constraint-assisted-vehicle-controller.md); and
- [the socket and collision authoring contract](../../ArchitectureDecisions/0002-use-domain-authored-track-pieces.md).

## Verification policy

Every implementation PR must add focused tests for new domain or state
behavior, run the exact build and simulator-test commands in
[`AGENTS.md`](../../../AGENTS.md), and
record relevant simulator and physical-device smoke checks.

Do not add tests merely to maximize coverage. Test calculations, contracts,
state transitions, failure recovery, and regression-prone behavior; verify
spatial feel and RealityKit integration on actual hardware.

## Final Phase 0 exit check

- [x] All implementation prototype branches were merged into `main` before
      this final decision branch was created.
- [x] The documented build and all focused tests pass.
- [x] Both controllers were evaluated on the same device, loop, and input
      configuration.
- [x] The selected controller completes three consecutive loop traversals
      without a seam-induced catch, launch, or reset.
- [x] DualSense connect, disconnect, and reconnect succeed three times without
      stuck input.
- [x] A ten-minute seated session is comfortable at the selected scale.
- [x] Steering, throttle, and braking latency are acceptable.
- [x] Required architecture decisions and environment versions are recorded.
- [x] No out-of-scope production or online feature was added.

This checklist records the completed Phase 0 exit state. Current completion
evidence and follow-on work are summarized in the
[Phase 0 record](../README.md).
