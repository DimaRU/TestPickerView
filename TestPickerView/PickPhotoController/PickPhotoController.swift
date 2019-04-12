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

protocol PickPhotoControllerProtocol {
    func selected(assets: [PHAsset])
}

class PickPhotoController: UICollectionViewController {
    struct Asset {
        let asset: PHAsset
        var selected: Bool
        var image: UIImage?
    }
    
    private var location: CLLocation?
    private var assets: [Asset] = []
    private let offset = (UIImagePickerController.isSourceTypeAvailable(.camera) &&
        AVCaptureDevice.authorizationStatus(for: .video) != .denied) ? 1 : 0
    private var itemSize: CGSize {
        get {
            let collectionViewLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            return collectionViewLayout.itemSize
        }
    }
    public var delegate: PickPhotoControllerProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dragInteractionEnabled = true
        let collectionViewLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let spacing = collectionViewLayout.minimumInteritemSpacing
        let itemWidth = (UIScreen.main.bounds.width - spacing * CGFloat(Params.viewColumns - 1)) / CGFloat(Params.viewColumns)
        collectionViewLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        CLLocationManager.requestAuthorization(type: .whenInUse)
            .then { _ in
                CLLocationManager.requestLocation()
            }.done { locations in
                self.location = locations.last
            }.ignoreErrors()

        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.fetchImages()
            }
        }
    }
    
    private func fetchImages() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = (Params.viewColumns * Params.viewRows) - (offset + 1)
        let fetched = PHAsset.fetchAssets(with: .image, options: options)
        let promises = (0 ..< fetched.count)
            .map { PHImageManager.default().requestPreviewImage(for: fetched[$0], itemSize: itemSize)
                .done { self.assets.append(PickPhotoController.Asset(asset: $0.1, selected: false, image: $0.0))
            }
        }
        when(fulfilled: promises)
            .done {
                self.collectionView.reloadData()
            }.ignoreErrors()
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

    func requestFullImage(for asset: PHAsset, completion: @escaping (UIImage) -> Void) {
        let manager = PHImageManager.default()
        manager.requestImageData(for: asset, options: .none) { (data, dataUTI, orientation, info) in
            guard let data = data, let image = UIImage(data: data) else { return }
            completion(image)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count + offset + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.item {
        case offset - 1:
            // From camera
            pickImage(from: .camera)
                .then { info -> Promise<PHAsset> in
                    guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { throw PMKError.cancelled }
                    let metadata = info[UIImagePickerController.InfoKey.mediaMetadata] as? [AnyHashable: Any]
                    let data = image.JPEGDataRepresentation(withMetadata: metadata ?? [:], location: self.location)
                    return PHPhotoLibrary.shared().add(imageData: data, withLocation: self.location)
                }.then { phasset in
                    PHImageManager.default().requestPreviewImage(for: phasset, itemSize: self.itemSize)
                }.done {
                    let asset = Asset(asset: $0.1, selected: true, image: $0.0)
                    self.assets.insert(asset, at: 0)
                    let indexPath = IndexPath(item: 1, section: 0)
                    self.collectionView.insertItems(at: [indexPath])
                    self.delegate?.selected(assets: self.assets.filter{ $0.selected }.map{ $0.asset })
                }.ignoreErrors()
        case assets.count + offset:
            // From photo library
            pickImage(from: .photoLibrary)
                .then { info -> Promise<(UIImage, PHAsset)> in
                    guard let phasset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset else { throw PMKError.cancelled }
                    return PHImageManager.default().requestPreviewImage(for: phasset, itemSize: self.itemSize)
                }.done {
                    let asset = Asset(asset: $0.1, selected: true, image: $0.0)
                    self.assets.append(asset)
                    self.collectionView.insertItems(at: [indexPath])
                    self.delegate?.selected(assets: self.assets.filter{ $0.selected }.map{ $0.asset })
                }.ignoreErrors()
        default:
            // Select image
            let index = indexPath.item - offset
            assets[index].selected.toggle()
            self.collectionView.reloadItems(at: [indexPath])
            delegate?.selected(assets: assets.filter{ $0.selected }.map{ $0.asset })
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        switch indexPath.item {
        case offset - 1:
            return false
        case assets.count + offset:
            return false
        default:
            return true
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        var item = proposedIndexPath.item
        switch item {
        case offset - 1:
            item += 1
        case assets.count + offset:
            item -= 1
        default:
            break
        }
        return IndexPath(item: item, section: proposedIndexPath.section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let temp = assets.remove(at: sourceIndexPath.item)
        assets.insert(temp, at: destinationIndexPath.item)
        if temp.selected {
            delegate?.selected(assets: assets.filter{ $0.selected }.map{ $0.asset })
        }
    }
}

extension PickPhotoController {
    private struct Params {
        static let viewColumns = 3
        static let viewRows = 3
    }
}
