# Phase 0 foundation implementation plan

> Status: Completed; retained as a historical implementation record.

## Outcome

Deliver a small, offline visionOS foundation that:

- has an intentional window-to-mixed-immersive-space flow;
- defines testable track-piece and socket domain models;
- procedurally renders straight, left-curve, and start/finish gray-box pieces;
- has a source layout that can grow without mixing domain and presentation
  responsibilities; and
- passes focused unit tests plus the repository build and test commands.

This slice does not implement snapping interactions, track persistence,
validation, controllers, vehicle movement, online services, or final artwork.

## Baseline observations

- `LoopLab` and `LoopLabTests` are the only native targets in the shared
  `LoopLab` scheme.
- The app target is visionOS 26.5 and uses SwiftUI, RealityKit, and a local
  `RealityKitContent` Swift package.
- The starter already has a window, a mixed immersive space, shared open/close
  state, and a placeholder Swift Testing target.
- The app and test directories are file-system-synchronized Xcode groups.
  Moving Swift files into subfolders under those roots should preserve target
  membership without hand-editing `project.pbxproj`.
- Existing `Scene` and `Immersive` Reality Composer Pro assets are template
  placeholders. The Phase 0 preview should not depend on them.

## Proposed source structure

```text
LoopLab/
├── App/
│   ├── LoopLabApp.swift
│   └── AppModel.swift
├── Domain/
│   └── Track/
│       ├── TrackPieceDefinition.swift
│       ├── TrackPieceKind.swift
│       ├── TrackSocket.swift
│       └── TrackPieceCatalog.swift
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── ImmersiveSpaceButton.swift
│   └── TrackPreview/
│       └── TrackPreviewImmersiveView.swift
└── Presentation/
    └── RealityKit/
        ├── GrayBoxTrackLayout.swift
        └── TrackPieceEntityFactory.swift

LoopLabTests/
├── App/
│   └── AppModelTests.swift
└── Domain/
    └── Track/
        ├── TrackPieceCatalogTests.swift
        └── TrackSocketTests.swift
```

Keep the local `RealityKitContent` package in place for later authored assets,
but remove its placeholder scene loading from the Phase 0 views.

## Domain contract

1. Define `TrackPieceKind` as a stable, `String`-backed identifier for
   `straight`, `leftCurve`, and `startFinish`. Make it `Codable`, `Hashable`,
   `CaseIterable`, and `Sendable` so the identifiers can survive future
   document and catalog work.
2. Define a small `TrackSocket` value type with:
   - a stable local socket ID;
   - an entry or exit role;
   - a connection category;
   - a position and orientation in piece-local coordinates.
3. Define `TrackPieceDefinition` as immutable domain data containing:
   - stable kind and schema version;
   - display name;
   - lane width and piece bounds;
   - exactly one entry and one exit socket for the Phase 0 catalog;
   - a renderer-neutral geometry recipe such as straight deck or arc deck.
4. Define `TrackPieceCatalog.phase0` as the single source of truth for the
   three definitions and their shared authoring measurements.
5. Use meters, right-handed RealityKit coordinates, `+Y` up, and define one
   documented forward axis. Socket orientations point out of the piece so a
   later snap transform can align one socket with the inverse of another.
6. Keep SwiftUI and RealityKit imports out of `Domain/`. `simd`/spatial value
   types are acceptable, but the domain model must not own `Entity`,
   `MeshResource`, `Material`, or collision components.

For this slice, model definitions rather than full placed-piece documents or a
track graph. Add those only when placement and persistence enter scope.

## Window-to-immersive-space flow

1. Replace the template `ContentView` with `HomeView`, showing the product
   title, a concise prototype description, and one primary action:
   **Enter Track Preview**.
2. Retain an explicit state machine in `AppModel`:
   `closed`, `opening`, `open`, and `closing`. Derive the button label and
   disabled state from it.
3. Put calls to `openImmersiveSpace` and `dismissImmersiveSpace` in
   `ImmersiveSpaceButton`. Treat `.userCancelled`, `.error`, and unknown open
   results as a transition back to `closed`.
4. Let `TrackPreviewImmersiveView.onAppear` and `.onDisappear` reconcile the
   final open/closed state, because immersive spaces may be dismissed outside
   the button path.
5. Keep one mixed immersive space with a stable ID owned by `AppModel`. Do not
   introduce volumes, additional windows, persistence, or navigation stacks in
   this slice.

## Procedural gray-box rendering

1. Implement `TrackPieceEntityFactory` as the only mapping from a
   `TrackPieceDefinition` geometry recipe to RealityKit.
2. Use a neutral `SimpleMaterial` palette and deterministic entity names based
   on domain IDs:
   - straight: generated box deck;
   - left curve: an annular-sector mesh built from a fixed number of segments;
   - start/finish: the straight deck recipe plus a thin contrasting grayscale
     line or marker.
3. Keep all measurements in the domain catalog. The factory should not contain
   a second set of magic dimensions.
4. Create `GrayBoxTrackLayout` to position the three generated entities in a
   readable tabletop sample, parented under one root entity. The layout is
   preview-only and is not a track model.
5. Add the root once in the `RealityView` content closure. Avoid frame-update
   rebuilding and duplicate entities when the immersive space reappears.
6. Do not add final materials, textures, audio, effects, dynamic bodies, a car,
   or vehicle forces. Static collision can wait for the snapping/seam
   prototype, where its contract can be tested deliberately.

## Focused unit tests

Use Swift Testing in `LoopLabTests`:

1. `TrackPieceCatalogTests`
   - contains exactly the three Phase 0 piece kinds;
   - has unique, stable IDs;
   - gives every definition positive dimensions and exactly one entry and one
     exit socket;
   - keeps socket positions on the expected piece boundaries;
   - verifies shared lane width and schema version.
2. `TrackSocketTests`
   - connection compatibility is symmetric;
   - incompatible connection categories are rejected;
   - entry/exit role rules are enforced;
   - socket poses use normalized rotations and finite coordinates.
3. `AppModelTests`
   - valid open and close transition sequences;
   - cancellation/error recovery to `closed`;
   - duplicate requests are ignored while a transition is in progress.

Keep UI-environment actions and mesh pixel appearance out of unit tests.
Verify the RealityKit result through compilation plus a short simulator smoke
test.

## Implementation sequence

1. Move the existing files into the proposed folders and rename the template
   views. Build immediately to confirm synchronized target membership.
2. Add the domain value types and Phase 0 catalog, then add and run their tests.
3. Add the procedural entity factory and gray-box sample layout.
4. Replace placeholder asset loading with the generated root entity.
5. Refine the immersive state machine and home action, then add state tests.
6. Run the exact build and test commands in
   [`AGENTS.md`](../../../AGENTS.md).
7. Launch in the Apple Vision Pro simulator and manually verify:
   - the window appears with the entry action;
   - the action opens the mixed immersive space;
   - all three grayscale pieces are visible at a comfortable tabletop scale;
   - dismiss and reopen work without duplicates or a stuck transition state.

## Acceptance criteria

- The proposed folder structure exists and Xcode discovers all sources without
  manual target-membership drift.
- The app builds for a generic visionOS destination.
- All focused unit tests pass on the visionOS 26.5 Apple Vision Pro simulator.
- The window can open, dismiss, and reopen the mixed immersive preview.
- Straight, left-curve, and start/finish pieces are generated from domain
  definitions and are all visibly distinct in grayscale.
- No online-service dependency, final-art asset, car controller, dynamic
  vehicle physics, persistence layer, or unrelated editor feature is added.
