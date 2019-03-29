//
//  ViewController.swift
//  TestPickerView
//
//  Created by Dmitriy Borovikov on 21/03/2019.
//  Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePickerController = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPickerController()
    }
    
    @IBAction func selectPhotoButtonTap(_ sender: Any) {
        present(imagePickerController, animated: true)
    }
    
    @IBAction func selectPhotoPromise(_ sender: Any) {
        pickImage()
            .done { image in
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }.catch { error in
                print(error)
        }
    }
    
    private func authCameraAccess(completion: @escaping () -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    completion()
                }
            }
        case .authorized:
            completion()
        case .restricted:
            print("Restricted")
        case .denied:
            print("Denied")
        @unknown default:
            print("Unknown")
        }
    }
    
    private func setupPickerController() {
        imagePickerController.delegate = self
        if UIImagePickerController.isSourceTypeAvailable(.camera) &&
            AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            imagePickerController.sourceType = .camera
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePickerController.cameraDevice = .rear
            }
        } else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePickerController.sourceType = .photoLibrary
        } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePickerController.sourceType = .savedPhotosAlbum
        } else {
            print("Nothing avaible")
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer {
            imagePickerController.dismiss(animated: true)
        }
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            print("Strange: no image aviable")
            return
        }
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Cancelled")
        imagePickerController.dismiss(animated: true)
    }
}

extension ViewController: UINavigationControllerDelegate {
    
}
