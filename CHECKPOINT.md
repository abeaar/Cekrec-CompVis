# Cekrec — Session Checkpoint

> Rolling snapshot. Overwritten at the end of each session so the next one can
> pick up cold. Distinct from AGENTS.md (build/architecture reference) and
> DEBUG.md (long-term bug backlog).

## Snapshot
- **Branch:** `opt` (tracking `MacAbe/opt`)
- **HEAD:** `468fa0e` "aadd feaeture"
- **Date:** 2026-06-21
- **Working tree:** uncommitted edits in `Views/Screen/ContentView.swift` and
  `Views/Screen/GalleryView.swift`; `DEBUG.md` moved from `Cekrec/` to repo root
  (untracked at new location, deletion staged at old location).

## File map
Files relevant to current/next-session work (i.e. either currently different
from HEAD or direct targets of the next steps).

| File | Status | Notes |
|---|---|---|
| `Cekrec/CekrecApp.swift` | unchanged | `@main` entry. |
| `Models/DetectedSubject.swift` | unchanged | Identifiable rect. |
| `Models/Grid.swift` | unchanged | `GridType` + `.next` cycle. |
| `Models/Image.swift` | unchanged | `IdentifiableImage`. |
| `Models/GalleryState.swift` | empty (1 byte) | P3 #13 delete candidate; real enum in `GalleryViewModel.swift:4`. |
| `ViewModels/CameraManager.swift` | target | P1 #4/#6, P2 #9/#10/#12, P3 #14/#15/#16. |
| `ViewModels/VisionManager.swift` | target | P1 #4 (#22, #33), P1 #8 (#35). |
| `ViewModels/GalleryViewModel.swift` | target | P1 #5 (#19, #87). |
| `ViewModels/PhotoView.swift` | unchanged | `TabView` pager. |
| `ViewModels/ZoomControlView.swift` | target | P1 #6 partner. |
| `Views/Screen/ContentView.swift` | **uncommitted** | P0 #1 partial, P0 #2 fixed. |
| `Views/Screen/GalleryView.swift` | **uncommitted** | P1 #3 target. |
| `Views/Screen/GalleryPageView.swift` | unchanged | Single photo page. |
| `Views/Camera/CameraPreview.swift` | target | P1 #7 partner (#17, `.resizeAspectFill`). |
| `Views/Camera/BoundingBox.swift` | unchanged | Tracking rect + corner brackets. |
| `Views/Camera/GridOverlay.swift` | unchanged | Rule-of-thirds / symmetry overlays. |

## Current focus
Information-gathering pass: mapped the project end-to-end, reviewed `DEBUG.md`,
inspected the uncommitted changes that already tackle two P0 items
(gallery navigation + `@State` managers). **No code edits were performed in
this session.** Plan was agreed with the user; checkpoint written as the
deliverable.

