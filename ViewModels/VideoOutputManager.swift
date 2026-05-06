import AVFoundation

extension CameraManager {
    // Menambahkan video data output untuk memproses frame dari kamera
    func addVideoDataOutput() {
        let videoOutput = AVCaptureVideoDataOutput()
        // membuang frame yang terlambat
        videoOutput.alwaysDiscardsLateVideoFrames = true

        // format pixel
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        // queue untuk memproses frame
        let frameQueue = DispatchQueue(
            label: "com.cekrec.camera.videoOutput",
            qos: .userInitiated
        )
        videoOutput.setSampleBufferDelegate(self, queue: frameQueue)

        // menambahkan video output ke session
        guard session.canAddOutput(videoOutput) else {
            print("[VideoOutputManager] Cannot add video data output.")
            return
        }
        session.addOutput(videoOutput)

        // mengatur rotasi video output
        if let connection = videoOutput.connection(with: .video) {
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
}

// Delegate untuk memproses frame dari video output
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    // mengambil frame
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        autoreleasepool {
            frameDelegate?.cameraManager(self, didOutput: sampleBuffer)
        }
    }

    // ketika frame di-drop
    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

    }
}