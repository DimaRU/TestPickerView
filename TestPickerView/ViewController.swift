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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pickPhotoController = children.first as! PickPhotoController
        pickPhotoController.delegate = self
    }
    
    private func updateImageView(assets: [PHAsset]) {
        let locations = assets.compactMap{ $0.location }
        let promises = assets.map { asset in PHImageManager.default().requestFullImage(for: asset) }
        print(locations)
        when(fulfilled: promises)
            .done { result in
                self.imageView.animationImages = result.map{ $0.0 }
                self.imageView.animationDuration = 1.0 *  Double(self.imageView.animationImages?.count ?? 0)
                self.imageView.startAnimating()
            }.ignoreErrors()
    }
}

extension ViewController: PickPhotoControllerProtocol {
    func selected(assets: [PHAsset]) {
        updateImageView(assets: assets)
    }
}
