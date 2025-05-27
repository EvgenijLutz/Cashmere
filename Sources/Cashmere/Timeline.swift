//
//  Timeline.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 03.03.25.
//

import CMPlatform
import SwiftUI


// Og sjógvurin tyngist
// Alt togar móti dýpinum
// Eg veit eg má fara
// Eg veit at eg kann


// MARK: Point

/// Because there is never enough implementations of a point in 2D space.
public struct CMPoint: Sendable {
    public var x: Float
    public var y: Float
    
    public init() {
        x = 0
        y = 0
    }
    
    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    public var cgPoint: CGPoint {
        .init(x: CGFloat(x), y: CGFloat(y))
    }
    
    public var length: Float {
        sqrt(x * x + y * y)
    }
    
    /// Salti∂ í kroppinum
    public var normalized: CMPoint {
        let len = length
        guard abs(len) > 0.00001 else {
            return .init(x: 1, y: 0)
        }
        
        return .init(x: x / length, y: y / length)
    }
    
    public static func + (lhs: CMPoint, rhs: CMPoint) -> CMPoint {
        .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    public static func - (lhs: CMPoint, rhs: CMPoint) -> CMPoint {
        .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    public static func * (lhs: CMPoint, rhs: Float) -> CMPoint {
        .init(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    public static func / (lhs: CMPoint, rhs: Float) -> CMPoint {
        .init(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}


public extension CMPoint {
    init(_ point: CGPoint) {
        self.init(x: Float(point.x), y: Float(point.y))
    }
}


public extension CGPoint {
    init(_ point: CMPoint) {
        self.init(x: CGFloat(point.x), y: CGFloat(point.y))
    }
}


public prefix func - (value: CMPoint) -> CMPoint {
    .init(x: -value.x, y: -value.y)
}


public extension CMPoint {
    func makeCGPoint(offset: CGPoint, scaleX: CGFloat, scaleY: CGFloat) -> CGPoint {
        .init(
            x: offset.x + CGFloat(x) * scaleX,
            y: offset.y - CGFloat(y) * scaleY
        )
    }
}


// MARK: Record

public struct TMRecord: Sendable {
    public var point: CMPoint
    
    public init(point: CMPoint) {
        self.point = point
    }
    
    public init(x: Float, y: Float) {
        point = .init(x: x, y: y)
    }
    
    public init(_ x: Float, _ y: Float) {
        point = .init(x: x, y: y)
    }
    
    public var localControl1: CMPoint = .init(x: -0.5, y: 0)
    public var globalControl1: CMPoint {
        point + localControl1
    }
    
    public var localControl2: CMPoint = .init(x: 0.5, y: 0)
    public var globalControl2: CMPoint {
        point + localControl2
    }
}


// MARK: Axis

@MainActor
public class TMAxis {
    weak var view: CMTimelineEditor?
    var name: String
    var points: [TMRecord]
    
#if os(macOS)
    let label = NSTextField(labelWithString: "")
#elseif os(iOS)
    let label = UILabel()
#endif
    
    
    init(view: CMTimelineEditor, name: String, records: [TMRecord]) {
        self.view = view
        self.name = name
        self.points = records
        
        // Add label
#if os(macOS)
        label.stringValue = name
#elseif os(iOS)
        label.text = name
#endif
        label.sizeToFit()
        view.navigatorContentView.addSubview(label)
    }
    
    
    /// Adds a point.
    public func addPoint(_ point: CMPoint) {
        // Insert point
        var pointIndex = 0
        let numPoints = points.count
        for index in 0 ..< numPoints {
            if points[index].point.x >= point.x {
                break
            }
            
            pointIndex += 1
        }
        points.insert(.init(point: point), at: pointIndex)
        
        // Schedule update
        guard let view else {
            return
        }
        view.invalidateLayout()
    }
    
    
    func resetControlPoints() {
        guard !points.isEmpty else {
            return
        }
        
        guard points.count > 1 else {
            points[0].localControl1 = .init(x: -1, y: 0)
            points[0].localControl2 = .init(x: 1, y: 0)
            return
        }
        
        do {
            let first = points[0]
            let next = points[1]
            
            let direction = next.point - first.point
            let length = direction.length
            let vector = direction.normalized * length * 0.33
            points[0].localControl1 = -vector
            points[0].localControl2 = vector
        }
        
        for index in points.indices.dropFirst().dropLast() {
            let previous = points[index - 1].point
            let current = points[index].point
            let next = points[index + 1].point
            
            let direction = next - previous
            let vector = direction.normalized
            points[index].localControl1 = -vector * (current - previous).length * 0.33
            points[index].localControl2 = vector * (current - next).length * 0.33
        }
        
        do {
            let previous = points[points.count - 2]
            let last = points[points.count - 1]
            
            let direction = last.point - previous.point
            let length = direction.length
            let vector = direction.normalized * length * 0.33
            points[points.count - 1].localControl1 = -vector
            points[points.count - 1].localControl2 = vector
        }
    }
}


// MARK: Group

@MainActor
public class TMGroup {
    // TODO: Make optional, remove force unwrap
    weak var view: CMTimelineEditor!
    var name: String // = "Position"
    var axes: [TMAxis]
    
    // Where this group offset starts
    //var yOffset: CGFloat = 0
    var axisLayers: [TMAxisLayer] = []
    
#if os(macOS)
    let label = NSTextField(labelWithString: "")
#elseif os(iOS)
    let label = UILabel()
#endif
    
    
    init(view: CMTimelineEditor, name: String, axes: [TMAxis] = []) {
        self.view = view
        self.name = name
        self.axes = axes
        
        // Add label
#if os(macOS)
        label.stringValue = name
#elseif os(iOS)
        label.text = name
#endif
        label.sizeToFit()
        view.navigatorContentView.addSubview(label)
    }
    
    
    func disconnect() {
        label.removeFromSuperview()
        
        for axis in axes {
            axis.label.removeFromSuperview()
        }
        
        for axisLayer in axisLayers {
            axisLayer.baselineLayer.removeFromSuperlayer()
            axisLayer.bezierLayer.removeFromSuperlayer()
            axisLayer.mustacheLayer.removeFromSuperlayer()
            axisLayer.mustacheTipsLayer.removeFromSuperlayer()
            axisLayer.pointsLayer.removeFromSuperlayer()
        }
    }
    
    
    // MARK: Bézier curves, mustaches and control points
    
    private func addAxisLayer(color: PlatformColor) {
        guard let view else {
            return
        }
        
        let baselineLayer = CAShapeLayer()
        let bezierLayer = CAShapeLayer()
        let mustacheLayer = CAShapeLayer()
        let mustacheTipsLayer = CAShapeLayer()
        let pointsLayer = CAShapeLayer()
        
        view.curveContentView.withLayer { layer in
            baselineLayer.fillColor = nil
            baselineLayer.strokeColor = view.mustacheColor.withAlphaComponent(0.2).cgColor
            baselineLayer.lineWidth = 1
            baselineLayer.masksToBounds = false
            layer.addSublayer(baselineLayer)
            
            //bezierLayer.backgroundColor = PlatformColor.black.withAlphaComponent(0.1).cgColor
            bezierLayer.fillColor = nil
            bezierLayer.strokeColor = color.cgColor
            bezierLayer.lineWidth = view.curveThickness
            bezierLayer.masksToBounds = false
            layer.addSublayer(bezierLayer)
            
            mustacheLayer.fillColor = nil
            mustacheLayer.strokeColor = view.mustacheColor.cgColor
            mustacheLayer.lineWidth = view.mustacheThickness
            mustacheLayer.masksToBounds = false
            //layer.addSublayer(mustacheLayer)
            
            mustacheTipsLayer.fillColor = PlatformColor.white.cgColor
            mustacheTipsLayer.strokeColor = view.mustacheColor.cgColor
            mustacheTipsLayer.lineWidth = view.mustacheThickness
            //layer.addSublayer(mustacheTipsLayer)
            
            pointsLayer.fillColor = view.eyeColor.cgColor
            pointsLayer.strokeColor = color.cgColor
            pointsLayer.lineWidth = view.eyelidThickness
            layer.addSublayer(pointsLayer)
            
        }
        
        axisLayers.append(
            .init(
                baselineLayer: baselineLayer,
                bezierLayer: bezierLayer,
                mustacheLayer: mustacheLayer,
                mustacheTipsLayer: mustacheTipsLayer,
                pointsLayer: pointsLayer
            )
        )
    }
    
    
    private func initiateAnimation(for targetLayer: CAShapeLayer, _ animated: Bool) -> CABasicAnimation? {
        guard animated else {
            return nil
        }
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.repeatCount = 0
        animation.duration = 0.35
        animation.fromValue = targetLayer.path
        
        return animation
    }
    
    private func completeAnimation(_ animation: CABasicAnimation?, for targetLayer: CAShapeLayer) {
        guard let animation else {
            return
        }
        
        animation.toValue = targetLayer.path
        targetLayer.add(animation, forKey: "some key")
    }
    
    
    private func cgPoint(_ point: CMPoint) -> CGPoint {
        let offset = CGPoint(x: 0, y: view.axisHeight / 2)
        return point.makeCGPoint(offset: offset, scaleX: view.xScale, scaleY: view.axisHeight / 2)
    }
    
    
    private func updateBaseline(in targetLayer: CAShapeLayer, animated: Bool) {
        let width = view?.frame.width ?? 100
        
        let basicAnimation = initiateAnimation(for: targetLayer, animated)
        
        let path = CGMutablePath()
        let y = view.axisHeight / 2
        path.move(to: .init(x: 0, y: y))
        path.addLine(to: .init(x: width, y: y))
        
        targetLayer.path = path
        
        completeAnimation(basicAnimation, for: targetLayer)
    }
    
    private func updatePath(for records: [TMRecord], in targetLayer: CAShapeLayer, animated: Bool) {
        guard records.count > 1 else {
            return
        }
        
        let basicAnimation = initiateAnimation(for: targetLayer, animated)
        
        var lastRecord = records[0]
        
        let path = CGMutablePath()
        path.move(to: cgPoint(lastRecord.point))
        
        for index in 1 ..< records.count {
            let record = records[index]
            
            let point = cgPoint(record.point)
            path.addCurve(to: point,
                          control1: cgPoint(lastRecord.globalControl2),
                          control2: cgPoint(record.globalControl1))
            
            lastRecord = record
        }
        
        targetLayer.path = path
        
        completeAnimation(basicAnimation, for: targetLayer)
    }
    
    private func updateMustache(for records: [TMRecord], in targetLayer: CAShapeLayer, animated: Bool) {
        guard records.count > 1 else {
            return
        }
        
        let basicAnimation = initiateAnimation(for: targetLayer, animated)
        
        let path = CGMutablePath()
        for index in records.indices {
            let record = records[index]
            
            let point = cgPoint(record.point)
            
            path.move(to: point)
            path.addLine(to: cgPoint(record.globalControl1))
            
            path.move(to: point)
            path.addLine(to: cgPoint(record.globalControl2))
        }
        
        targetLayer.path = path
        
        completeAnimation(basicAnimation, for: targetLayer)
    }
    
    
    private func updateMustacheTips(for records: [TMRecord], in targetLayer: CAShapeLayer, animated: Bool) {
        guard records.count > 1 else {
            return
        }
        
        let basicAnimation = initiateAnimation(for: targetLayer, animated)
        
        let path = CGMutablePath()
        for index in records.indices {
            let record = records[index]
            
            let gPoint1 = cgPoint(record.globalControl1)
            let gPoint2 = cgPoint(record.globalControl2)
            
            path.move(to: gPoint1)
            path.addEllipse(in: .init(x: gPoint1.x - view.mustacheTipRadius,
                                      y: gPoint1.y - view.mustacheTipRadius,
                                      width: view.mustacheTipRadius * 2,
                                      height: view.mustacheTipRadius * 2))
            
            path.move(to: gPoint2)
            path.addEllipse(in: .init(x: gPoint2.x - view.mustacheTipRadius,
                                      y: gPoint2.y - view.mustacheTipRadius,
                                      width: view.mustacheTipRadius * 2,
                                      height: view.mustacheTipRadius * 2))
        }
        
        targetLayer.path = path
        
        completeAnimation(basicAnimation, for: targetLayer)
    }
    
    
    private func updatePoints(for records: [TMRecord], in targetLayer: CAShapeLayer, animated: Bool) {
        let path = CGMutablePath()
        
        let basicAnimation = initiateAnimation(for: targetLayer, animated)
        
        for record in records {
            let point = cgPoint(record.point)
            
            path.addEllipse(in: .init(x: point.x - view.eyeRadius,
                                      y: point.y - view.eyeRadius,
                                      width: view.eyeRadius * 2,
                                      height: view.eyeRadius * 2))
        }
        
        targetLayer.path = path
        
        completeAnimation(basicAnimation, for: targetLayer)
    }
    
    
    private func updateCurves(animated: Bool) {
        while axisLayers.count < axes.count {
            //addAxisLayer(color: .gray)
            
            addAxisLayer(color: view.colors[view.currentColorIndex])
            
            view.currentColorIndex = (view.currentColorIndex + 1) % view.colors.count
        }
        
        while axisLayers.count > axes.count {
            axisLayers.removeLast()
        }
        
        for index in axes.indices {
            let axis = axes[index]
            let layers = axisLayers[index]
            
            updateBaseline(in: layers.baselineLayer, animated: animated)
            updatePath(for: axis.points, in: layers.bezierLayer, animated: animated)
            updateMustache(for: axis.points, in: layers.mustacheLayer, animated: animated)
            updateMustacheTips(for: axis.points, in: layers.mustacheTipsLayer, animated: animated)
            updatePoints(for: axis.points, in: layers.pointsLayer, animated: animated)
        }
    }
    
    
    func updateLayout(level: Int, yOffset: CGFloat, width: CGFloat, height: CGFloat, animated: Bool) -> CGFloat {
        guard let view else {
            return yOffset
        }
        
        let padding: CGFloat = 8
        
        var currentYOffset = yOffset
        
        
        // Navigator size
        let navigatorFrame = view.navigatorContentView.frame
        
        // Label
        var labelFrame = label.frame
        labelFrame.origin = .init(
            x: navigatorFrame.width - labelFrame.width - padding,
            y: currentYOffset
        )
        label.frame = labelFrame
        currentYOffset += labelFrame.height + 8
        
        
        // Update curves
        updateCurves(animated: animated)
        
        
        // Update layer frame
        for index in axes.indices {
            // Label
            let axis = axes[index]
            var axisFrame = axis.label.frame
            axisFrame.origin = .init(
                x: navigatorFrame.width - axisFrame.width - padding,
                y: currentYOffset
            )
            axis.label.frame = axisFrame
            
            // Layer
            let layer = axisLayers[index]
            let layerFrame = PlatformRect(
                origin: .init(x: 0, y: currentYOffset),
                size: .init(width: width, height: height)
            )
            layer.baselineLayer.frame = layerFrame
            layer.bezierLayer.frame = layerFrame
            layer.mustacheLayer.frame = layerFrame
            layer.mustacheTipsLayer.frame = layerFrame
            layer.pointsLayer.frame = layerFrame
            
            // Height
            currentYOffset += height
        }
        
        return currentYOffset
    }
    
    
    public func createAxis(_ name: String, records: [TMRecord]) -> TMAxis {
        let axis = TMAxis(view: view, name: name, records: records)
        axes.append(axis)
        return axis
    }
}


extension TMGroup {
    static func mockPosition(view: CMTimelineEditor) -> TMGroup {
        .init(view: view, name: "Position", axes: [
            .init(view: view, name: "x", records: [
                .init(0, 0.1),
                .init(1, 1.0),
                .init(2, -0.6),
                .init(3, 0.4),
                .init(4, 0.9),
            ]),
            .init(view: view, name: "y", records: [
                .init(0, 0.55),
                .init(1, -0.01),
                .init(2, 0.4),
                .init(3, -0.2),
                .init(4, 0.35),
            ]),
            .init(view: view, name: "z", records: [
                .init(0, 0.95),
                .init(1, 0.2),
                .init(2, -0.1),
                .init(3, -0.3),
                .init(4, 0.15),
            ])
        ])
    }
    
    
    static func mockRotation(view: CMTimelineEditor) -> TMGroup {
        .init(view: view, name: "Rotation", axes: [
            .init(view: view, name: "x", records: [
                .init(0, 0.1),
                .init(1, 1.0),
                .init(2, -0.6),
                .init(3, 0.4),
                .init(4, 0.9),
            ]),
            .init(view: view, name: "y", records: [
                .init(0, 0.55),
                .init(1, -0.01),
                .init(2, 0.4),
                .init(3, -0.2),
                .init(4, 0.35),
            ]),
            .init(view: view, name: "z", records: [
                .init(0, 0.95),
                .init(1, 0.2),
                .init(2, -0.1),
                .init(3, -0.3),
                .init(4, 0.15),
            ])
        ])
    }
}


// MARK: Collection

struct TMAxisLayer {
    let baselineLayer: CAShapeLayer
    let bezierLayer: CAShapeLayer
    let mustacheLayer: CAShapeLayer
    let mustacheTipsLayer: CAShapeLayer
    let pointsLayer: CAShapeLayer
}


@MainActor
public class TMCollection {
    weak var view: CMTimelineEditor!
    var name: String
    var groups: [TMGroup]
    
    var children: [TMCollection]
    
#if os(macOS)
    let label = NSTextField(labelWithString: "")
#elseif os(iOS)
    let label = UILabel()
#endif
    
    
    init(view: CMTimelineEditor, name: String, groups: [TMGroup] = [], children: [TMCollection] = []) {
        self.view = view
        self.name = name
        self.groups = groups
        self.children = children
        
        // Add label
#if os(macOS)
        label.stringValue = name
#elseif os(iOS)
        label.text = name
#endif
        label.sizeToFit()
        view.navigatorContentView.addSubview(label)
    }
    
    
    func disconnect() {
        label.removeFromSuperview()
        
        for group in groups {
            group.disconnect()
        }
        
        for child in children {
            child.disconnect()
        }
    }
    
    
    public func resetControlPoints() {
        for group in groups {
            for index in group.axes.indices {
                group.axes[index].resetControlPoints()
            }
        }
        
        for child in children {
            child.resetControlPoints()
        }
    }
    
    
    func updateLayout(level: Int, yOffset: CGFloat, width: CGFloat, height: CGFloat, animated: Bool) -> CGFloat {
        let padding: CGFloat = 8
        
        var currentYOffset = yOffset + padding
        
        var axisFrame = label.frame
        axisFrame.origin = .init(
            x: padding + CGFloat(level * 24),
            y: currentYOffset
        )
        label.frame = axisFrame
        currentYOffset += axisFrame.height + padding
        
        for group in groups {
            currentYOffset = group.updateLayout(level: level, yOffset: currentYOffset, width: width, height: height, animated: animated)
        }
        
        for child in children {
            currentYOffset = child.updateLayout(level: level + 1, yOffset: currentYOffset, width: width, height: height, animated: animated)
        }
        
        return currentYOffset
    }
    
    
    public func createGroup(_ name: String) -> TMGroup {
        let group = TMGroup(view: view, name: name)
        groups.append(group)
        return group
    }
    
    
    public func createCollection(_ name: String) -> TMCollection {
        // FIXME: Return optional
        let view = view!
        //guard let view else {
        //    return
        //}
        
        let collection = TMCollection(view: view, name: name)
        children.append(collection)
        return collection
    }
    
    
    public func updateLayout() {
        view.updateLayout()
    }
}


extension TMCollection {
    static func mockLeg(view: CMTimelineEditor, side: String) -> TMCollection {
        .init(view: view, name: "Hip \(side)", groups: [
            .mockRotation(view: view)
        ], children: [
            .init(view: view, name: "Leg \(side)", groups: [
                .mockRotation(view: view)
            ], children: [
                .init(view: view, name: "Foot \(side)", groups: [
                    .mockRotation(view: view)
                ], children: []),
            ]),
        ])
    }
    
    
    static func mockArm(view: CMTimelineEditor, side: String) -> TMCollection {
        .init(view: view, name: "Shoulder \(side)", groups: [
            .mockRotation(view: view)
        ], children: [
            .init(view: view, name: "Arm \(side)", groups: [
                .mockRotation(view: view)
            ], children: [
                .init(view: view, name: "Hand \(side)", groups: [
                    .mockRotation(view: view)
                ], children: []),
            ]),
        ])
    }
}


// MARK: Delegate

public protocol CMTimelimeViewDelegate: AnyObject {
    // Call setNeedsLayout() by every change
}


// MARK: Data source

@MainActor
public class TimelineEditorModel {
    weak var view: CMTimelineEditor?
    var collections: [TMCollection]
    
    init(view: CMTimelineEditor, collections: [TMCollection]) {
        self.view = view
        self.collections = collections
    }
    
    
    public func updateLayout(animated: Bool) -> CGSize {
        guard let view else {
            return .zero
        }
        
        var yOffset: CGFloat = 0
        let width = view.xScale * CGFloat(view.maxXValue)
        let height = view.axisHeight
        
        for collection in collections {
            yOffset = collection.updateLayout(level: 0, yOffset: yOffset, width: width, height: height, animated: animated)
        }
        
        return .init(width: width, height: yOffset)
    }
    
    
    public func clear() {
        for collection in collections {
            collection.disconnect()
        }
        collections.removeAll()
    }
    
    
    public func createCollection(_ name: String) -> TMCollection? {
        guard let view = view else {
            return nil
        }
        
        let collection = TMCollection(view: view, name: name)
        collections.append(collection)
        return collection
    }
}


extension TimelineEditorModel {
    static func mock(view: CMTimelineEditor) -> TimelineEditorModel {
        return TimelineEditorModel(view: view, collections: [
            .init(
                view: view,
                name: "Root",
                groups: [
                    .mockPosition(view: view),
                    .mockRotation(view: view)
                ], children: [
                    .mockLeg(view: view, side: "left"),
                    .mockLeg(view: view, side: "right"),
                    .init(view: view, name: "Torso", groups: [
                        .mockRotation(view: view)
                    ], children: [
                        .mockArm(view: view, side: "left"),
                        .mockArm(view: view, side: "right"),
                        .init(view: view, name: "Head", groups: [
                            .mockRotation(view: view)
                        ], children: []),
                    ]),
                ]
            )
        ])
        
    }
}


// MARK: Timeline editor

public class CMTimelineEditor: PlatformView {
    var contents: TimelineEditorModel!
    
    /// Contains curves, points and mustaches
    let contentView = PlatformView()
    let scrollView = PlatformScrollView()
    
    /// Contains curves, points and mustaches
    let curveContentView = PlatformView()
    /// Navigator
    let navigatorContentView = PlatformView()
    let navigatorDivider = PlatformView()
    
    
    var xScale: CGFloat = 32
    var axisHeight: CGFloat = 64
    
    fileprivate var currentColorIndex = 0
    fileprivate let colors: [PlatformColor] = [
        .red.darken(by: 0.9),
        .green.darken(by: 0.8),
        .blue.darken(by: 0.9)
    ]
    
    
    var curveThickness: CGFloat = 3 {
        didSet {
            //
        }
    }
    
    
    var eyeRadius: CGFloat = 4 {
        didSet {
            // Rebuild eyelid paths
        }
    }
    
    var eyelidThickness: CGFloat = 3 {
        didSet {
            //for axisLayer in axisLayers {
            //    axisLayer.pointsLayer.lineWidth = eyelidThickness
            //}
        }
    }
    
    var eyeColor: PlatformColor = .dynamic(
        PlatformColor.white,
        PlatformColor.white.darken(by: 0.8)
    )
    
    
    var mustacheThickness: CGFloat = 2
    
    var mustacheTipRadius: CGFloat = 3
    
    var mustacheColor: PlatformColor = .dynamic(
        PlatformColor.black.withAlphaComponent(0.5),
        PlatformColor.white.withAlphaComponent(0.75)//.darken(by: 0.8)
    )
    
    
    public override func setupLayout() {
        contents = .mock(view: self)
        
        setWantsLayer()
        
        
        // Curves
        contentView.setWantsLayer()
#if os(macOS)
        scrollView.documentView = contentView
        contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(scrollContentViewBoundsChange),
                                               name: NSView.boundsDidChangeNotification,
                                               object: scrollView.contentView)
#elseif os(iOS)
        scrollView.delegate = self
        scrollView.addSubview(contentView)
#endif
        addSubview(scrollView)
        
        
        // Curve content view
        curveContentView.setWantsLayer()
        contentView.addSubview(curveContentView)
        
        
        // Navigator
        navigatorContentView.setWantsLayer()
        contentView.addSubview(navigatorContentView)
        
        navigatorContentView.addSubview(navigatorDivider)
        
        
        // Fill with random points
#if false
        for index in axes.indices {
            axes[index].points.removeAll()
        }
        
        for axisIndex in axes.indices {
            for index in 0...50 {
                axes[axisIndex].points.append(
                    .init(Float(index), 0)
                )
            }
        }
#endif
        
        
#if os(iOS)
        backgroundColor = .secondarySystemBackground
#endif
        
        for collection in contents.collections {
            collection.resetControlPoints()
        }
        
        //animateChange()
    }
    
    
    
    private func animateChange() {
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000 / 2)
            //try await Task.sleep(nanoseconds: 350_000_000)
            
            
            @MainActor
            func randomizeCollection(_ collection: TMCollection) {
                for group in collection.groups {
                    for axisIndex in group.axes.indices {
                        for pointIndex in group.axes[axisIndex].points.indices {
                            let point = group.axes[axisIndex].points[pointIndex].point
                            group.axes[axisIndex].points[pointIndex].point = .init(x: point.x, y: .random(in: -1...1))
                        }
                        group.axes[axisIndex].resetControlPoints()
                    }
                }
                
                for child in collection.children {
                    randomizeCollection(child)
                }
            }
            
            for collection in contents.collections {
                randomizeCollection(collection)
                collection.resetControlPoints()
                _ = collection.updateLayout(level: 0, yOffset: 0, width: bounds.width, height: axisHeight, animated: true)
            }
            
            animateChange()
        }
    }
    
    
    
    let padding: CGFloat = 20
    
    /// Cached `x` component of every `TMCollection` data.
    private(set) var maxXValue: Float = 0
    
    /// Call only on adding/removing points to not nuke performance
    private func recalculateMaxXValue() {
        func collect(_ col: TMCollection) -> [Float] {
            let values = col.groups.flatMap { group in
                group.axes.flatMap { axis in
                    axis.points.map { point in
                        point.point.x
                    }
                }
            }
            
            let childValues = col.children.flatMap { col in
                collect(col)
            }
            
            return values + childValues
        }
        maxXValue = contents.collections.flatMap({ collect($0) }).max() ?? 1
    }

    
    //let offset = CGPoint(x: 20, y: bounds.height / 2)
    var offset: CGPoint {
        CGPoint(x: padding, y: axisHeight / 2)
    }
    
    func cgPoint(_ point: CMPoint) -> CGPoint {
        point.makeCGPoint(offset: offset, scaleX: xScale, scaleY: axisHeight / 2)
    }
    
    
    private var needsCurveUpdate: Bool = true
    /// Update curves at next layout update
    func invalidateLayout() {
        needsCurveUpdate = true
        setNeedsLayout()
    }
    
    
    let navigatorWidth: CGFloat = 192
    
    private func updateNavigatorLayout() {
#if os(macOS)
        let scrollOffset = scrollView.contentView.bounds.origin
#else
        let scrollOffset = scrollView.contentOffset
#endif
        
        var curveFrame = navigatorContentView.frame
        curveFrame.origin.x = -(safeAreaInsets.left - scrollOffset.x)
        
        navigatorContentView.frame = curveFrame
    }
    
    
    public override func updateLayout() {
        // Update curves if needed
        //if needsCurveUpdate {
            // Call only on adding/removing points
            recalculateMaxXValue()
            //
            
            needsCurveUpdate = false
        //}
        
        let contentSize = contents.updateLayout(animated: false)
        //print(contentSize)
        
        // Navigator content
        navigatorContentView.frame = .init(
            origin: .zero,
            size: .init(width: navigatorWidth, height: contentSize.height)
        )
        updateNavigatorLayout()
        
        // Divider
        navigatorDivider.frame = .init(
            origin: .init(x: navigatorContentView.frame.maxX - 1, y: 0),
            size: .init(width: 1, height: navigatorContentView.frame.height)
        )
        
        // Curve content
        curveContentView.frame = .init(
            origin: .init(x: navigatorContentView.frame.maxX, y: 0),
            size: contentSize
        )
        
        // Set scroll view content size
        let totalWidth = max(navigatorWidth + contentSize.width, bounds.width)
        contentView.frame = .init(
            origin: contentView.frame.origin,
            size: .init(width: totalWidth, height: contentSize.height)
        )
        
        // Scroll view size
        scrollView.frame = bounds
        
#if os(iOS)
        //scrollView.contentInset = .init(top: 0, left: navigatorWidth, bottom: 0, right: 0)
        scrollView.scrollsToTop = true
        scrollView.contentSize = contentView.frame.size
#endif
    }
    
    
    public override func updateAppearance() {
#if os(macOS)
        navigatorContentView.layer?.backgroundColor = PlatformColor.controlBackgroundColor.cgColor
        //curveContentView.layer?.backgroundColor = PlatformColor.gray.cgColor
        navigatorDivider.layer?.backgroundColor = PlatformColor.separatorColor.cgColor
#elseif os(iOS)
        navigatorContentView.backgroundColor = .secondarySystemBackground
        //curveContentView.backgroundColor = .gray
        navigatorDivider.backgroundColor = .separator
#endif
    }
    
    
    //public override func scrollWheel(with event: NSEvent) {
    //    axisHeight += event.scrollingDeltaY * 0.1
    //    updateCurves()
    //}
}


// MARK: Scroll view delegate

#if os(macOS)

extension CMTimelineEditor {
    @objc func scrollContentViewBoundsChange(_ notification: Notification) {
        updateNavigatorLayout()
    }
}

#elseif os(iOS)

extension CMTimelineEditor: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigatorLayout()
    }
}

#endif


// MARK: View controller

public class TimelineEditorController: PlatformViewController {
    fileprivate let timelineView = CMTimelineEditor()
    
    
    public override func setupLayout() {
        view = timelineView
    }
}


// MARK: SwiftUI bridge

#if os(macOS)

public struct TimelineEditor: NSViewControllerRepresentable {
    let modelCallback: (_ model: TimelineEditorModel) -> Void
    
    
    public init(modelCallback: @escaping (_ model: TimelineEditorModel) -> Void = { _ in }) {
        self.modelCallback = modelCallback
    }
    
