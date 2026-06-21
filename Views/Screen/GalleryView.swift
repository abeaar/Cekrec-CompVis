import SwiftUI
import Photos

struct GalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GalleryViewModel()
    
    var body: some View {
        
        ZStack {
            Color.black.ignoresSafeArea()
            PhotoView(viewModel: viewModel)
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
            await viewModel.loadImage(at: viewModel.currentIndex)
        }
        .onChange(of: viewModel.currentIndex) { _, newIndex in
            viewModel.prefetchNextPageIfNeeded(currentIndex: newIndex)
            Task { await viewModel.loadImage(at: newIndex) }
        }
    }
}

#Preview {
    ContentView()
}
