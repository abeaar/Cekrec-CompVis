import Foundation
import CoreGraphics

struct DetectedSubject: Identifiable, Equatable {
    let id: UUID
    let normalizedRect: CGRect
    let confidence: Float
    let sourceImageSize: CGSize

    init(normalizedRect: CGRect, confidence: Float, sourceImageSize: CGSize = .zero) {
        self.id             = UUID()
        self.normalizedRect = normalizedRect
        self.confidence     = confidence
        self.sourceImageSize = sourceImageSize
    }
}
