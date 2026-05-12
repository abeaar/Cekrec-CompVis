
import AVFoundation
import SwiftUI
import Combine

struct IdentifiableImage: Identifiable {
  let id = UUID()
  let image:UIImage
}