## What we learned / decided
1. **`Models/GalleryState.swift` is empty** (1 byte). The real `GalleryState`
   enum lives at `ViewModels/GalleryViewModel.swift:4`. Treat the file as
   dead. (P3 #13.)
2. **`showGallery` flag is now dead.** Replaced by a `NavigationLink` in the
   uncommitted `ContentView`; remove it for cleanliness once we settle the
   navigation model.
3. **`GalleryView` no longer owns a `NavigationStack`.** It was removed in the
   uncommitted diff and now relies on the parent stack in `ContentView`.
   Toolbar modifiers apply at the call site.
4. **`GalleryView`'s `#Preview` still wraps `ContentView()`** — would
   double-nest stacks in previews. Cosmetic; fix when we touch the file.
5. **`path: NavigationPath` at `ContentView.swift:9` is unused.** Delete or
   wire it up.
6. **"16:9" button at `ContentView.swift:87` is a no-op.** Aspect ratio is an
   unimplemented feature, not a bug.
7. **P0 #1 is only half-done.** The uncommitted `NavigationLink` makes the
   gallery reachable, but P1 #3 (back button) is now strictly a follow-on:
   push vs `fullScreenCover` must be a single deliberate decision.
8. **Vision returns at most 1 subject** (`.prefix(1)` at
   `VisionManager.swift:51`) — matches AGENTS.md spec; no change needed.
9. **Pinch zoom uses `ramp(toVideoZoomFactor:)` per gesture tick**
   (`CameraManager.swift:222`) — known to feel laggy; P2 #10.

## State of the code
Per-file diff summary, in the current uncommitted state (i.e. what is on
disk right now, not what is committed).

### `Views/Screen/ContentView.swift`
- `#5-6` — `cameraManager` and `visionManager` now `@State`. **Fixes P0 #2.**
- `#9` — added `path: NavigationPath` (currently unused).
- `#28` — body wrapped in a new top-level `NavigationStack`.
- `#104-107` — gallery button changed from `Button { showGallery = true }` to
  `NavigationLink { GalleryView() }`. **Partially addresses P0 #1.**
- `#154-156` — commented-out `.fullScreenCover` block still present (dead).
- Re-indentation of the whole `ZStack` body due to the new wrapper.

### `Views/Screen/GalleryView.swift`
- `#8-9` — internal `NavigationStack {` wrapper removed; view body starts
  directly with `ZStack { Color.black … }`. Toolbar modifiers follow.
- Toolbar items unchanged: principal title, trailing `ellipsis`, bottom bar
  share/info/heart/menu/trash buttons (all no-op).
- `.task { await viewModel.load(); await viewModel.loadImage(at: currentIndex) }`
  unchanged.
- `.onChange(of: viewModel.currentIndex)` unchanged.
- `#87` — `#Preview` still wraps `ContentView()` (will double-nest).

### `DEBUG.md` (file move)
- Deleted from `Cekrec/DEBUG.md` (staged in working tree).
- Recreated at repo root `DEBUG.md` (untracked).
- Content unchanged.

## Open questions / blockers
1. **Gallery navigation model** — `NavigationLink` push (current uncommitted)
   vs `fullScreenCover` (DEBUG's original direction). Must be settled
   *before* fixing P1 #3, because the back-button solution depends on it.
2. **Empty `Models/GalleryState.swift`** — delete outright, or keep as a
   placeholder? Delete is cleaner; the enum lives in
   `GalleryViewModel.swift:4` either way.
3. **Unused `path: NavigationPath`** at `ContentView.swift:9` — remove or
   actually use it for a future navigation refactor?

## Next steps
Ordered. Each step lists the file:line to start at.

1. **Decide gallery presentation; complete P0 #1 + P1 #3 together.** Choose
   `NavigationLink` push (keep current uncommitted direction, add a back
   button / `navigationBarBackButtonHidden` strategy) **or** revert to
   `.fullScreenCover` and wire `dismiss`. Start at
   `Views/Screen/ContentView.swift:104` and `Views/Screen/GalleryView.swift:5`.
2. **Fix `VisionManager.isProcessing` race (P1 #4).** Move the gate onto a
   single queue or wrap in an `OSAllocatedUnfairLock` / actor. Start at
   `ViewModels/VisionManager.swift:22` and `:33`.
3. **Fix `GalleryViewModel` permission flow (P1 #5).** Set `.denied` on
   every non-authorized outcome; handle `.limited`; render denied/empty
   states in `GalleryView`. Start at
   `ViewModels/GalleryViewModel.swift:19` and `:87`.
4. **Address 0.5× zoom (P1 #6).** Either switch the input to
   `.builtInUltraWideCamera` (real ultra-wide) or drop the 0.5× slot in
   `ZoomControlView`. Start at `ViewModels/CameraManager.swift:16` and
   `ViewModels/ZoomControlView.swift:6`.
5. **On-device repro of box alignment + Vision orientation (P1 #7, #8).**
   Account for `.resizeAspectFill` crop in `convertToScreenRect`, and
   derive Vision orientation from the video connection rather than
   hardcoding `.up`. Start at
   `Views/Camera/CameraPreview.swift:17`, `ViewModels/VisionManager.swift:35`,
   `ViewModels/VisionManager.swift:74`, and
   `ViewModels/CameraManager.swift:110`.
6. **Session lifecycle (P2 #9).** Stop `AVCaptureSession` on background /
   `.inactive`; observe `AVCaptureSession.interruptionNotification`. Start
   at `ViewModels/CameraManager.swift:62` (add `stopSession` + scene-phase
   wiring in `ContentView`).
7. **P3 cleanup (no device needed).** Delete `Models/GalleryState.swift`,
   remove `capturedPhotos` / `captureImage` orphans, drop unused
   `path: NavigationPath` and `showGallery`. Start at
   `Models/GalleryState.swift:1`, `ViewModels/CameraManager.swift:7,13,169`,
   `Views/Screen/ContentView.swift:8,9,154`.

## How to resume
Read this file, jump to **Next steps §1**, and start at
`Views/Screen/ContentView.swift:104`. Decide push vs `fullScreenCover` first;
that decision unblocks P1 #3.
