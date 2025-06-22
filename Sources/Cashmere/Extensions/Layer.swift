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
public func getCurrentUIAnimationDuration() -> TimeInterval {
#if os(iOS)
    return UIView.inheritedAnimationDuration
#else
    return 0
#endif
}


@MainActor
public extension CALayer {
    var cgImage: CGImage? {
        let ref = contents as CFTypeRef
        if CFGetTypeID(ref) == CGImage.typeID {
            let image = contents as! CGImage
            return image
        }
        
        return nil
    }
    
    
    // Resizes image contents to fill available space
    func sizeToFillImage() {
        let layerBounds = bounds
        guard layerBounds.width > 0 && layerBounds.height > 0, let image = cgImage else {
            return
        }
        
        let rect: CGRect = {
            let imageSize = CGSize(width: image.width, height: image.height)
            let imageAspect = imageSize.width / imageSize.height
            let layerAspect = layerBounds.width / layerBounds.height
            if imageAspect > layerAspect {
                let aspect = layerAspect / imageAspect
                return CGRect(origin: .init(x: -(aspect - 1) / 2, y: 0), size: .init(width: aspect, height: 1))
            }
            else {
                let aspect = imageAspect / layerAspect
                return CGRect(origin: .init(x: 0, y: -(aspect - 1) / 2), size: .init(width: 1, height: aspect))
            }
        }()
        setContentsRectAnimatedIfNeeded(rect)
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
    
    
    func setContentsRectAnimatedIfNeeded(_ targetContentsRect: CGRect) {
        let animationKey = "contentsRect key"

        let duration = getCurrentUIAnimationDuration()
        guard duration > 0.01 else {
            CATransaction.withoutAnimations {
                contentsRect = targetContentsRect
            }
            return
        }
        
        let animation = CABasicAnimation(keyPath: "contentsRect")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        //animation.beginTime = beginTime
        animation.duration = duration
        animation.fromValue = presentation()?.contentsRect ?? contentsRect
        
        contentsRect = targetContentsRect
        
        animation.toValue = contentsRect
        //removeAnimation(forKey: animationKey)
        add(animation, forKey: animationKey)
    }
    
    
    func setPositionAnimatedIfNeeded(_ targetPosition: CGPoint) {
        let animationKey = "position key"
        //let beginTime: CFTimeInterval = animation(forKey: animationKey)?.beginTime ?? 0
        //if let animation = self.animation(forKey: animationKey) as? CABasicAnimation {
        //    print("Reuse position animation")
        //    position = targetPosition
        //    animation.toValue = position
        //    return
        //}
        
#if true
        let duration = getCurrentUIAnimationDuration()
        guard duration > 0.01 else {
            CATransaction.withoutAnimations {
                position = targetPosition
            }
            return
        }
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        //animation.beginTime = beginTime
        animation.duration = duration
        animation.fromValue = presentation()?.position ?? position
        
        position = targetPosition
        
        animation.toValue = position
        //removeAnimation(forKey: animationKey)
        add(animation, forKey: animationKey)
#else
        position = targetPosition
#endif
    }
    
    
    func setBoundsSizeAnimatedIfNeeded(_ targetSize: CGSize) {
        let animationKey = "bounds.size key"
        //let beginTime: CFTimeInterval = animation(forKey: animationKey)?.beginTime ?? 0
        //if let animation = self.animation(forKey: "bounds.size key") as? CABasicAnimation {
        //    print("Reuse bounds size animation")
        //    bounds.size = targetSize
        //    animation.toValue = bounds.size
        //    return
        //}
        
#if true
        let duration = getCurrentUIAnimationDuration()
        guard duration > 0.01 else {
            CATransaction.withoutAnimations {
                bounds.size = targetSize
            }
            return
        }
        
        let animation = CABasicAnimation(keyPath: "bounds.size")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        //animation.beginTime = beginTime
        animation.duration = duration
        animation.fromValue = presentation()?.bounds.size ?? bounds.size
        
        bounds.size = targetSize
        
        animation.toValue = bounds.size
        //removeAnimation(forKey: animationKey)
        add(animation, forKey: animationKey)
#else
        bounds.size = targetSize
#endif
    }
    
    
    func setTransformAnimatedIfNeeded(_ targetTransform: CATransform3D) {
        let animationKey = "transform key"
        //let beginTime: CFTimeInterval = animation(forKey: animationKey)?.beginTime ?? 0
        //if let animation = self.animation(forKey: "transform key") as? CABasicAnimation {
        //    print("Reuse transform animation")
        //    transform = targetTransform
        //    animation.toValue = targetTransform
        //}
        
        let duration = getCurrentUIAnimationDuration()
        guard duration > 0.01 else {
            CATransaction.withoutAnimations {
                transform = targetTransform
            }
            return
        }
        
        let animation = CABasicAnimation(keyPath: "transform")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        //animation.beginTime = beginTime
        animation.duration = duration
        animation.fromValue = presentation()?.transform ?? transform
        
        transform = targetTransform
        
        animation.toValue = targetTransform
        //removeAnimation(forKey: animationKey)
        add(animation, forKey: animationKey)
    }
    
}


@MainActor
public extension CAShapeLayer {
    func setPathAnimatedIfNeeded(_ targetPath: CGPath) {
        let animationKey = "path key"
        //let beginTime: CFTimeInterval = animation(forKey: animationKey)?.beginTime ?? 0
#if true
        let duration = getCurrentUIAnimationDuration()
        guard duration > 0.01 else {
            path = targetPath
            return
        }
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        //animation.beginTime = beginTime
        animation.duration = duration
        animation.fromValue = presentation()?.path ?? path
        
        path = targetPath
        
        animation.toValue = path
        //removeAnimation(forKey: animationKey)
        add(animation, forKey: animationKey)
#else
        path = targetPath
#endif
    }
    
}
