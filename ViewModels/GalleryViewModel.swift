import SwiftUI
import Photos

enum GalleryState {
    case idle, loading, loaded, denied
}

@Observable
class GalleryViewModel: NSObject, PHPhotoLibraryChangeObserver {
    var assets: [PHAsset] = []
    var state: GalleryState = .idle
    var fullImages: [String: UIImage] = [:]
    var thumbnails: [String: UIImage] = [:]
    var currentIndex: Int = 0

    private var fetchResult: PHFetchResult<PHAsset>?
    private var isObserving = false

    override init() {
        super.init()
    }

    deinit {
        if isObserving {
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }

    func load() async {
        state = .loading
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch current {
        case .authorized, .limited:
            fetchAssets()
            startObserving()
        case .notDetermined:
            let result = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if result == .authorized || result == .limited {
                fetchAssets()
                startObserving()
            } else {
                state = .denied
            }
        default:
            state = .denied
        }
    }

    private func startObserving() {
        guard !isObserving else { return }
        PHPhotoLibrary.shared().register(self)
        isObserving = true
    }

    private func fetchAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        fetchResult = result
        var fetched: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in fetched.append(asset) }
        assets = fetched
        state = .loaded
    }

    // Called by Photos on a background queue whenever the library changes.
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResult,
              let details = changeInstance.changeDetails(for: fetchResult) else { return }
        let updated = details.fetchResultAfterChanges
        Task { @MainActor in
            self.fetchResult = updated
            var fetched: [PHAsset] = []
            updated.enumerateObjects { asset, _, _ in fetched.append(asset) }
            self.assets = fetched
            // Keep the current page in range after deletions.
            if self.currentIndex >= fetched.count {
                self.currentIndex = max(0, fetched.count - 1)
            }
        }
    }

    func loadImage(for asset: PHAsset) async {
        let id = asset.localIdentifier
        if fullImages[id] != nil { return }          // cache hit, skip
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

    func loadThumbnail(for asset: PHAsset) async {
        let id = asset.localIdentifier
        if thumbnails[id] != nil { return }
        let image = await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 80, height: 100), contentMode: .aspectFill, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
        thumbnails[id] = image
    }

    var currentAsset: PHAsset? {
        guard assets.indices.contains(currentIndex) else { return nil }
        return assets[currentIndex]
    }

    var headerTitle: String {
        guard let date = currentAsset?.creationDate else { return "Photo" }
        return date.formatted(.dateTime.weekday(.wide).day().month())
    }

    var headerSubtitle: String {
        guard let date = currentAsset?.creationDate else { return "" }
        return date.formatted(.dateTime.hour().minute())
    }
}
