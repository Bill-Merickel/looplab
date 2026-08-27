# ADR-0002: Use domain-authored track pieces and generated collision

- Status: Accepted
- Date: 2026-08-23
- Phase: Phase 0

## Context

Track definitions must support exact snapping, validation, persistence, later
sharing, and multiple presentation styles. Per-piece closed collision shapes
created internal end faces at connections even when visible geometry appeared
flush. The Phase 0 loop passed topology and seam-tolerance checks after its top
faces were combined into one welded collision surface.

## Decision

Keep reusable track-piece definitions, placed transforms, sockets, connection
roles, geometry recipes, and seam validation independent of SwiftUI and
RealityKit.

Use meters in a right-handed coordinate system with `+Y` up and `+Z` as the
default forward direction. Socket orientations point outward from each piece;
connections require matching categories and complementary entry/exit roles.

Generate RealityKit visual entities from the domain definitions. For a complete
assembled course, generate one top-only static drive mesh and weld coincident
lane-edge vertices within the accepted seam tolerance. RealityKit entities and
meshes are derived output, never the persisted track model.

## Consequences

- Exact snapping, loop traversal, and seam validation remain deterministic and
  testable without RealityKit.
- Final artwork may replace gray-box presentation while preserving the same
  sockets, dimensions, and domain identity.
- Collision generation happens at the assembled-course boundary instead of on
  each visible piece.
- New piece families must provide valid sockets, bounds, drive-surface metadata,
  and collision-compatible geometry under the same coordinate contract.
- Automated geometry checks and physical seam passes remain required whenever
  the authoring contract or collision tessellation changes.

## Alternatives considered

- Persisting RealityKit entities would couple track documents to renderer state
  and make schema evolution and sharing fragile.
- Independent closed collision bodies per piece leave internal seam faces that
  can disturb small dynamic bodies.
- Freeform placement would make validation, deterministic traversal, and later
  replay compatibility substantially harder than socket-first construction.
