//
//  PlatformView.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 03.03.25.
//

import CMPlatform
import SwiftUI


@MainActor
fileprivate func getCurrentAnimationDuration() -> TimeInterval {
#if os(macOS)
    NSAnimationContext.current.duration
#else
    UIView.inheritedAnimationDuration
#endif
}


// The PlatformEdgeInsets struct on iOS conforms to the Equatable protocol, but on macOS it does not, so implement it here
#if os(macOS)
extension PlatformEdgeInsets: @retroactive Equatable {
    public static func == (lhs: PlatformEdgeInsets, rhs: PlatformEdgeInsets) -> Bool {
        lhs.left == rhs.left && lhs.top == rhs.top && lhs.right == rhs.right && lhs.bottom == rhs.bottom
    }
}
#endif


// MARK: - Platform view

/// An unethical monster of NSView and UIView. It does not bite as long as you use it properly, but if you don't...
///
/// This view is designed to bridge both NSView and UIView interfaces so you don't need to
///
/// The following methods are called at view's creation time:
/// 1. `setupLayout`
/// 2. `updateLayout`
/// 3. `updateAppearanceWithoutAppearanceSettings`
/// 4. `updateAppearance`
open class PlatformView: CMView {
    public override init(frame frameRect: PlatformRect) {
        super.init(frame: frameRect)
        setWantsLayer()
        setupLayout()
        updateLayout()
        callUpdateAppearance()
        registerForAppearanceUpdates()
    }
    
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setWantsLayer()
        setupLayout()
        updateLayout()
        callUpdateAppearance()
        registerForAppearanceUpdates()
    }
    
    
    private func setWantsLayer() {
#if os(macOS)
        wantsLayer = true
#endif
    }
    
    
    // MARK: Layout changes
    
    /// Called at view's creation time. Override to implement custom layout initialization.
    open func setupLayout() {
        //
    }
    
    
    /// Called when layout needs to be updated. Override this method if you have custom layout that is not managed by autolayout.
    open func updateLayout() {
        //
    }
    
    
    /// Determines whether layout needs update even though view's frame did not change - used in the ``checkIfFrameChanged`` function.
    private var layoutValid: Bool = false
    
    /// Used in the `checkIfFrameChanged` function to check if `frame` wasn't changed since last frame check.
    private var lastFrame: PlatformRect? = nil
    private var lastSafeAreaRect: PlatformEdgeInsets? = nil
    
    /// Checks if frame wasn't changed since last frame check.
    private func checkIfFrameChanged() -> Bool {
        let currentFrame = frame
        let currentInsets = safeAreaInsets
        
        // Compare last saved frame with the current frame and check if layout is valid
        if lastFrame == currentFrame && lastSafeAreaRect == currentInsets && layoutValid {
            return false
        }
        
        // Override last saved frame if it was changed
        lastFrame = currentFrame
        lastSafeAreaRect = currentInsets
        layoutValid = true
        return true
    }
    
    public func forceSetNeedsLayout() {
        layoutValid = false
        setNeedsLayout()
    }
    
    
#if os(macOS)
    public override func layout() {
        super.layout()
        platformLayoutSubviews()
    }
#elseif os(iOS)
    public override func layoutSubviews() {
        super.layoutSubviews()
        platformLayoutSubviews()
    }
#endif
    
    private func platformLayoutSubviews() {
        // Prevent unnecessary layout updates
        guard checkIfFrameChanged() else {
            return
        }
        
        updateLayout()
    }
    
    
    // MARK: Appearance
    
    /// Register for appearance updates.
    private func registerForAppearanceUpdates() {
#if os(macOS)
        // Do nothing on macOS
#elseif os(iOS)
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                //print("User interface style changed")
                self.callUpdateAppearance()
            }
            
            registerForTraitChanges([UITraitActiveAppearance.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                //print("Active appearance changed")
                self.callUpdateAppearance()
            }
        }
#endif
    }
    
    
    private func callUpdateAppearance() {
        updateAppearanceWithoutAppearanceSettings()
        
        withCurrentAppearance {
            updateAppearance()
        }
    }
    
    
    /// Override to implement appearance change **without** appearance settings applied.
    open func updateAppearanceWithoutAppearanceSettings() {
        //
    }
    
    
    /// Override to implement appearance change **with** appearance settings applied.
    open func updateAppearance() {
        //
    }
    
    
    // MARK: macOS specific
    
#if os(macOS)
    public override func updateLayer() {
        callUpdateAppearance()
    }
    
    public override var isFlipped: Bool {
        true
    }
#endif
}


// MARK: Unify platform specific API


public extension PlatformView {
#if os(macOS)
    func sizeToFit() {
        setFrameSize(totalSize)
    }
    
    func setNeedsLayout() {
        needsLayout = true
    }
#endif
}


