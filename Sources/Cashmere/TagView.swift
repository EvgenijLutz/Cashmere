//
//  TagView.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 14.11.24.
//

#if os(iOS)

import UIKit
import SwiftUI
import OSLog


// MARK: - Utilities

fileprivate let enableTagViewLogging = true

#if false

@available(iOS 14.0, *)
fileprivate let logger = Logger(subsystem: "Cashmere", category: "TagView")

fileprivate func log(_ message: String) {
    guard enableTagViewLogging else {
        return
    }
    
    if #available(iOS 14.0, *) {
        logger.log("\(message)")
    }
    else {
        print(message)
    }
}

#else

fileprivate func log(_ message: String) {
    // Log only if it's a preview
    guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" else {
        return
    }
    
    guard enableTagViewLogging else {
        return
    }
    
    print(message)
}

#endif


fileprivate func floatString(_ value: CGFloat?) -> String {
    guard let value else {
        return "nil"
    }
    guard !value.isNaN else {
        return "nan"
    }
    guard !value.isInfinite else {
        return "inf"
    }
    return String(Int(value))
}


// MARK: - Tag collection view

public struct ViewData {
    let view: UIView
    
    /// A view controller the ``view`` comes from
    let viewController: UIViewController?
}


fileprivate struct ViewMap<Item: Identifiable>: Identifiable {
    let item: Item
    let viewData: ViewData
    
    var id: Item.ID {
        item.id
    }

    var view: UIView {
        viewData.view
    }
    
    var viewController: UIViewController? {
        viewData.viewController
    }
}


public protocol TagViewItem: AnyObject {
    var view: UIView { get }
    var viewController: UIViewController? { get }
}


@MainActor
private protocol CMTagViewDataSource: AnyObject {
    var numItems: Int { get }
    
    func calculateSizeThatFits(proposedWidth: CGFloat?, proposedHeight: CGFloat?) -> CGSize
    func updateContentLayout()
}


private class CMTagViewStorage<Item: Identifiable>: CMTagViewDataSource {
    private weak var owner: CMTagView!
    fileprivate var items = [ViewMap<Item>]()
    
    
    public var numItems: Int {
        items.count
    }
    
    
    init(owner: CMTagView) {
        self.owner = owner
    }
    
    
    var defaultWidth: CGFloat { owner.defaultWidth }
    var horizontalPadding: CGFloat { owner.horizontalPadding }
    var verticalPadding: CGFloat { owner.verticalPadding }
    var horizontalSpacing: CGFloat { owner.horizontalSpacing }
    var verticalSpacing: CGFloat { owner.verticalSpacing }
    
    
    func calculateSizeThatFits(proposedWidth: CGFloat?, proposedHeight: CGFloat?) -> CGSize {
        let width: CGFloat = {
            guard let proposedWidth else {
                return defaultWidth
            }
            
            guard !proposedWidth.isNaN else {
                return defaultWidth
            }
            
            guard !proposedWidth.isInfinite else {
                return defaultWidth
            }
            
            return proposedWidth
        }()
        var height: CGFloat = verticalPadding
        
        if items.isEmpty {
            return .init(width: width, height: 0)
        }
        
        var currentRowItem: Int = 0
        var currentRowWidth: CGFloat = horizontalPadding
        var currentRowHeight: CGFloat = 0
        
        for item in items {
            let view = item.view
            let viewSize = view.intrinsicContentSize
            
            // Go to the new row if the view's width doesn't fit into the rest of the row
            if currentRowItem > 0 && currentRowWidth + viewSize.width + horizontalPadding > width {
                height += currentRowHeight + verticalSpacing
                
                // Reset counters
                currentRowItem = 0
                currentRowWidth = horizontalPadding
                currentRowHeight = 0
            }
            
            // Update current row item, width and max height
            currentRowItem += 1
            currentRowWidth += viewSize.width + horizontalSpacing
            currentRowHeight = max(currentRowHeight, viewSize.height)
        }
        
        height += currentRowHeight + verticalPadding
        
        
        //log("Proposed size: \(floatString(proposedWidth)) x \(floatString(proposedHeight)), Calculated size: \(floatString(width)) x \(floatString(height))")
        
        return .init(width: width, height: height)
    }
    
    
    func updateContentLayout() {
        updateContentLayout(disablingAnimationsFor: [])
    }
    
    
    func updateContentLayout(disablingAnimationsFor ignoredItems: [ViewMap<Item>]) {
        log("Update content layout")
                
#if false
        let contentSize = calculateSizeThatFits(proposedWidth: frame.width, proposedHeight: frame.height)
        let width = contentSize.width
#else
        let width = owner.frame.width
#endif
        
        
        var height: CGFloat = verticalPadding
        
        if items.isEmpty {
            return
        }
        
        var currentRowItem: Int = 0
        var currentRowWidth: CGFloat = horizontalPadding
        var currentRowHeight: CGFloat = 0
        
        for item in items {
            let view = item.view
            //let viewSize = view.intrinsicContentSize
            //let viewSize = view.frame.size
            let viewSize = Int(view.frame.size.height) == 0 ? view.intrinsicContentSize : view.frame.size
            
            // Go to the new row if the view's width doesn't fit into the rest of the row
            if currentRowItem > 0 && currentRowWidth + viewSize.width + horizontalPadding > width {
                height += currentRowHeight + verticalSpacing
                
                // Reset counters
                currentRowItem = 0
                currentRowWidth = horizontalPadding
                currentRowHeight = 0
            }
            
            // Set item position and size, with animation if needed
            let itemFrame: CGRect = .init(origin: .init(x: currentRowWidth, y: height), size: viewSize)
            if ignoredItems.contains(where: { $0.id == item.id }) {
                UIView.performWithoutAnimation {
                    view.frame = itemFrame
                }
            }
            else {
                view.frame = itemFrame
            }
            
            // Update current row item, width and max height
            currentRowItem += 1
            currentRowWidth += viewSize.width + horizontalSpacing
            currentRowHeight = max(currentRowHeight, viewSize.height)
        }
        
        //currentIntrinsicContentSize = contentSize
        // The tag view tries to take the maximum available width
        //currentIntrinsicContentSize.width = UIView.noIntrinsicMetric
    }
}


