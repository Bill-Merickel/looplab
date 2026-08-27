# LoopLab — visionOS Development Plan

## 1. Product vision

LoopLab is a toy-like spatial racing game for Apple Vision Pro where players:

1. Assemble a custom racetrack from modular pieces.
2. Place and edit the track naturally in their space.
3. Drive a small car around the completed track.
4. Save, replay, and share tracks.
5. Compete for the best lap time through leaderboards and ghosts.
6. Eventually race other players in real time.

The experience should feel playful and tactile, with a clean interface that stays out of the way of building and driving.

## 2. Product principles

- **Make the core loop fun offline first.** Building and driving must be satisfying before online systems are added.
- **Prefer toy-like behavior over simulation.** Cars should be readable, responsive, and forgiving.
- **Keep spatial interactions comfortable.** Avoid excessive head movement, tiny controls, and required precision gestures.
- **Use progressive disclosure.** Show only the tools relevant to the current mode.
- **Make tracks deterministic and portable.** A track should have a canonical definition that can be saved, hashed, uploaded, downloaded, and versioned.
- **Design for multiple input methods.** DualSense is important, but the app should remain navigable without one.
- **Separate gameplay from presentation.** Track rules, timing, vehicle state, and online records should not depend directly on menu or rendering code.

## 3. Initial scope

### MVP

- A visionOS app built with SwiftUI and RealityKit.
- Windowed main menu plus an immersive or volumetric track-building/driving experience.
- Local player profile and settings.
- Track pieces:
  - Straight
  - Short and long straight
  - Left and right curves
  - Incline and decline
  - Elevated straight
  - Ramp
  - Start/finish piece
- Piece snapping with visible connection points.
- Placement, rotation, deletion, undo, and redo.
- Track validation for a single closed loop.
- One toy-like car.
- Third-person/chase and trackside camera options, as comfort allows.
- DualSense controls.
- On-screen/spatial fallback controls for essential actions.
- Lap timing, checkpoints, best local time, reset, and restart.
- Local saving, loading, renaming, duplicating, and deleting of tracks.
- A short onboarding flow.

### Post-MVP

- Additional cars and handling profiles.
- More track-piece families and cosmetic themes.
- Track upload/download.
- Per-track online leaderboards.
- Downloadable ghosts.
- Ratings, favorites, discovery, and reporting.
- Real-time multiplayer.

### Explicitly out of scope for the first playable build

- Real-time multiplayer.
- Competitive physics simulation.
- In-app track-piece modeling tools.
- User-created 3D assets.
- Monetization.
- Cross-platform clients.
- Server-authoritative full physics.

## 4. Recommended technical foundation

Use the current stable versions of Xcode, Swift, and the visionOS SDK when implementation begins.

### Apple frameworks

- **SwiftUI:** app lifecycle, windows, menus, settings, and overlays.
- **RealityKit:** track and vehicle entities, rendering, collisions, physics, animation, and spatial input.
- **GameController:** DualSense discovery and input.
- **Observation:** app, editor, race, and settings state.
- **SwiftData:** local track metadata, player settings, and local race records.
- **Codable files:** canonical track documents and replay/ghost payloads.
- **CloudKit or a custom service:** shared tracks and asynchronous competition, selected after a backend spike.
- **GameKit or a custom multiplayer service:** evaluate later for identity, invites, and real-time racing.
- **OSLog and MetricKit:** diagnostics and performance monitoring.

### Architecture

Use a feature-oriented architecture with explicit state boundaries:

```text
App
├── App Shell and Navigation
├── Track Library
├── Track Editor
├── Race Session
├── Vehicle System
├── Input System
├── Replay/Ghost System
├── Persistence
├── Online Services
└── Shared UI and Assets
```

Recommended layers:

- **Domain:** track graph, piece definitions, validation, timing rules, vehicle configuration, replay schema.
- **Simulation:** vehicle movement, collision responses, checkpoints, lap state, reset rules.
- **Presentation:** RealityKit entities, materials, effects, audio, SwiftUI menus.
- **Platform adapters:** GameController, persistence, CloudKit/backend, account identity.

