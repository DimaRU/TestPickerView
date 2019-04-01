//
//  ImagePickerPromise.swift
//  TestPickerView
//
//  Created by Dmitriy Borovikov on 28/03/2019.
//  Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import AVFoundation
import PromiseKit

extension UIViewController {
    
    private func authCameraAccess() -> Guarantee<Void> {
        let (guarantee, resolve) = Guarantee<Void>.pending()
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                resolve(())
            }
        default:
            resolve(())
            return guarantee
        }
        return guarantee
    }
    
    public func pickImage(from source: UIImagePickerController.SourceType) -> Promise<UIImage> {
        guard let vc = makeImagePickerController(for: source) else {
            return Promise(error: UIImagePickerController.PMKError.cancelled)
        }
        let proxy = UIImagePickerControllerProxy()
        vc.delegate = proxy
        present(vc, animated: true)
        return proxy.promise.ensure {
            vc.presentingViewController?.dismiss(animated: true)
        }
    }

    private func makeImagePickerController(for source: UIImagePickerController.SourceType) -> UIImagePickerController? {
        let imagePickerController = UIImagePickerController()
        if source == .camera,
            UIImagePickerController.isSourceTypeAvailable(.camera),
            (AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined ||
            AVCaptureDevice.authorizationStatus(for: .video) == .authorized) {
            imagePickerController.sourceType = .camera
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePickerController.cameraDevice = .rear
            }
        } else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePickerController.sourceType = .photoLibrary
        } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePickerController.sourceType = .savedPhotosAlbum
        } else {
            return nil
        }
        return imagePickerController
    }
}

@objc private class UIImagePickerControllerProxy: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let (promise, seal) = Promise<UIImage>.pending()
    var retainCycle: AnyObject?
    
    required override init() {
        super.init()
        retainCycle = self
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            seal.fulfill(image)
        } else {
            seal.reject(UIImagePickerController.PMKError.cancelled)
        }
        retainCycle = nil
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        seal.reject(UIImagePickerController.PMKError.cancelled)
        retainCycle = nil
    }
}

extension UIImagePickerController {
    /// Errors representing PromiseKit UIImagePickerController failures
    public enum PMKError: CancellableError {
        /// The user cancelled the UIImagePickerController.
        case cancelled
        /// - Returns: true
        public var isCancelled: Bool {
            switch self {
            case .cancelled:
                return true
            }
        }
    }
}
