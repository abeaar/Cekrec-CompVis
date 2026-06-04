import SwiftUI
import Photos

enum GalleryState {
    case idle, loading, loaded, denied
}

@Observable
class GalleryViewModel {
    var assets: [PHAsset] = []
    var loadedCount: Int = 0 // pagination
    var state: GalleryState = .idle
    var fullImages: [String: UIImage] = [:] //dictionaries cache to avoide reloading
    var currentIndex: Int = 0

    private let pageSize: Int = 15
    private let prefetchThreshold: Int = 2

    func load() async {
        state = .loading
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch current {
        case .authorized:
            fetchAssets()
        case .notDetermined:
            let result = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if result == .authorized { fetchAssets() }
            
        default:
            state = .denied
        }
    }

    func fetchAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        //configuration for iamge in photo settings
        let result = PHAsset.fetchAssets(with: .image, options: options)
        //save data from library that have .image type.
        //result is collection with PHFetchResult type
        var fetched: [PHAsset] = []
        //temporary array
        result.enumerateObjects { asset, _, _ in fetched.append(asset) }
        assets = fetched
        //fetch into global var
        loadedCount = min(pageSize, fetched.count)
        state = .loaded
    }

    //pagination algorithm
    func prefetchNextPageIfNeeded(currentIndex: Int) {
        guard state == .loaded else { return }
        //ensure the app isnt collecting any photo from library
        guard loadedCount < assets.count else { return }
        //if there are actually any more photos left to load. in this case 50 pcs
        if currentIndex >= loadedCount - prefetchThreshold {
            loadedCount = min(loadedCount + pageSize, assets.count)
        }
        
    }
    
    func loadImage(at index: Int) async {
        guard assets.indices.contains(index) else { return }
        let asset = assets[index]
        let id = asset.localIdentifier
        if fullImages[id] != nil { return }
        let image = await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard let data, let image = UIImage(data: data) else {
                    continuation.resume(returning: nil); return
                }
                continuation.resume(returning: image)
            }
        }
        fullImages[id] = image
    }
    
    
    var currentAsset: PHAsset? {
        guard assets.indices.contains(currentIndex) else { return nil }
        return assets[currentIndex]
    }
    
    var isDenied: Bool { state == .denied }
    var headerTitle: String {
        guard let date = currentAsset?.creationDate else { return "Photo" }
        return date.formatted(.dateTime.weekday(.wide).day().month())
    }

    var headerSubtitle: String {
        guard let date = currentAsset?.creationDate else { return "" }
        return date.formatted(.dateTime.hour().minute())
    }
}