Use protocols around persistence, input, leaderboards, track sharing, and replay storage so local implementations can be replaced without rewriting gameplay.

## 5. Core data model

### Track document

Each track should be a versioned, portable document containing:

- Stable track ID and schema version.
- Name, author ID/display name, creation date, and update date.
- Ordered piece instances.
- Piece type/version.
- Transform relative to the track origin.
- Connection/socket assignments.
- Start position and forward direction.
- Checkpoint definitions.
- Optional theme and environment settings.
- Editor bounds and preferred scale.
- Derived canonical hash.

Do not serialize RealityKit entities directly. Build entities from the domain model.

### Track-piece definition

Each reusable piece definition should include:

- Stable piece type ID.
- Render asset reference.
- Collision asset/reference.
- Entry and exit sockets with position, orientation, and allowed connection type.
- Driveable surface metadata.
- Recommended checkpoint or centerline samples.
- Bounding box used by editor overlap checks.
- Elevation change and curvature metadata.
- Placement thumbnail/icon.
- Schema/version compatibility.

Represent the track as both:

- A list of placed piece instances for persistence and rendering.
- A graph of connected sockets for validation and traversal.

### Vehicle configuration

Keep car behavior data-driven:

- Mass and center of mass.
- Acceleration and braking curves.
- Maximum speed.
- Steering response by speed.
- Tire grip/slip behavior.
- Suspension or hover/grounding behavior.
- Air control.
- Downforce.
- Stability assistance.
- Recovery behavior.
- Visual and audio asset references.

### Race record

- Track ID and canonical track hash.
- Track schema/gameplay rules version.
- Car configuration ID/version.
- Player ID.
- Completion time and split times.
- Timestamp.
- Input method.
- Replay/ghost reference.
- Validation status.

Versioning the track, car, physics, and timing rules prevents incomparable runs from sharing a leaderboard.

## 6. Spatial experience and navigation

### App flow

```text
Launch
  → Home
      → Build New Track
      → My Tracks
      → Browse Tracks (online phase)
      → Garage (post-MVP)
      → Settings

Track selected
  → Edit
  → Test Drive
  → Race
  → Results
```

### Clean menu system

Use a conventional SwiftUI window for browsing and management, then a compact spatial toolbar during creation and racing.

Home menu:

- Large, clear primary actions.
- Recent tracks.
- Controller connection state.
- Minimal account/online status.

Editor toolbar:

- Piece palette grouped by type.
- Select/move mode.
- Undo/redo.
- Validate.
- Test drive.
- Save/exit.

Race HUD:

- Current lap time.
- Best time and delta.
- Lap/checkpoint status.
- Reset car.
- Pause/exit.
- Controller status only when relevant.

Avoid placing essential controls at extreme viewing angles. Support readable scale and contrast, reduced motion, handedness where applicable, and seated/standing use.

## 7. Track-building system

### Placement model

1. Player selects a piece from the palette.
2. The piece appears as a translucent preview.
3. Compatible sockets on the existing track are highlighted.
4. Moving near a socket snaps position and orientation.
5. Placement is rejected or clearly warned if it creates invalid overlap.
6. Confirming placement updates the track graph and undo history.

For the first release, use socket-based construction instead of freeform deformation. This makes validation, collision, AI lines, ghosts, and sharing substantially more reliable.

### Required editor operations

- Add piece.
- Select piece.
- Move a disconnected section if practical; otherwise move one piece.
- Rotate around valid socket orientations.
- Replace piece while preserving compatible connections.
- Delete piece.
- Duplicate piece.
- Undo/redo via command history.
- Recenter/reposition the entire track.
- Save draft.
- Clear track with confirmation.

### Validation

The validator should report specific, actionable problems:

- Missing start/finish piece.
- Unconnected socket.
- Branch or multiple-loop topology when only one loop is supported.
- Incorrect direction or incompatible socket.
- Piece overlap.
- Driveable surface discontinuity beyond tolerance.
- Excessive slope or transition for the selected car class.
- Missing or ambiguous checkpoint order.
- Track outside supported spatial bounds.

