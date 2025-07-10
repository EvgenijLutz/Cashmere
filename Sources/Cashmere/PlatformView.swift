//
//  PlatformView.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 03.03.25.
//

import CMPlatform


@MainActor
fileprivate func getCurrentAnimationDuration() -> TimeInterval {
#if os(macOS)
    NSAnimationContext.current.duration
#else
    UIView.inheritedAnimationDuration
#endif
}


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
    
    
    /// Determines whether layout needs update even though view's frame did not change.
    private var layoutValid: Bool = false
    
    /// Used in the `checkIfFrameChanged` function to check if `frame` wasn't changed since last frame check.
    private var lastFrame: PlatformRect? = nil
    
    /// Checks if frame wasn't changed since last frame check.
    private func checkIfFrameChanged() -> Bool {
        // Compare last saved frame with the current frame and check if layout is valid
        if lastFrame == frame && layoutValid {
            //print("Frame didn't change")
            return false
        }
        
        // Override last saved frame if it was changed
        lastFrame = frame
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
        //let oldFrame = lastFrame ?? .zero
        
        // Prevent unnecessary layout updates
        guard checkIfFrameChanged() else {
            //print("❌ \(oldFrame.compactString) -> \(frame.compactString) ~ \(safeAreaInsets.top) ° \(getCurrentAnimationDuration())")
            return
        }
        
        //print("✅ \(oldFrame.compactString) -> \(frame.compactString) ~ \(safeAreaInsets.top) ° \(getCurrentAnimationDuration())")
        //print("Layout ~ \(UIView.inheritedAnimationDuration)")
        
        updateLayout()
    }
    
    
    // MARK: Appearance
    
    
#if os(macOS)
    private func registerForAppearanceUpdates() {
        // Do nothing on macOS
    }
#elseif os(iOS)
    /// Register for appearance updates on iOS 17 and newer. For older versions, appearance changes are handled in the ``traitCollectionDidChange(_:)`` function.
    private func registerForAppearanceUpdates() {
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
    }
    
    /// Respond to appearance updates on iOS 16 and older. For newer versions, appearance changes are handled in the ``registerForAppearanceUpdates()`` function.
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 17.0, *) {
            // Do nothing. The logic is handled by the ``registerForAppearanceUpdates`` function
        } else {
            let activeAppearanceChanged = {
                if #available(iOS 14.0, *) {
                    return traitCollection.activeAppearance != previousTraitCollection?.activeAppearance
                }
                
                return false
            }()
            
            if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle || activeAppearanceChanged {
                callUpdateAppearance()
            }
        }
    }
#endif
    
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
