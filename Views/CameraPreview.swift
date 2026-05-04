import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
        
        context.coordinator.cameraManager = cameraManager
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var lastZoomFactor: CGFloat = 1.0
        var cameraManager:CameraManager?
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer){
            guard let manager = cameraManager else {return}
            
            switch gesture.state{
            case .began:
                lastZoomFactor = manager.zoomFactor
                
            case .changed:
                let newZoom = lastZoomFactor * gesture.scale
                manager.zoom(factor:newZoom)
            default: break
            }
        }
    }
}