A valid MVP race track is one closed, directed loop with one start/finish line and an automatically generated ordered checkpoint sequence.

### Content pipeline

Create every piece around a shared authoring contract:

- Consistent units, origin, scale, and forward axis.
- Precisely placed sockets.
- Separate simplified collision geometry.
- Consistent lane width and edge barriers.
- LODs where useful.
- Material variants driven by theme.
- Automated asset checks for missing sockets, bad scale, and collision gaps.

Start with gray-box pieces. Replace them with final art only after snapping, collision, and driving feel are proven.

## 8. Vehicle and driving model

### MVP approach

Use a custom arcade vehicle controller layered on RealityKit collision/physics rather than relying on an opaque full vehicle simulator.

The controller should:

- Sample the surface beneath the car.
- Apply forward drive and braking forces.
- Calculate steering response based on speed.
- Apply lateral grip with a tunable slip limit.
- Add stability torque and downforce.
- Allow small jumps while discouraging uncontrolled flipping.
- Detect stuck, fallen, or off-track states.
- Restore the car to the latest valid checkpoint.

This provides predictable toy-like handling and makes later cars feel distinct through configuration rather than separate code paths.

### Driving modes to prototype

- Physics-force controller with ray-cast suspension.
- Simpler kinematic/constraint-assisted controller.

Choose based on feel, collision reliability on connected pieces, frame-time cost, and replay consistency. Record the result in an architecture decision.

### Race rules

- Countdown before control is enabled.
- Ordered checkpoints prevent shortcut times.
- Lap completes only after all checkpoints are crossed in order.
- Reset returns to the latest safe checkpoint and may add a configurable time penalty.
- Pausing excludes wall-clock pause time.
- Invalid runs are clearly labeled and never submitted online.

## 9. Input and DualSense support

Create an `InputProvider` abstraction that emits semantic actions:

- Steer.
- Throttle.
- Brake/reverse.
- Handbrake or drift assist.
- Reset car.
- Change camera.
- Pause.
- Confirm/cancel.
- Editor select, rotate, delete, undo, and redo.

### Suggested DualSense mapping

- Left stick: steering.
- R2: throttle.
- L2: brake/reverse.
- Square: reset car.
- Triangle: change camera.
- Options: pause.
- Cross/Circle: confirm/cancel in menus.
- D-pad or shoulder buttons: editor palette navigation.
- L1/R1: rotate selected track piece.

### Input requirements

- Handle connection and disconnection at any time.
- Show a subtle connection notification.
- Preserve the current action safely when a controller disconnects.
- Provide remapping and sensitivity/dead-zone settings later.
- Use haptics only if the supported controller APIs provide a robust path; do not make haptics a dependency.
- Keep gaze/pinch and SwiftUI controls available for menu navigation.

## 10. Persistence and local library

### Storage strategy

- Store searchable metadata and local records in SwiftData.
- Store the full track document and replay payload as versioned files.
- Generate thumbnails after a track is saved.
- Save drafts automatically after meaningful edits.
- Use atomic file replacement and maintain a recovery copy.

### Local library features

- Grid/list of track thumbnails.
- Sort by recently edited, name, and best time.
- Rename, duplicate, delete, and export.
- Compatibility/migration status.
- Graceful handling of corrupt or newer-version documents.

## 11. Online tracks and leaderboards

Online work begins only after local track IDs, hashes, schema migration, race records, and replays are stable.

### Backend decision spike

Compare:

- CloudKit public/private databases.
- A small custom API with managed authentication, object storage, and a relational database.
- Game Center/GameKit capabilities for identity and applicable competition features.

Evaluate:

- Dynamic per-user-generated-track leaderboards.
- Moderation and abuse reporting.
- Querying, sorting, pagination, and discovery.
- Replay/object size and bandwidth.
- Server-side validation options.
- Operational cost and observability.
- Account deletion and privacy requirements.

Hide the choice behind service protocols.

### Track publishing flow

