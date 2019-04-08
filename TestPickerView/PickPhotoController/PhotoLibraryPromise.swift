//
//  PhotoLibraryPromise.swift
//  TestPickerView
//
//  Created by Dmitriy Borovikov on 02/04/2019.
//  Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import Photos
import PromiseKit

extension PHPhotoLibrary {
    public class func requestAuthorization() -> Guarantee<PHAuthorizationStatus> {
        return Guarantee(resolver: PHPhotoLibrary.requestAuthorization)
    }
    
    public class func requestPhotoLibraryAccess() -> Guarantee<Void> {
        let (guarantee, resolve) = Guarantee<Void>.pending()
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                resolve(())
            }
        default:
            resolve(())
        }
        return guarantee
    }
    
    public func add(imageData: Data, withLocation location: CLLocation?) -> Promise<PHAsset> {
        var placeholder: PHObjectPlaceholder!
        let (promise, seal) = Promise<PHAsset>.pending()
        performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: imageData, options: .none)
            request.creationDate = Date()
            request.location = location
            placeholder = request.placeholderForCreatedAsset
        }, completionHandler: { (success, error) -> Void in
            if let error = error {
                seal.reject(error)
                return
            }
            guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: .none).firstObject else {
                seal.reject(NSError())
                return
            }
            seal.fulfill(asset)
        })
        return promise
    }
}