/// A view that contains collection of tags.
public class CMTagView: UIView {
    private var storage: CMTagViewDataSource? = nil
    
    fileprivate var defaultWidth: CGFloat = 10
    
    fileprivate var horizontalPadding: CGFloat = 8
    fileprivate var verticalPadding: CGFloat = 8
    
    fileprivate var horizontalSpacing: CGFloat = 8
    fileprivate var verticalSpacing: CGFloat = 8
    
    fileprivate var animationDuration: CGFloat = 0.35   // Standard UIKit's animation duration
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initTagView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initTagView()
    }
    
    private func initTagView() {
        log("Init tag view")
        
        backgroundColor = .clear
        
        // Width is flexible, but height is always calculated based on width
        
        // Don't mind to be smaller than intrinsic width
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // Resist being made smaller than intrinsic height
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        // Don't mind to be larger than intrinsic width
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        // Resist being made larger than intrinsic height
        setContentHuggingPriority(.defaultHigh, for: .vertical)
    }
    
    
    /// Updates collection of items
    public func updateContent<Item: Identifiable>(_ content: [Item], animated: Bool, owner: UIViewController? = nil, viewGenerator: (_ item: Item) -> ViewData) {
        if storage == nil {
            storage = CMTagViewStorage<Item>(owner: self)
        }
        
        guard let storage = storage as? CMTagViewStorage<Item> else {
            return
        }
        
        func performWithOptionalAnimation(animation: @escaping () -> Void,
                                          completion: @escaping (_ finished: Bool) -> Void) {
            if animated {
                UIView.animate(withDuration: animationDuration, delay: 0, options: [.allowUserInteraction], animations: animation, completion: completion)
                return
            }
            
            animation()
            completion(true)
        }
        
        
        // Find added views
        var addedItems = [ViewMap<Item>]()
        for item in content {
            if !storage.items.contains(where: { $0.id == item.id }) {
                let viewData = viewGenerator(item)
                viewData.view.backgroundColor = .clear
                let value = ViewMap(item: item, viewData: viewData)
                addedItems.append(value)
            }
        }
        
        // Find removed views
        var removedViews = [ViewMap<Item>]()
        for item in storage.items {
            if !content.contains(where: { $0.id == item.id }) {
                removedViews.append(item)
            }
        }
        
        // Animate removing views
        performWithOptionalAnimation {
            for item in removedViews {
                let view = item.view
                view.transform = .init(scaleX: 0.01, y: 0.01)
                view.alpha = 0
            }
        } completion: { _ in
            for item in removedViews {
                // Child view controller needs to know that it will be removed soon
                if let childController = item.viewController {
                    childController.willMove(toParent: nil)
                }
                
                // Remove child view
                let view = item.view
                view.removeFromSuperview()
                
                // Child view controller needs to be removed from view controller hierarchy
                if let childController = item.viewController {
                    childController.removeFromParent()
                }
            }
        }
        
        // Animate adding views
        for item in addedItems {
            // Child view controller needs to know that it will be added soon
            if let owner, let childController = item.viewController {
                owner.addChild(childController)
            }
            
            // Add child view
            let view = item.view
            addSubview(view)
            view.transform = .init(scaleX: 0, y: 0)
            
            // Child view controller needs to know that it was added to a parent
            if let owner, let childController = item.viewController {
                childController.didMove(toParent: owner)
            }
        }
        performWithOptionalAnimation {
            for item in addedItems {
                let view = item.view
                view.transform = .init(scaleX: 1, y: 1)
            }
        } completion: { _ in }
        
        // Update items collection
        storage.items.removeAll { item in
            removedViews.contains(where: { $0.id == item.id })
        }
        storage.items.append(contentsOf: addedItems)
        for (index, item) in storage.items.enumerated() {
            item.view.layer.zPosition = CGFloat(index)
        }
        
        // Update layout
        performWithOptionalAnimation {
            storage.updateContentLayout(disablingAnimationsFor: addedItems)
        } completion: { _ in }
        invalidateIntrinsicContentSize()
    }
    
    
    //private var currentIntrinsicContentSize = CGSize(width: 10, height: 10)
    public override var intrinsicContentSize: CGSize {
        let size = calculateSizeThatFits(proposedWidth: frame.width, proposedHeight: 0)
        
        let w = floatString(size.width)
        let h = floatString(size.height)
        log("Request intrinsic content size: (\(w) x \(h))")
        
        return size
    }
    
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let fittingSize = calculateSizeThatFits(proposedWidth: size.width, proposedHeight: size.height)
        log("UIKit request size that fits in (\(floatString(size.width)) x \(floatString(size.height))) - result (\(floatString(fittingSize.width)) x \(floatString(fittingSize.height)))")
        return fittingSize
    }
    
    
    func calculateSizeThatFits(proposedWidth: CGFloat?, proposedHeight: CGFloat?) -> CGSize {
        if let size = storage?.calculateSizeThatFits(proposedWidth: proposedWidth, proposedHeight: proposedHeight) {
            return size
        }
        
        let width: CGFloat = {
            guard let proposedWidth else {
                return defaultWidth
            }
            
            guard !proposedWidth.isNaN else {
                return defaultWidth
            }
            
            guard !proposedWidth.isInfinite else {
                return defaultWidth
            }
            
            return proposedWidth
        }()
        
        return .init(width: width, height: 0)
    }
    
    
    public override var frame: CGRect {
        get {
            super.frame
        }
        
        set {
            log("Set frame, size: (\(floatString(newValue.size.width)) x \(floatString(newValue.size.height)))")
            super.frame = newValue
            
            invalidateIntrinsicContentSize()
            storage?.updateContentLayout()
        }
    }
}


