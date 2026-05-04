import Vision
import AVFoundation
import CoreImage
import Combine


protocol CameraFrameDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer)
}

final class VisionManager: ObservableObject {

    @Published var detectedSubjects: [DetectedSubject] = []

    private let visionQueue = DispatchQueue(
        label: "com.cekrec.vision.processing",
        qos: .userInitiated
    )

    private var isProcessing = false
    private lazy var humanDetectionRequest: VNDetectHumanRectanglesRequest = {
        let request = VNDetectHumanRectanglesRequest()
        // Allow detection of up to 10 humans in a single frame.
        request.upperBodyOnly = false
        return request
    }()

    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard !isProcessing else { return }
        isProcessing = true

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessing = false
            return
        }

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

                // --- Extract results ---
                guard let results = self.humanDetectionRequest.results else {
                    self.publishSubjects([])
                    return
                }

                // --- Convert Vision observations to DetectedSubject models ---
                let subjects = results.compactMap { observation -> DetectedSubject? in
                    // Filter out low-confidence detections to reduce noise.
                    guard observation.confidence > 0.5 else { return nil }
                    return DetectedSubject(
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

    private func publishSubjects(_ subjects: [DetectedSubject]) {
        DispatchQueue.main.async { [weak self] in
            self?.detectedSubjects = subjects
        }
    }

    static func convertToScreenRect(normalizedRect: CGRect, viewSize: CGSize) -> CGRect {
        // Flip the Y axis: Vision's Y goes up, SwiftUI's Y goes down.
        let screenX      = normalizedRect.origin.x                              * viewSize.width
        let screenY      = (1 - normalizedRect.origin.y - normalizedRect.height) * viewSize.height
        let screenWidth  = normalizedRect.width                                 * viewSize.width
        let screenHeight = normalizedRect.height                                * viewSize.height

        return CGRect(x: screenX, y: screenY, width: screenWidth, height: screenHeight)
    }
}

extension VisionManager: CameraFrameDelegate {

    /// Receives raw camera frames from `CameraManager` and forwards them for Vision processing.
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        processFrame(sampleBuffer)
    }
}
