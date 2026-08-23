# Phase 0 semantic input and DualSense verification

## Prototype contract

Gameplay reads `SemanticInputState`, not GameController objects. The platform
adapter observes controllers that report the DualSense product category and
maps the extended-gamepad profile as follows:

| DualSense control | Semantic input |
| --- | --- |
| Left stick horizontal axis | Steering |
| R2 | Throttle |
| L2 | Brake/reverse |
| Square | Reset |
| Triangle | Change camera |
| Options | Pause |
| Cross | Confirm |
| Circle | Cancel |

Steering uses a `0.12` axial dead zone. L2 and R2 use a `0.05` dead zone.
Values outside each dead zone are rescaled to preserve the full output range.
Steering is clamped to `-1...1`; triggers are clamped to `0...1`. Nonfinite
values become zero.

The platform adapter consumes buffered snapshots from `GCControllerLiveInput`
so short presses are not lost between display frames. The immersive
`RealityView` requests gamepad delivery, and every collidable track piece is an
indirect input target so looking at the track counts as looking at LoopLab's
game content. A separate invisible trigger surface sits above the complete
rectangular track footprint with a generous margin, including the open center
of the oval. Its placement prevents the track and vehicle from occluding the
game-controller focus region. The surface has no visible model, and its empty
collision filter and lack of a physics body keep it out of physics. The input
session ignores values while disconnected and immediately replaces all analog
and held-button values with the neutral state on disconnect or shutdown. SwiftUI
remains the essential navigation fallback.

## Physical Apple Vision Pro checklist

Device: Apple Vision Pro, visionOS 26.5  

- [x] Pair the DualSense before launching LoopLab; the home window reports it
      as connected without entering the immersive space.
- [x] Launch LoopLab without the controller, enter the immersive space, and
      then connect it; the status changes without restarting the app.
- [x] Look across the straight, curve, and start/finish track pieces and verify
      full input is delivered without targeting or following an orange seam
      probe.
- [x] Sweep gaze throughout the oval's open center, both track halves, and the
      small margin outside the track; verify the event count continues to
      advance across the complete capture footprint.
- [x] In Track Preview, press and release every available DualSense button; the
      persistent event count advances and the last-event label identifies each
      framework-delivered control change.
- [x] Confirm Cross, Circle, Square, Triangle, L1, R1, L2, R2, both sticks,
      and the D-pad reach Track Preview instead of producing gaze/pinch
      interaction while track controller capture is active.
- [x] Look briefly at the LoopLab home window while Track Preview remains open
      and confirm its controller-event routing does not interrupt standard
      gamepad input delivery.
- [x] Move the left stick through its full horizontal range; the displayed
      steering value reaches approximately `-1` and `+1` and rests at zero.
- [x] Pull R2 and L2 independently; throttle and brake/reverse each move from
      zero to approximately one.
- [x] Verify Square, Triangle, Options, Cross, and Circle display Reset,
      Camera, Pause, Confirm, and Cancel respectively.
- [x] Hold the left stick and R2, then disconnect the controller; every
      displayed value returns immediately to neutral.
- [x] Reconnect and confirm input resumes without closing the immersive space
      or restarting LoopLab.
- [x] Repeat connect, disconnect, and reconnect three times without a stuck
      input.
- [x] Confirm the window and immersive-space button remain usable with
      gaze/pinch while the controller is disconnected.
- [x] Record whether visible response latency is acceptable for the upcoming
      vehicle-controller comparison.

Automated tests verify mapping, clamping, dead zones, connection transitions,
and stuck-input prevention. Physical-device delivery, gaze coverage,
reconnection, and perceived-latency results are recorded above.
