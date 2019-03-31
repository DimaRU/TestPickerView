//
//  PhotoOverlayView.swift
//  TestPickerView
//
//  Created by Dmitriy Borovikov on 31/03/2019.
//  Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import UIKit

class PhotoOverlayView: UIView {
    let galleryButton = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        galleryButton.setImage(UIImage(named: "gallery"), for: .normal)
        galleryButton.addTarget(self, action: #selector(galleryButtonTap(_:)), for: .touchUpInside)
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(galleryButton)
        NSLayoutConstraint.activate([
            galleryButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 16),
            galleryButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 32),
            galleryButton.widthAnchor.constraint(equalToConstant: 25),
            galleryButton.heightAnchor.constraint(equalToConstant: 25)
            ])
    }
    
    @objc func galleryButtonTap(_ sender: UIButton) {
        print("Gallery tap")
    }
}
