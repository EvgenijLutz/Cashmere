//
//  PlatformView.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 03.03.25.
//

import CMPlatform


// MARK: - Platform view

/// An unethical monster of NSView and UIView. It does not bite as long as you use it properly, but if you don't...
///
/// `setupLayout` is called at view's creation time. Override this method to add subviews. `updateLayout` is called then.
/// `updateLayout` is called when layout needs to be updated. Override this method if you have custom layout that is not managed by autolayout.
open class PlatformView: CMView {
    public override init(frame frameRect: PlatformRect) {
        super.init(frame: frameRect)
        setupLayout()
        updateLayout()
        callUpdateAppearance()
        registerForAppearanceUpdates()
    }
    
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
        updateLayout()
        callUpdateAppearance()
        registerForAppearanceUpdates()
    }
    
    
    // MARK: Layout changes
    
    /// Override to implement custom layout initialization.
    open func setupLayout() {
        //
    }
    
    /// Override to implement layout change
    open func updateLayout() {
        //
    }
    
#if os(macOS)
    public override func layout() {
        super.layout()
        updateLayout()
    }
#elseif os(iOS)
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
#endif
    
    
    // MARK: Appearance
    
#if os(macOS)
    private func registerForAppearanceUpdates() {
        // Do nothing on macOS
    }
#elseif os(iOS)
    private func registerForAppearanceUpdates() {
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitActiveAppearance.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                self.callUpdateAppearance()
            }
        } else {
            // Fallback on earlier versions
        }
    }
#endif
    
    private func callUpdateAppearance() {
        updateAppearanceWithoutAppearanceSettings()
        
        withCurrentAppearance {
            updateAppearance()
        }
    }
    
    /// Override to implement layout change
    open func updateAppearanceWithoutAppearanceSettings() {
        //
    }
    
    /// Override to implement layout change
    open func updateAppearance() {
        //
    }
    
    
    // MARK: Overloads
    
#if os(macOS)
    public override func updateLayer() {
        callUpdateAppearance()
    }
#endif
    
#if os(macOS)
    public override var isFlipped: Bool {
        true
    }
#endif
}


public extension PlatformView {
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
    
    
#if os(macOS)
    func sizeToFit() {
        setFrameSize(totalSize)
    }
    
    func setNeedsLayout() {
        needsLayout = true
    }
#endif
    
    
    func setWantsLayer() {
#if os(macOS)
        wantsLayer = true
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
        
        fatalError("fuck")
        //return baselineView.totalSize.height
        //return 0
#endif
    }
}
