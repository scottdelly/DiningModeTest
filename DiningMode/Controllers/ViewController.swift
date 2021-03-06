//
//  ViewController.swift
//  DiningMode
//
//  Created by Olivier Larivain on 12/2/16.
//  Copyright © 2016 OpenTable, Inc. All rights reserved.
//

import UIKit

import AFNetworking

class ViewController: UIViewController, StoryboardTrait {
    
    @IBAction func buttonShowBanner(_ sender: Any) {
        NotificationCenter.default.post(name: BannerShowNotification, object: nil, userInfo: ["reservationID": "FullReservation"])
    }
    
    @IBAction func buttonHideBannerTUIAction(_ sender: Any) {
        NotificationCenter.default.post(name: BannerHideNotification, object: nil)
    }

    @IBAction func buttonToggleBanner(_ sender: Any) {
        NotificationCenter.default.post(name: BannerToggleNotification, object: nil)
    }
    @IBAction func presentModalTUIAction(_ sender: Any) {
        let newVC = UIViewController(nibName: nil, bundle: nil)
        newVC.view.backgroundColor = UIColor.red
        newVC.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(ViewController.closePresentedVC))
        let newNC = UINavigationController(rootViewController: newVC)
        self.present(newNC, animated: true) { 
            //
        }
    }
    
    func closePresentedVC() {
        self.presentedViewController?.dismiss(animated: true, completion: { 
            //
        })
    }
}

