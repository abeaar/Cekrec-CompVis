//
//  ZoomControlView.swift
//  Cekrec
//
//  Created by Carolyn Santana on 05/05/26.
//


import SwiftUI

struct ZoomControlView: View {
    @ObservedObject var cameraManager: CameraManager
    
    private let zoomLevels: [CGFloat] = [0.5, 1.0, 2.0]
    
    private let itemWidth: CGFloat = 30
    private let spacing: CGFloat = 8
    
    private func formatZoom(_ zoom: CGFloat) -> String {
        if abs(zoom - round(zoom)) < 0.05 {
            return "\(Int(round(zoom)))×"
        } else {
            return String(format: "%.1f×", zoom)
        }
    }
    
    private func isActive(_ zoom: CGFloat) -> Bool {
        abs(cameraManager.zoomFactor - zoom) < 0.15
    }
    
    private func slotIndex() -> Int {
        zoomLevels.enumerated().min(by: {
            abs($0.element - cameraManager.zoomFactor) <
                abs($1.element - cameraManager.zoomFactor)
        })?.offset ?? 1
    }
    
    var body: some View {
        GeometryReader { geo in
            
            let totalItemWidth = itemWidth + spacing
            let centerIndex = CGFloat(zoomLevels.count - 1) / 2
            
            let offsetX = (centerIndex - CGFloat(slotIndex())) * totalItemWidth
            
            HStack(spacing: spacing) {
                
                ForEach(Array(zoomLevels.enumerated()), id: \.element) { index, zoom in
                    
                    let isCurrentSlot = index == slotIndex()
                    let isSnapped = abs(cameraManager.zoomFactor - zoomLevels[slotIndex()]) < 0.15
                    
                    Text(isCurrentSlot ? formatZoom(cameraManager.zoomFactor) : formatZoom(zoom))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isCurrentSlot && isSnapped ? .yellow : .white)
                        .frame(width: itemWidth, height: itemWidth)
                        .background(
                            Circle()
                                .fill(isCurrentSlot && isSnapped
                                      ? .black.opacity(0.55)
                                      : .black.opacity(0.25))
                        )
                        .scaleEffect(isCurrentSlot && isSnapped ? 1.05 : 1.0)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                cameraManager.setZoom(zoom)
                            }
                            
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                }
            }
            .offset(x: offsetX)
            .frame(width: geo.size.width, alignment: .center)
            .animation(.easeInOut(duration: 0.2), value: cameraManager.zoomFactor)
        }
        .frame(height: 50)
    }
}
