//
//  StoryboardTrait.swift
//  DiningMode
//
//  Created by Scott Delly on 2/13/17.
//  Copyright © 2017 OpenTable, Inc. All rights reserved.
//

import UIKit

protocol StoryboardTrait {
    static var StoryboardIdentifier: String { get }
}

extension StoryboardTrait where Self: UIViewController {
    static var StoryboardIdentifier: String {
        return String(describing: self)
    }
    
    static func StoryboardController() -> Self {
        let identifier = Self.StoryboardIdentifier
        let storyboard = UIStoryboard(name: identifier, bundle: nil)
        let optionalViewController = storyboard.instantiateViewController(withIdentifier: identifier)
        
        guard let viewController = optionalViewController as? Self  else {
            fatalError("Couldn’t instantiate view controller with identifier \(identifier) ")
        }
        return viewController
    }
}
