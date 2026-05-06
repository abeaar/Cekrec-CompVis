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
        // Zstack I untuk layering semua UI (camera UI, viewfinder,vision etc)
        ZStack {
            if cameraManager.authorizationStatus == .authorized {
                GeometryReader { geo in
                    let screenWidth = geo.size.width
                    let previewHeight = screenWidth * (16.0 / 9.0)
                    
                    //Zstack II untuk viewfinder dan overlay ke view lain cth, camera preview dan bounding box, vission manager
                    ZStack {
                        CameraPreview(session: cameraManager.session, cameraManager: cameraManager)
                        if !visionManager.detectedSubjects.isEmpty {
                            BoundingBoxView(subjects: visionManager.detectedSubjects)
                        }
                        if selectedGrid != .none {
                            GridOverlayView(
                                gridType: selectedGrid,
                                subjects: visionManager.detectedSubjects
                            )
                        }
                        if cameraManager.showCaptureFlash {
                            Color.white
                                .transition(.opacity)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .ignoresSafeArea()
            } else {
                //UI callback semisal belum authorisasi Camera dari user
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
                // top bar untuk flash dan grid
                HStack {
                    Button {
                        cameraManager.toggleFlash()
                    } label: {
                        Image(systemName: flashIcon)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .glassEffect(in: .circle)
                            .overlay(
                                Circle()
                                    .fill(.black.opacity(0.3))
                            )
                    }
                    
                    Spacer()
                    
                    Button {
                        selectedGrid = selectedGrid.next
                    } label: {
                        Image(systemName: selectedGrid.iconName)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .glassEffect(in: .circle)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                VStack(alignment: .center) {
                    ZoomControlView(cameraManager: cameraManager)
                    
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
                        // Composition Button
                        Button {
                            selectedGrid = selectedGrid.next
                        } label: {
                            Image(systemName: selectedGrid.iconName)
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 45, height: 45)
                                .glassEffect(in: .circle)
                                .overlay(
                                    Circle()
                                        .fill(.black.opacity(0.3))
                                )
                        }
                        .frame(width: 70)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }.frame(maxWidth: .infinity)
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
}

#Preview {
    ContentView()
}
