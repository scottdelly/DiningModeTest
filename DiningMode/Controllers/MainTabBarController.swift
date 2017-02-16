//
//  MainTabBarController.swift
//  DiningMode
//
//  Created by Scott Delly on 2/13/17.
//  Copyright © 2017 OpenTable, Inc. All rights reserved.
//

import UIKit

let BannerShowNotification = Notification.Name(rawValue: "BannerShowNotification")
let BannerHideNotification = Notification.Name(rawValue: "BannerHideNotification")
let BannerToggleNotification = Notification.Name(rawValue: "BannerToggleNotification")

class MainTabBarController: UITabBarController {
    
    var diningTransitionIsInteractive = true
    
    var transitionAnimator = DiningModeAnimatedTransitioning()
    var interactivePresentationTransitionController: DiningModeInteractiveTransition?
    var interactiveDismissalTransitionController: DiningModeInteractiveTransition?

    weak var diningModeBanner: UIView?
    weak var diningModeBannerTopConstraint: NSLayoutConstraint?
    
    var currentReservationID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainTabBarController.showDiningModeBanner(notification:)), name: BannerShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainTabBarController.hideDiningModeBanner), name: BannerHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainTabBarController.toggleDiningModeBanner), name: BannerToggleNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func showDiningModeBanner(notification: Notification) {
        if let reservationID = notification.userInfo?["reservationID"] as? String {
            self.showDiningModeBanner(reservationID: reservationID)
        }
    }
    
    func showDiningModeBanner(reservationID: String) {
        guard self.diningModeBanner == nil else { return }

        self.currentReservationID = reservationID
        let banner = UILabel()
        banner.textAlignment = .center
        banner.isUserInteractionEnabled = true
        banner.text = reservationID
        banner.textColor = UIColor.white
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.backgroundColor = UIColor.blue
        self.view.insertSubview(banner, belowSubview: self.tabBar)
        banner.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MainTabBarController.didTapBanner)))
        
        self.diningModeBanner = banner
        let topConstraint = banner.topAnchor.constraint(equalTo: self.tabBar.topAnchor)
        NSLayoutConstraint.activate([
            topConstraint,
            banner.leftAnchor.constraint(equalTo: self.tabBar.leftAnchor),
            banner.widthAnchor.constraint(equalTo: self.tabBar.widthAnchor),
            banner.heightAnchor.constraint(equalTo: self.tabBar.heightAnchor)
            ])
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.4) {
            topConstraint.constant = -1 * self.tabBar.bounds.size.height
            self.view.layoutSubviews()
        }
        self.diningModeBannerTopConstraint = topConstraint
        self.interactivePresentationTransitionController = DiningModeInteractiveTransition(mode: .present({ [weak self] in
            self?.presentDiningMode()
        }), view: self.diningModeBanner!)
    }
    
    func hideDiningModeBanner() {
        guard let topConstraint = self.diningModeBannerTopConstraint else { return }
        self.interactivePresentationTransitionController = nil
        self.interactiveDismissalTransitionController = nil
        UIView.animate(withDuration: 0.4, animations: { 
            topConstraint.constant = 0
            self.view.layoutSubviews()
        }) { (finished: Bool) in
            if finished {
                self.diningModeBanner?.removeFromSuperview()
            }
        }
    }
    
    func toggleDiningModeBanner() {
        if self.diningModeBanner != nil {
            self.hideDiningModeBanner()
        } else {
            self.showDiningModeBanner(reservationID: "PartialReservation")
        }
    }
    
    func didTapBanner() {
        self.diningTransitionIsInteractive = false
        self.presentDiningMode { [unowned self] in
            self.diningTransitionIsInteractive = true
        }
    }
    
    func didTapClose() {
        self.diningTransitionIsInteractive = false
        self.dismissDiningMode { [unowned self] in
            self.diningTransitionIsInteractive = true
        }
    }
    
    func presentDiningMode(then: (()->())? = nil) {
        let diningModeVC = DiningModeVC.StoryboardController()
        diningModeVC.reservationID = self.currentReservationID
        diningModeVC.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(MainTabBarController.didTapClose))
        let diningModeNC = UINavigationController(rootViewController: diningModeVC)
        diningModeNC.transitioningDelegate = self
        diningModeNC.modalPresentationStyle = .fullScreen
        self.present(diningModeNC, animated: true) {
            then?()
        }
        self.interactiveDismissalTransitionController = DiningModeInteractiveTransition(mode: .dismiss({ [weak self] in
            self?.dismissDiningMode()
        }), view: diningModeNC.navigationBar)
    }
    
    func dismissDiningMode(then: (()->())? = nil) {
        self.presentedViewController?.dismiss(animated: true) {
            then?()
        }
    }


}
