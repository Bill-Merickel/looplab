# ADR-0005: Defer simulation-step selection

- Status: Deferred
- Date: 2026-08-26
- Phase: Phase 0

## Context

The Phase 0 harness sanitizes variable frame deltas, substitutes a nominal
`1/90` second when a delta is invalid, and caps long frames at `1/15` second.
That was sufficient to compare both controller prototypes interactively. The
selected constraint-assisted calculator is deterministic for the same state,
input, surface sample, configuration, and time step.

Phase 0 does not yet implement checkpoints, lap timing, replay capture, ghost
playback, or compatibility validation. Without those systems, it cannot
measure whether capped variable steps are reproducible enough or whether a
fixed simulation step is required.

## Deferral

Do not select a production fixed or variable simulation step during Phase 0.
Keep the existing sanitized timing behavior for the technical prototype.

Revisit this decision when Phase 1 introduces lap timing and before committing
to a replay or ghost payload. The decision must precede any leaderboard or
replay-compatibility guarantee.

## Evidence required to decide

- Repeat identical input sequences under stable, jittered, and capped frame
  schedules.
- Measure final pose, velocity, checkpoint order, lap time, and reset divergence.
- Confirm behavior after a dropped or unusually long frame.
- Compare device cost and responsiveness for fixed-step accumulation and capped
  variable-step integration.
- Decide whether replays store inputs, authoritative state samples, or both.

## Consequences

- Phase 0 makes no replay-determinism guarantee.
- The nominal `1/90` fallback and `1/15` cap remain prototype sanitation values,
  not a frozen gameplay-rules contract.
- Vehicle, replay, and race-rule versions must include the eventual timing
  decision before competitive records are considered comparable.
