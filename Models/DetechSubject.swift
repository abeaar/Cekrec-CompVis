import Foundation

struct DetectedSubject: Identifiable, Equatable {
    let id: UUID
    let normalizedRect: CGRect
    let confidence: Float
    init(normalizedRect: CGRect, confidence: Float) {
        self.id             = UUID()
        self.normalizedRect = normalizedRect
        self.confidence     = confidence
    }
}
