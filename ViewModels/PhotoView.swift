import SwiftUI
import Photos

struct PhotoView: View {
    @Bindable var viewModel: GalleryViewModel

    var body: some View {
        TabView(selection: $viewModel.currentIndex) {
            ForEach(0..<viewModel.loadedCount, id: \.self) { index in
                GalleryPageView(image: viewModel.fullImages[viewModel.assets[index].localIdentifier])
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}
