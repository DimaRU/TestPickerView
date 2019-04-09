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
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func selectPhotoButtonTap(_ sender: Any) {
        let storyboard = UIStoryboard(name: "PickPhotoController", bundle: nil)
        let pickPhotoController = storyboard.instantiateInitialViewController() as! PickPhotoController
        pickPhotoController.delegate = self
        navigationController?.pushViewController(pickPhotoController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard !phassets.isEmpty else { return }
        imageView.animationImages = []
        let promises = phassets.map {
            PHImageManager.default().requestFullImage(for: $0).done { self.imageView.animationImages?.append($0) }
        }
        when(fulfilled: promises)
            .done {
                self.imageView.animationDuration = 0.5 * Double(self.imageView.animationImages?.count ?? 0)
                self.imageView.startAnimating()
            }.catch { print($0) }
    }
    
}

extension ViewController: PickPhotoControllerProtocol {
    func selected(assets: [PHAsset]) {
        phassets = assets
    }
}
