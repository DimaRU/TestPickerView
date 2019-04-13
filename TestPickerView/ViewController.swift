//
//  ViewController.swift
//  TestPickerView
//
//  Created by Dmitriy Borovikov on 21/03/2019.
//  Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import Photos
import PromiseKit

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    private var phassets: [PHAsset] = []
    private var locations: [CLLocation?] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pickPhotoController = children.first as! PickPhotoController
        pickPhotoController.delegate = self
    }
    
    private func updateImageView() {
        imageView.animationImages = []
        locations = []
        let promises = phassets.map { asset in
            PHImageManager.default().requestFullImage(for: asset)
                .done { image, gpsdictionary in
                    self.imageView.animationImages?.append(image)
                    self.locations.append(asset.location)
                    print(asset.location?.coordinate)
            }
        }
        when(fulfilled: promises)
            .done {
                self.imageView.animationDuration = 1.0 *  Double(self.imageView.animationImages?.count ?? 0)
                self.imageView.startAnimating()
            }.catch { print($0) }
    }
}

extension ViewController: PickPhotoControllerProtocol {
    func selected(assets: [PHAsset]) {
        phassets = assets
        updateImageView()
    }
}
