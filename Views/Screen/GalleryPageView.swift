import SwiftUI

struct GalleryPageView: View {
    let image: UIImage?
    var body: some View {
        ZStack {
            Color.black
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

