//
//  PageSlider.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 10.07.25.
//

import CMPlatform
import SwiftUI


public protocol PageInfoProvider: PlatformViewController {
    var pageContents: [CMView] { get }
}


public protocol PageSliderDelegate: AnyObject {
    var numPages: Int { get }
    func pageInfoProvider(at index: Int) -> PageInfoProvider
}


class PageSliderView: PlatformView {
    weak var owner: PageSliderViewController!
#if os(iOS)
    private let panGestureRecognizer = UIPanGestureRecognizer()
    private let panDynamicAnimator = UIDynamicAnimator()
    
    private let testView = PlatformView()
#endif
    
    
    public var pages: [PageInfoProvider] = [] {
        didSet {
            setCurrentPage(pages.first)
        }
    }
    private var currentViewController: PageInfoProvider?
    
    private func setCurrentPage(_ page: PageInfoProvider?) {
        // Remove old controller
        if let currentViewController {
            // Reset state of every element
            let elements = currentViewController.pageContents
            for element in elements {
                element.transform = .identity
                element.alpha = 1
            }
            
            currentViewController.willMove(toParent: nil)
            currentViewController.view.removeFromSuperview()
            currentViewController.removeFromParent()
        }
        
        // Add new controller
        currentViewController = page
        if let currentViewController {
            owner.addChild(currentViewController)
            addSubview(currentViewController.view)
            currentViewController.didMove(toParent: owner)
            
            currentViewController.view.frame = bounds
            
            
            currentViewController.view.alpha = 0
            UIView.animate(withDuration: 0.25) {
                currentViewController.view.alpha = 1
            }
        }
    }
    
    
    override func setupLayout() {
#if os(iOS)
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture))
        
        addGestureRecognizer(panGestureRecognizer)
        
        testView.backgroundColor = .red.withAlphaComponent(0.05)
        testView.frame = .init(x: 0, y: 0, width: 140, height: 140)
        testView.layer.cornerRadius = 70
        testView.alpha = 0
        addSubview(testView)
#endif
        //
    }
    
    
    private var startLocation: CGPoint?
    
    
    struct DragRecord {
        let time: TimeInterval
        let velocity: CGPoint
    }
    var dragRecords: [DragRecord] = []
}


// MARK: - Swipe

#if os(iOS)

extension PageSliderView {
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let state = gestureRecognizer.state
        let location = gestureRecognizer.location(in: self)
        
        // Drop old records
        let recordThreshold: CGFloat = 0.05
        let now = CACurrentMediaTime()
        dragRecords.removeAll { now - $0.time > recordThreshold }
        
        let distanceThreshold = frame.height / 2
        
        let weightSpeed: CGFloat = 1.0
        let influence: CGFloat = 0.3
        
        testView.center = location
        if state == .began {
            startLocation = location
        }
        else if state == .changed {
            let velocity = gestureRecognizer.velocity(in: self)
            let speed = velocity.length
            if speed > 0.1 {
                dragRecords.append(.init(time: now, velocity: velocity))
            }
            
            if let startLocation, let currentViewController {
                let contents = currentViewController.pageContents
                let numContents = contents.count
                if numContents > 0 {
                    let delta = location - startLocation
                    
                    for (index, content) in contents.enumerated() {
                        let currentIndex: Int
                        if delta.y < 0 {
                            currentIndex = index
                        }
                        else {
                            currentIndex = numContents - 1 - index
                        }
                        
                        let weight: CGFloat = (1 * weightSpeed) / (1 + CGFloat(currentIndex) * influence)
                        
                        
                        let yDistance: CGFloat = {
                            let value = delta.y * weight
                            if value > 0 {
                                return min(distanceThreshold, value)
                            }
                            else {
                                return max(-distanceThreshold, value)
                            }
                        }()
                        let progress: CGFloat = min(1, 1 / distanceThreshold * abs(yDistance))
                        
                        content.transform = .init(translationX: 0, y: distanceThreshold * progress * (delta.y > 0 ? 1 : -1))
                        content.alpha = max(0, 1 - progress)
                    }
                    
                    //currentViewController.view.frame = bounds
                }
            }
        }
        else if state == .ended {
            let delta: CGPoint = {
                guard let startLocation else {
                    return .zero
                }
                
                return (location - startLocation)
            }()
            let deltaSign = delta.y >= 0
            
            let totalDistance = delta.y
            
            // Calculate velocity
            var accumulatedVelocity: CGPoint = .zero
            for record in dragRecords {
                // Oldest records have the most weight, because latest records can be accidential
                let weight = CGFloat(now - record.time) / recordThreshold
                accumulatedVelocity = accumulatedVelocity + record.velocity * weight
            }
            accumulatedVelocity = accumulatedVelocity / CGFloat(dragRecords.count)
            
            // Animate the bubble
            //let speed = accumulatedVelocity.y
            let speed = accumulatedVelocity.length
            if speed > 0 {
                let direction = accumulatedVelocity.normalized()
                let curveIntegral: CGFloat = 0.75 // For easeOutCubic
                let duration: CGFloat = 0.35
                //let duration: CGFloat = (frame.height - abs(location.y - (startLocation?.y ?? 0))) / speed
                let distance = speed * duration * curveIntegral
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                    let center = self.testView.center
                    self.testView.center = center + direction * distance
                }
            }
            
            
            let outOfMinimalThreshold = abs(totalDistance) > (distanceThreshold)
            //print("\(totalDistance) -> \(distanceThreshold)")
            let fastEnoughToSwipe = abs(totalDistance) > (distanceThreshold * 1 / 8) && speed > 300
            if outOfMinimalThreshold || fastEnoughToSwipe {
                if let itemIndex = pages.firstIndex(where: { $0 === currentViewController }) {
                    let nextIndex = (itemIndex + 1) % pages.count
                    
                    let curveIntegral: CGFloat = 0.75 // For easeOutCubic
                    let duration: CGFloat = 0.25
                    //let duration: CGFloat = (frame.height - abs(location.y - (startLocation?.y ?? 0))) / speed
                    let distance = speed * duration * curveIntegral
                    
                    if let currentViewController {
                        let contents = currentViewController.pageContents
                        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                            let numContents = contents.count
                            for (index, content) in contents.enumerated() {
                                let currentIndex: Int
                                if accumulatedVelocity.y < 0 {
                                    currentIndex = index
                                }
                                else {
                                    currentIndex = numContents - 1 - index
                                }
                                let weight: CGFloat = (1 * weightSpeed) / (1 + CGFloat(currentIndex) * influence)
                                
                                //content.transform = .identity
                                //content.alpha = 1
                                
                                //content.transform = .init(translationX: 0, y: distanceThreshold * (totalDistance > 0 ? 1 : -1))
                                //content.transform = .init(translationX: 0, y: totalDistance + (totalDistance > 0 ? 1 : -1) * speed * 0.25)
                                //content.transform = .init(translationX: 0, y: totalDistance + (totalDistance > 0 ? 1 : -1) * distance * weight)
                                content.transform = .init(translationX: 0, y: distanceThreshold * (totalDistance > 0 ? 1 : -1) * weight)
                                content.alpha = 0
                            }
                        } completion: { finished in
                            self.setCurrentPage(self.pages[nextIndex])
                        }
                    }
                }
            }
            else {
                if let currentViewController {
                    let contents = currentViewController.pageContents
                    UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
                        for content in contents {
                            content.transform = .identity
                            content.alpha = 1
                        }
                    } completion: { finished in
                        //
                    }
                }
            }
            
            // Drop all records
            dragRecords.removeAll()
        }
    }
}

