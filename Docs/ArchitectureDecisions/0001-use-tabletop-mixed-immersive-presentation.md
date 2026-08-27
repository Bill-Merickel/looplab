# ADR-0001: Use a tabletop-first mixed immersive presentation

- Status: Accepted
- Date: 2026-08-23
- Phase: Phase 0

## Context

LoopLab needs conventional navigation and a comfortable spatial surface for
building and driving tracks. Phase 0 tested a SwiftUI launch window, one mixed
immersive space, and a gray-box course presented at `0.35` tabletop scale.
Physical Apple Vision Pro testing confirmed that the loop was comfortable to
view, controller input remained available across its footprint, and repeated
entry restored the same presentation.

## Decision

Use a SwiftUI window for app navigation and lifecycle controls. Enter one mixed
immersive space for tabletop track building and driving. Keep the course rooted
in track-local meters and apply presentation scale at the RealityKit scene root.

The `0.35` scale is the validated Phase 0 baseline, not a permanent content
constant. Future recentering or scale settings may adjust presentation without
changing canonical track geometry.

The supported maximum track footprint is intentionally separate from this
presentation decision and is deferred in
[`ADR-0004`](0004-defer-maximum-track-footprint.md).

## Consequences

- Core menus remain readable and familiar in a window.
- Track interaction gets a stable spatial frame without requiring room-scale
  movement or full immersion.
- Domain geometry, collision calculations, and persisted transforms remain in
  meters instead of inheriting presentation scale.
- Essential controls must stay comfortably visible and must not rely on gaze at
  a single entity.
- A volumetric-only or room-scale mode can be evaluated later without changing
  the track model.

## Alternatives considered

- A volumetric window alone constrained the available track footprint.
- Full immersion was unnecessary for the tabletop-first MVP and would increase
  comfort and environment-design work.
- Room-scale tracks would make building and driving require more head and body
  movement than the Phase 0 experience target.
