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

                guard let results = self.humanDetectionRequest.results else {
                    self.publishSubjects([])
                    return
                }
                let subjects = results
                    .filter { $0.confidence > 0.6 }
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

    private func publishSubjects(_ subjects: [DetectedSubject]) {
        DispatchQueue.main.async { [weak self] in
            self?.detectedSubjects = subjects
        }
    }

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

extension VisionManager: CameraFrameDelegate {

    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        processFrame(sampleBuffer)
    }
}
