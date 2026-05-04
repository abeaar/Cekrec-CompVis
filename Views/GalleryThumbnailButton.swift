//
//  GalleryThumbnailButton.swift
//  Cekrec
//
//  Created by Antigravity on 04/05/26.
//

import SwiftUI

/// A rounded thumbnail button showing the last captured photo,
/// positioned at the bottom-left of the camera interface.
/// Styled with iOS 26 Liquid Glass aesthetic.
struct GalleryThumbnailButton: View {
    let lastImage: UIImage?
    let photoCount: Int
    let action: () -> Void

    @State private var bounceScale: CGFloat = 1.0
    @State private var previousCount: Int = 0

    private let size: CGFloat = 54
    private let cornerRadius: CGFloat = 14

    var body: some View {
        Button(action: action) {
            ZStack {
                if let image = lastImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(.white.opacity(0.5), lineWidth: 1.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: size, height: size)
                        .overlay(
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.5))
                        )
                }

                // Badge count
                if photoCount > 0 {
                    Text("\(photoCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.25))
                        .glassEffect(in: .capsule)
                        .offset(x: size / 2 - 4, y: -size / 2 + 4)
                }
            }
            .scaleEffect(bounceScale)
        }
        .buttonStyle(.plain)
        .onChange(of: photoCount) { oldValue, newValue in
            if newValue > oldValue {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    bounceScale = 1.2
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5).delay(0.15)) {
                    bounceScale = 1.0
                }
            }
            previousCount = newValue
        }
    }
}

#Preview {
    ZStack {
        Color.black
        GalleryThumbnailButton(
            lastImage: nil,
            photoCount: 3,
            action: {}
        )
    }
    .ignoresSafeArea()
}
