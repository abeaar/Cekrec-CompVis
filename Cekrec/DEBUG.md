# Cekrec — Debug & Triage Backlog

> Working doc for debugging Cekrec. Written for an agent picking this up cold —
> see [AGENTS.md](AGENTS.md) for build/run and architecture conventions first.
> Line references were accurate as of branch `opt`; re-verify before editing.

## Project in one paragraph
Cekrec is a SwiftUI composition-assistant camera (iOS 26.4, iPhone + iPad).
A single `AVCaptureSession` feeds **two** outputs: `AVCapturePhotoOutput` (stills)
and `AVCaptureVideoDataOutput` (per-frame **Vision** human detection). Detected
subjects drive a tracking bounding box + composition grids (rule-of-thirds /
symmetry) over the live viewfinder. Captured photos are written to the system
Photos library; a separate gallery reads them back via PhotoKit. MVVM with the
`@Observable` macro. AVFoundation runs on a private `sessionQueue`; Vision on its
own `visionQueue`.

### Component map
| Concern | File |
|---|---|
| App entry | [Cekrec/CekrecApp.swift](Cekrec/CekrecApp.swift) |
| Main screen + wiring | [Views/Screen/ContentView.swift](Views/Screen/ContentView.swift) |
| Camera + capture | [ViewModels/CameraManager.swift](ViewModels/CameraManager.swift) |
| Vision detection | [ViewModels/VisionManager.swift](ViewModels/VisionManager.swift) |
| Preview bridge | [Views/Camera/CameraPreview.swift](Views/Camera/CameraPreview.swift) |
| Overlays | [Views/Camera/BoundingBox.swift](Views/Camera/BoundingBox.swift), [Views/Camera/GridOverlay.swift](Views/Camera/GridOverlay.swift) |
| Zoom UI | [ViewModels/ZoomControlView.swift](ViewModels/ZoomControlView.swift) |
| Gallery | [Views/Screen/GalleryView.swift](Views/Screen/GalleryView.swift), [Views/Screen/GalleryPageView.swift](Views/Screen/GalleryPageView.swift), [ViewModels/PhotoView.swift](ViewModels/PhotoView.swift), [ViewModels/GalleryViewModel.swift](ViewModels/GalleryViewModel.swift) |
| Models | [Models/DetectedSubject.swift](Models/DetectedSubject.swift), [Models/Grid.swift](Models/Grid.swift), [Models/Image.swift](Models/Image.swift) |

### Reference
Patterns cross-checked against Apple's AVCam sample:
https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app
(Note: the JSON API `…/avcam-building-a-camera-app.json` returns the real content;
the HTML page is JS-rendered and fetches empty.)

---

## How to verify
- **No test target, no linter, no CI** (see AGENTS.md). Verification = build in
  Xcode + run on a **real device** (Simulator has no camera/Vision frames).
- For each fix below, the "Verify" line says what to observe on device.

---

## P0 — Broken right now (blocks core flow)

### [ ] 1. Gallery is unreachable
- **Where:** gallery button sets `showGallery = true` at
  [ContentView.swift:102](Views/Screen/ContentView.swift:102), but the
  `.fullScreenCover` presenting `GalleryView` is commented out at
  [ContentView.swift:148-150](Views/Screen/ContentView.swift:148).
- **Effect:** tapping the gallery does nothing; all of `GalleryView` /
  `GalleryViewModel` / `PhotoView` is unreachable.
- **Fix direction:** restore a presentation (`.fullScreenCover` or
  `NavigationStack` push) for `GalleryView`. Decide the navigation model now,
  because it interacts with bug #3.
- **Verify:** tap gallery → gallery opens.

### [ ] 2. View-owned managers aren't `@State`
- **Where:** [ContentView.swift:5-6](Views/Screen/ContentView.swift:5)
  (`private var cameraManager = CameraManager()` / `visionManager`).
- **Effect:** with `@Observable`, plain `var` reference types can be
  re-instantiated on view re-render, tearing down and rebuilding the
  `AVCaptureSession`. Suspected root cause of flicker / state loss.
