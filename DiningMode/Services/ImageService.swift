//
//  ImageService.swift
//  DiningMode
//
//  Created by Scott Delly on 2/15/17.
//  Copyright © 2017 OpenTable, Inc. All rights reserved.
//

import UIKit

class ImageService {
    static let shared = ImageService()
    fileprivate var imageTasks = [URL: URLSessionDownloadTask]()
    private let imageCache = NSCache<NSURL, UIImage>()//Cant use URL type as the key, it's not an `AnyObject`
    
    var callbackQueue = DispatchQueue.main
    
    func loadImage(atURL url: URL, callback: @escaping (Response<UIImage>) -> ()) {
        if let cachedImage = self.imageCache.object(forKey: url as NSURL) {
            self.callbackQueue.async { callback(Response.Pass(cachedImage)) }
        } else {
            let task = URLSession.shared.downloadTask(with: url) { [unowned self] (location, response, error) in
                self.imageTasks.removeValue(forKey: url)
                if let error = error {
                    self.callbackQueue.async { callback(Response.Fail(error)) }
                } else if let location = location {
                    do {
                        let data = try Data(contentsOf: location)
                        let image = UIImage(data: data)!
                        self.imageCache.setObject(image, forKey: url as NSURL)
                        self.callbackQueue.async { callback(Response.Pass(image)) }
                    } catch let error {
                        self.callbackQueue.async { callback(Response.Fail(error)) }
                    }
                } else {
                    self.callbackQueue.async { callback(Response.Fail(NSError(domain: "omni", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to download image, empty response"]))) }
                }
                
            }
            self.imageTasks[url] = task
            task.resume()
        }
    }
    
    func cancelImage(atURL url: URL) {
        if let task = self.imageTasks[url] {
            task.cancel()
        }
    }
}
