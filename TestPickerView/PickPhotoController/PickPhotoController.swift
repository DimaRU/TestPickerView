//
//  PickPhotoController.swift
//  PickPhotoController
//
//  Created by Dmitriy Borovikov on 01/04/2019.
//  Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import PromiseKit

class PickPhotoController: UIViewController {
    struct Asset {
        let asset: PHAsset
        var selected: Bool
        var image: UIImage?
        init(_ asset: PHAsset, selected: Bool = false) {
            self.asset = asset
            self.selected = selected
        }
    }
    @IBOutlet weak var collectionView: UICollectionView!
    private var assets: [Asset] = []
    private let offset = (UIImagePickerController.isSourceTypeAvailable(.camera) &&
        AVCaptureDevice.authorizationStatus(for: .video) != .denied) ? 1 : 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let collectionViewLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let spacing = collectionViewLayout.minimumInteritemSpacing
        let itemWidth = (UIScreen.main.bounds.width - spacing * CGFloat(Params.viewColumns - 1)) / CGFloat(Params.viewColumns)
        collectionViewLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)

        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.fetchImages()
                }
            }
        } else {
            fetchImages()
        }
    }
    
    private func fetchImages() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = (Params.viewColumns * Params.viewRows) - (offset + 1)
        let fetched = PHAsset.fetchAssets(with: .image, options: options)
        assets = (0 ..< fetched.count).map{ Asset(fetched[$0]) }
        collectionView.reloadData()
        for i in assets.indices {
            requestPreviewImage(for: assets[i].asset) { image in
                self.assets[i].image = image
                let indexPath = IndexPath(item: i + self.offset, section: 0)
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    func requestPreviewImage(for asset: PHAsset, completion: @escaping (UIImage) -> Void) {
        let collectionViewLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemSize = collectionViewLayout.itemSize
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        let manager = PHImageManager.default()
        manager.requestImage(for: asset, targetSize: itemSize, contentMode: .aspectFill, options: options) {
            (image, info) in
            guard let image = image else { return }
            completion(image)
        }
    }

    func requestFullImage(at index: Int, completion: @escaping (UIImage) -> Void) {
        let asset = assets[index].asset
        let manager = PHImageManager.default()
        manager.requestImageData(for: asset, options: .none) { (data, dataUTI, orientation, info) in
            guard let data = data, let image = UIImage(data: data) else { return }
            completion(image)
        }
    }
}



extension PickPhotoController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count + offset + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.item {
        case offset - 1:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "CameraCell", for: indexPath)
        case assets.count + offset:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath)
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickPhotoCollectionViewCell", for: indexPath) as! PickPhotoCollectionViewCell
            let asset = assets[indexPath.item - offset]
            cell.photoImageView.image = asset.image
            cell.checkMarkIcon.isHidden = !asset.selected
            return cell
        }
    }
}

extension PickPhotoController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.item {
        case offset - 1:
            // From camera
            pickImage(from: .camera)
                .done { info in
                }.catch { error in
                    print(error)
            }
        case assets.count + offset:
            // From photo library
            pickImage(from: .photoLibrary)
                .done { info in
                    guard let phasset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset
                        else {
                            throw PMKError.cancelled
                    }
                    let asset = Asset(phasset, selected: true)
                }.catch { error in
                    print(error)
            }
        default:
            // Select image
            let index = indexPath.item - offset
            assets[index].selected.toggle()
            self.collectionView.reloadItems(at: [indexPath])
        }
    }
}

extension PickPhotoController {
    private struct Params {
        static let viewColumns = 3
        static let viewRows = 3
    }
}
