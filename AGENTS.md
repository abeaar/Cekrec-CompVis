# Cekrec — agent instructions

## Build & run
- Open `Cekrec.xcodeproj` in Xcode — **no other build tool** (no Makefile, no SwiftPM CLI).
- **No test targets**, no linter, no formatter, no CI config.
- Deployment target: **iOS 26.4**. The app only runs on very recent iOS versions.
- Two devices: iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- Verification: build in Xcode (⌘B). Xcode 26.5 (build 17F42) is what was
  used to verify the current working tree; `xcodebuild` works without
  `xcode-select` changes if invoked via
  `/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild`.

## Project layout
```
Cekrec/           → CekrecApp.swift  (entrypoint)
Models/           → DetectedSubject, GridType, IdentifiableImage
                    (GalleryState.swift has been deleted; the enum lives
                     in GalleryViewModel.swift)
ViewModels/       → CameraManager, VisionManager, GalleryViewModel,
                    PhotoView, ZoomControlView
Views/            → ContentView, CameraPreview, BoundingBox, GridOverlay,
                    GalleryView, GalleryPageView
```
- Xcode uses **`PBXFileSystemSynchronizedRootGroup`** — files you add/remove on disk are auto-synced to the target; no manual project-editor steps needed.
- No Swift Package dependencies.

## Architecture
- **MVVM** with SwiftUI’s `@Observable` macro (iOS 17+, not `ObservableObject`).
- `CekrecApp` → `ContentView` owns a `CameraManager` and a `VisionManager`, wired together at `.onAppear` (both directions: `cameraManager.visionManager = visionManager` and, when applicable, `visionManager.cameraManager = cameraManager`).
- `CameraManager` runs `AVCaptureSession` on a private `sessionQueue` — **never touch the session from the main queue**.
- `VisionManager` runs `VNDetectHumanRectanglesRequest` on `visionQueue`; throttled by `isProcessing` guard (drops frames while busy).
- Vision’s normalized rects use a Y-up coordinate system; convert via `VisionManager.convertToScreenRect()`.

## Key conventions & quirks
- **`glassEffect(in:)`** is a built-in SwiftUI API (available on this SDK), not a custom modifier. There is no `LiquidGlassModifier` — the file in the layout diagram is a historical artifact; ignore it.
- `capturePhoto()` → saves `UIImage` to the system Photos library via `UIImageWriteToSavedPhotosAlbum`. There is also an in-memory `capturedPhotos: [IdentifiableImage]` and a `captureImage: IdentifiableImage?` on `CameraManager`; both are **orphaned** (the gallery reads PhotoKit, not these). See DEBUG.md P3 #14, #15.
- **Gallery navigation:** the gallery is presented via `NavigationLink` push from `ContentView`. The push happens inside a top-level `NavigationStack` declared at `ContentView.swift:28`. `GalleryView` does **not** own its own `NavigationStack` — it relies on the parent for the back gesture and toolbar. Adding a `NavigationStack` inside `GalleryView` will cause double-nested stacks (visible in `#Preview`).
- **Zoom:** `ZoomControlView` advertises `[0.5, 1.0, 2.0]` slots. `0.5×` is a **dead button** — `CameraManager.minZoomFactor = 1.0` and there is no ultra-wide input swap. See DEBUG.md P1 #6 (a fix was attempted and reverted). Treat the 0.5× slot as cosmetic; do not "fix" it without explicit user go-ahead.
- `previewHeight` is computed at `ContentView.swift:33` and **currently unused**. It is the input that DEBUG.md P1 #7 (bounding-box alignment) is supposed to consume; a fix was attempted (Strategy 1) and rejected. Leave the line in place until P1 #7 is resolved — deleting it removes a useful input for the next attempt.
- **Known limitation — `VisionManager.isProcessing` race.** Two queues mutate a non-atomic `Bool` (`VisionManager.swift:22–23` on `videoOutputQueue`, `:33` on `visionQueue`). A fix (replace with `OSAllocatedUnfairLock<Bool>`) was attempted this session and reverted at user call: "should be right that from the start". Do not re-attempt without explicit user go-ahead. See CHECKPOINT.md §"What was attempted this session but reverted" and DEBUG.md #4.
- Grid cycles: `.none` → `.ruleOfThirdsWithDiagonals` → `.symmetry`.
- Zoom device limits: `[1.0, min(5.0, device max)]`. The `0.5×` slot is dead (see above).
- Human detection uses `upperBodyOnly = false`, confidence threshold `> 0.6`, returns at most **1** subject (highest confidence).
- **Build / launch safety:** the current working tree does **not** have session lifecycle handling — `AVCaptureSession` starts in `setupSession` and is never explicitly stopped. The session keeps running while the gallery is on the navigation stack. Acceptable for the current navigation model (consistent with Photos app); a stop-on-background / start-on-foreground fix (DEBUG.md P2 #9) was attempted and reverted.

## Info.plist (auto-generated)
- `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` required.
- Bundle ID: `abr.Cekrec`, Team: `VMKDVWCB45`.

## Related docs
- [CHECKPOINT.md](CHECKPOINT.md) — rolling session snapshot. Overwritten at
  the end of each session; the next session reads this first.
- [DEBUG.md](DEBUG.md) — long-term bug backlog. Checked items are closed
  in the current working tree; unchecked items are still open.
