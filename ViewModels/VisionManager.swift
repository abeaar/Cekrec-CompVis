import Vision
import AVFoundation
import CoreImage
import Observation

<<<<<<< HEAD
// Protokol delegasi untuk menjembatani flow frame dari kamera ke Vision Manager.
protocol CameraFrameDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer)
}

// Vision Manager bertanggung jawab untuk mengelola deteksi subjek menggunakan Vision framework.
final class VisionManager: ObservableObject {
    @Published var detectedSubjects: [DetectedSubject] = []
    // Membuat antrian untuk memproses frame secara asynchronous
=======
@Observable
final class VisionManager {
    var detectedSubjects: [DetectedSubject] = []
>>>>>>> main
    private let visionQueue = DispatchQueue(
        label: "com.cekrec.vision.processing",
        qos: .userInitiated
    )

    private var isProcessing = false
<<<<<<< HEAD
    // VNRequest untuk mendeteksi bounding box human 
    // lazy var di Swift adalah properti yang inisialisasinya ditunda hingga pertama kali diakses, berguna untuk mengoptimalkan performa dan memori
    private lazy var humanDetectionRequest: VNDetectHumanRectanglesRequest = {
=======
    private var humanDetectionRequest: VNDetectHumanRectanglesRequest = {
>>>>>>> main
        let request = VNDetectHumanRectanglesRequest()
        request.upperBodyOnly = false
        return request
    }()

    // Fungsi utama untuk memproses frame dari kamera
    // Mengambil sampleBuffer (frame video) dan menjalankan deteksi manusia
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard !isProcessing else { return }
        isProcessing = true

        // Mengkonversi sampleBuffer ke pixelBuffer 
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessing = false
            return
        }

        // Proses drop frame jika sedang memproses frame lain (FPS bergantung pada hasil pemrosesan)
        visionQueue.async { [weak self] in
            guard let self = self else { return }

            defer { self.isProcessing = false }

            let requestHandler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .up,
                options: [:]
            )

            do {
                try requestHandler.perform([self.humanDetectionRequest])

                // Mengambil hasil deteksi bounding box human
                guard let results = self.humanDetectionRequest.results else {
                    self.publishSubjects([])
                    return
                }
                let subjects = results
                    .filter { $0.confidence > 0.6 } // mengatur confidence threshold
                    .sorted { $0.confidence > $1.confidence }
                    .prefix(1)
                    .map { observation in
                        DetectedSubject(
                            normalizedRect: observation.boundingBox,
                            confidence: observation.confidence
                        )
                    }

                self.publishSubjects(subjects)

            } catch {
                print("[VisionManager] Human detection failed: \(error.localizedDescription)")
                self.publishSubjects([])
            }
        }
    }

    // Mengupdate subject dengan detected bounding box human
    private func publishSubjects(_ subjects: [DetectedSubject]) {
        DispatchQueue.main.async { [weak self] in
            self?.detectedSubjects = subjects
        }
    }

    // Mengkonversi bounding box dari koordinat normalized ke koordinat layar
    static func convertToScreenRect(normalizedRect: CGRect, viewSize: CGSize) -> CGRect {
        // Flip the Y axis: Vision's Y goes up, SwiftUI's Y goes down.
        let screenX = normalizedRect.origin.x * viewSize.width
        let screenY = (1 - normalizedRect.origin.y - normalizedRect.height) * viewSize.height
        let screenWidth = normalizedRect.width * viewSize.width
        let screenHeight = normalizedRect.height * viewSize.height
        
        return CGRect(
            x: screenX,
            y: screenY,
            width: screenWidth,
            height: screenHeight
        )
    }
}
<<<<<<< HEAD

// Mengupdate subject dengan detected bounding box human
extension VisionManager: CameraFrameDelegate {

    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        processFrame(sampleBuffer)
    }
}
=======
>>>>>>> main