// MARK: - SwiftUI bridge

public class CMTagViewController: UIViewController {
    fileprivate let tagView: CMTagView
    
    
    init() {
        tagView = CMTagView()
        super.init()
        
        initTagView()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        tagView = CMTagView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        initTagView()
    }
    
    required init?(coder: NSCoder) {
        tagView = CMTagView()
        super.init(coder: coder)
        
        initTagView()
    }
    
    
    private func initTagView() {
        view = tagView
    }
    
    
    func updateContent<Item: Identifiable>(_ items: [Item], animated: Bool, viewGenerator: (_ item: Item) -> ViewData) {
        for controller in children {
            controller.removeFromParent()
        }

        tagView.updateContent(items, animated: animated, owner: self, viewGenerator: viewGenerator)

        preferredContentSize = tagView.intrinsicContentSize
    }


    func calculateSizeThatFits(proposedWidth: CGFloat?, proposedHeight: CGFloat?) -> CGSize {
        return tagView.calculateSizeThatFits(proposedWidth: proposedWidth, proposedHeight: proposedHeight)
    }
}


public struct TagView<Item: Identifiable, V: View>: UIViewControllerRepresentable {
    private let items: [Item]
    private let viewGenerator: (Item) -> V
    
    
    public init(_ items: [Item], viewGenerator: @escaping (Item) -> V) {
        //log("Init TagView")
        self.items = items
        self.viewGenerator = viewGenerator
    }
    
    
    public func makeUIViewController(context: Context) -> CMTagViewController {
        log("Make UIViewController")
        let controller = CMTagViewController()
        return controller
    }
    
    
    public func updateUIViewController(_ uiViewController: CMTagViewController, context: Context) {
        log("Update view controller with \(items.count) items")
        
        uiViewController.updateContent(items, animated: context.transaction.animation != nil) { item in
            let swiftUIView = viewGenerator(item)
            let hostingVC = UIHostingController(rootView: swiftUIView)
            
            // A very dangereous move
            let view = hostingVC.view!
            
            if #available(iOS 16, *) {
                hostingVC.sizingOptions = .intrinsicContentSize
            }
            
            // TODO: Don't drop the view controller: https://medium.com/arcush-tech/two-pitfalls-to-avoid-when-working-with-uihostingcontroller-534d1507563e
            return .init(view: view, viewController: hostingVC)
        }
    }
    
    
    // TODO: On iOS 13-15 the view takes all vertical space
    @available(iOS 16, *)
    public func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: CMTagViewController, context: Context) -> CGSize? {
        let fittingSize = uiViewController.tagView.calculateSizeThatFits(proposedWidth: proposal.width, proposedHeight: proposal.height)
        
        log("SwiftUI request size that fits in (\(floatString(proposal.width)) x \(floatString(proposal.height))) - result (\(floatString(fittingSize.width)) x \(floatString(fittingSize.height)))")
        
        return fittingSize
    }
}


