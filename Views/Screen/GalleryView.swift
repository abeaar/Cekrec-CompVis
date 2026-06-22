import SwiftUI
import Photos
import UIKit

struct GalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GalleryViewModel()

    var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                switch viewModel.state {
                case .idle, .loading:
                    ProgressView()
                        .tint(.white)
                        .controlSize(.large)
                case .denied:
                    GalleryDeniedView(message: viewModel.permissionMessage ?? "Photo access is unavailable.")
                case .loaded:
                    if viewModel.assets.isEmpty {
                        GalleryEmptyView()
                    } else {
                        PhotoView(viewModel: viewModel)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
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
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {} label: {
                        Image(systemName: "ellipsis")
                            .fontWeight(.semibold)
                    }
                    .tint(.white)
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {} label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Spacer()
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {} label: {
                        Image(systemName: "heart")
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {} label: {
                        Image(systemName: "info.circle")
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {} label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Spacer()
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {} label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .task {
                await viewModel.load()
                if viewModel.state == .loaded {
                    await viewModel.loadImage(at: viewModel.currentIndex)
                }
            }
            .onChange(of: viewModel.currentIndex) { _, newIndex in
                viewModel.prefetchNextPageIfNeeded(currentIndex: newIndex)
                viewModel.prefetchNeighbors(of: newIndex)
                Task { await viewModel.loadImage(at: newIndex) }
            }

    }
}

private struct GalleryDeniedView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white)
            Text(message)
                .font(.callout)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .glassEffect(.regular.interactive(), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct GalleryEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white)
            Text("No Photos")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Photos you take with Cekrec will appear here.")
                .font(.callout)
                .foregroundStyle(.white.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    GalleryView()
}
