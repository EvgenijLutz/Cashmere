//
//  SplitView.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 14.03.25.
//

import Foundation
import CMPlatform
import SwiftUI


public enum CMDirection {
    case horizontal
    case vertical
}


// MARK: Split view

public class CMSplitView: PlatformView {
    var direction: CMDirection = .horizontal
    
    struct ViewInfo {
        var view: CMView
        var priority: Int
        var separator: CMView
    }
    var children: [ViewInfo] = []
    
    
    public override func setupLayout() {
        //
    }
    
    public override func updateLayout() {
        //
    }
    
    public override func updateAppearance() {
        //
    }
    
    public func add(_ view: CMView, withSeparator separator: CMView? = nil) {
        //
    }
    
    
    public func collapseView(at index: Int, animated: Bool = true) {
        //
    }
}


// MARK: Split view controller

public class CMSplitViewController: PlatformViewController {
    private let splitView = CMSplitView()
    
    public override func setupLayout() {
        view = splitView
    }
}


// MARK: SwiftUI port

#if os(macOS)
public struct SplitView: NSViewControllerRepresentable {
    
    public init() {
        //
    }
    
    public func makeNSViewController(context: Context) -> CMSplitViewController {
        CMSplitViewController()
    }
    
    public func updateNSViewController(_ nsViewController: CMSplitViewController, context: Context) {
        //
    }
}
#elseif os(iOS)
public struct SplitView: UIViewControllerRepresentable {
    
    public init() {
        //
    }
    
    public func makeUIViewController(context: Context) -> CMSplitViewController {
        CMSplitViewController()
    }
    
    public func updateUIViewController(_ uiViewController: CMSplitViewController, context: Context) {
        //
    }
}
#endif


#Preview {
    SplitView()
}
