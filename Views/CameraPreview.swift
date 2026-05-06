import SwiftUI
import AVFoundation

//karena Swift ui gak punya function khusus camera maka perlu protokol UIViewRepresentable buat mengkoneksikan antara UIViewCamera dan SwiftUI
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let cameraManager: CameraManager



    func makeUIView(context: Context) -> UIView {
        //UIView() buat View layar kamera utama yng brisi frame kosong
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        // buat preview layer dari session camera
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    // updateuiview ini akan di panggil setiap ada perubahan data di swift ui yang mempengarui uiView, otomatis frame layer pun berubah maka otomatis frame layer pun berubah
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            // Cari previewLayer langsung di dalam uiView karena coordinator sudah dihapus
            if let layer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) {
                layer.frame = uiView.bounds
            }
        }
    }
    
}
