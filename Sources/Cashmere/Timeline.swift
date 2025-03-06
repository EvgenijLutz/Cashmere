//
//  Timeline.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 03.03.25.
//

import CMPlatform
import SwiftUI


// MARK: Point

public struct TMPoint: Sendable {
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
    
    public var normalized: TMPoint {
        let len = length
        guard abs(len) > 0.00001 else {
            return .init(x: 1, y: 0)
        }
        
        return .init(x: x / length, y: y / length)
    }
    
    public static func + (lhs: TMPoint, rhs: TMPoint) -> TMPoint {
        .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    public static func - (lhs: TMPoint, rhs: TMPoint) -> TMPoint {
        .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    public static func * (lhs: TMPoint, rhs: Float) -> TMPoint {
        .init(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    public static func / (lhs: TMPoint, rhs: Float) -> TMPoint {
        .init(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}


public prefix func - (value: TMPoint) -> TMPoint {
    .init(x: -value.x, y: -value.y)
}


public extension TMPoint {
    func makeCGPoint(offset: CGPoint, scaleX: CGFloat, scaleY: CGFloat) -> CGPoint {
        .init(
            x: offset.x + CGFloat(x) * scaleX,
            y: offset.y - CGFloat(y) * scaleY
        )
    }
}


// MARK: Record

public struct TMRecord: Sendable {
    public var point: TMPoint
    
    public init(point: TMPoint) {
        self.point = point
    }
    
    public init(_ x: Float, _ y: Float) {
        point = .init(x: x, y: y)
    }
    
    public var localControl1: TMPoint = .init(x: -0.5, y: 0)
    public var globalControl1: TMPoint {
        point + localControl1
    }
    
    public var localControl2: TMPoint = .init(x: 0.5, y: 0)
    public var globalControl2: TMPoint {
        point + localControl2
    }
}


// MARK: Axis

struct TMData: Sendable {
    var name: String
    var points: [TMRecord]
    
    init(name: String, points: [TMRecord]) {
        self.name = name
        self.points = points
    }
    
    mutating func resetControlPoints() {
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


extension TMData {
    
}


// MARK: Group

@MainActor
class TMGroup {
    var name: String // = "Position"
    var axes: [TMData]
    
    init(name: String, axes: [TMData]) {
        self.name = name
        self.axes = axes
    }
}


extension TMGroup {
    static var mockPosition: TMGroup {
        .init(name: "Position", axes: [
            .init(name: "x", points: [
                .init(0, 0.1),
                .init(1, 1.5),
                .init(2, -0.6),
                .init(3, 0.4),
                .init(4, 0.9),
            ]),
            .init(name: "y", points: [
                .init(0, 0.55),
                .init(1, -0.01),
                .init(2, 0.4),
                .init(3, -0.2),
                .init(4, 0.35),
            ]),
            .init(name: "z", points: [
                .init(0, 0.95),
                .init(1, 0.2),
                .init(2, -0.1),
                .init(3, -0.3),
                .init(4, 0.15),
            ])
        ])
    }
    
    
    static var mockRotation: TMGroup {
        .init(name: "Rotation", axes: [
            .init(name: "x", points: [
                .init(0, 0.1),
                .init(1, 1.5),
                .init(2, -0.6),
                .init(3, 0.4),
                .init(4, 0.9),
            ]),
            .init(name: "y", points: [
                .init(0, 0.55),
                .init(1, -0.01),
                .init(2, 0.4),
                .init(3, -0.2),
                .init(4, 0.35),
            ]),
            .init(name: "z", points: [
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

@MainActor
class TMCollection {
    weak var view: CMTimelineView?
    var name: String
    var groups: [TMGroup]
    
    var children: [TMCollection]
    
    init(view: CMTimelineView, name: String, groups: [TMGroup], children: [TMCollection]) {
        self.view = view
        self.name = name
        self.groups = groups
        self.children = children
    }
}


extension TMCollection {
    static func mockLeg(view: CMTimelineView, side: String) -> TMCollection {
        .init(view: view, name: "Hip \(side)", groups: [
            .mockRotation
        ], children: [
            .init(view: view, name: "Leg \(side)", groups: [
                .mockRotation
            ], children: [
                .init(view: view, name: "Foot \(side)", groups: [
                    .mockRotation
                ], children: []),
            ]),
        ])
    }
    
    
    static func mockArm(view: CMTimelineView, side: String) -> TMCollection {
        .init(view: view, name: "Shoulder \(side)", groups: [
            .mockRotation
        ], children: [
            .init(view: view, name: "Arm \(side)", groups: [
                .mockRotation
            ], children: [
                .init(view: view, name: "Hand \(side)", groups: [
                    .mockRotation
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
class TimelineViewModel {
    weak var view: CMTimelineView?
    var collections: [TMCollection]
    
    init(view: CMTimelineView, collections: [TMCollection]) {
        self.view = view
        self.collections = collections
    }
}


extension TimelineViewModel {
    static func mock(view: CMTimelineView) -> TimelineViewModel {
        return TimelineViewModel(view: view, collections: [
            .init(
                view: view,
                name: "Root",
                groups: [
                    .mockPosition,
                    .mockRotation
                ], children: [
                    .mockLeg(view: view, side: "left"),
                    .mockLeg(view: view, side: "right"),
                    .init(view: view, name: "Torso", groups: [
                        .mockRotation
                    ], children: [
                        .mockArm(view: view, side: "left"),
                        .mockArm(view: view, side: "right"),
                        .init(view: view, name: "Head", groups: [
                            .mockRotation
                        ], children: []),
                    ]),
                ]
            )
        ])
        
    }
}


// MARK: Timeline view

public class CMTimelineView: PlatformView {
    var axes: [TMData] = [
        .init(name: "Rotation X", points: [
            .init(0, 0.1),
            .init(1, 1.5),
            .init(2, -0.6),
            .init(3, 0.4),
            .init(4, 0.9),
        ]),
        .init(name: "Rotation Y", points: [
            .init(0, 0.55),
            .init(1, -0.01),
            .init(2, 0.4),
            .init(3, -0.2),
            .init(4, 0.35),
        ]),
        .init(name: "Rotation Z", points: [
            .init(0, 0.95),
            .init(1, 0.2),
            .init(2, -0.1),
            .init(3, -0.3),
            .init(4, 0.15),
        ])
    ]
    
    
    
    
    private var currentColorIndex = 0
    private let colors: [PlatformColor] = [
        .red.darken(by: 0.9),
        .green.darken(by: 0.8),
        .blue.darken(by: 0.9)
    ]
    
    
    
    var eyeRadius: CGFloat = 4.5 {
        didSet {
            // Rebuild eyelid paths
        }
    }
    
    var eyelidThickness: CGFloat = 3 {
        didSet {
            for axisLayer in axisLayers {
                axisLayer.pointsLayer.lineWidth = eyelidThickness
            }
        }
    }
    
    var eyeColor: PlatformColor = .dynamic(
        PlatformColor.white,
        PlatformColor.white.darken(by: 0.8)
    )
    
    var mustacheTipRadius: CGFloat = 3
    
    var mustacheColor: PlatformColor = .dynamic(
        PlatformColor.black.withAlphaComponent(0.2),
        PlatformColor.white.withAlphaComponent(0.75)//.darken(by: 0.8)
    )
    
    
    struct AxisLayer {
        let bezierLayer: CAShapeLayer
        let mustacheLayer: CAShapeLayer
        let mustacheTipsLayer: CAShapeLayer
        let pointsLayer: CAShapeLayer
    }
    var axisLayers: [AxisLayer] = []
    
    private func addAxisLayer(color: PlatformColor) {
        let bezierLayer = CAShapeLayer()
        let mustacheLayer = CAShapeLayer()
        let mustacheTipsLayer = CAShapeLayer()
        let pointsLayer = CAShapeLayer()
        
        withLayer { layer in
            bezierLayer.fillColor = nil
            bezierLayer.strokeColor = color.cgColor
            bezierLayer.lineWidth = 3
            layer.addSublayer(bezierLayer)
            
            mustacheLayer.fillColor = nil
            mustacheLayer.strokeColor = mustacheColor.cgColor
            mustacheLayer.lineWidth = 1
            layer.addSublayer(mustacheLayer)
            
            mustacheTipsLayer.fillColor = PlatformColor.white.cgColor
            mustacheTipsLayer.strokeColor = mustacheColor.cgColor
            mustacheTipsLayer.lineWidth = 1
            layer.addSublayer(mustacheTipsLayer)
            
            pointsLayer.fillColor = eyeColor.cgColor
            pointsLayer.strokeColor = color.cgColor
            pointsLayer.lineWidth = eyelidThickness
            layer.addSublayer(pointsLayer)
            
        }
        
        axisLayers.append(
            .init(
                bezierLayer: bezierLayer,
                mustacheLayer: mustacheLayer,
                mustacheTipsLayer: mustacheTipsLayer,
                pointsLayer: pointsLayer
            )
        )
    }
    
    
    public override func setupLayout() {
        setWantsLayer()
        
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
        
        for index in axes.indices {
            axes[index].resetControlPoints()
        }
        
        //animateChange()
    }
    
    
    
    private func animateChange() {
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000 / 2)
            //try await Task.sleep(nanoseconds: 350_000_000)
            
            
            for axisIndex in axes.indices {
                for pointIndex in axes[axisIndex].points.indices {
                    let point = axes[axisIndex].points[pointIndex].point
                    axes[axisIndex].points[pointIndex].point = .init(x: point.x, y: .random(in: -1...1))
                }
                axes[axisIndex].resetControlPoints()
            }
            updateCurves(animated: true)
            
            animateChange()
        }
    }
    
    
    
    let padding: CGFloat = 20
    
    //let xScale: CGFloat = 90
    var xScale: CGFloat {
        let minXValue: Float = 0
        guard let maxXValue = axes.flatMap({ $0.points.map { $0.point.x }}).max() else {
            return 1
        }
        
        let range = maxXValue - minXValue
        guard range > 0.00001 else {
            return 1
        }
        
        
        return (bounds.width - padding - padding) / CGFloat(range)
    }
    
    var yScale: CGFloat = 50
    
    //let offset = CGPoint(x: 20, y: bounds.height / 2)
    var offset: CGPoint {
        CGPoint(x: padding, y: bounds.height / 2)
    }
    
    func cgPoint(_ point: TMPoint) -> CGPoint {
        point.makeCGPoint(offset: offset, scaleX: xScale, scaleY: yScale)
    }
    
    
    public override func updateLayout() {
        updateCurves()
        
        for layer in axisLayers {
            layer.bezierLayer.frame = bounds
            layer.pointsLayer.frame = bounds
        }
    }
    
    public override func scrollWheel(with event: NSEvent) {
        yScale += event.scrollingDeltaY * 0.1
        updateCurves()
    }
}


// MARK: Bézier curves, mustaches and control points

extension CMTimelineView {
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
            path.addEllipse(in: .init(x: gPoint1.x - mustacheTipRadius,
                                      y: gPoint1.y - mustacheTipRadius,
                                      width: mustacheTipRadius * 2,
                                      height: mustacheTipRadius * 2))
            
            path.move(to: gPoint2)
            path.addEllipse(in: .init(x: gPoint2.x - mustacheTipRadius,
                                      y: gPoint2.y - mustacheTipRadius,
                                      width: mustacheTipRadius * 2,
                                      height: mustacheTipRadius * 2))
        }
        
        targetLayer.path = path
        
        completeAnimation(basicAnimation, for: targetLayer)
    }
    
    
    private func updatePoints(for records: [TMRecord], in targetLayer: CAShapeLayer, animated: Bool) {
        let path = CGMutablePath()
        
        let basicAnimation = initiateAnimation(for: targetLayer, animated)
        
        for record in records {
            let point = cgPoint(record.point)
            
            path.addEllipse(in: .init(x: point.x - eyeRadius,
                                      y: point.y - eyeRadius,
                                      width: eyeRadius * 2,
                                      height: eyeRadius * 2))
        }
        
        targetLayer.path = path
        
        completeAnimation(basicAnimation, for: targetLayer)
    }
    
    
    private func updateCurves(animated: Bool = false) {
        while axisLayers.count < axes.count {
            //addAxisLayer(color: .gray)
            
            addAxisLayer(color: colors[currentColorIndex])
            
            currentColorIndex = (currentColorIndex + 1) % colors.count
        }
        
        while axisLayers.count > axes.count {
            axisLayers.removeLast()
        }
        
        for index in axes.indices {
            let axis = axes[index]
            let layers = axisLayers[index]
            
            updatePath(for: axis.points, in: layers.bezierLayer, animated: animated)
            updateMustache(for: axis.points, in: layers.mustacheLayer, animated: animated)
            updateMustacheTips(for: axis.points, in: layers.mustacheTipsLayer, animated: animated)
            updatePoints(for: axis.points, in: layers.pointsLayer, animated: animated)
        }
    }
    
}


// MARK: View controller

open class PlatformViewController: CMViewController {
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupLayout()
    }
    
    open func setupLayout() {
        // Override by superclasses
    }
}


public class TimelineViewController: PlatformViewController {
    private let timelineView = CMTimelineView()
    
    
    public override func setupLayout() {
        view = timelineView
    }
}


// MARK: SwiftUI bridge

#if os(macOS)

public struct TimelineView: NSViewControllerRepresentable {
    public init() {
        //
    }
    
    public func makeNSViewController(context: Context) -> TimelineViewController {
        return TimelineViewController()
    }
    
    public func updateNSViewController(_ nsViewController: TimelineViewController, context: Context) {
        //
    }
}

#else

public struct TimelineView: UIViewControllerRepresentable {
    public init() {
        //
    }
    
    public func makeUIViewController(context: Context) -> TimelineViewController {
        return TimelineViewController()
    }
    
    public func updateUIViewController(_ uiViewController: TimelineViewController, context: Context) {
        //
    }
}

#endif


// MARK: Preview

@available(macOS 15.0, iOS 18.0, *)
#Preview {
    TimelineView()
        //.background { Color.red }
}