@available(*, deprecated, message: "Use TagView instead")
public struct OldTagView<Item: Identifiable, V: View>: UIViewRepresentable {
    private let items: [Item]
    private let viewGenerator: (Item) -> V
    
    
    public init(_ items: [Item], viewGenerator: @escaping (Item) -> V) {
        //log("Init OldTagView")
        self.items = items
        self.viewGenerator = viewGenerator
    }
    
    
    public func makeUIView(context: Context) -> CMTagView {
        log("Make UIView")
        let tagView = CMTagView()
        return tagView
    }
    
    
    public func updateUIView(_ uiView: CMTagView, context: Context) {
        log("Update view with \(items.count) items")
        
        uiView.updateContent(items, animated: context.transaction.animation != nil) { item in
            let swiftUIView = viewGenerator(item)
            let hostingVC = UIHostingController(rootView: swiftUIView)
            
            // A very dangereous move
            let view = hostingVC.view!
            
            //if #available(iOS 16, *) {
            //    hostingVC.sizingOptions = .intrinsicContentSize
            //}
            
            // TODO: Don't drop the view controller: https://medium.com/arcush-tech/two-pitfalls-to-avoid-when-working-with-uihostingcontroller-534d1507563e
            return .init(view: view, viewController: hostingVC)
        }
    }
    
    
    @available(iOS 16, *)
    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: CMTagView, context: Context) -> CGSize? {
        let fittingSize = uiView.calculateSizeThatFits(proposedWidth: proposal.width, proposedHeight: proposal.height)
        
        log("SwiftUI request size that fits in (\(floatString(proposal.width)) x \(floatString(proposal.height))) - result (\(floatString(fittingSize.width)) x \(floatString(fittingSize.height)))")
        
        return fittingSize
    }
}


// MARK: - Testing

struct TestItem: Identifiable {
    let id = UUID()
    let name: String
}


@available(iOS 18, *)
@Observable class TestViewModel {
    var items: [TestItem] = [
        .init(name: "First"),
        .init(name: "Second"),
        .init(name: "Third"),
        .init(name: "Fourth"),
        .init(name: "Fifth"),
        .init(name: "Sixth"),
        .init(name: "Seventh"),
        .init(name: "Eighth"),
        .init(name: "Ninth"),
        .init(name: "Tenth"),
        .init(name: "Eleventh"),
        .init(name: "Twelfth"),
        .init(name: "Thirteenth"),
        .init(name: "Fourteenth"),
        .init(name: "Fifteenth"),
        .init(name: "Sixteenth"),
        .init(name: "Seventeenth"),
        .init(name: "Eighteenth"),
        .init(name: "Nineteenth"),
        .init(name: "Twentieth")
    ]
    
    func removeItem(with id: TestItem.ID) {
        items.removeAll { $0.id == id }
    }
}


@available(iOS 18, *)
struct TestTagView: View {
    @State var on: Bool = false
    var title: String
    var removeAction: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
            
            Button {
                // Remove item with animation
                withAnimation {
                    removeAction()
                    //on.toggle()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .tint(Color(UIColor.label))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(on ? .green : Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


@available(iOS 18, *)
struct TagTestView: View {
    private var viewModel = TestViewModel()
    
    var body: some View {
        VStack {
            //HStack {
                TagView(viewModel.items) { item in
                    TestTagView(title: item.name) {
                        viewModel.removeItem(with: item.id)
                    }
                }
                //.background(.gray)
            //
            //    //Spacer()
            //
            //    Text("Hello")
            //}
            
            Button("Add tag") {
                withAnimation {
                    viewModel.items.append(.init(name: "tag #\(viewModel.items.count)"))
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}


@available(iOS 18, *)
#Preview {
    TagTestView()
}

#endif
