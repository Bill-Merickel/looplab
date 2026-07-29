# Phase 0 closed-loop collision verification

## Prototype contract

- The loop is generated deterministically from six placed domain pieces: one
  start/finish piece, one straight, and four left curves.
- All 12 sockets are occupied exactly once by six connections.
- A loop is accepted only when directed entry/exit traversal returns to the
  start/finish piece after visiting every piece once.
- Every seam is checked against the Phase 0 tolerances below before an
  already-positioned piece may close the loop.

| Measurement | Maximum error |
| --- | ---: |
| Centerline position | 0.0001 m |
| Drive-surface height | 0.0001 m |
| Opposed tangent angle | 0.001 rad |
| Matched lane-edge position | 0.0001 m |

RealityKit presentation is generated from this domain assembly. Each track
piece owns one static collision shape derived from its geometry recipe. Each
connection receives one small orange dynamic sphere with continuous collision
detection. These spheres are seam diagnostics only; they are not a vehicle
physics prototype.

## Physical Apple Vision Pro checklist

Run on the recorded visionOS 26.5 device and enter the mixed immersive space.

- [x] The complete six-piece loop appears at a comfortable tabletop scale.
- [x] Six orange probes appear, one immediately before each visible seam.
- [x] Each probe moves across its seam without catching or stopping.
- [x] No probe is launched upward or sideways at a seam.
- [x] No probe tunnels through the drive surface.
- [x] Close and reopen the immersive space three times; the loop and probes
      reset consistently on every entry.
- [x] Record any problematic seam by the adjacent piece names and capture
      video before changing geometry or physics parameters.

The simulator build and automated tests verify topology, geometric tolerances,
collision-component configuration, and probe configuration. Motion quality
across seams remains a physical-device acceptance check.
