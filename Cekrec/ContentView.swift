import AVFoundation
import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    
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
                CameraPreview(session : cameraManager.session, cameraManager: cameraManager)
                    .ignoresSafeArea()
            } else {
                VStack {
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
            VStack{
                HStack{
                    Button{
                        cameraManager.toggleFlash()
                    } label: {
                        Image(systemName: flashIcon)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
                Spacer()
                
                Button{
                    cameraManager.capturePhoto()
                } label: {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 70, height: 70)
                        .overlay {
                            Circle()
                                .fill(.white)
                                .frame(width : 60, height: 60)
                        }
                }
                .padding(.bottom,40)    
            }
            .sheet(item: $cameraManager.captureImage){ item in
                
                PhotoPreviewView(item: item, onDismiss: {
                    cameraManager.captureImage = nil
                })
            }
        }
        .onAppear {
            cameraManager.checkAuthorization()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
