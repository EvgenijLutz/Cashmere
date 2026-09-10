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
    // TODO: isPerformingAnimation is actially private. Move it then to PlatformView?
    if CMView.CurrentAnimation.isPerforming {
        return NSAnimationContext.current.duration
    }
    
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
fileprivate extension CALayer {
    func apply(_ value: CAAnimation, forKey key: String) {
        removeAnimation(forKey: key)
        //setValue(value, forKey: key)
        add(value, forKey: key)
    }
    
    func performAnimatedIfNeeded<T>(_ value: T, keyPath: ReferenceWritableKeyPath<CALayer, T>, _ keyPathString: String) {
        let animationKey = keyPathString + " key"
        // TODO: 08.09.2026: Abandon getCurrentUIAnimationDuration and use isPerformingAnimation instead. Check getCurrentUIAnimationDuration only on view frame and bound change events
        let duration = getCurrentUIAnimationDuration()
        guard duration > 0.01 else {
            CATransaction.withoutAnimations {
                removeAnimation(forKey: animationKey)
                self[keyPath: keyPath] = value
            }
            return
        }
        
        let animation = CABasicAnimation(keyPath: keyPathString)
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        //animation.beginTime = beginTime
        animation.duration = duration
        animation.fromValue = presentation()?[keyPath: keyPath] ?? self[keyPath: keyPath]
        
        CATransaction.withoutAnimations {
            self[keyPath: keyPath] = value
        }
        
        animation.toValue = value
        apply(animation, forKey: animationKey)
    }
}


@MainActor
fileprivate extension CAShapeLayer {
    /// Same implementation as in ``CALayer.performAnimatedIfNeeded``
    func performAnimatedIfNeeded<T>(_ value: T, keyPath: ReferenceWritableKeyPath<CAShapeLayer, T>, _ keyPathString: String) {
        let animationKey = keyPathString + " key"
        let duration = getCurrentUIAnimationDuration()
        guard duration > 0.01 else {
            CATransaction.withoutAnimations {
                removeAnimation(forKey: animationKey)
                self[keyPath: keyPath] = value
            }
            return
        }
        
        let animation = CABasicAnimation(keyPath: keyPathString)
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        //animation.beginTime = beginTime
        animation.duration = duration
        animation.fromValue = presentation()?[keyPath: keyPath] ?? self[keyPath: keyPath]
        
        CATransaction.withoutAnimations {
            self[keyPath: keyPath] = value
        }
        
        animation.toValue = value
        apply(animation, forKey: animationKey)
    }
}



@MainActor
public extension CALayer {
    func setFrameAnimatedIfNeeded(_ targetFrame: CGRect) {
#if false
        performAnimatedIfNeeded(targetFrame, keyPath: \.frame, "frame")
#else
        //frame = targetframe
        //setPositionAnimatedIfNeeded(targetFrame.origin)
        setPositionAnimatedIfNeeded(.init(
            x: targetFrame.origin.x + targetFrame.size.width * anchorPoint.x,
            y: targetFrame.origin.y + targetFrame.size.height * anchorPoint.y
        ))
        
        setBoundsSizeAnimatedIfNeeded(targetFrame.size)
#endif
    }
    
    
    func setBoundsAnimatedIfNeeded(_ targetBounds: CGRect) {
        performAnimatedIfNeeded(targetBounds, keyPath: \.bounds, "bounds")
    }
    
    
    func setContentsRectAnimatedIfNeeded(_ targetContentsRect: CGRect) {
        performAnimatedIfNeeded(targetContentsRect, keyPath: \.contentsRect, "contentsRect")
    }
    
    
    func setPositionAnimatedIfNeeded(_ targetPosition: CGPoint) {
        performAnimatedIfNeeded(targetPosition, keyPath: \.position, "position")
    }
    
    
    func setBoundsSizeAnimatedIfNeeded(_ targetSize: CGSize) {
        performAnimatedIfNeeded(targetSize, keyPath: \.bounds.size, "bounds.size")
    }
    
    
    func setTransformAnimatedIfNeeded(_ targetTransform: CATransform3D) {
        performAnimatedIfNeeded(targetTransform, keyPath: \.transform, "transform")
    }
    
    
    func setOpacityAnimatedIfNeeded(_ targetOpacity: Float) {
        performAnimatedIfNeeded(targetOpacity, keyPath: \.opacity, "opacity")
    }
    
}


@MainActor
public extension CAShapeLayer {
    func setPathAnimatedIfNeeded(_ targetPath: CGPath) {
        performAnimatedIfNeeded(targetPath, keyPath: \.path, "path")
    }
    
}
