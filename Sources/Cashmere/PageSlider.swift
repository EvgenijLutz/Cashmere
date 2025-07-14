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
#if os(iOS)
    private let panGestureRecognizer = UIPanGestureRecognizer()
    private let panDynamicAnimator = UIDynamicAnimator()
    
    private let testView = PlatformView()
#endif
    
    override func setupLayout() {
#if os(iOS)
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture))
        
        addGestureRecognizer(panGestureRecognizer)
        
        testView.backgroundColor = .red.withAlphaComponent(0.05)
        testView.frame = .init(x: 0, y: 0, width: 140, height: 140)
        testView.layer.cornerRadius = 70
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
        }
        else if state == .ended {
            // Calculate velocity
            var accumulatedVelocity: CGPoint = .zero
            for record in dragRecords {
                // Oldest records have the most weight, because latest records can be accidential
                let weight = CGFloat(now - record.time) / recordThreshold
                accumulatedVelocity = accumulatedVelocity + record.velocity * weight
            }
            accumulatedVelocity = accumulatedVelocity / CGFloat(dragRecords.count)
            
            // Check if we can
            let speed = accumulatedVelocity.length
            guard speed > 0.1 else {
                return
            }
            
            let duration: CGFloat = 0.35
            //let duration: CGFloat = (frame.height - abs(location.y - (startLocation?.y ?? 0))) / speed
            
            let direction = accumulatedVelocity.normalized()
            let curveIntegral: CGFloat = 0.75 // For easeOutCubic
            let distance = speed * duration * curveIntegral
            
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                let center = self.testView.center
                self.testView.center = center + direction * distance
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
        view = pageSliderView
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

#endif


@MainActor
func makeLabel(_ text: String, _ size: CGFloat = 32) -> UILabel {
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
        label2.frame.size = label2.sizeThatFits(.init(width: view.frame.width - 40, height: 1000))
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
    TestScreen1()
    //TestScreen2()
    //PageSliderView()
}
