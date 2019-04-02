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

private func requestPhotoLibraryAccess() -> Guarantee<Void> {
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
