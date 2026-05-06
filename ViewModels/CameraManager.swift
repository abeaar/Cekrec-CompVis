import AVFoundation
import SwiftUI
import Observation

@Observable
class CameraManager : NSObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{
    var captureImage : IdentifiableImage?
    var isSessionRunning = false
    var authorizationStatus: AVAuthorizationStatus = .notDetermined
    var flashMode: AVCaptureDevice.FlashMode = .off
    var zoomFactor: CGFloat = 1.0
    
    // Gallery state
    var capturedPhotos: [IdentifiableImage] = []
    var lastCapturedImage: UIImage?
    var showCaptureFlash: Bool = false
    private let minZoomFactor: CGFloat = 1.0
    private let maxZoomFactor: CGFloat = 5.0
    
    weak var frameDelegate: CameraFrameDelegate?
    // main capture session handle
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var isSessionConfigured = false

    
    private let sessionQueue = DispatchQueue(label: "com.customcamera.sessionQueue")
    private let videoOutputQueue = DispatchQueue(label: "com.customcamera.videoOutputQueue", qos: .userInitiated)
    
    override init() {
        super.init()
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.authorizationStatus = .authorized
            }
            self.setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                }
                if granted {
                    self?.setupSession()
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.authorizationStatus = .denied
            }
        @unknown default:
            DispatchQueue.main.async {
                self.authorizationStatus = .denied
            }
        }
    }

    private func setupSession() {
        // setup capture session 
        sessionQueue.async { [weak self] in
        // maksa setup code untuk berjalan di background thread berbeda (sessionQueue) biar gak ganggu UI
            guard let self = self else { return }
            // if session sudah berjalan maka tidak perlu setup lagi
            if self.isSessionConfigured {
                if !self.session.isRunning {
                    self.session.startRunning()
                    DispatchQueue.main.async {
                        self.isSessionRunning = self.session.isRunning
                    }
                }
                return
            }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            // ambil device camera belakang sebagai input
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),

            let input = try? AVCaptureDeviceInput(device: camera) else {
                print("failed to access camera")
                self.session.commitConfiguration()
                return
            }
            // input dioper ke if else dibawah
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.currentInput = input
            }
            
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.maxPhotoQualityPrioritization = .quality
            }
            
            // ini buat video output ke Vision manager, Input video diambil dari output photo
            if self.session.canAddOutput(self.videoOutput) {
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                // maksa frame camera dari output diubah jadi color format 32BGRA untuk vision manager
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
                self.session.addOutput(self.videoOutput)
                
                if let connection = self.videoOutput.connection(with: .video) {
                    if #available(iOS 17.0, *) {
                        if connection.isVideoRotationAngleSupported(90) {
                            connection.videoRotationAngle = 90
                        }
                    } else {
                        if connection.isVideoOrientationSupported {
                            connection.videoOrientation = .portrait
                        }
                    }
                }
            }
            
            self.session.commitConfiguration()
            self.isSessionConfigured = true
            self.session.startRunning()
            
            // update UI state 
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    
    func capturePhoto() {
        // maksa setup code untuk berjalan di background thread berbeda (sessionQueue) biar gak ganggu UI
        sessionQueue.async {
            [weak self] in
            // if session sudah berjalan maka tidak perlu setup lagi
            guard let self = self else {return}
            let settings = AVCapturePhotoSettings()
            settings.flashMode = self.flashMode
            if self.photoOutput.isHighResolutionCaptureEnabled {
                settings.isHighResolutionPhotoEnabled = true
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("photo capture error \(error.localizedDescription)")
            return
        }
        //extract image data
        guard let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData) else {
            print ("failed to convert photo to image")
            return
        }
        //update UI on main thread
        DispatchQueue.main.async{
            [weak self] in
            guard let self = self else { return }
            
            let identifiable = IdentifiableImage(image: uiImage)
            self.captureImage = identifiable
            self.lastCapturedImage = uiImage
            self.capturedPhotos.insert(identifiable, at: 0)
            
            // Trigger flash animation
            self.showCaptureFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.showCaptureFlash = false
            }
        }
    }
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        autoreleasepool {
            frameDelegate?.cameraManager(self, didOutput: sampleBuffer)
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

    }

    func toggleFlash(){
        flashMode = switch flashMode {
        case .off:
                .on
        case .on:
                .auto
        case .auto:
                .off
        @unknown default:
                .off
        }
    }
    func zoom(factor: CGFloat) {
        sessionQueue.async {
            [weak self] in
            guard let self = self,
                  let device = self.currentInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                let clamped = max(
                    self.minZoomFactor,
                    min(factor, min(self.maxZoomFactor, device.activeFormat.videoMaxZoomFactor))
                )
                
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.25)
                device.ramp(toVideoZoomFactor: clamped, withRate: 5.0)
                CATransaction.commit()
                
                DispatchQueue.main.async {
                    self.zoomFactor = clamped
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Zoom error \(error.localizedDescription)")
            }
        }
    }
    func setZoom(_ factor: CGFloat) {
         zoom(factor: factor)
     }
}

