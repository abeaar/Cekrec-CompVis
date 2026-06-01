# Cekrec — agent instructions

## Build & run
- Open `Cekrec.xcodeproj` in Xcode — **no other build tool** (no Makefile, no SwiftPM CLI).
- **No test targets**, no linter, no formatter, no CI config.
- Deployment target: **iOS 26.4**. The app only runs on very recent iOS versions.
- Two devices: iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).

## Project layout
```
Cekrec/          → CekrecApp.swift  (entrypoint)
Models/          → DetectedSubject, GridType, IdentifiableImage
ViewModels/      → CameraManager, VisionManager
Views/           → ContentView, CameraPreview, BoundingBox, GridOverlay, Gallery*, ZoomControl, LiquidGlassModifier
```
- Xcode uses **`PBXFileSystemSynchronizedRootGroup`** — files you add/remove on disk are auto-synced to the target; no manual project-editor steps needed.
- No Swift Package dependencies.

## Architecture
- **MVVM** with SwiftUI’s `@Observable` macro (iOS 17+, not `ObservableObject`).
- `CekrecApp` → `ContentView` owns a `CameraManager` and a `VisionManager`, wired together at `.onAppear`.
- `CameraManager` runs `AVCaptureSession` on a private `sessionQueue` — **never touch the session from the main queue**.
- `VisionManager` runs `VNDetectHumanRectanglesRequest` on `visionQueue`; throttled by `isProcessing` guard (drops frames while busy).
- Vision’s normalized rects use a Y-up coordinate system; convert via `VisionManager.convertToScreenRect()`.

## Key conventions & quirks
- **`glassEffect(in:)`** is a built-in SwiftUI API (available on this SDK), not a custom modifier.
- `capturePhoto()` → saves `UIImage` to in-memory `capturedPhotos: [IdentifiableImage]`. Only persists during the session; saved to Photos library via `UIImageWriteToSavedPhotosAlbum` from the gallery view.
- Grid cycles: `.none` → `.ruleOfThirdsWithDiagonals` → `.symmetry`.
- Zoom snaps to `[0.5×, 1.0×, 2.0×]` with limits `[1.0, min(5.0, device max)]`.
- Human detection uses `upperBodyOnly = false`, confidence threshold `> 0.6`, returns at most **1** subject (highest confidence).

## Info.plist (auto-generated)
- `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` required.
- Bundle ID: `abr.Cekrec`, Team: `VMKDVWCB45`.