- **Fix direction:** `@State private var cameraManager = …` / `visionManager`.
  Keep the `.onAppear` wiring (`cameraManager.visionManager = visionManager`).
- **Verify:** session is created once; preview stays stable across UI changes.

---

## P1 — Real bugs, fix next (confirmed in code)

### [ ] 3. Back-button bug (known — see commit `bug from back button still exist`)
- **Where:** `GalleryView` declares `@Environment(\.dismiss)` at
  [GalleryView.swift:5](Views/Screen/GalleryView.swift:5) but never calls it and
  wires no back button. If presented via `fullScreenCover`, the inner
  `NavigationStack` back gesture won't dismiss the cover.
- **Fix direction:** depends on #1's navigation choice. Add an explicit
  dismiss/back control that matches the presentation style.
- **Verify:** open gallery → back → returns to camera cleanly, session still live.

### [ ] 4. `VisionManager.isProcessing` data race
- **Where:** checked+set on the camera's `videoOutputQueue` at
  [VisionManager.swift:22-23](ViewModels/VisionManager.swift:22); reset on
  `visionQueue` via `defer` at
  [VisionManager.swift:33](ViewModels/VisionManager.swift:33).
- **Effect:** two queues mutate a non-atomic `Bool` with no synchronization —
  can wedge (frames stop) or overlap.
- **Fix direction:** guard `isProcessing` behind a lock, make it atomic, or move
  the whole gate onto one queue / an actor (AVCam uses an actor for this reason).
- **Verify:** detection keeps running indefinitely; no stalls under fast motion.

### [ ] 5. Gallery permission flow can hang on "loading" forever
- **Where:** [GalleryViewModel.swift:19-32](ViewModels/GalleryViewModel.swift:19).
  The `.notDetermined` branch only sets state on success — a denial leaves
  `state == .loading`. `.limited` falls into `default → .denied`, hiding photos
  the user *did* grant.
- **Also:** `GalleryView` never renders `.denied`/empty (the `isDenied` helper at
  [GalleryViewModel.swift:87](ViewModels/GalleryViewModel.swift:87) is unused) →
  silent black screen.
- **Fix direction:** set `.denied` on every non-authorized outcome; handle
  `.limited`; render denied/empty states in `GalleryView`.
- **Verify:** deny permission → see a denied message, not a black screen / spinner.

### [ ] 6. 0.5× zoom is a dead button
- **Where:** `ZoomControlView` offers `[0.5, 1.0, 2.0]` at
  [ZoomControlView.swift:6](ViewModels/ZoomControlView.swift:6), but `zoom()`
  clamps to `minZoomFactor = 1.0`
  ([CameraManager.swift:16](ViewModels/CameraManager.swift:16),
  [CameraManager.swift:218-221](ViewModels/CameraManager.swift:218)).
- **Effect:** tapping 0.5× does nothing.
- **Fix direction:** true 0.5× requires switching the input to
  `.builtInUltraWideCamera` (not just a zoom factor); or remove the 0.5× slot if
  ultra-wide is out of scope.
- **Verify:** 0.5× visibly widens FOV (or the slot is gone).

---

## P1 — Needs on-device repro (behavioral, high suspicion)

### [ ] 7. Bounding boxes likely misaligned with subject
- **Where:** preview uses `.resizeAspectFill` (crops) at
  [CameraPreview.swift:17](Views/Camera/CameraPreview.swift:17), but
  `convertToScreenRect` maps the normalized rect linearly onto the *full* view
  bounds at [VisionManager.swift:74-87](ViewModels/VisionManager.swift:74).
  Cropped preview + un-cropped mapping ⇒ offset boxes. Hint: `previewHeight` is
  computed but unused at
  [ContentView.swift:30](Views/Screen/ContentView.swift:30).
- **Fix direction:** account for the aspectFill crop when mapping normalized →
  screen coords (or render the box in the preview layer's coordinate space via
  `AVCaptureVideoPreviewLayer.layerRectConverted(fromMetadataOutputRect:)`).
