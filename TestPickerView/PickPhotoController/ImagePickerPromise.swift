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
    
    public func requestCameraAccess() -> Guarantee<Void> {
        let (guarantee, resolve) = Guarantee<Void>.pending()
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                resolve(())
            }
        default:
            resolve(())
        }
        return guarantee
    }
    
    public func pickImage(from source: UIImagePickerController.SourceType) -> Promise<[UIImagePickerController.InfoKey: Any]> {
        guard let vc = makeImagePickerController(for: source) else {
            return Promise(error: PMKError.cancelled)
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
        guard UIImagePickerController.isSourceTypeAvailable(source) else { return nil }
        imagePickerController.sourceType = source
        
        if source == .camera {
            guard AVCaptureDevice.authorizationStatus(for: .video) != .restricted else { return nil }
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePickerController.cameraDevice = .rear
            }
        }
        return imagePickerController
    }
}

@objc private class UIImagePickerControllerProxy: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let (promise, seal) = Promise<[UIImagePickerController.InfoKey: Any]>.pending()
    var retainCycle: AnyObject?
    
    required override init() {
        super.init()
        retainCycle = self
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) != nil {
            seal.fulfill(info)
        } else {
            seal.reject(PMKError.cancelled)
        }
        retainCycle = nil
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        seal.reject(PMKError.cancelled)
        retainCycle = nil
    }
}
