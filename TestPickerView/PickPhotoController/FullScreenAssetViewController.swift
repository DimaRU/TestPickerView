//
//  FullScreenAssetViewController.swift
//  FullScreenAssetViewController
//
//  Created by Dmitriy Borovikov on 01/04/2019.
//  Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import Photos

protocol FullScreenAssetViewControllerProtocol {
    func selectPhoto(asset: PHAsset)
}

class FullScreenAssetViewController: UIViewController, UIScrollViewDelegate {
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    var asset: PHAsset!
    var delegate: FullScreenAssetViewControllerProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        scrollView.frame = view.bounds
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        scrollView.delegate = self
        addGestureRecognizers()
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDoneButton(_:)))
        navigationItem.rightBarButtonItem = doneItem
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(tapCancelButton(_:)))
        navigationItem.leftBarButtonItem = cancelItem
        scrollView.addSubview(self.imageView)

        activityIndicator.frame = view.bounds
        activityIndicator.backgroundColor = .lightGray
        scrollView.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()

        PHImageManager.default().requestFullImage(for: asset)
            .done { image, _ in
                self.imageView.image = image
                self.activityIndicator.stopAnimating()
                self.imageView.sizeToFit()
                self.scrollView.contentSize = self.imageView.bounds.size
                self.setZoomScale()
                let yOffset = self.scrollView.frame.size.height - self.imageView.frame.size.height
                self.scrollView.contentOffset = CGPoint(x: 0, y: -yOffset / 2)
            }.catch { error in
                self.dismiss(animated: true)
        }
    }
    
    @objc func tapDoneButton(_ sender: Any) {
        delegate?.selectPhoto(asset: asset)
        dismiss(animated: true)
    }

    @objc func tapCancelButton(_ sender: Any) {
        dismiss(animated: true)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    override func viewWillLayoutSubviews() {
        setZoomScale()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageSize = imageView.frame.size
        let scrollSize = scrollView.bounds.size
        
        let verticalPadding = imageSize.height < scrollSize.height ? (scrollSize.height - imageSize.height) / 2 : 0
        let horizontalPadding = imageSize.width < scrollSize.width ? (scrollSize.width - imageSize.width) / 2 : 0
        
        scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }
    
    func setZoomScale() {
        let imageViewSize = imageView.bounds.size
        let scrollViewSize = scrollView.bounds.size
        let widthScale = scrollViewSize.width / imageViewSize.width
        let heightScale = scrollViewSize.height / imageViewSize.height
        
        scrollView.minimumZoomScale = min(widthScale, heightScale)
        scrollView.zoomScale = scrollView.minimumZoomScale
    }
    
    func addGestureRecognizers() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(recognizer:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.delegate = self
        scrollView.addGestureRecognizer(singleTap)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(recognizer:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    @objc func handleSingleTap(recognizer: UITapGestureRecognizer) {
        let isHidden = !(navigationController?.navigationBar.isHidden ?? true)
        navigationController?.setNavigationBarHidden(isHidden, animated: true)
        view.backgroundColor = isHidden ? .black : .white
    }
    
    @objc func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        if (scrollView.zoomScale > scrollView.minimumZoomScale) {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        }
    }
}

extension FullScreenAssetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