1. Validate the track locally.
2. Freeze a published revision.
3. Compute its canonical hash.
4. Generate a thumbnail and compact metadata.
5. Upload the document and metadata.
6. Run server-side schema and safety validation.
7. Assign a public track/revision ID.
8. Make the immutable revision available for racing.

Editing a published track creates a new revision. Existing leaderboard entries stay attached to the old revision.

### Leaderboards

Support:

- Global best times for a track revision.
- Player’s personal best.
- Friends leaderboard when identity support allows it.
- Pagination and cached recent results.
- Filters by car class/rules version if the design requires them.

Never trust a submitted time alone. At minimum, require the exact track hash, rules versions, checkpoint splits, and a replay/telemetry payload. Add plausibility checks before accepting a result. Strong competitive integrity may ultimately require server-authoritative or server-replayed simulation; this is a later investment.

### Safety and moderation

Before public sharing:

- Sanitize names and text.
- Set size and complexity limits.
- Add report/block flows.
- Rate-limit publishing and submissions.
- Define track visibility: private, unlisted, or public.
- Provide takedown and account-deletion paths.
- Publish clear privacy and community policies.

## 12. Ghost replay system

### MVP ghost format

Record a compact, timestamped sequence of:

- Car position.
- Car orientation.
- Optional wheel/steering visual state.
- Checkpoint events.

Interpolate these samples for a non-colliding translucent ghost. This is more robust across small physics changes than replaying raw inputs.

### Requirements

- Ghost never affects local physics.
- Start time aligns exactly with the countdown/race clock.
- Hide or fade a ghost when it obstructs the player.
- Validate that the ghost matches the track hash, car version, and rules version.
- Allow racing personal best, global best, or a selected player.
- Compress, cap, and checksum payloads.

Input replay can be evaluated later for stronger validation, but it requires sufficiently deterministic simulation.

## 13. Real-time multiplayer roadmap

Treat real-time racing as a separate phase because it changes simulation, networking, UX, and cheating concerns.

### Recommended progression

1. Asynchronous shared tracks.
2. Online leaderboards.
3. Downloaded ghosts.
4. Private two-player prototype.
5. Lobby/invite flow.
6. State synchronization and latency compensation.
7. Reconnect, host migration, and results reconciliation.
8. Broader matchmaking and public races.

For an early prototype, cars can be non-colliding between players. This avoids network-sensitive vehicle-to-vehicle physics while preserving the social race experience.

## 14. Audio, visual style, and feedback

- Use a cohesive tabletop/toy aesthetic with readable shapes and slightly exaggerated scale.
- Give each piece a strong silhouette and clear connection markings.
- Use placement previews: valid, invalid, and selected states.
- Add satisfying snap, place, delete, countdown, checkpoint, finish, and personal-best feedback.
- Vary motor pitch with speed/load.
- Use restrained particles for dust, landing, and finish effects.
- Ensure effects do not overwhelm the player’s real environment.

## 15. Testing and quality strategy

### Automated tests

- Socket compatibility and snapping transforms.
- Track graph traversal and closed-loop validation.
- Checkpoint generation and ordering.
- Track canonicalization and hash stability.
- Document encoding, decoding, and migrations.
- Undo/redo command behavior.
- Race timer and reset rules.
- Input mapping and disconnect behavior.
- Replay encoding, interpolation, and compatibility.
- Online request/response contracts with mocks.

### Integration tests

- Build, save, reload, and race a track.
- Change a track and verify its revision/hash changes.
- Complete/invalid lap scenarios.
- Controller connection during menu, edit, and race modes.
- Upload/download round trip in a test environment.
- Leaderboard submission acceptance and rejection.

### Device testing

The simulator is useful for iteration, but regular Apple Vision Pro testing is required for:

- Text and control legibility.
- Gesture reach and precision.
- Spatial scale.
- Tracking behavior.
- Comfort and motion.
- Controller pairing and latency.
- Thermal behavior and sustained frame rate.

### Performance budgets

Define budgets during the first prototype for:

