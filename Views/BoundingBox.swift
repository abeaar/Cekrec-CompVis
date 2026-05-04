import SwiftUI

struct BoundingBoxView: View {
    let subjects: [DetectedSubject]

    private let fillColor   = Color.white.opacity(0.15)
    private let borderColor = Color.white.opacity(0.8)
    private let borderWidth: CGFloat = 1.5

    private let cornerRadius: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            let viewSize = geometry.size

            ForEach(subjects) { subject in
                let screenRect = VisionManager.convertToScreenRect(
                    normalizedRect: subject.normalizedRect,
                    viewSize: viewSize,
                    sourceImageSize: subject.sourceImageSize
                )

                BoundingBoxShape(rect: screenRect, cornerRadius: cornerRadius)
                    .fill(fillColor)
                    .overlay(
                        BoundingBoxShape(rect: screenRect, cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .overlay(
                        // Corner brackets for a professional tracking look.
                        CornerBrackets(rect: screenRect, bracketLength: 16, cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.95), lineWidth: 2)
                    )
                    .transition(.opacity)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.15), value: subjects)
    }
}

struct BoundingBoxShape: Shape {
    let rect: CGRect
    let cornerRadius: CGFloat

    func path(in bounds: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: cornerRadius)
    }
}

struct CornerBrackets: Shape {
    let rect: CGRect
    let bracketLength: CGFloat
    let cornerRadius: CGFloat

    func path(in bounds: CGRect) -> Path {
        var path = Path()

        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY
        let len  = min(bracketLength, rect.width / 3, rect.height / 3)

        // Top-left corner bracket.
        path.move(to: CGPoint(x: minX, y: minY + len))
        path.addLine(to: CGPoint(x: minX, y: minY))
        path.addLine(to: CGPoint(x: minX + len, y: minY))

        // Top-right corner bracket.
        path.move(to: CGPoint(x: maxX - len, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY + len))

        // Bottom-left corner bracket.
        path.move(to: CGPoint(x: minX, y: maxY - len))
        path.addLine(to: CGPoint(x: minX, y: maxY))
        path.addLine(to: CGPoint(x: minX + len, y: maxY))

        // Bottom-right corner bracket.
        path.move(to: CGPoint(x: maxX - len, y: maxY))
        path.addLine(to: CGPoint(x: maxX, y: maxY))
        path.addLine(to: CGPoint(x: maxX, y: maxY - len))

        return path
    }
}


#Preview {
    ZStack {
        Color.black
        BoundingBoxView(subjects: [
            DetectedSubject(
                normalizedRect: CGRect(x: 0.2, y: 0.3, width: 0.3, height: 0.5),
                confidence: 0.95,
                sourceImageSize: CGSize(width: 1080, height: 1920)
            ),
            DetectedSubject(
                normalizedRect: CGRect(x: 0.6, y: 0.4, width: 0.25, height: 0.4),
                confidence: 0.85,
                sourceImageSize: CGSize(width: 1080, height: 1920)
            )
        ])
    }
    .ignoresSafeArea()
}
