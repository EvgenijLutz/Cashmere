//
//  PageSlider.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 10.07.25.
//

import CMPlatform


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
        testView.frame = .init(x: 0, y: 0, width: 100, height: 100)
        testView.layer.cornerRadius = 50
        addSubview(testView)
#endif
        //
    }
    
    
    private var startLocation: CGPoint?
}


// MARK: - Swipe

#if os(iOS)

extension PageSliderView {
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let state = gestureRecognizer.state
        let translation = gestureRecognizer.translation(in: self)
        let location = gestureRecognizer.location(in: self)
        let velocity = gestureRecognizer.velocity(in: self)
        //print("\(state.rawValue) \(translation) \(velocity)")
        
        testView.center = location
        if state == .began {
            startLocation = location
        }
        else if state == .changed {
            //
        }
        else if state == .ended {
            let time: CGFloat = 0.35
            UIView.animate(withDuration: time, delay: 0, options: .curveEaseOut) {
                var center = self.testView.center
                center.x += velocity.x * time
                center.y += velocity.y * time
                self.testView.center = center
            }
        }
    }
}

#endif


@available(iOS 17.0, *)
#Preview {
    PageSliderView()
}