- Frame time.
- Active physics bodies.
- Triangle and material counts.
- Collision complexity.
- Memory.
- Track-piece count.
- Replay sample size.
- Network payload size.

Add a developer HUD showing frame rate, physics time, entity count, active contacts, track hash, and input state.

## 16. Accessibility and comfort

- Seated and standing support.
- Recenter and reposition controls.
- Adjustable UI scale and high-contrast placement feedback.
- Reduced-motion option.
- Camera smoothing and shake controls.
- Steering sensitivity and dead-zone settings.
- Optional driving assists: auto-righting, steering stability, and track reset.
- Visual alternatives for important audio cues.
- No gameplay-critical reliance on color alone.

## 17. Delivery phases

### Phase 0 — Discovery and technical prototypes

Completion and verification evidence is recorded in
[`Docs/Phase0/README.md`](Docs/Phase0/README.md).

Deliver:

- Short product brief and experience flow.
- Current SDK/device capability check.
- RealityKit track-piece snapping prototype.
- Gray-box loop with reliable collision seams.
- DualSense input prototype.
- Two competing vehicle-controller prototypes.
- Architecture decisions for spatial mode, physics approach, and asset authoring contract.

Exit criteria:

- A car can complete a gray-box loop comfortably on device.
- Snapped pieces have no frequent collision gaps.
- DualSense connects and drives with acceptable latency.

### Phase 1 — First playable

Deliver:

- App shell and clean navigation.
- Piece palette and core editor actions.
- Undo/redo.
- Closed-loop validation.
- One complete track-piece set.
- One car with reset/recovery.
- Checkpoints, countdown, lap timing, and results.
- Local save/load.

Exit criteria:

- A new player can build, validate, save, and race a track without developer help.

### Phase 2 — Alpha polish

Deliver:

- Onboarding.
- Improved materials, audio, effects, and thumbnails.
- Settings and accessibility controls.
- Controller disconnect/reconnect UX.
- Track library management.
- Autosave and recovery.
- Performance budgets and diagnostics.
- Broader unit/integration coverage.

Exit criteria:

- Core loop is stable across supported track sizes and repeated sessions.
- No known save corruption or common progress-loss path.
- Sustained device performance meets the chosen target.

### Phase 3 — Cars and content

Deliver:

- Data-driven garage.
- Several handling profiles.
- Additional track pieces and themes.
- Piece/car compatibility rules if needed.
- Local personal-best ghosts.

Exit criteria:

- Cars feel meaningfully different without requiring separate controller implementations.

### Phase 4 — Shared tracks

Deliver:

- Account/identity decision.
- Backend and test environment.
- Immutable published track revisions.
- Upload, download, browse, search, favorites, and report flows.
- Moderation and rate limiting.

Exit criteria:

- A published track can be reliably downloaded and produces the same canonical hash and geometry.

### Phase 5 — Leaderboards and online ghosts

Deliver:

- Per-revision leaderboards.
- Submission validation and telemetry.
- Ghost upload/download.
- Personal, global, and selected-player ghost racing.
- Privacy and retention controls.

Exit criteria:

- Incompatible or obviously invalid runs are rejected.
- Accepted results and ghosts remain reproducible on the exact published track revision.

### Phase 6 — Real-time racing prototype

Deliver:

- Private lobby/invites.
- Two-player non-colliding races.
- Network state synchronization.
- Latency, disconnect, reconnect, and results UX.
- Technical decision on scaling beyond private races.

Exit criteria:

- Two remote players can reliably start, finish, and reconcile the same race.

## 18. Initial implementation backlog

Work roughly in this order:

