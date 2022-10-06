//
//  BoundingBox.swift
//  Wacoma
//
//  Created by James Hanson on 9/29/20.
//

import Foundation
import simd

public struct BoundingBox: Sendable, Codable {
    
    public var xMin: Float
    public var yMin: Float
    public var zMin: Float
    
    public var xMax: Float
    public var yMax: Float
    public var zMax: Float

    public init(x0: Float, y0: Float, z0: Float, x1: Float, y1: Float, z1: Float) {
        xMin = Float.minimum(x0, x1)
        yMin = Float.minimum(y0, y1)
        zMin = Float.minimum(z0, z1)
        
        xMax = Float.maximum(x0, x1)
        yMax = Float.maximum(y0, y1)
        zMax = Float.maximum(z0, z1)
    }
    
    public init(_ point: SIMD3<Float>) {
        xMin = point.x
        yMin = point.y
        zMin = point.z
        
        xMax = point.x
        yMax = point.y
        zMax = point.z
    }

    public init(center: SIMD3<Float>, halfSize: Float) {
        xMin = center.x - halfSize
        yMin = center.y - halfSize
        zMin = center.z - halfSize

        xMax = center.x + halfSize
        yMax = center.y + halfSize
        zMax = center.z + halfSize
    }

    public init(_ p0: SIMD3<Float>, _ p1: SIMD3<Float>) {
        xMin = Swift.min(p0.x, p1.x)
        yMin = Swift.min(p0.y, p1.y)
        zMin = Swift.min(p0.z, p1.z)

        xMax = Swift.max(p0.x, p1.x)
        yMax = Swift.max(p0.y, p1.y)
        zMax = Swift.max(p0.z, p1.z)
    }

    public mutating func cover(_ point: SIMD3<Float>) {
        if point.x < xMin {
            xMin = point.x
        }
        if point.y < yMin {
            yMin = point.y
        }
        if point.z < zMin {
            zMin = point.z
        }
        
        if point.x > xMax {
            xMax = point.x
        }
        if point.y > yMax {
            yMax = point.y
        }
        if point.z > zMax {
            zMax = point.z
        }
    }
    
    public mutating func cover(_ bbox: BoundingBox) {
        self.cover(bbox.min)
        self.cover(bbox.max)
    }
}

extension BoundingBox {
    
    public static func unitCube() -> BoundingBox {
        return BoundingBox(x0: 0, y0: 0, z0: 0, x1: 1, y1: 1, z1: 1)
    }
    
    public static func centeredCube(_ size: Float = 1) -> BoundingBox {
        let w = (size > 0) ? size/2 : 0.5
        return BoundingBox(x0: -w, y0: -w, z0: -w, x1: w, y1: w, z1: w)
    }
}

extension BoundingBox {
    
    public var xCenter: Float {
        xMin + xSize/2
    }
    
    public var yCenter: Float {
        yMin + ySize/2
    }
    
    public var zCenter: Float {
        zMin + zSize/2
    }
    
    public var xSize: Float {
        xMax - xMin
    }
    
    public var ySize: Float {
        yMax - yMin
    }
    
    public var zSize: Float {
        zMax - zMin
    }
    
    public var min: SIMD3<Float> {
        return SIMD3<Float>(xMin, yMin, zMin)
    }

    public var max: SIMD3<Float> {
        return SIMD3<Float>(xMax, yMax, zMax)
    }

    public var center: SIMD3<Float> {
        return SIMD3<Float>(xCenter, yCenter, zCenter)
    }
    
    public var size: SIMD3<Float>  {
        return SIMD3<Float>(xSize, ySize, zSize)
    }
    
    public var xBounds: ClosedRange<Float> {
        return xMin...xMax
    }
    
    public var yBounds: ClosedRange<Float> {
        return yMin...yMax
    }
    
    public var zBounds: ClosedRange<Float> {
        return zMin...zMax
    }
    
    public var corners: [SIMD3<Float>] {
        [
            SIMD3<Float>(xMin, yMin, zMin),
            SIMD3<Float>(xMin, yMin, zMax),
            SIMD3<Float>(xMin, yMax, zMin),
            SIMD3<Float>(xMin, yMax, zMax),
            SIMD3<Float>(xMax, yMin, zMin),
            SIMD3<Float>(xMax, yMin, zMax),
            SIMD3<Float>(xMax, yMax, zMin),
            SIMD3<Float>(xMax, yMax, zMax)
        ]
    }
    
    public var radius: Float {
        var rx: Float = 0
        let cx = self.center
        for corner in corners {
            let d = simd_distance(corner, cx)
            if d > rx {
                rx = d
            }
        }
        return rx
    }
}