    public func makeNSViewController(context: Context) -> TimelineEditorController {
        let vc = TimelineEditorController()
        modelCallback(vc.timelineView.contents)
        return vc
    }
    
    public func updateNSViewController(_ nsViewController: TimelineEditorController, context: Context) {
        //
    }
}

#else

public struct TimelineEditor: UIViewControllerRepresentable {
    let modelCallback: (_ model: TimelineEditorModel) -> Void
    
    
    public init(modelCallback: @escaping (_ model: TimelineEditorModel) -> Void = { _ in }) {
        self.modelCallback = modelCallback
    }
    
    public func makeUIViewController(context: Context) -> TimelineEditorController {
        let vc = TimelineEditorController()
        modelCallback(vc.timelineView.contents)
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: TimelineEditorController, context: Context) {
        //
    }
}

#endif


// MARK: Preview

@available(macOS 15.0, iOS 18.0, *)
#Preview(traits: .fixedLayout(width: 384, height: 768)) {
#if true
    TimelineEditor()
        .ignoresSafeArea()
        //.frame(height: 1024)
#else
    ScrollView {
        VStack {
            ForEach(0..<100) { _ in
                HStack {
                    Text("Hello")
                        .padding()
    
                    Spacer()
                }
            }
        }
    }
#endif
    
}
