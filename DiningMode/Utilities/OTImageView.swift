//
//  OTImageView.swift
//  DiningMode
//
//  Created by Scott Delly on 2/15/17.
//  Copyright © 2017 OpenTable, Inc. All rights reserved.
//

import UIKit

class OTImageView: UIImageView {
    
    private var url: URL?
    
    func image(withPhoto photo: Photo) {
        let photoURLString = photo.urlForSize(desiredSize: self.bounds.size)
        if let photoURL = URL(string: photoURLString) {
            self.setImageWith(photoURL)
        }
    }
    
    func image(fromURL url: URL) {
        self.cancelImageLoad()
        self.url = url
        ImageService.shared.loadImage(atURL: url) { [weak self] (response) in
            switch response {
            case .Fail(let error):
                print("Failed to load image into UIImageView \(error)")
            case .Pass(let image):
                self?.image = image
                self?.url = nil
            }
        }
    }
    
    func cancelImageLoad() {
        if let existingURL = self.url {
            ImageService.shared.cancelImage(atURL: existingURL)
        }
    }
}
