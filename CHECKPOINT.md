# Cekrec — Session Checkpoint

> Rolling snapshot. Overwritten at the end of each session so the next one
> can pick up cold. Distinct from AGENTS.md (build/architecture reference) and
> DEBUG.md (long-term bug backlog).

## Snapshot
- **Branch:** opt
- **HEAD:** 47c5d31 "add checkpoint"
- **Date:** 2026-06-22
- **Working tree:** uncommitted edits in `Views/Screen/ContentView.swift`,
  `Views/Screen/GalleryView.swift`, `ViewModels/GalleryViewModel.swift`;
  `Models/GalleryState.swift` deleted.

## Current state of code
Per file, in the current working tree. "Original" means matching HEAD
(unchanged from `468fa0e` "aadd feaeture").

### Files in working tree
- `Views/Screen/ContentView.swift` — §1 state: `@State` managers,
  `NavigationStack` wrapper, `NavigationLink` gallery button. `showGallery`
  and `path` removed. `previewHeight` still computed at line 33 (unused).
  No `scenePhase` wiring (§9 reverted).
- `Views/Screen/GalleryView.swift` — §1 + §3 state: no internal
  `NavigationStack` (uses parent stack from `ContentView`), exhaustive
  switch over `GalleryState` with `GalleryDeniedView` / `GalleryEmptyView`,
  `prefetchNeighbors` wired in `onChange`. Preview at the bottom renders
  `GalleryView()` directly.
- `ViewModels/GalleryViewModel.swift` — §3 + P2 #11 state: exhaustive
  permission switch, `permissionMessage`, `isLimited`,
  `prefetchNeighbors(of:)`.
- `ViewModels/VisionManager.swift` — **original pre-§2**. `isProcessing`
  is the unsynchronized `Bool` race (P1 #4) — known limitation; an
  attempted fix was reverted because it changed the logic. (User call:
  leave as-is from the start.)
- `ViewModels/CameraManager.swift` — **original pre-§4, pre-§9,
  pre-batch**. No ultra-wide 0.5× (P1 #6 reverted), no session lifecycle
  (§9 reverted), no batch cleanup (P2 #12, P3 #14/15/16 reverted). Still
  has `captureImage`, `capturedPhotos`, the deprecated
  `isHighResolution*` block, the unsynchronized `flashMode` read in
  `capturePhoto`.
- `Views/Camera/CameraPreview.swift` — original (creates its own preview
  layer; does not depend on `CameraManager.previewLayer`).
- `Views/Camera/BoundingBox.swift` — original (uses
  `convertToScreenRect(normalizedRect:viewSize:)`).
- `Views/Camera/GridOverlay.swift` — original (same).
- `Models/GalleryState.swift` — deleted (P3 #13 done).

## Build status
- **Build:** passes (Xcode 26.5, iPhoneSimulator 26.5 SDK, target
  arm64-apple-ios26.4-simulator).
- **Pre-existing warnings (not blocking):**
  - `MainActor` isolation on `AVCaptureVideoDataOutputSampleBufferDelegate`
    and `AVCapturePhotoCaptureDelegate` (Swift 6 mode warning; not a build
    error today).
  - `previewHeight` unused at `ContentView.swift:33`.
  - `isHighResolutionCaptureEnabled` / `isHighResolutionPhotoEnabled`
    deprecated at `CameraManager.swift:143–144`.

## What was attempted this session but reverted
The following items were implemented, verified by build, and then
reverted at the user's call. They are recorded here so the next session
knows not to re-attempt them without checking first.

| Item | Reason for revert |
|---|---|
| P1 #4 — `VisionManager.isProcessing` race | "should be right that from the start" — the unsynchronized `Bool` is treated as a known limitation, not a bug. |
| P1 #6 — 0.5× ultra-wide input swap | Worked; user preferred to keep the wide-only input. |
| P2 #9 — session lifecycle (`stopSession` / `scenePhase`) | Worked; reverted along with other batch work. |
| P2 #12 — remove deprecated `isHighResolution*` | Worked; reverted along with batch. |
| P3 #14 — remove `capturedPhotos` | Worked; reverted along with batch. |
| P3 #15 — remove `captureImage` | Worked; reverted along with batch. |
| P3 #16 — `flashMode` cross-thread | Worked; reverted along with batch. |
| P1 #7 + #8 — bounding-box alignment + Vision orientation (Strategy 1: preview-layer coordinate space) | "logic now destroyed" — the preview-layer-ownership refactor was rejected. Still open. |

## Known limitations (not bugs we plan to fix; documented as caveats)
- **P1 #4 — `isProcessing` race.** Two queues mutate a non-atomic `Bool`
  (`VisionManager.swift:22–23` on `videoOutputQueue`, `:33` on
  `visionQueue`). In practice doesn't wedge on this device class;
  documented for posterity. Do not "fix" without checking this section
  first — a fix was attempted and reverted.
- **P1 #7 + #8 — bounding-box alignment + Vision orientation.** Preview
  uses `.resizeAspectFill` (crops) but `convertToScreenRect` maps onto
  the full view bounds. Vision orientation hardcoded `.up` while the
  video connection is rotated 90°. A Strategy 1 refactor (promote
  preview layer to `CameraManager`, use `layerRectConverted`) was
  attempted and reverted. Needs a different approach or on-device
  debugging of the actual mis-registration. See DEBUG.md for the
  original symptom list. The unused `previewHeight` at
  `ContentView.swift:33` is the input Strategy 2 (minimal change)
  would consume.

## Next steps
1. (P1 #7 + #8) Decide whether to attempt Strategy 2 (minimal change:
   pass `orientation: .right` to Vision, account for the crop in
   `convertToScreenRect` using the `previewHeight` already computed at
   `ContentView.swift:33`) or leave as-is. The unused `previewHeight`
   is the natural input — the prior attempt rejected Strategy 1, not
   the underlying problem.
2. (P2 #10) Pinch zoom `ramp` per gesture tick — independent, no device
   needed.
3. (Cosmetic) Remove `previewHeight` at `ContentView.swift:33` *only*
   if P1 #7 is officially closed (it isn't, so keep it).

## How to resume
Read this file. The current working tree is fully buildable; all the
session work in §1/§3/P2#11 is preserved. P1 #4, P1 #6, P2 #9, and the
batch cleanup are deliberately not in the tree. P1 #7 + #8 are known
limitations awaiting a different approach.

If you are about to re-attempt any item in the "reverted" table above,
read the Reason column first. If you are about to fix the
`isProcessing` race or the bounding-box alignment, this file's
"Known limitations" section is the source of truth — do not assume the
prior approach is acceptable.
