//
//  Point.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 29.05.25.
//

import CMPlatform


public extension PlatformPoint {
    var length: CGFloat {
        sqrt(x * x + y * y)
    }
    
    func inverted() -> PlatformPoint {
        .init(x: -x, y: -y)
    }
    
    func normalized() -> PlatformPoint {
        self / length
    }
}


public func + (lhs: PlatformPoint, rhs: PlatformPoint) -> PlatformPoint {
    .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func - (lhs: PlatformPoint, rhs: PlatformPoint) -> PlatformPoint {
    .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}


public func * (lhs: PlatformPoint, rhs: CGFloat) -> PlatformPoint {
    .init(x: lhs.x * rhs, y: lhs.y * rhs)
}

public func / (lhs: PlatformPoint, rhs: CGFloat) -> PlatformPoint {
    .init(x: lhs.x / rhs, y: lhs.y / rhs)
}
