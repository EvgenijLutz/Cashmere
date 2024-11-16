//
//  TagView.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 14.11.24.
//

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


public class UITagView<Item: Identifiable>: UIView {
    private var items = [ViewMap<Item>]()
    
    private var defaultWidth: CGFloat = 10
    
    private var horizontalPadding: CGFloat = 8
    private var verticalPadding: CGFloat = 8
    
    private var horizontalSpacing: CGFloat = 8
    private var verticalSpacing: CGFloat = 8
    
    private var animationDuration: CGFloat = 0.35   // Standard UIKit's animation duration
    
    
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
    public func updateContent(_ content: [Item], animated: Bool, viewGenerator: (_ item: Item) -> ViewData) {
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
            if !items.contains(where: { $0.id == item.id }) {
                let viewData = viewGenerator(item)
                viewData.view.backgroundColor = .clear
                let value = ViewMap(item: item, viewData: viewData)
                addedItems.append(value)
            }
        }
        
        // Find removed views
        var removedViews = [ViewMap<Item>]()
        for item in items {
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
                let view = item.view
                view.removeFromSuperview()
            }
        }
        
        // Animate adding views
        for item in addedItems {
            let view = item.view
            addSubview(view)
            view.transform = .init(scaleX: 0, y: 0)
        }
        performWithOptionalAnimation {
            for item in addedItems {
                let view = item.view
                view.transform = .init(scaleX: 1, y: 1)
            }
        } completion: { _ in }
        
        // Update items collection
        items.removeAll { item in
            removedViews.contains(where: { $0.id == item.id })
        }
        items.append(contentsOf: addedItems)
        for (index, item) in items.enumerated() {
            item.view.layer.zPosition = CGFloat(index)
        }
        
        // Update layout
        performWithOptionalAnimation {
            self.updateContentLayout(disablingAnimationsFor: addedItems)
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
    
    
    private func updateContentLayout(disablingAnimationsFor ignoredItems: [ViewMap<Item>] = []) {
        log("Update content layout")
#if false
        let contentSize = calculateSizeThatFits(proposedWidth: frame.width, proposedHeight: frame.height)
        let width = contentSize.width
#else
        let width = frame.width
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
            let viewSize = view.intrinsicContentSize
            
            // Go to the new row if the view's width doesn't fit into the rest of the row
            if currentRowItem > 0 && currentRowWidth + viewSize.width + horizontalPadding > width {
                height += currentRowHeight + verticalSpacing
                
                // Reset counters
                currentRowItem = 0
                currentRowWidth = horizontalPadding
                currentRowHeight = 0
            }
            
            // Set item position and size, with animation if needed
            let itemFrame: CGRect = .init(origin: .init(x: currentRowWidth, y: height), size: view.intrinsicContentSize)
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
    
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let fittingSize = calculateSizeThatFits(proposedWidth: size.width, proposedHeight: size.height)
        log("UIKit request size that fits in (\(floatString(size.width)) x \(floatString(size.height))) - result (\(floatString(fittingSize.width)) x \(floatString(fittingSize.height)))")
        return fittingSize
    }
    
    
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
    
    
    public override var frame: CGRect {
        get {
            super.frame
        }
        
        set {
            log("Set frame, size: (\(floatString(newValue.size.width)) x \(floatString(newValue.size.height)))")
            super.frame = newValue
            
            invalidateIntrinsicContentSize()
            updateContentLayout()
        }
    }
}


// MARK: - SwiftUI bridge

// TODO: Use UIViewControllerRepresentable instead of UIViewRepresentable
//public class UITagViewController<Identifier: Identifiable>: UIViewController {
//    private let tagView: UITagView<Identifier>
//
//    init() {
//        tagView = UITagView()
//
//        super.init()
//        initTagView()
//    }
//
//    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        tagView = UITagView()
//
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//        initTagView()
//    }
//
//    public required init?(coder: NSCoder) {
//        guard let tView = UITagView<Identifier>(coder: coder) else {
//            return nil
//        }
//        tagView = tView
//
//        super.init(coder: coder)
//        initTagView()
//    }
//
//
//    private func initTagView() {
//        view = tagView
//    }
//
//
//    func update(_ controllers: [UIViewController]) {
//        for controller in children {
//            controller.removeFromParent()
//        }
//
//        let views = controllers.map { $0.view! }
//        tagView.updateContent(views)
//
//        for controller in controllers {
//            addChild(controller)
//            controller.didMove(toParent: self)
//        }
//
//        preferredContentSize = tagView.intrinsicContentSize
//    }
//
//
//    func calculateSizeThatFits(proposedWidth: CGFloat?, proposedHeight: CGFloat?) -> CGSize {
//        return tagView.calculateSizeThatFits(proposedWidth: proposedWidth, proposedHeight: proposedHeight)
//    }
//}


public struct TagView<Item: Identifiable, V: View>: UIViewRepresentable {
    private let items: [Item]
    private let viewGenerator: (Item) -> V
    
    
    public init(_ items: [Item], viewGenerator: @escaping (Item) -> V) {
        //log("Init TagView")
        self.items = items
        self.viewGenerator = viewGenerator
    }
    
    
    public func makeUIView(context: Context) -> UITagView<Item> {
        log("Make UIView")
        let tagView = UITagView<Item>()
        return tagView
    }
    
    
    public func updateUIView(_ uiView: UITagView<Item>, context: Context) {
        log("Update view with \(items.count) items")
        
        uiView.updateContent(items, animated: context.transaction.animation != nil) { item in
            let swiftUIView = viewGenerator(item)
            let hostingVC = UIHostingController(rootView: swiftUIView)
            
            // A very dangereous move
            let view =  hostingVC.view!
            
            //if #available(iOS 16, *) {
            //    hostingVC.sizingOptions = .intrinsicContentSize
            //}
            
            // TODO: Don't drop the view controller: https://medium.com/arcush-tech/two-pitfalls-to-avoid-when-working-with-uihostingcontroller-534d1507563e
            return .init(view: view, viewController: hostingVC)
        }
    }
    
    
    @available(iOS 16, *)
    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITagView<Item>, context: Context) -> CGSize? {
        let fittingSize = uiView.calculateSizeThatFits(proposedWidth: proposal.width, proposedHeight: proposal.height)
        
        log("SwiftUI request size that fits in (\(floatString(proposal.width)) x \(floatString(proposal.height))) - result (\(floatString(fittingSize.width)) x \(floatString(fittingSize.height)))")
        
        return fittingSize
    }
}


// MARK: - Testing

struct SomeItem: Identifiable {
    let id = UUID()
    let name: String
}


final class TestViewModel: ObservableObject {
    @Published var items: [SomeItem] = [
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
    
    func removeItem(with id: SomeItem.ID) {
        items.removeAll { $0.id == id }
    }
}


@available(iOS 18, *)
struct TestTagView: View {
    var title: String
    var removeAction: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                //.frame(height: CGFloat(10 + item.name.count * 5))
                .font(.callout)
            
            Button {
                withAnimation {
                    removeAction()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .tint(Color(UIColor.label))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


@available(iOS 18, *)
struct TagTestView: View {
    @ObservedObject var viewModel: TestViewModel
    
    var body: some View {
        VStack {
            TagView(viewModel.items) { item in
                TestTagView(title: item.name) {
                    viewModel.removeItem(with: item.id)
                }
            }
            
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
    TagTestView(viewModel: .init())
}
