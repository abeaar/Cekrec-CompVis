
import AVFoundation
import SwiftUI
import Combine

class CameraManager : NSObject, ObservableObject, AVCapturePhotoCaptureDelegate  {
  @Published var captureImage : IdentifiableImage?
  @Published var isSessionRunning = false
  @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
  @Published var flashMode: AVCaptureDevice.FlashMode = .off
  @Published var zoomFactor: CGFloat = 1.0
  
  // Gallery state
  @Published var capturedPhotos: [IdentifiableImage] = []
  @Published var lastCapturedImage: UIImage?
  @Published var showCaptureFlash: Bool = false
  private let minZoomFactor: CGFloat = 1.0
  private let maxZoomFactor: CGFloat = 5.0
  
  weak var frameDelegate: CameraFrameDelegate?
  
  let session = AVCaptureSession()
  private let photoOutput = AVCapturePhotoOutput()
  private let videoOutput = AVCaptureVideoDataOutput()
  private var currentInput: AVCaptureDeviceInput?
  private var isSessionConfigured = false
  
  
  private let sessionQueue = DispatchQueue(label: "com.customcamera.sessionQueue")
  
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
      sessionQueue.async { [weak self] in
          guard let self = self else { return }
          
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
          
          guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back), let input = try? AVCaptureDeviceInput(device: camera) else {
              print("failed to access camera")
              self.session.commitConfiguration()
              return
          }
          
          if self.session.canAddInput(input) {
              self.session.addInput(input)
              self.currentInput = input
          }
          
          if self.session.canAddOutput(self.photoOutput) {
              self.session.addOutput(self.photoOutput)
              self.photoOutput.maxPhotoQualityPrioritization = .quality
          }
          
          if self.session.canAddOutput(self.videoOutput) {
              self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
              self.videoOutput.alwaysDiscardsLateVideoFrames = true
              self.session.addOutput(self.videoOutput)
          }
          
          self.session.commitConfiguration()
          self.isSessionConfigured = true
          self.session.startRunning()
          
          DispatchQueue.main.async {
              self.isSessionRunning = self.session.isRunning
          }
      }
  }
  
  func capturePhoto() {
      sessionQueue.async {
          [weak self] in
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


struct IdentifiableImage: Identifiable {
  let id = UUID()
  let image:UIImage
}