1. Create the visionOS project and shared module boundaries.
2. Add diagnostics, development settings, and a small test target.
3. Define `TrackDocument`, `TrackPieceDefinition`, sockets, and schema versioning.
4. Build three gray-box pieces: straight, curve, and start/finish.
5. Implement entity generation from track data.
6. Implement socket visualization and exact snapping.
7. Add track graph construction and closed-loop validation.
8. Add simplified collision geometry and seam tests.
9. Implement semantic input actions and DualSense adapter.
10. Prototype and compare vehicle-controller approaches.
11. Add reset/recovery and latest-safe-checkpoint tracking.
12. Add race countdown, checkpoints, lap timer, and results.
13. Add editor command history for undo/redo.
14. Add remaining MVP track pieces.
15. Add SwiftData metadata and versioned track files.
16. Build home, track library, editor toolbar, pause, and results UI.
17. Add autosave, recovery, thumbnails, and onboarding.
18. Test and profile repeatedly on Apple Vision Pro.

## 19. Key risks and mitigations

| Risk | Mitigation |
|---|---|
| Physics catches or launches the car at piece seams | Shared mesh contract, simplified collision shapes, seam test fixtures, and constraint-assisted grounding |
| Track editor feels imprecise | Socket-first snapping, generous targets, previews, undo/redo, and automatic orientation |
| Large tracks exceed performance budgets | Piece caps, collision LOD, entity batching where appropriate, profiling, and publish-time complexity limits |
| Motion or camera behavior causes discomfort | Tabletop scale, stable references, camera smoothing, restrained effects, and reduced-motion settings |
| Physics changes invalidate competition | Version track, car, physics, and race rules; isolate leaderboards by compatible version |
| Client-side cheating pollutes leaderboards | Immutable revisions, telemetry/replays, plausibility checks, rate limits, and later authoritative validation |
| Cloud/backend choice limits discovery or moderation | Complete a focused backend spike and keep services behind protocols |
| Real-time physics is unstable over networks | Ship asynchronous competition first and prototype non-colliding multiplayer |
| User-generated content creates safety/privacy burden | Minimal text, visibility controls, reporting, rate limits, moderation, and documented retention/deletion |

## 20. Architecture decisions to record

Create short decision records as these questions are resolved:

- [Window and immersive-space responsibilities](Docs/ArchitectureDecisions/0001-use-tabletop-mixed-immersive-presentation.md).
- [Physics-force versus constraint-assisted vehicle controller](Docs/ArchitectureDecisions/0003-use-constraint-assisted-vehicle-controller.md).
- [Fixed or variable simulation step — deferred](Docs/ArchitectureDecisions/0005-defer-simulation-step-selection.md).
- [Track scale and maximum spatial footprint — deferred](Docs/ArchitectureDecisions/0004-defer-maximum-track-footprint.md).
- [Asset socket and collision authoring contract](Docs/ArchitectureDecisions/0002-use-domain-authored-track-pieces.md).
- SwiftData/file boundary.
- Canonical serialization and hashing method.
- CloudKit versus custom backend.
- Player identity approach.
- Ghost sample rate and compression.
- Leaderboard validation trust model.
- Real-time networking framework and authority model.

## 21. MVP definition of done

The MVP is complete when:

- A first-time player can understand the main menu and enter the builder.
- The player can create a valid closed-loop track from all MVP piece types.
- Snapping, undo/redo, deletion, and validation behave predictably.
- The track can be saved, closed, reopened, and raced without changing geometry.
- A DualSense controller can drive, brake, steer, reset, change camera, and pause.
- A full lap is timed only after checkpoints are completed in order.
- The app stores and displays the local best time for the exact track revision.
- Essential flows work when the controller is disconnected.
- The experience remains comfortable and performant on Apple Vision Pro for the supported track-size limit.
- Automated tests cover the domain model, validation, persistence, timing, input mapping, and replay foundations.
- Known limitations are documented and no critical data-loss or crash issue remains.

## 22. First decisions needed before implementation

1. Choose the target presentation: tabletop miniature, room-scale track, or support for both. A tabletop-first MVP is recommended.
2. Decide whether driving is primarily a chase-camera experience, a fixed spectator view, or offers both. Prototype both for comfort.
3. Define the visual theme and approximate track/car scale.
4. Confirm the minimum visionOS version and supported devices.
5. Confirm whether an Apple Developer account and physical Apple Vision Pro are available for controller and device testing.
6. Decide whether online services must be ready for the first public release or can follow the offline MVP.
