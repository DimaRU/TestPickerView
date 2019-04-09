//
//  PHImageManagerPromise.swift
//  TestPickerView
//
//  Created by Dmitriy Borovikov on 08/04/2019.
//  Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Photos
import PromiseKit

extension PHImageManager {
    func requestPreviewImage(for asset: PHAsset, itemSize: CGSize) -> Promise<(UIImage, PHAsset)> {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        return Promise { seal in
            requestImage(for: asset, targetSize: itemSize, contentMode: .aspectFill, options: options) {
                (image, info) in
                if let image = image {
                    seal.fulfill((image, asset))
                } else {
                    seal.reject(PMKError.cancelled)
                }
    
            }
        }
    }
    
    func requestFullImage(for asset: PHAsset) -> Promise<UIImage> {
        return Promise { seal in
            requestImageData(for: asset, options: .none) { (data, dataUTI, orientation, info) in
                if let data = data, let image = UIImage(data: data) {
                    seal.fulfill(image)
                } else {
                    seal.reject(PMKError.cancelled)
                }
            }
        }
    }

}
