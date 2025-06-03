//
//  Layer.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 03.06.25.
//

import CoreGraphics
import CMPlatform


@MainActor
public extension CATransaction {
    static func withoutAnimations(_ action: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        action()
        CATransaction.commit()
    }
}


@MainActor
public extension CALayer {
    func setFrameAnimatedIfNeeded(_ targetFrame: CGRect) {
#if false
        let duration = UIView.inheritedAnimationDuration
        guard duration > 0.01 else {
            frame = targetFrame
            return
        }
        
        let animation = CABasicAnimation(keyPath: "frame")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        animation.duration = duration
        animation.fromValue = presentation()?.frame ?? frame
        
        frame = targetFrame
        
        animation.toValue = frame
        add(animation, forKey: "frame key")
#else
        //frame = targetframe
        //setPositionAnimatedIfNeeded(targetFrame.origin)
        setPositionAnimatedIfNeeded(.init(
            x: targetFrame.origin.x + targetFrame.size.width / 2,
            y: targetFrame.origin.y + targetFrame.size.height / 2
        ))
        setBoundsSizeAnimatedIfNeeded(targetFrame.size)
#endif
    }
    
    
    func setPositionAnimatedIfNeeded(_ targetPosition: CGPoint) {
#if true
        let duration = UIView.inheritedAnimationDuration
        guard duration > 0.01 else {
            CATransaction.withoutAnimations {
                position = targetPosition
            }
            return
        }
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        animation.duration = duration
        animation.fromValue = presentation()?.position ?? position
        
        position = targetPosition
        
        animation.toValue = position
        add(animation, forKey: "position key")
#else
        position = targetPosition
#endif
    }
    
    
    func setBoundsSizeAnimatedIfNeeded(_ targetSize: CGSize) {
#if true
        let duration = UIView.inheritedAnimationDuration
        guard duration > 0.01 else {
            CATransaction.withoutAnimations {
                bounds.size = targetSize
            }
            return
        }
        
        let animation = CABasicAnimation(keyPath: "bounds.size")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        animation.duration = duration
        animation.fromValue = presentation()?.bounds.size ?? bounds.size
        
        bounds.size = targetSize
        
        animation.toValue = bounds.size
        add(animation, forKey: "bounds.size key")
#else
        bounds.size = targetSize
#endif
    }
    
    
    func setTransformAnimatedIfNeeded(_ targetTransform: CATransform3D) {
        let duration = UIView.inheritedAnimationDuration
        guard duration > 0.01 else {
            CATransaction.withoutAnimations {
                transform = targetTransform
            }
            return
        }
        
        let animation = CABasicAnimation(keyPath: "transform")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        animation.duration = duration
        animation.fromValue = presentation()?.transform ?? transform
        
        transform = targetTransform
        
        animation.toValue = targetTransform
        add(animation, forKey: "transform key")
    }
    
}


@MainActor
public extension CAShapeLayer {
    func setPathAnimatedIfNeeded(_ targetPath: CGPath) {
#if true
        let duration = UIView.inheritedAnimationDuration
        guard duration > 0.01 else {
            path = targetPath
            return
        }
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        animation.duration = duration
        animation.fromValue = presentation()?.path ?? path
        
        path = targetPath
        
        animation.toValue = path
        add(animation, forKey: "path key")
#else
        path = targetPath
#endif
    }
    
}
