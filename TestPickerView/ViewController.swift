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

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func selectPhotoButtonTap(_ sender: Any) {
        let storyboard = UIStoryboard(name: "PickPhotoController", bundle: nil)
        let pickPhotoController = storyboard.instantiateInitialViewController() as! PickPhotoController
        pickPhotoController.delegate = self
        present(pickPhotoController, animated: true)
    }
    
}

extension ViewController: PickPhotoControllerDelegate {
    func imageDidSelect(image: UIImage) {
        imageView.image = image
        self.presentedViewController?.dismiss(animated: true)
    }
}
