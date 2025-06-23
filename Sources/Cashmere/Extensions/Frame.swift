//
//  Frame.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 28.05.25.
//

import CoreGraphics
import CMPlatform


public extension PlatformRect {
    init(surrounding rects: [PlatformRect]) {
        let minX = rects.map(\.minX).min() ?? 0
        let minY = rects.map(\.minY).min() ?? 0
        let maxX = rects.map(\.maxX).max() ?? 0
        let maxY = rects.map(\.maxY).max() ?? 0
        
        self.init(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    
    func offsetting(by offset: PlatformPoint) -> PlatformRect {
        .init(x: origin.x + offset.x, y: origin.y + offset.y, width: width, height: height)
    }
    
    
    var center: PlatformPoint {
        .init(x: midX, y: midY)
    }
    
    
    var localCenter: PlatformPoint {
        .init(x: width / 2, y: height / 2)
    }
}


extension PlatformRect {
    var compactString: String {
        "(\(Int(origin.x)), \(Int(origin.y)), \(Int(size.width)), \(Int(size.height)))"
    }
}
