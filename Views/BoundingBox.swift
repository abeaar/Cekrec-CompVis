import SwiftUI

struct BoundingBoxView: View {
    // menerima data bounding box
    let subjects: [DetectedSubject]

    private let fillColor   = Color.white.opacity(0.15)
    private let borderColor = Color.white.opacity(0.8)
    private let borderWidth : CGFloat = 1.5

    private let cornerRadius: CGFloat = 8

    var body: some View {
        // GeometryReader digunakan untuk mendapatkan ukuran layar aktual (dalam pixel/points) karena data dari Vision berbentuk persentase (0.0 - 1.0)
        GeometryReader { geometry in
            let viewSize = geometry.size

            ForEach(subjects) { subject in
                // mengubah koordinat vision menjadi koordinat layar
                let screenRect = VisionManager.convertToScreenRect(
                    normalizedRect: subject.normalizedRect,
                    viewSize: viewSize
                )
                
                // menggambar area kotak
                BoundingBoxShape(rect: screenRect, cornerRadius: cornerRadius)
                    .fill(fillColor)
                    // menambahkan border
                    .overlay(
                        BoundingBoxShape(rect: screenRect, cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    // braket
                    .overlay(
                        // Corner brackets for a professional tracking look.
                        CornerBrackets(rect: screenRect, bracketLength: 16, cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.95), lineWidth: 2)
                    )
                    .transition(.opacity)
            }
        }
        // animasi dan transisi
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.15), value: subjects)
    }
}

// shape
struct BoundingBoxShape: Shape {
    let rect: CGRect
    let cornerRadius: CGFloat

    func path(in bounds: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: cornerRadius)
    }
}

// bentuk braket siku-siku "L" di keempat sudut kotak
struct CornerBrackets: Shape {
    let rect: CGRect
    let bracketLength: CGFloat
    let cornerRadius: CGFloat

    func path(in bounds: CGRect) -> Path {
        var path = Path()
        
        // batas koordinat kotak
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY
        let len  = min(bracketLength, rect.width / 3, rect.height / 3)

        // Top-left braket.
        path.move(to: CGPoint(x: minX, y: minY + len))
        path.addLine(to: CGPoint(x: minX, y: minY))
        path.addLine(to: CGPoint(x: minX + len, y: minY))

        // Top-right braket.
        path.move(to: CGPoint(x: maxX - len, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY + len))

        // Braket Bottom-left corner.
        path.move(to: CGPoint(x: minX, y: maxY - len))
        path.addLine(to: CGPoint(x: minX, y: maxY))
        path.addLine(to: CGPoint(x: minX + len, y: maxY))

        // Braket Bottom-right corner.
        path.move(to: CGPoint(x: maxX - len, y: maxY))
        path.addLine(to: CGPoint(x: maxX, y: maxY))
        path.addLine(to: CGPoint(x: maxX, y: maxY - len))

        return path
    }
}

// testing
#Preview {
    ZStack {
        Color.black
        BoundingBoxView(subjects: [
            DetectedSubject(
                normalizedRect: CGRect(x: 0.2, y: 0.3, width: 0.3, height: 0.5),
                confidence: 0.95
            ),
            DetectedSubject(
                normalizedRect: CGRect(x: 0.6, y: 0.4, width: 0.25, height: 0.4),
                confidence: 0.85
            )
        ])
    }
    .ignoresSafeArea()
}
