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

protocol PickPhotoControllerDelegate {
    func imageDidSelect(image: UIImage)
}

class PickPhotoController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    private var fetched: PHFetchResult<PHAsset>!
    private var previewImage: [Int: UIImage] = [:]
    private let offset = (UIImagePickerController.isSourceTypeAvailable(.camera) &&
        AVCaptureDevice.authorizationStatus(for: .video) != .denied) ? 1 : 0
    private var count = 0
    var delegate: PickPhotoControllerDelegate?
    
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
        let collectionViewLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemSize = collectionViewLayout.itemSize
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = (Params.viewColumns * Params.viewRows) - (offset + 1)
        fetched = PHAsset.fetchAssets(with: .image, options: options)
        count = fetched.count
        collectionView.reloadData()
        for i in 0..<count {
            requestPreviewImage(for: fetched[i], itemSize: itemSize) { image in
                self.previewImage[i] = image
                let indexPath = IndexPath(item: i + self.offset, section: 0)
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    func requestPreviewImage(for asset: PHAsset, itemSize: CGSize, completion: @escaping (UIImage) -> Void) {
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
        let asset = fetched[index]
        let manager = PHImageManager.default()
        manager.requestImageData(for: asset, options: .none) { (data, dataUTI, orientation, info) in
            guard let data = data, let image = UIImage(data: data) else { return }
            completion(image)
        }
    }
}



extension PickPhotoController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return count + offset + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.item {
        case offset - 1:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "CameraCell", for: indexPath)
        case count + offset:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath)
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickPhotoCollectionViewCell", for: indexPath) as! PickPhotoCollectionViewCell
            cell.photoImageView.image = previewImage[indexPath.item - offset]
            cell.checkMarkIcon.isHidden = false
            return cell
        }
    }
}

extension PickPhotoController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.item {
        case offset - 1:
            pickImage(from: .camera)
                .done { image in
                    
                    self.delegate?.imageDidSelect(image: image)
                }.catch { error in
                    print(error)
            }
        case count + offset:
            pickImage(from: .photoLibrary)
                .done {
                    let cell = self.collectionView.cellForItem(at: indexPath) as? PickPhotoCollectionViewCell
                    cell?.checkMarkIcon.isHidden.toggle()
                    self.delegate?.imageDidSelect(image: $0)
                }.catch { error in
                    print(error)
            }
        default:
            requestFullImage(at: indexPath.item - offset) {
                self.delegate?.imageDidSelect(image: $0)
            }
        }
    }
}

extension PickPhotoController {
    private struct Params {
        static let viewColumns = 3
        static let viewRows = 3
    }
}