- **Verify:** box tracks tightly around a person across the frame edges.

### [ ] 8. Vision orientation hardcoded `.up`
- **Where:** video connection rotated 90° at
  [CameraManager.swift:110-120](ViewModels/CameraManager.swift:110); Vision runs
  with `orientation: .up` at
  [VisionManager.swift:35-39](ViewModels/VisionManager.swift:35).
- **Effect:** if these disagree, detections come back rotated/misplaced.
- **Fix direction:** make the Vision orientation consistent with the buffer
  rotation (derive from device/connection rather than hardcoding).
- **Verify:** portrait detection lands on the actual person.

> #7 and #8 interact — verify them together on device with one person in frame.

---

## P2 — Should fix

### [ ] 9. Session never stops / no lifecycle handling
- `startRunning()` is called but there's no `stopRunning()` and no scene-phase or
  `AVCaptureSession` interruption handling anywhere in
  [CameraManager.swift](ViewModels/CameraManager.swift).
- **Effect:** battery drain; no clean resume after backgrounding / phone call.
- **Fix direction:** stop on background / `.inactive`, restart on foreground;
  observe interruption notifications.

### [ ] 10. Pinch zoom uses `ramp(toVideoZoomFactor:)` per gesture tick
- **Where:** [CameraManager.swift:222-225](ViewModels/CameraManager.swift:222),
  driven by `MagnifyGesture.updating` at
  [ContentView.swift:36-42](Views/Screen/ContentView.swift:36).
- **Effect:** ramp is for animated transitions, not continuous live pinch — feels
  jumpy/laggy.
- **Fix direction:** set `device.videoZoomFactor` directly during pinch; reserve
  `ramp` for tap-to-zoom presets.

### [ ] 11. Gallery black-flash on swipe
- `loadImage` fetches only the current index
  ([GalleryView.swift:80-83](Views/Screen/GalleryView.swift:80)); neighbors
  aren't prefetched, so each swipe shows black until load.
- **Fix direction:** prefetch ±1 (or more) around `currentIndex`.

### [ ] 12. Deprecated photo-resolution API (likely a no-op)
- `isHighResolutionCaptureEnabled` / `isHighResolutionPhotoEnabled` at
  [CameraManager.swift:143-145](ViewModels/CameraManager.swift:143) are
  deprecated (iOS 16+); the guard is almost certainly always false.
- **Fix direction:** use `maxPhotoDimensions` on the photo output + settings.

---

## P3 — Cleanup (not bugs, reduce noise)

- [ ] **13.** [Models/GalleryState.swift](Models/GalleryState.swift) is empty —
  the `GalleryState` enum actually lives in
  [GalleryViewModel.swift:4-6](ViewModels/GalleryViewModel.swift:4). Delete the
  empty file or move the enum into it.
- [ ] **14.** `capturedPhotos` is orphaned — the gallery reads PhotoKit, never
  this array ([CameraManager.swift:13](ViewModels/CameraManager.swift:13)).
  Delete it, or use it to seed the gallery.
- [ ] **15.** `captureImage` is set but never read
  ([CameraManager.swift:7](ViewModels/CameraManager.swift:7),
  [CameraManager.swift:169](ViewModels/CameraManager.swift:169)).
- [ ] **16.** `flashMode` is written on main (`toggleFlash`) and read on
  `sessionQueue` (`capturePhoto`) — minor cross-thread access, low impact.

---

## Recommended order
1. **#2 (`@State`)** and **#1 (present the gallery)** — small, unblock everything
   and likely make #3 reproducible.
2. **#3 (back button)**, **#4 (Vision race)**, **#5 (permission hang)** — clear
   logic/concurrency bugs.
3. **#7 / #8 (box alignment + orientation)** — needs a device build; verify the
   pair together.
4. P2 / P3 as capacity allows.

## Notes for the next agent
- Build only via Xcode (`Cekrec.xcodeproj`); no CLI build/test exists.
- AVFoundation must stay off the main queue — use `sessionQueue` (see AGENTS.md).
- Check the `[ ]` boxes and append findings under each item as you go.
