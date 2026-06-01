import Foundation
import SwiftUI

struct GridOverlayView: View {

    let gridType: GridType
    var subjects: [DetectedSubject] = []

    let lineColor   = Color.white.opacity(0.55)
    let lineWidth: CGFloat = 0.8
    let accentColor = Color.white.opacity(0.35)

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                switch gridType {
                case .none:
                    EmptyView()
                case .ruleOfThirdsWithDiagonals:
                    ruleOfThirdsGrid(size: size)
                    powerPoints(size: size)
                case .symmetry:
                    let isSym = isSymmetric(size: size)
                    symmetryGrid(size: size, isSymmetric: isSym)
                    symmetryIndicators(size: size, isSymmetric: isSym)
                }
            }
            .allowsHitTesting(false)
        }
        .transition(.opacity)
    }

    func ruleOfThirdsGrid(size: CGSize) -> some View {
        Path { path in
            let thirdW = size.width / 3
            let thirdH = size.height / 3
            for i in 1...2 {
                let x = thirdW * CGFloat(i)
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for i in 1...2 {
                let y = thirdH * CGFloat(i)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(lineColor, lineWidth: lineWidth)
    }
    
    @ViewBuilder
    func powerPoints(size: CGSize) -> some View {
        let thirdW = size.width / 3
        let thirdH = size.height / 3
        let radius: CGFloat = 4
        ForEach(1...2, id: \.self) { col in
            ForEach(1...2, id: \.self) { row in
                let point = CGPoint(x: thirdW * CGFloat(col), y: thirdH * CGFloat(row))
                let isHit = subjects.contains { subject in
                    let screenRect = VisionManager.convertToScreenRect(
                        normalizedRect: subject.normalizedRect,
                        viewSize: size
                    )
                    return screenRect.contains(point)
                }
                Circle()
                    .fill(isHit ? Color.green : accentColor)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(point)
            }
        }
    }

    @ViewBuilder
    func symmetryGrid(size: CGSize, isSymmetric: Bool) -> some View {
        Path { path in
            let centerX = size.width / 2
            let centerY = size.height / 2
            path.move(to: CGPoint(x: centerX, y: 0))
            path.addLine(to: CGPoint(x: centerX, y: size.height))
            path.move(to: CGPoint(x: 0, y: centerY))
            path.addLine(to: CGPoint(x: size.width, y: centerY))
        }
        .stroke(isSymmetric ? Color.green.opacity(0.8) : lineColor, lineWidth: lineWidth)
    }

    @ViewBuilder
    func symmetryIndicators(size: CGSize, isSymmetric: Bool) -> some View {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let indicatorColor = isSymmetric ? Color.green : lineColor
        let dotColor       = isSymmetric ? Color.green : accentColor

        Circle()
            .stroke(indicatorColor, lineWidth: 0.8)
            .frame(width: 24, height: 24)
            .position(x: centerX, y: centerY)

        Circle()
            .fill(dotColor)
            .frame(width: 6, height: 6)
            .position(x: centerX, y: centerY)

        Path { path in
            let tick: CGFloat = 16
            path.move(to: CGPoint(x: centerX, y: 0));            path.addLine(to: CGPoint(x: centerX, y: tick))
            path.move(to: CGPoint(x: centerX, y: size.height));  path.addLine(to: CGPoint(x: centerX, y: size.height - tick))
            path.move(to: CGPoint(x: 0, y: centerY));            path.addLine(to: CGPoint(x: tick, y: centerY))
            path.move(to: CGPoint(x: size.width, y: centerY));   path.addLine(to: CGPoint(x: size.width - tick, y: centerY))
        }
        .stroke(indicatorColor.opacity(0.7), lineWidth: 1.5)
    }

    func isSymmetric(size: CGSize) -> Bool {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let center  = CGPoint(x: centerX, y: centerY)
        return subjects.contains { subject in
            let rect = VisionManager.convertToScreenRect(
                normalizedRect: subject.normalizedRect,
                viewSize: size
            )
            let isInside  = rect.contains(center)
            let offsetX   = abs(rect.midX - centerX)
            let offsetY   = abs(rect.midY - centerY)
            let isCentered = (offsetX < size.width * 0.1) && (offsetY < size.height * 0.1)
            return isInside || isCentered
        }
    }
}

#Preview {
    ZStack {
        Color.black
        GridOverlayView(gridType: .ruleOfThirdsWithDiagonals)
    }
    .ignoresSafeArea()
}
