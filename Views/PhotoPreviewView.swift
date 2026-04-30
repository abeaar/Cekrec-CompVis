//
//  PhotoPreciewView.swift
//  Cekrec
//
//  Created by abr on 30/04/26.
//

import Foundation
import SwiftUI
import AVFoundation

struct PhotoPreviewView: View {
    let item: IdentifiableImage
    let onDismiss: () -> Void
    
    var body: some View {
        VStack{
            HStack{
                Button("retake"){
                    onDismiss()
                }
                .padding()
                
                Spacer()
                
                Button("save"){
                    UIImageWriteToSavedPhotosAlbum(item.image, nil, nil,nil)
                    onDismiss()
                }
            }
            .background(.ultraThinMaterial)
            Image(uiImage: item.image)
                .resizable()
                .scaledToFit()
        }
    }
}