#endif


public class PageSliderViewController: PlatformViewController {
    let pageSliderView = PageSliderView()
    
    public override func setupLayout() {
        pageSliderView.owner = self
        view = pageSliderView
        
        pageSliderView.pages = {
            let testScreen1 = TestScreen1()
            let testScreen2 = TestScreen2()
            return [testScreen1, testScreen2]
        }()
        
    }
}


#if os(iOS)

public struct PageSlider: UIViewControllerRepresentable {
    public init() {
        //
    }
    
    public func makeUIViewController(context: Context) -> PageSliderViewController {
        let vc = PageSliderViewController()
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: PageSliderViewController, context: Context) {
        //
    }
}

#elseif os(macOS)

public struct PageSlider: NSViewControllerRepresentable {
    public init() {
        //
    }
    
    public func makeNSViewController(context: Context) -> PageSliderViewController {
        let vc = PageSliderViewController()
        return vc
    }
    
    public func updateNSViewController(_ nsViewController: PageSliderViewController, context: Context) {
        //
    }
}

#endif


@MainActor
func makeLabel(_ text: String, _ size: CGFloat = 32) -> CMView {
    let label1 = UILabel()
    
    label1.numberOfLines = 0
    label1.textAlignment = .center
    label1.font = .init(
        descriptor: .init(
            fontAttributes: [
                .family: "Savoye LET",
                //.traits: [
                //    UIFontDescriptor.TraitKey.weight: UIFont.Weight.bold
                //]
            ]
        ),
        size: size
    )
    label1.text = text
    label1.sizeToFit()
    
    return label1
}


class TestScreen1: PlatformViewController, PageInfoProvider {
    // Defining New Luxury
    // https://www.design.studio/collection/defining-new-luxury
    
    let label1 = makeLabel("Branding Unicorns", 56)
    let label2 = makeLabel("Defining New Luxury", 42)
    
    
    var pageContents: [CMView] {
        [label1, label2]
    }
    
    
    override func setupLayout() {
        view.addSubview(label1)
        view.addSubview(label2)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let spacing: CGFloat = 20
        
        var position = view.center
        position.y -= 50
        
        // Label 1
        label1.center = position
        position.y += label1.frame.height / 2
        
        // Label 2
        position.y += label2.frame.height / 2 + spacing
        label2.center = position
        position.y += label2.frame.height / 2
    }
}


class TestScreen2: PlatformViewController, PageInfoProvider {
    let label1 = makeLabel("Test Screen 1", 56)
    let label2 = makeLabel("String interpolations are string literals that evaluate any included expressions and convert the results to string form. String interpolations give you an easy way to build a string from multiple pieces. Wrap each expression in a string interpolation in parentheses, prefixed by a backslash.", 32)
    let label3 = makeLabel("Sleek and simple", 42)
    
    
    var pageContents: [CMView] {
        [label1, label2, label3]
    }
    
    
    override func setupLayout() {
        view.addSubview(label1)
        view.addSubview(label2)
        view.addSubview(label3)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let spacing: CGFloat = 20
        
        var position = view.center
        position.y -= 200
        
        // Label 1
        label1.center = position
        position.y += label1.frame.height / 2
        
        // Label 2
        label2.bounds.size = label2.sizeThatFits(.init(width: view.frame.width - 40, height: 1000))
        position.y += label2.frame.height / 2 + spacing
        label2.center = position
        position.y += label2.frame.height / 2
        
        // Label 3
        position.y += label3.frame.height / 2 + spacing
        label3.center = position
        position.y += label3.frame.height / 2
    }
}


@available(iOS 17.0, *)
#Preview {
    //TestScreen1()
    //TestScreen2()
    
    PageSlider()
}
