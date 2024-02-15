//
//  GestureHandlers.swift
//  Wacoma
//
//  Created by Jim Hanson on 12/14/21.
//

import SwiftUI


public protocol TapHandler {

    /// location is in clip space: (-1, -1) to (+1, +1)
    @MainActor
    mutating func tap(at location: SIMD2<Float>)
}


public protocol LongPressHandler {

    /// called when the user starts executing a long-press gesture
    /// location is in clip space: (-1, -1) to (+1, +1)
    @MainActor
    mutating func longPressBegan(at location: SIMD2<Float>)

    @MainActor
    mutating func longPressMoved(to location: SIMD2<Float>)

    @MainActor
    mutating func longPressEnded(at location: SIMD2<Float>)
}


public protocol DragHandler {

    /// called when the user starts executing a drag gesture
    /// location is in clip space: (-1, -1) to (+1, +1)
    @MainActor
    mutating func dragBegan(at location: SIMD2<Float>)

    /// panFraction is in [-1, 1]. It's fraction of view width; negative means "to the left"
    /// scrollFraction is in [-1, 1]. It's fraction of view height; negative means "down"
    @MainActor
    mutating func dragChanged(panFraction: Float, scrollFraction: Float)

    @MainActor
    mutating func dragEnded()
}


public protocol PinchHandler {

    /// called when the user starts executing a pinch gesture
    /// loation is midpoint between two fingers, in clip space: (-1, -1) to (+1, +1)
    @MainActor
    mutating func pinchBegan(at location: SIMD2<Float>)

    /// scale goes like 1 -> 0.1 when squeezing,  1 -> 10 when stretching
    @MainActor
    mutating func pinchChanged(scale: Float)

    @MainActor
    mutating func pinchEnded()
}


public protocol RotationHandler {

    /// called when the user starts executing a rotation gesture
    /// center is midpoint between two fingers, in clip space: (-1, -1) to (+1, +1)
    @MainActor
    mutating func rotationBegan(at location: SIMD2<Float>)

    /// increases as the fingers rotate counterclockwise
    @MainActor
    mutating func rotationChanged(radians: Float)

    @MainActor
    mutating func rotationEnded()
}


public struct GestureHandlers {

    public var primaryTap: TapHandler? = nil

    public var secondaryTap: TapHandler? = nil

    public var primaryLongPress: LongPressHandler? = nil

    public var secondaryLongPress: LongPressHandler? = nil

    public var primaryDrag: DragHandler? = nil

    public var secondaryDrag: DragHandler? = nil

    public var pinch: PinchHandler? = nil

    public var rotation: RotationHandler? = nil

    public init(primaryTap: TapHandler? = nil,
                secondaryTap: TapHandler? = nil,
                primaryLongPress: LongPressHandler? = nil,
                secondaryLongPress: LongPressHandler? = nil,
                primaryDrag: DragHandler? = nil,
                secondaryDrag: DragHandler? = nil,
                pinch: PinchHandler? = nil,
                rotation: RotationHandler? = nil) {
        self.primaryTap = primaryTap
        self.secondaryTap = secondaryTap
        self.primaryLongPress = primaryLongPress
        self.secondaryLongPress = secondaryLongPress
        self.primaryDrag = primaryDrag
        self.secondaryDrag = secondaryDrag
        self.pinch = pinch
        self.rotation = rotation
    }
}

