# LoopLab

LoopLab is an early-stage spatial racing game for Apple Vision Pro. Players
will build toy-like racetracks from modular pieces, place them in their space,
and race for the best lap time.

## Current prototype

Phase 0 established an offline, gray-box technical foundation with:

- a SwiftUI window that opens a tabletop-scale mixed immersive space;
- renderer-independent track-piece, socket, snapping, assembly, and seam
  models;
- procedural track geometry and a closed six-piece loop with a welded collision
  surface;
- semantic DualSense input with connection and recovery handling;
- a shared vehicle comparison harness with physics-force and
  constraint-assisted controllers; and
- the constraint-assisted controller selected as the Phase 1 vehicle baseline.

The current experience is a prototype, not a complete game. A production track
editor, race rules, lap timing, persistence, final artwork, and online services
remain future work. See [`plan.md`](plan.md) for the product direction and
roadmap, and the [Phase 0 record](Docs/Phase0/README.md) for completed prototype
evidence.

## Requirements

- A Mac with Apple silicon
- Xcode with the visionOS 26.5 SDK
- An Apple Vision Pro running visionOS 26.5 or a matching simulator runtime
- A DualSense controller for physical input verification

The project deployment target is visionOS 26.5.

## Getting started

1. Clone the repository.
2. Open `LoopLab.xcodeproj` in Xcode.
3. Select the `LoopLab` scheme.
4. Choose an Apple Vision Pro simulator or connected device.
5. Build and run with **Product → Run** (`⌘R`).
6. Select **Enter Track Preview** to open the mixed immersive prototype.

## Project structure

```text
LoopLab/
├── LoopLab/
│   ├── App/                         App lifecycle and shared state
│   ├── Domain/                      Renderer-independent gameplay models
│   ├── Features/                    Home, input, track, and vehicle features
│   ├── Platform/                    Apple framework integrations
│   └── Presentation/                RealityKit entities and runtime scenes
├── LoopLabTests/                    Swift Testing test target
├── Docs/
│   ├── ArchitectureDecisions/       Durable architecture decisions
│   └── Phase0/                      Completed plans and verification records
├── Packages/RealityKitContent/      Future authored RealityKit content
├── LoopLab.xcodeproj/               Xcode project
├── AGENTS.md                        Canonical build and test commands
└── plan.md                          Product and development roadmap
```

Phase 0 track and vehicle visuals are generated procedurally. The
`RealityKitContent` package remains available for later authored content.

## Build and test

Run commands from the repository root. The canonical generic-device build and
Apple Vision Pro simulator test commands are maintained in
[`AGENTS.md`](AGENTS.md).

The simulator test command requires the visionOS 26.5 runtime. If its named
destination is unavailable, use the destination-listing command in `AGENTS.md`
to inspect the installed runtimes.

## Documentation

- [Product and development roadmap](plan.md)
- [Phase 0 completion record](Docs/Phase0/README.md)
- [Architecture decision records](Docs/ArchitectureDecisions/README.md)
- [Repository build and test guidance](AGENTS.md)

## Next milestone

Phase 1 turns the technical foundation into a first playable experience. Its
planned scope includes the app shell, core track editor actions, closed-loop
validation, one complete track-piece set, vehicle recovery, checkpoints, lap
timing, results, and local save/load.
