import AVFoundation
import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var visionManager = VisionManager()
    @State private var selectedGrid: GridType = .none
    @State private var showGallery: Bool = false

    private var flashIcon: String {
        switch cameraManager.flashMode {
        case .off:
            return "bolt.slash.fill"
        case .on:
            return "bolt.fill"
        case .auto:
            return "bolt.badge.automatic.fill"
        @unknown default:return "bolt.slash.fill"
        }
    }

    var body: some View {
        ZStack {
            if cameraManager.authorizationStatus == .authorized {
                ZStack {
                    CameraPreview(session: cameraManager.session, cameraManager: cameraManager)

                    if selectedGrid != .none {
                        GridOverlayView(
                            gridType: selectedGrid,
                            subjects: visionManager.detectedSubjects
                        )
                    }

                    if !visionManager.detectedSubjects.isEmpty {
                        BoundingBoxView(subjects: visionManager.detectedSubjects)
                    }

                    // Capture flash animation
                    if cameraManager.showCaptureFlash {
                        Color.white
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .allowsHitTesting(false)
                    }
                }
                .ignoresSafeArea()
            } else {
                VStack {
                    Text("apapun itu yabng bisa ditulis langsung")
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                    Text("camera access required")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                    if cameraManager.authorizationStatus ==
                        .denied{
                        Text("please enable camera in settings")
                        Button("open Settings"){
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString){
                                UIApplication.shared.open(settingsURL)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            // Camera controls overlay
            VStack {
                // Top bar: Flash + Grid
                HStack {
                    Button {
                        cameraManager.toggleFlash()
                    } label: {
                        Image(systemName: flashIcon)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .glassEffect(in: .circle)
                    }

                    Spacer()

                    Button {
                        selectedGrid = selectedGrid.next
                    } label: {
                        Image(systemName: selectedGrid.iconName)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .glassEffect(in: .circle)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // Bottom bar: Thumbnail | Shutter | (placeholder for flip)
                HStack(alignment: .center) {
                    // Gallery thumbnail
                    GalleryThumbnailButton(
                        lastImage: cameraManager.lastCapturedImage,
                        photoCount: cameraManager.capturedPhotos.count,
                        action: {
                            if !cameraManager.capturedPhotos.isEmpty {
                                showGallery = true
                            }
                        }
                    )
                    .frame(width: 70, alignment: .center)

                    Spacer()

                    // Shutter button
                    Button {
                        cameraManager.capturePhoto()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.15))
                                .frame(width: 78, height: 78)
                                .glassEffect(in: .circle)

                            Circle()
                                .fill(.white)
                                .frame(width: 62, height: 62)
                        }
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: cameraManager.capturedPhotos.count)

                    Spacer()

                    // Spacer for symmetry (future: camera flip button)
                    Color.clear
                        .frame(width: 70, height: 54)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }

            // Full-screen gallery
            .fullScreenCover(isPresented: $showGallery) {
                GalleryPreviewView(
                    cameraManager: cameraManager,
                    isPresented: $showGallery
                )
            }
        }
        .onAppear {
            cameraManager.frameDelegate = visionManager
            cameraManager.checkAuthorization()
        }
        .animation(.easeInOut(duration: 0.12), value: cameraManager.showCaptureFlash)
    }
}

#Preview {
    ContentView()
}
