//
//  FOV.swift
//  
//
//  Created by Jim Hanson on 1/8/22.
//

import SwiftUI
import simd

public protocol FOVController {

    /// forward distance in view coords from the plane of the POV to the point at which the figure starts to fade out
    var fadeoutOnset: Float { get set }

    /// distance over which the figure fades out
    /// fadeoutDistance+fadeoutOnset is the forward distance in view coords from the plane of the POV to the point at which the fadeout is complete
    var fadeoutDistance: Float { get set }

    /// physical dimensions of the UI view in pixels.
    var viewSize: CGSize { get set }

    /// front of the FOV, i.e.,  forward distance in view coords from the plane of the POV to the nearest renderable point
    var zNear: Float { get set }

    /// back of the FOV, i.e., forward distance in view coords from the plane of the POV to the farthest renderable point
    var zFar: Float { get set }

    var projectionMatrix: float4x4 { get }

    /// Sets the POV's properties to the values they should have at the given system time.
    /// This is called during each rendering cycle as a way to support a POV that changes on its own
    func update(_ date: Date)
}

public class PerspectiveFOVController: ObservableObject, FOVController {

    @Published public var fadeoutOnset: Float

    @Published public var fadeoutDistance: Float

    public var viewSize = CGSize(width: 1, height: 1) // dummy values > 0 for safety

    public var zNear: Float

    public var zFar: Float

    /// angular width in radians
    public var yFOV: Float = .piOverTwo

    public var projectionMatrix: float4x4 {
        let aspectRatio = (viewSize.height > 0) ? Float(viewSize.width) / Float(viewSize.height) : 1
        return float4x4(perspectiveProjectionRHFovY: yFOV,
                        aspectRatio: aspectRatio,
                        nearZ: zNear,
                        farZ: zFar)
    }

    public init(fadeoutOnset: Float = 0, fadeoutDistance: Float = 1000, zNear: Float = 0.001, zFar: Float = 1000, yFOV: Float = .piOverTwo) {
        self.fadeoutOnset = fadeoutOnset
        self.fadeoutDistance = fadeoutDistance
        self.zNear = zNear
        self.zFar = zFar
        self.yFOV = yFOV
    }

    public func update(_ date: Date) {
        // NOP
    }
}
