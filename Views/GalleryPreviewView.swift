//
//  GalleryPreviewView.swift
//  Cekrec
//
//  Created by Antigravity on 04/05/26.
//

import SwiftUI

/// Full-screen immersive photo gallery with iOS 26 Liquid Glass controls.
/// Replaces the old sheet-based PhotoPreviewView.
struct GalleryPreviewView: View {
    @ObservedObject var cameraManager: CameraManager
    @Binding var isPresented: Bool

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showSavedFeedback: Bool = false
    @State private var savedFeedbackText: String = ""
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let photos = cameraManager.capturedPhotos
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            if photos.isEmpty {
                emptyState
            } else {
                // Photo pager
                TabView(selection: $currentIndex) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, item in
                        ZoomablePhotoView(image: item.image)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .offset(y: dragOffset)
                .gesture(dismissDragGesture)
            }

            // Overlays
            VStack {
                topBar(photos: photos)
                Spacer()
                if !photos.isEmpty {
                    bottomBar(photos: photos)
                }
            }
            .offset(y: dragOffset * 0.3)

            // Saved feedback toast
            if showSavedFeedback {
                savedToast
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .statusBarHidden(true)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showSavedFeedback)
        .onChange(of: photos.count) { oldVal, newVal in
            // Adjust index if photo was deleted
            if newVal > 0 && currentIndex >= newVal {
                withAnimation { currentIndex = newVal - 1 }
            }
        }
    }

    // MARK: - Top Bar

    private func topBar(photos: [IdentifiableImage]) -> some View {
        HStack {
            // Close button
            GlassIconButton(icon: "xmark") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }

            Spacer()

            // Photo counter
            if !photos.isEmpty {
                Text("\(currentIndex + 1) of \(photos.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .glassEffect(in: .capsule)
            }

            Spacer()

            // Share button
            if !photos.isEmpty {
                ShareLink(item: Image(uiImage: photos[safe: currentIndex]?.image ?? UIImage()),
                          preview: SharePreview("Photo", image: Image(uiImage: photos[safe: currentIndex]?.image ?? UIImage()))) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .glassEffect(in: .circle)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Bottom Bar

    private func bottomBar(photos: [IdentifiableImage]) -> some View {
        HStack(spacing: 32) {
            // Delete / Retake
            LiquidGlassButton(icon: "trash", label: "Delete", role: .destructive) {
                deleteCurrentPhoto(photos: photos)
            }

            // Save current
            LiquidGlassButton(icon: "arrow.down.to.line", label: "Save") {
                saveCurrentPhoto(photos: photos)
            }

            // Save all
            if photos.count > 1 {
                LiquidGlassButton(icon: "arrow.down.doc", label: "Save All") {
                    saveAllPhotos(photos: photos)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .glassEffect(in: .capsule)
        .padding(.bottom, 30)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.white.opacity(0.4))
            Text("No photos yet")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))
            Text("Take a photo to see it here")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    // MARK: - Saved Toast

    private var savedToast: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(savedFeedbackText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(in: .capsule)
            .padding(.top, 60)

            Spacer()
        }
    }

    // MARK: - Gestures

    private var dismissDragGesture: some Gesture {
        DragGesture(minimumDistance: 40)
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > 150 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Actions

    private func deleteCurrentPhoto(photos: [IdentifiableImage]) {
        guard photos.indices.contains(currentIndex) else { return }

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            cameraManager.capturedPhotos.remove(at: currentIndex)
            if cameraManager.capturedPhotos.isEmpty {
                isPresented = false
            }
        }
    }

    private func saveCurrentPhoto(photos: [IdentifiableImage]) {
        guard photos.indices.contains(currentIndex) else { return }
        let image = photos[currentIndex].image

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        let notifFeedback = UINotificationFeedbackGenerator()
        notifFeedback.notificationOccurred(.success)

        showFeedback("Saved to Photos")
    }

    private func saveAllPhotos(photos: [IdentifiableImage]) {
        for photo in photos {
            UIImageWriteToSavedPhotosAlbum(photo.image, nil, nil, nil)
        }

        let notifFeedback = UINotificationFeedbackGenerator()
        notifFeedback.notificationOccurred(.success)

        showFeedback("All \(photos.count) photos saved")
    }

    private func showFeedback(_ message: String) {
        savedFeedbackText = message
        withAnimation { showSavedFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSavedFeedback = false }
        }
    }
}

// MARK: - Zoomable Photo View

/// Individual photo page with pinch-to-zoom support.
struct ZoomablePhotoView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let newScale = lastScale * value.magnification
                        scale = max(1.0, min(newScale, 5.0))
                    }
                    .onEnded { _ in
                        lastScale = scale
                        if scale <= 1.0 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                    }
            )
            .simultaneousGesture(
                scale > 1.0
                ? DragGesture()
                    .onChanged { value in
                        offset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
                : nil
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if scale > 1.0 {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        scale = 2.5
                        lastScale = 2.5
                    }
                }
            }
    }
}

// MARK: - Safe Array Access

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
