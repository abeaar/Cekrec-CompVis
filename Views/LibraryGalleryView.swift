import SwiftUI
import Photos

struct LibraryGalleryView: View {
    @State private var viewModel = GalleryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // ZStack: Handles depth
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.assets.enumerated()), id: \.offset) { index, asset in
                    GalleryPageView(image: viewModel.fullImages[asset.localIdentifier])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .task(id: viewModel.currentIndex) {
                guard viewModel.assets.indices.contains(viewModel.currentIndex) else { return }
                await viewModel.loadImage(for: viewModel.assets[viewModel.currentIndex])
            }

            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .frame(width: 44, height: 44)
                            .font(.title2.weight(.medium))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                    .glassEffect(.regular.interactive(), in: Circle())

                    Spacer()

                    VStack(spacing: 2) {
                        Text(viewModel.headerTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 30)
                        Text(viewModel.headerSubtitle)
                            .font(.caption)
                            .foregroundStyle(.white.secondary)
                    }
                    .frame(width: 200, height: 44)
                    .glassEffect(.regular.interactive(), in: Capsule())

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("More")
                    .glassEffect(.regular.interactive(), in: Capsule())
                }
                .padding(.horizontal, 25)

                Spacer()

                // --- BOTTOM AREA ---
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 2) {
                                ForEach(Array(viewModel.assets.enumerated()), id: \.offset) { index, asset in
                                    ThumbnailView(image: viewModel.thumbnails[asset.localIdentifier], isSelected: index == viewModel.currentIndex)
                                        .id(index)
                                        .onTapGesture {
                                            withAnimation { viewModel.currentIndex = index }
                                        }
                                }
                            }
                            .padding(.horizontal, 25)
                        }
                        .frame(height: 60)
                        .onChange(of: viewModel.currentIndex) { _, newValue in
                            withAnimation { proxy.scrollTo(newValue, anchor: .center) }
                        }
                    }

                    // Action Toolbar (decorative — read-only gallery)
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2.weight(.medium))
                        }
                        .frame(width: 44, height: 44)
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: Circle())

                        Spacer()
                        HStack(spacing: 40) {
                            Button(action: {}) { Image(systemName: "heart") }
                                .buttonStyle(.plain)
                            Button(action: {}) { Image(systemName: "info.circle") }
                                .buttonStyle(.plain)
                            Button(action: {}) { Image(systemName: "line.3.horizontal") }
                                .buttonStyle(.plain)
                        }
                        .font(.title2.weight(.medium))
                        .padding(.horizontal, 15)
                        .frame(height: 44)
                        .glassEffect(.regular.interactive(), in: Capsule())

                        Spacer()

                        Button(action: {}) {
                            Image(systemName: "trash")
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .font(.title2.weight(.medium))
                        .glassEffect(.regular.interactive(), in: Circle())
                    }
                    .padding(.horizontal, 25)
                }
            }
        }
        .task {
            await viewModel.load()
            for asset in viewModel.assets {
                await viewModel.loadThumbnail(for: asset)
            }
        }
    }
}

private struct GalleryPageView: View {
    let image: UIImage?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Color.clear
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct ThumbnailView: View {
    let image: UIImage?
    let isSelected: Bool

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray
            }
        }
        .frame(width: isSelected ? 38 : 30, height: isSelected ? 48 : 40)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            isSelected
            ? RoundedRectangle(cornerRadius: 3).stroke(Color.white, lineWidth: 2)
            : nil
        )
    }
}

#Preview {
    LibraryGalleryView()
}
