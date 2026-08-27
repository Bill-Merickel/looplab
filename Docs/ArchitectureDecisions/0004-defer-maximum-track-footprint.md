# ADR-0004: Defer the maximum track footprint

- Status: Deferred
- Date: 2026-08-26
- Phase: Phase 0

## Context

Phase 0 validated a six-piece gray-box loop at `0.35` tabletop presentation
scale. Physical Apple Vision Pro testing found that loop comfortable during a
ten-minute seated session and confirmed input delivery across its visible
footprint. This proves a useful prototype baseline but does not provide enough
evidence to define the largest track LoopLab should support.

A product limit depends on editor reach, recentering, seated and standing
comfort, piece count, collision complexity, entity and material budgets,
memory, and sustained device frame time. The Phase 0 prototype intentionally
does not contain the complete piece set or arbitrary-size editor needed to
measure those constraints.

## Deferral

Do not set a production maximum track footprint during Phase 0. Retain the
validated `0.35` six-piece loop as a prototype baseline only; it is neither a
minimum nor a maximum product size.

Revisit this decision in Phase 1 before the editor permits unrestricted track
growth or persists a maximum-bounds validation rule. Measure representative
small, typical, and stress-test tracks on physical Apple Vision Pro hardware.

## Evidence required to decide

- Comfortable reach and viewing angles in seated and standing use.
- Recenter and whole-track reposition behavior.
- Readability and manipulation precision at supported presentation scales.
- Sustained frame time, memory, collision cost, and active-entity count.
- A proposed piece-count or bounds limit that produces actionable editor
  validation feedback.

## Consequences

- Phase 1 may continue using the Phase 0 tabletop baseline while the editor is
  built.
- Canonical track geometry remains in meters and independent of presentation
  scale or an eventual footprint limit.
- No persistence schema, validator, or public product promise should encode the
  Phase 0 loop size as the supported maximum.
