//
//  LiquidSwipeContainerController.swift
//  liquid-swipe
//
//  Created by Anton Skopin on 28/12/2018.
//  Copyright © 2018 cuberto. All rights reserved.
//

import UIKit
import pop

public protocol LiquidSwipeContainerDataSource {
    func numberOfControllersInLiquidSwipeContainer(_ liquidSwipeContainer: LiquidSwipeContainerController) -> Int
    func liquidSwipeContainer(_ liquidSwipeContainer: LiquidSwipeContainerController, viewControllerAtIndex index: Int) -> UIViewController
}

public protocol LiquidSwipeContainerDelegate {
    func liquidSwipeContainer(_ liquidSwipeContainer: LiquidSwipeContainerController, willTransitionTo: UIViewController)
    func liquidSwipeContainer(_ liquidSwipeContainer: LiquidSwipeContainerController, didFinishTransitionTo: UIViewController, transitionCompleted: Bool)
}

open class LiquidSwipeContainerController: UIViewController {
    
    public var datasource: LiquidSwipeContainerDataSource? {
        didSet {
            configureInitialState()
        }
    }
    public var delegate: LiquidSwipeContainerDelegate?
    public private(set) var currentPageIndex: Int = 0
    private var currentPage: UIView? {
        return currentViewController?.view
    }
    private var currentViewController: UIViewController?
    private var nextViewController: UIViewController?
    private var previousViewController: UIViewController?
    private var btnNext: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.setImage(UIImage(named: "btnNext.png", in: Bundle.resourseBundle, compatibleWith: nil), for: .normal)
        return button
    }()
    
    private var initialHorRadius: CGFloat = 48.0
    private var maxHorRadius: CGFloat {
        return view.bounds.width * 0.8
    }
    
    private var initialVertRadius: CGFloat = 82.0
    private var maxVertRadius: CGFloat {
        return view.bounds.height * 0.9
    }
    private var initialSideWidth: CGFloat = 15.0
    private var initialWaveCenter: CGFloat  {
        return view.bounds.height * 0.7167487685
    }
    private var animationStartTime: CFTimeInterval?
    private var animating: Bool = false
    private var duration: CFTimeInterval = 0.8
    
    private var rightEdgeGesture = UIScreenEdgePanGestureRecognizer()
    private var leftEdgeGesture = UIScreenEdgePanGestureRecognizer()
    
    private var csBtnNextLeading: NSLayoutConstraint?
    private var csBtnNextCenterY: NSLayoutConstraint?
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return currentViewController?.preferredStatusBarStyle ?? .default
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        configureBtnNext()
        configureGestures()
        configureInitialState()
    }
    
    private func configureBtnNext() {
        view.addSubview(btnNext)
        csBtnNextLeading = btnNext.leadingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(initialHorRadius + initialSideWidth) + 8.0)
        csBtnNextLeading?.isActive = true
        csBtnNextCenterY = btnNext.centerYAnchor.constraint(equalTo: view.topAnchor, constant: initialWaveCenter)
        csBtnNextCenterY?.isActive = true
        btnNext.addTarget(self, action: #selector(btnTapped(_:)), for: .touchUpInside)
    }
    
    private func configureGestures() {
        rightEdgeGesture.addTarget(self, action: #selector(rightEdgePan))
        rightEdgeGesture.edges = .right
        view.addGestureRecognizer(rightEdgeGesture)
        
        leftEdgeGesture.addTarget(self, action: #selector(leftEdgePan))
        leftEdgeGesture.edges = .left
        view.addGestureRecognizer(leftEdgeGesture)
        leftEdgeGesture.isEnabled = false
    }
    
    private func animate(view: UIView, forProgress progress: CGFloat, waveCenterY: CGFloat? = nil) {
        guard let mask = view.layer.mask as? WaveLayer else {
            return
        }
        if let centerY = waveCenterY {
            mask.waveCenterY = centerY
            csBtnNextCenterY?.constant = centerY
        }
        btnNext.alpha = btnAlpha(forProgress: progress)
        mask.sideWidth = sideWidth(forProgress: progress)
        mask.waveHorRadius = waveHorRadius(forProgress: progress)
        mask.waveVertRadius = waveVertRadius(forProgress: progress)
        csBtnNextLeading?.constant = -(mask.waveHorRadius + mask.sideWidth - 8.0)
        mask.updatePath()
        
        self.btnNext.layoutIfNeeded()
    }
    
    private func animateBack(view: UIView, forProgress progress: CGFloat, waveCenterY: CGFloat? = nil) {
        guard let mask = view.layer.mask as? WaveLayer else {
            return
        }
        if let centerY = waveCenterY {
            mask.waveCenterY = centerY
        }
        mask.sideWidth = sideWidth(forProgress: progress)
        mask.waveHorRadius = waveHorRadiusBack(forProgress: progress)
        mask.waveVertRadius = waveVertRadius(forProgress: progress)
        mask.updatePath()
        self.btnNext.layoutIfNeeded()
    }
    
    
    private var shouldFinish: Bool = false
    private var shouldCancel: Bool = false
    private var animationProgress: CGFloat = 0.0
    @objc private func rightEdgePan(_ sender: UIPanGestureRecognizer) {
        guard !animating else {
            return
        }
        if sender.state == .began {
            shouldCancel = false
            shouldFinish = false
            animating = true
            if let viewController = nextViewController {
                delegate?.liquidSwipeContainer(self, willTransitionTo: viewController)
            }
            let animation = POPCustomAnimation {[weak sender] (target, animation) -> Bool in
                guard let gesture = sender,
                      let view = target as? UIView,
                      let mask = view.layer.mask as? WaveLayer,
                      let time = animation?.elapsedTime else {
                        if let viewController = self.nextViewController {
                            self.delegate?.liquidSwipeContainer(self, didFinishTransitionTo: viewController, transitionCompleted: false)
                        }
                    return false
                }
                let speed: CGFloat = 2000
                let direction: CGFloat = (gesture.location(in: view).y - mask.waveCenterY).sign == .plus ? 1 : -1
                let distance = min(CGFloat(time) * speed, abs(mask.waveCenterY - gesture.location(in: view).y))
                let centerY = mask.waveCenterY + distance * direction
                let change = -gesture.translation(in: view).x
                let maxChange: CGFloat = self.view.bounds.width * (1.0/0.45)
                if !(self.shouldFinish || self.shouldCancel) {
                    let progress: CGFloat = min(1.0, max(0, change / maxChange))
                    self.animate(view: view, forProgress: progress, waveCenterY: centerY)
                    switch gesture.state {
                    case .began, .changed:
                        return true
                    default:
                        if progress >= 0.15 {
                            self.shouldFinish = true
                            self.shouldCancel = false
                            self.animationStartTime = CACurrentMediaTime() - CFTimeInterval(CGFloat(self.duration) * progress)
                        } else {
                            self.shouldFinish = false
                            self.shouldCancel = true
                            self.animationProgress = progress
                            self.animationStartTime = CACurrentMediaTime()
                        }
                    }
                }
                let cTime = (animation?.currentTime ?? CACurrentMediaTime()) - (self.animationStartTime ?? CACurrentMediaTime())
                if self.shouldFinish {
                    let progress = CGFloat(cTime/self.duration)
                    self.animate(view: view, forProgress: progress)
                    self.animating = progress <= 1.0
                    return self.animating
                } else if self.shouldCancel {
                    let progress = self.animationProgress - CGFloat(cTime/self.duration)
                    let direction: CGFloat = (self.initialWaveCenter - mask.waveCenterY).sign == .plus ? 1 : -1
                    let distance = min(CGFloat(time) * speed, abs(self.initialWaveCenter - mask.waveCenterY))
                    let centerY = mask.waveCenterY + distance * direction
                    self.animate(view: view, forProgress: progress, waveCenterY: centerY)
                    self.animating = progress >= 0.0 || abs(self.initialWaveCenter - mask.waveCenterY) > 0.01
                    return self.animating
                } else {
                    return false
                }
            }
            animation?.completionBlock = { (animation, isFinished) in
                self.animating = false
                if self.shouldFinish {
                    self.showNextPage()
                }
                if self.shouldCancel,
                    let viewController = self.nextViewController {
                        self.delegate?.liquidSwipeContainer(self, didFinishTransitionTo: viewController, transitionCompleted: false)
                }
            }
            currentPage?.pop_add(animation, forKey: "animation")
        }
    }
    
    @objc private func leftEdgePan(_ sender: UIPanGestureRecognizer) {
        guard !animating else {
            return
        }
        if sender.state == .began {
            shouldCancel = false
            shouldFinish = false
            animating = true
            previousViewController?.view.isHidden = false
            if let viewController = previousViewController {
                delegate?.liquidSwipeContainer(self, willTransitionTo: viewController)
            }
            let previousViewAnimation = POPCustomAnimation {[weak sender] (target, animation) -> Bool in
                guard let gesture = sender,
                    let view = target as? UIView,
                    let mask = view.layer.mask as? WaveLayer,
                    let time = animation?.elapsedTime else {
                        if let nextViewController = self.nextViewController {
                            self.delegate?.liquidSwipeContainer(self, didFinishTransitionTo: nextViewController, transitionCompleted: false)
                        }
                        return false
                }
                let speed: CGFloat = 2000
                let direction: CGFloat = (gesture.location(in: view).y - mask.waveCenterY).sign == .plus ? 1 : -1
                let distance = min(CGFloat(time) * speed, abs(mask.waveCenterY - gesture.location(in: view).y))
                let centerY = mask.waveCenterY + distance * direction
                let change = gesture.translation(in: view).x
                let maxChange: CGFloat = self.view.bounds.width
                if !(self.shouldFinish || self.shouldCancel) {
                    let progress: CGFloat = min(1.0, max(0, 1 - change / maxChange))
                    self.animateBack(view: view, forProgress: progress, waveCenterY: centerY)
                    switch gesture.state {
                    case .began, .changed:
                        return true
                    default:
                        if progress <= 0.6 {
                            self.shouldFinish = true
                            self.shouldCancel = false
                            self.animationProgress = progress
                            self.animationStartTime = CACurrentMediaTime()
                        } else {
                            self.shouldFinish = false
                            self.shouldCancel = true
                            self.animationStartTime = CACurrentMediaTime() - CFTimeInterval(CGFloat(self.duration) * progress)
                        }
                    }
                }
                let cTime = (animation?.currentTime ?? CACurrentMediaTime()) - (self.animationStartTime ?? CACurrentMediaTime())
                if self.shouldFinish {
                    let progress = self.animationProgress - CGFloat(cTime/self.duration)
                    let direction: CGFloat = (self.initialWaveCenter - mask.waveCenterY).sign == .plus ? 1 : -1
                    let distance = min(CGFloat(time) * speed, abs(self.initialWaveCenter - mask.waveCenterY))
                    let centerY = mask.waveCenterY + distance * direction
                    self.animateBack(view: view, forProgress: progress, waveCenterY: centerY)
                    self.animating = progress >= 0 || abs(self.initialWaveCenter - mask.waveCenterY) > 0.01
                    return self.animating
                } else if self.shouldCancel {
                    let progress = CGFloat(cTime/self.duration)
                    self.animateBack(view: view, forProgress: progress)
                    self.animating = progress <= 1.0
                    return self.animating
                } else {
                    return false
                }
            }
            previousViewAnimation?.completionBlock = { (animation, isFinished) in
                self.animating = false
                if self.shouldFinish {
                    self.showPreviousPage()
                }
                if self.shouldCancel,
                    let viewController = self.previousViewController {
                    self.delegate?.liquidSwipeContainer(self, didFinishTransitionTo: viewController, transitionCompleted: false)
                }
            }
            previousViewController?.view.pop_add(previousViewAnimation, forKey: "animation")
            guard nextViewController != nil else {
                return
            }
            let startTime = CACurrentMediaTime()
            var cancelTime: CFTimeInterval?
            let currentViewAnimation = POPCustomAnimation {[weak sender] (target, animation) -> Bool in
                guard let gesture = sender,
                    let view = target as? UIView,
                    let mask = view.layer.mask as? WaveLayer,
                    let time = animation?.currentTime else {
                        return false
                }
                let duration: CGFloat = 0.3
                if !self.shouldCancel {
                    let progress: CGFloat = 1.0 - min(1.0, max(0, CGFloat(time - startTime) / duration))
                    mask.sideWidth = self.initialSideWidth * progress
                    mask.waveHorRadius = self.initialHorRadius * progress
                    self.csBtnNextLeading?.constant = -(mask.waveHorRadius + mask.sideWidth - 8.0)
                    self.btnNext.transform = CGAffineTransform(scaleX: progress, y: progress)
                    mask.updatePath()
                    switch gesture.state {
                    case .began, .changed:
                        return true
                    default:
                        break
                    }
                }
                if self.shouldFinish {
                    return self.animating
                } else if self.shouldCancel {
                    if cancelTime == nil {
                        cancelTime = CACurrentMediaTime()
                    }
                    let progress = min(1.0, max(0, CGFloat(time - (cancelTime ?? CACurrentMediaTime())) / duration))
                    mask.sideWidth = self.initialSideWidth * progress
                    mask.waveHorRadius = self.initialHorRadius * progress
                    self.csBtnNextLeading?.constant = -(mask.waveHorRadius + mask.sideWidth - 8.0)
                    self.btnNext.transform = CGAffineTransform(scaleX: progress, y: progress)
                    self.btnNext.layoutIfNeeded()
                    mask.updatePath()
                    return progress < 1.0
                } else {
                    return self.animating
                }
            }
            currentPage?.pop_add(currentViewAnimation, forKey: "animation")
        }
    }
    
    private func layoutPageView(_ page: UIView) {
        page.translatesAutoresizingMaskIntoConstraints = false
        page.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        page.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        page.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        page.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    }
    
    private func clearSubviews() {
        if previousViewController?.view.superview == view {
           previousViewController?.view.removeFromSuperview()
        }
        previousViewController = nil
        if currentViewController?.view.superview == view {
            currentViewController?.view.removeFromSuperview()
        }
        currentViewController = nil
        if nextViewController?.view.superview == view {
            nextViewController?.view.removeFromSuperview()
        }
        nextViewController = nil
    }
    
    private func configureInitialState() {
        clearSubviews()
        guard let datasource = datasource else {
            return
        }
        let pagesCount = datasource.numberOfControllersInLiquidSwipeContainer(self)
        guard pagesCount > 0 else {
            return
        }
        let firstVC = datasource.liquidSwipeContainer(self, viewControllerAtIndex: 0)
        guard let firstPage = firstVC.view else {
            return
        }
        view.addSubview(firstPage)
        layoutPageView(firstPage)

        if pagesCount > 1 {
            let maskLayer = WaveLayer(waveCenterY: initialWaveCenter, waveHorRadius: initialHorRadius, waveVertRadius: initialVertRadius, sideWidth: initialSideWidth)
            apply(mask: maskLayer, on: firstPage)
        }
        currentViewController = firstVC
        configureNextPage()
        view.bringSubviewToFront(btnNext)
    }
    
    private func showNextPage() {
        previousViewController?.view.removeFromSuperview()
        currentPage?.isHidden = true
        previousViewController = currentViewController
        currentViewController = nextViewController
        currentPageIndex += 1
        leftEdgeGesture.isEnabled = true
        let maskLayer = WaveLayer(waveCenterY: initialWaveCenter,
                                  waveHorRadius: 0,
                                  waveVertRadius: initialVertRadius,
                                  sideWidth: 0)
        if let currentPage = currentPage {
            apply(mask: maskLayer, on: currentPage)
        }
        configureNextPage()
        setNeedsStatusBarAppearanceUpdate()
        guard nextViewController != nil else {
            btnNext.isHidden = true
            rightEdgeGesture.isEnabled = false
            if let viewController = currentViewController {
                delegate?.liquidSwipeContainer(self, didFinishTransitionTo: viewController, transitionCompleted: true)
            }
            return
        }

        let startTime = CACurrentMediaTime()
        let duration: CFTimeInterval = 0.3
        csBtnNextCenterY?.constant = initialWaveCenter
        let animation = POPCustomAnimation {(target, animation) -> Bool in
            guard let view = target as? UIView,
                let mask = view.layer.mask as? WaveLayer,
                let time = animation?.currentTime else {
                    return false
            }
            let cTime = time - startTime
            let progress = CGFloat(cTime/duration)
            mask.waveHorRadius = self.initialHorRadius * progress
            mask.waveVertRadius = self.initialVertRadius
            mask.sideWidth = self.initialSideWidth * progress
            mask.updatePath()
            self.btnNext.alpha = progress
            self.csBtnNextLeading?.constant = -(mask.waveHorRadius + mask.sideWidth - 8.0)
            self.btnNext.transform = CGAffineTransform(scaleX: progress, y: progress)
            self.btnNext.layoutIfNeeded()
            return progress <= 1.0
        }
        animation?.completionBlock = { (_,_) in
            if let viewController = self.currentViewController {
                self.delegate?.liquidSwipeContainer(self, didFinishTransitionTo: viewController, transitionCompleted: true)
            }
        }
        currentPage?.pop_add(animation, forKey: "animation")
    }
    
    private func showPreviousPage() {
        nextViewController?.view.removeFromSuperview()
        nextViewController = currentViewController
        currentViewController = previousViewController
        currentPageIndex -= 1
        btnNext.isHidden = false
        rightEdgeGesture.isEnabled = true
        let maskLayer = WaveLayer(waveCenterY: initialWaveCenter,
                                  waveHorRadius: 0,
                                  waveVertRadius: maxVertRadius,
                                  sideWidth: view.bounds.width)
        configurePreviousPage()
        setNeedsStatusBarAppearanceUpdate()
        if let prevPage = previousViewController?.view {
            apply(mask: maskLayer, on: prevPage)
        } else {
            leftEdgeGesture.isEnabled = false
        }
        let startTime = CACurrentMediaTime()
        let duration: CFTimeInterval = 0.3
        csBtnNextCenterY?.constant = initialWaveCenter
        view.bringSubviewToFront(btnNext)
        let animation = POPCustomAnimation {(target, animation) -> Bool in
            guard let view = target as? UIView,
                let mask = view.layer.mask as? WaveLayer,
                let time = animation?.currentTime else {
                    return false
            }
            let cTime = time - startTime
            let progress = CGFloat(cTime/duration)
            self.btnNext.alpha = progress
            self.csBtnNextLeading?.constant = -(mask.waveHorRadius + mask.sideWidth - 8.0)
            self.btnNext.transform = CGAffineTransform(scaleX: progress, y: progress)
            self.btnNext.layoutIfNeeded()
            return progress <= 1.0
        }
        animation?.completionBlock = { (_,_) in
            if let viewController = self.currentViewController {
                self.delegate?.liquidSwipeContainer(self, didFinishTransitionTo: viewController, transitionCompleted: true)
            }
        }
        currentPage?.pop_add(animation, forKey: "animation")
    }
    
    private func configureNextPage() {
        guard let datasource = datasource else {
            return
        }
        let pagesCount = datasource.numberOfControllersInLiquidSwipeContainer(self)
        guard pagesCount > currentPageIndex + 1 else {
            nextViewController = nil
            rightEdgeGesture.isEnabled = false
            return
        }
        let nextVC = datasource.liquidSwipeContainer(self, viewControllerAtIndex: currentPageIndex + 1)
        nextViewController = nextVC
        guard let page = nextVC.view else {
            return
        }
        if let currentPage = currentPage {
            view.insertSubview(page, belowSubview: currentPage)
        } else {
            view.addSubview(page)
        }
        layoutPageView(page)
    }
    
    private func configurePreviousPage() {
        guard let datasource = datasource else {
            return
        }
        let pagesCount = datasource.numberOfControllersInLiquidSwipeContainer(self)
        guard currentPageIndex > 0 && pagesCount > 0 else {
            previousViewController = nil
            leftEdgeGesture.isEnabled = false
            return
        }
        let previousVC = datasource.liquidSwipeContainer(self, viewControllerAtIndex: currentPageIndex - 1)
        previousViewController = previousVC
        guard let page = previousVC.view else {
            return
        }
        if let currentPage = currentPage {
            view.insertSubview(page, aboveSubview: currentPage)
        } else {
            view.addSubview(page)
        }
        layoutPageView(page)
        page.isHidden = true
    }
    
    private func apply(mask: WaveLayer, on view: UIView) {
        mask.frame = view.bounds
        mask.updatePath()
        view.layer.mask = mask
    }
    
    @objc private func btnTapped(_ sender: AnyObject) {
        animationStartTime = CACurrentMediaTime()
        guard !animating else {
            return
        }
        animating = true
        if let viewController = nextViewController {
            delegate?.liquidSwipeContainer(self, willTransitionTo: viewController)
        }
        let animation = POPCustomAnimation {(target, animation) -> Bool in
            guard let view = target as? UIView,
                let time = animation?.currentTime else {
                    return false
            }
            let cTime = time - (self.animationStartTime ?? CACurrentMediaTime())
            let progress = CGFloat(cTime/self.duration)
            self.animate(view: view, forProgress: progress)
            self.animating = progress <= 1.0
            return progress <= 1.0
        }
        animation?.completionBlock = { (animation, isFinished) in
            self.animating = false
            self.showNextPage()
        }
        currentPage?.pop_add(animation, forKey: "animation")
    }
}

//MARK: Animation helpers
private extension LiquidSwipeContainerController {
    
    private func btnAlpha(forProgress progress: CGFloat) -> CGFloat {
        let p1: CGFloat = 0.1
        let p2: CGFloat = 0.3
        if progress <= p1 {
            return 1.0
        }
        if progress >= p2 {
            return 0.0
        }
        return 1.0 - (progress - p1)/(p2-p1)
    }
    
    private func waveHorRadius(forProgress progress: CGFloat) -> CGFloat {
        if progress <= 0 {
            return initialHorRadius
        }
        if progress >= 1 {
            return 0
        }
        let p1: CGFloat = 0.4
        if progress <= p1 {
            return initialHorRadius + progress/p1*(maxHorRadius - initialHorRadius)
        }
        let t: CGFloat = (progress - p1)/(1.0 - p1)
        let A: CGFloat = maxHorRadius
        let r: CGFloat = 40
        let m: CGFloat = 9.8
        let beta: CGFloat = r/(2*m)
        let k: CGFloat = 50
        let omega0: CGFloat = k/m
        let omega: CGFloat = pow(-pow(beta,2)+pow(omega0,2), 0.5)
        
        return A * exp(-beta * t) * cos( omega * t)
    }
    
    private func waveHorRadiusBack(forProgress progress: CGFloat) -> CGFloat {
        if progress <= 0 {
            return initialHorRadius
        }
        if progress >= 1 {
            return 0
        }
        let p1: CGFloat = 0.4
        if progress <= p1 {
            return initialHorRadius + progress/p1*initialHorRadius
        }
        let t: CGFloat = (progress - p1)/(1.0 - p1)
        let A: CGFloat = 2 * initialHorRadius
        let r: CGFloat = 40
        let m: CGFloat = 9.8
        let beta: CGFloat = r/(2*m)
        let k: CGFloat = 50
        let omega0: CGFloat = k/m
        let omega: CGFloat = pow(-pow(beta,2)+pow(omega0,2), 0.5)
        
        return A * exp(-beta * t) * cos( omega * t)
    }
    
    private func waveVertRadius(forProgress progress: CGFloat) -> CGFloat {
        let p1: CGFloat = 0.4
        if progress <= 0 {
            return initialVertRadius
        }
        if progress >= p1 {
            return maxVertRadius
        }
        return initialVertRadius + (maxVertRadius - initialVertRadius) * progress/p1
    }
    
    private func sideWidth(forProgress progress: CGFloat) -> CGFloat {
        let p1: CGFloat = 0.2
        let p2: CGFloat = 0.8
        if progress <= p1 {
            return initialSideWidth
        }
        if progress >= p2 {
            return view.bounds.width
        }
        return initialSideWidth + (view.bounds.width - initialSideWidth) * (progress - p1)/(p2 - p1)
    }
}
