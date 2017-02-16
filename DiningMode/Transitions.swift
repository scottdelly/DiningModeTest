//
//  Transitions.swift
//  DiningMode
//
//  Created by Scott Delly on 2/15/17.
//  Copyright © 2017 OpenTable, Inc. All rights reserved.
//

import Foundation
import UIKit

extension MainTabBarController: UIViewControllerTransitioningDelegate {
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = self.transitionAnimator
        animator.origin = self.diningModeBanner!.frame.origin
//        animator.origin.y += self.diningModeBanner!.bounds.size.height
        return animator
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = self.transitionAnimator
        animator.origin = self.diningModeBanner!.frame.origin
//        animator.origin.y += self.diningModeBanner!.bounds.size.height
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
            
            toVC.view.frame = fromRect
            let container = transitionContext.containerView
            let bannerSnapshot = rootVC.diningModeBanner!.snapshotView(afterScreenUpdates: true)!
            bannerSnapshot.frame.origin = self.origin
            let tabBarSnapshot = rootVC.tabBar.snapshotView(afterScreenUpdates: true)!
            
            let belowBannerOriginY = self.origin.y + bannerSnapshot.bounds.size.height
            toVC.view.frame.origin = CGPoint(x: self.origin.x, y: belowBannerOriginY)

            toVC.view.clipsToBounds = false
            container.addSubview(rootVC.view)
            container.addSubview(toVC.view)
            container.addSubview(bannerSnapshot)
            container.addSubview(tabBarSnapshot)
            tabBarSnapshot.frame.origin.y = belowBannerOriginY
            let animOptions: UIViewAnimationOptions = transitionContext.isInteractive ? [UIViewAnimationOptions.curveLinear] : []
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: animOptions, animations: {
                toVC.view.frame = fromRect
                bannerSnapshot.frame.origin.y = fromRect.origin.y - bannerSnapshot.bounds.size.height
                tabBarSnapshot.frame.origin.y = tabBarSnapshot.superview!.bounds.size.height
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
            container.addSubview(rootVC.view)
            container.addSubview(fromVC.view)
            
            let bannerHeight: CGFloat
            if let bannerSnapshot = self.bannerSnapshot {
                bannerHeight = bannerSnapshot.bounds.size.height
                bannerSnapshot.frame.origin = CGPoint(x: self.origin.x, y: 0 - bannerHeight)
                container.addSubview(bannerSnapshot)
            } else {
                bannerHeight = 0
            }
            
            if let tabBarSnapshot = self.tabBarSnapshot {
                tabBarSnapshot.frame.origin.y = container.bounds.size.height
                container.addSubview(tabBarSnapshot)
            }
            
            let animOptions: UIViewAnimationOptions = transitionContext.isInteractive ? [UIViewAnimationOptions.curveLinear] : []
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: animOptions, animations: {
                fromVC.view.frame = fromRect
                self.tabBarSnapshot?.frame.origin.y = self.origin.y + bannerHeight
                self.bannerSnapshot?.frame.origin.y = self.origin.y
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
