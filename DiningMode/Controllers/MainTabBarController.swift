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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainTabBarController.showDiningModeBanner), name: BannerShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainTabBarController.hideDiningModeBanner), name: BannerHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainTabBarController.toggleDiningModeBanner), name: BannerToggleNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func showDiningModeBanner() {
        guard self.diningModeBanner == nil else { return }
        let banner = UIView()
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
            self.showDiningModeBanner()
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
        let diningModeVC = DiningModeVC(nibName: nil, bundle: nil)
        diningModeVC.view.backgroundColor = UIColor.purple
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


extension MainTabBarController: UIViewControllerTransitioningDelegate {
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = self.transitionAnimator
        animator.origin = self.diningModeBanner!.frame.origin
        animator.origin.y += self.diningModeBanner!.bounds.size.height
        return animator
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = self.transitionAnimator
        animator.origin = self.diningModeBanner!.frame.origin
        animator.origin.y += self.diningModeBanner!.bounds.size.height
        return animator
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.diningTransitionIsInteractive {
            return self.interactivePresentationTransitionController
        }
        return nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.diningTransitionIsInteractive {
            return self.interactiveDismissalTransitionController
        }
        return nil
    }
    
}

class DiningModeAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    var origin = CGPoint.zero
    var bannerSnapshot: UIView?
    var tabBarSnapshot: UIView?
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        if let rootVC = fromVC as? MainTabBarController {
            //Presenting
            let fromRect = transitionContext.initialFrame(for: rootVC)
            var toRect = fromRect
            toRect.origin = self.origin
            
            toVC.view.frame = toRect
            let container = transitionContext.containerView
            let bannerSnapshot = rootVC.diningModeBanner!.snapshotView(afterScreenUpdates: true)!
            let tabBarSnapshot = rootVC.tabBar.snapshotView(afterScreenUpdates: true)!
            
            toVC.view.addSubview(bannerSnapshot)
            
            toVC.view.clipsToBounds = false
            container.addSubview(rootVC.view)
            container.addSubview(toVC.view)
            container.addSubview(tabBarSnapshot)
            tabBarSnapshot.frame.origin.y = self.origin.y
            let animOptions: UIViewAnimationOptions = transitionContext.isInteractive ? [UIViewAnimationOptions.curveLinear] : []
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: animOptions, animations: {
                toVC.view.frame = fromRect
                tabBarSnapshot.frame.origin.y = tabBarSnapshot.superview!.bounds.size.height
                bannerSnapshot.alpha = 0
            }) { (finished) in
                bannerSnapshot.removeFromSuperview()
                tabBarSnapshot.removeFromSuperview()
                if transitionContext.transitionWasCancelled {
                    transitionContext.completeTransition(false)
                } else {
                    transitionContext.completeTransition(true)
                }
            }
            
            self.tabBarSnapshot = tabBarSnapshot
            self.bannerSnapshot = bannerSnapshot
        } else if let rootVC = toVC as? MainTabBarController {
            var fromRect = transitionContext.initialFrame(for: fromVC)
            fromRect.origin = self.origin
            
            let container = transitionContext.containerView
            
            if let bannerSnapshot = self.bannerSnapshot {
                bannerSnapshot.alpha = 0
                fromVC.view.addSubview(bannerSnapshot)
            }
            
            container.addSubview(rootVC.view)
            container.addSubview(fromVC.view)
            
            if let tabBarSnapshot = self.tabBarSnapshot {
                tabBarSnapshot.frame.origin.y = container.bounds.size.height
                container.addSubview(tabBarSnapshot)
            }
            
            let animOptions: UIViewAnimationOptions = transitionContext.isInteractive ? [UIViewAnimationOptions.curveLinear] : []
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: animOptions, animations: {
                fromVC.view.frame = fromRect
                self.tabBarSnapshot?.frame.origin.y = self.origin.y
                self.bannerSnapshot?.alpha = 1
            }) { (finished) in
                self.bannerSnapshot?.removeFromSuperview()
                self.tabBarSnapshot?.removeFromSuperview()
                if transitionContext.transitionWasCancelled {
                    transitionContext.completeTransition(false)
                } else {
                    transitionContext.completeTransition(true)
                }
            }
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionContext!.isInteractive ? 0.4 : 0.3
    }
    
}

class DiningModeInteractiveTransition: UIPercentDrivenInteractiveTransition {
    
    typealias ViewControllerPresentationBlock = ()->()
    enum TransitionMode {
        case present(ViewControllerPresentationBlock)
        case dismiss(ViewControllerPresentationBlock)
        
        func execute() {
            switch self {
            case .present(let block):
                block()
            case .dismiss(let block):
                block()
            }
        }
    }
    
    var transitionMode: TransitionMode
    var shouldComplete = false
    var lastProgress: CGFloat?
    
    weak var panGR: UIPanGestureRecognizer!

    
    init(mode: TransitionMode, view: UIView) {
        self.transitionMode = mode
        super.init()
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(DiningModeInteractiveTransition.handlePanGesture(_:)))
        view.addGestureRecognizer(panGR)
        self.panGR = panGR
    }
    
    func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view?.superview)
        
        //Represents the percentage of the transition that must be completed before allowing to complete.
        let percentThreshold: CGFloat = 0.2
        //Represents the difference between progress that is required to trigger the completion of the transition.
        let automaticOverrideThreshold: CGFloat = 0.03
        
        let screenHeight: CGFloat = UIScreen.main.bounds.size.height - (gestureRecognizer.view?.bounds.size.height ?? 0)
        let dragAmount: CGFloat = { switch self.transitionMode { case .dismiss: return screenHeight ; case .present: return -screenHeight} }()
        var progress: CGFloat = translation.y / dragAmount
        
        progress = fmax(progress, 0)
        progress = fmin(progress, 1)
        
        switch gestureRecognizer.state {
        case .began:
            self.transitionMode.execute()
        case .changed:
            guard let lastProgress = lastProgress else {return}
            
            // When swiping back
            if lastProgress > progress {
                shouldComplete = false
                // When swiping quick to the right
            } else if progress > lastProgress + automaticOverrideThreshold {
                shouldComplete = true
            } else {
                // Normal behavior
                shouldComplete = progress > percentThreshold
            }
            self.update(progress)
            
        case .ended, .cancelled:
            if gestureRecognizer.state == .cancelled || self.shouldComplete == false {
                self.cancel()
            } else {
                self.finish()
            }
            
        default:
            break
        }
        
        lastProgress = progress
    }

}