public extension CMView {
    var platformLayer: CALayer? {
        return layer
    }
    
    
    func withLayer(action: (_ layer: CALayer) -> Void) {
#if os(macOS)
        if let layer {
            action(layer)
        }
#elseif os(iOS)
        action(layer)
#endif
    }
    
    
    /// Executes given closure with a context of current appearance.
    func withCurrentAppearance(action: () -> Void) {
#if os(macOS)
        effectiveAppearance.performAsCurrentDrawingAppearance {
            action()
        }
#elseif os(iOS)
        traitCollection.performAsCurrent {
            action()
        }
#endif
    }
    
    
    /// Executes given closure with a context of current appearance and layer.
    func withCurrentAppearance(action: (_ layer: CALayer) -> Void) {
#if os(macOS)
        if let layer {
            effectiveAppearance.performAsCurrentDrawingAppearance {
                action(layer)
            }
        }
#elseif os(iOS)
        traitCollection.performAsCurrent {
            action(layer)
        }
#endif
    }
    
    
    /// The size that the view naturally takes to fit its contents.
    ///
    /// **intrinsicContentSize** with **alignmentRectInsets** on macOS and **intrinsicContentSize** on iOS
    var totalSize: PlatformSize {
        var size = intrinsicContentSize
        
        if size.width != CMView.noIntrinsicMetric {
            size.width += alignmentRectInsets.left + alignmentRectInsets.right
        }
        
        if size.height != CMView.noIntrinsicMetric {
            size.height += alignmentRectInsets.top + alignmentRectInsets.bottom
        }
        
        return size
    }
    
    var platformFirstBaselineOffsetFromTop: CGFloat {
#if os(macOS)
        firstBaselineOffsetFromTop
#elseif os(iOS)
        let baselineView = forFirstBaselineLayout
        
        if let baselineView = baselineView as? UILabel {
            return baselineView.font.ascender + baselineView.alignmentRectInsets.top
        }
        
        if let baselineView = baselineView as? UITextField {
            let font = baselineView.font ?? .systemFont(ofSize: UIFont.systemFontSize)
            return font.ascender + baselineView.alignmentRectInsets.top
        }
        
        if let baselineView = baselineView as? UITextView {
            let font = baselineView.font ?? .systemFont(ofSize: UIFont.systemFontSize)
            return font.ascender + baselineView.alignmentRectInsets.top
        }
        
        //fatalError("fuck")
        return baselineView.totalSize.height
        //return 0
#endif
    }
}


public extension CMView {
    @MainActor
    enum CurrentAnimation {
        // TODO: not fileprivate because getCurrentUIAnimationDuration uses it
        /*fileprivate*/ static var isPerforming = false
        static var animation: CMAnimation = .easeInOut
        static var duration: TimeInterval = 0
    }
    
    
    enum CMAnimation {
        case easeIn
        case easeOut
        case easeInOut
        case spring
        
        var timingFunction: CAMediaTimingFunction {
            switch self {
            case .easeIn: CAMediaTimingFunction(name: .easeIn)
            case .easeOut: CAMediaTimingFunction(name: .easeOut)
            case .easeInOut: CAMediaTimingFunction(name: .easeInEaseOut)
            case .spring: CAMediaTimingFunction(name: .linear)
            }
        }
    }
    
    
    var cmAnimatable: Self {
#if os(macOS)
        if Self.CurrentAnimation.isPerforming {
            return self.animator()
        }
#endif
        
        return self
    }
    
    
    func performAnimation(_ animation: CMAnimation, duration: TimeInterval = 0.35, _ changes: @MainActor @escaping () -> Void) {
        let oldIsAnimating = CMView.CurrentAnimation.isPerforming
        let oldAnimation = CMView.CurrentAnimation.animation
        let oldAnimationDuration = CMView.CurrentAnimation.duration
        
        CMView.CurrentAnimation.isPerforming = true
        CMView.CurrentAnimation.animation = animation
        CMView.CurrentAnimation.duration = duration
        #if os(macOS)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = animation.timingFunction
            changes()
        }
        #else
        UIView.animate(withDuration: duration) {
            changes()
        }
        #endif
        CMView.CurrentAnimation.duration = oldAnimationDuration
        CMView.CurrentAnimation.animation = oldAnimation
        CMView.CurrentAnimation.isPerforming = oldIsAnimating
    }
    
    
    /// Performs animated layout changes if the specified closure if needed.
    /// - Parameter animate: executes the closure inside an animation block, otherwise just executes the closure.
    func withOrWithoutAnimation(_ animate: Bool, _ animation: CMAnimation, duration: TimeInterval = 0.35, _ changes: @MainActor @escaping () -> Void) {
        if animate {
            performAnimation(animation, duration: duration, changes)
        }
        else {
            //CATransaction.begin()
            //CATransaction.setDisableActions(true)
            changes()
            //CATransaction.commit()
        }
    }
    
}
