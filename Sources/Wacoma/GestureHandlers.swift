//
//  GestureHandlers.swift
//  Wacoma
//
//  Created by Jim Hanson on 12/14/21.
//

import SwiftUI
import MetalKit

public protocol TapHandler {

    /// called when the user executes a tap gesture
    /// location is in clip space: (-1, -1) to (+1, +1)
    mutating func tap(at location: SIMD2<Float>)
}

public protocol LongPressHandler {

    /// called when the user starts executing a long-press gesture
    /// location is in clip space: (-1, -1) to (+1, +1)
    mutating func longPressBegan(at location: SIMD2<Float>)

    mutating func longPressEnded()
}


public protocol DragHandler {

    /// called when the user starts executing a drag gesture
    /// location is in clip space: (-1, -1) to (+1, +1)
    mutating func dragBegan(at location: SIMD2<Float>)

    /// pan is fraction of view width; negative means "to the left"
    /// scroll is fraction of view height; negative means "down"
    mutating func dragChanged(pan: Float, scroll: Float)

    mutating func dragEnded()
}

public protocol PinchHandler {

    /// called when the user starts executing a pinch gesture
    /// center is midpoint between two fingers
    mutating func pinchBegan(at location: SIMD2<Float>)

    /// scale goes like 1 -> 0.1 when squeezing,  1 -> 10 when stretching
    mutating func pinchChanged(by scale: Float)

    mutating func pinchEnded()
}


public protocol RotationHandler {

    /// called when the user starts executing a rotation gesture
    /// center is midpoint between two fingers
    mutating func rotationBegan(at location: SIMD2<Float>)

    /// increases as the fingers rotate counterclockwise
    mutating func rotationChanged(by radians: Float)

    mutating func rotationEnded()
}


#if os(iOS) // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// MARK: - iOS

public class GestureHandlers: NSObject, UIGestureRecognizerDelegate {

    public var onePointTapHandler: TapHandler?
    public var twoPointTapHandler: TapHandler?
    public var longPressHandler: LongPressHandler?
    public var dragHandler: DragHandler?
    public var pinchHandler: PinchHandler?
    public var rotationHandler: RotationHandler?

    private var onePointTapRecognizer: UITapGestureRecognizer? = nil
    private var twoPointTapRecognizer: UITapGestureRecognizer? = nil
    private var longPressRecognizer: UILongPressGestureRecognizer? = nil
    private var dragRecognizer: UIPanGestureRecognizer? = nil
    private var pinchRecognizer: UIPinchGestureRecognizer? = nil
    private var rotationRecognizer: UIRotationGestureRecognizer? = nil

    public init(onePointTapHandler: TapHandler? = nil,
                twoPointTapHandler: TapHandler? = nil,
                longPressHandler: LongPressHandler? = nil,
                dragHandler: DragHandler? = nil,
                pinchHandler: PinchHandler? = nil,
                rotationHandler: RotationHandler? = nil) {

        self.onePointTapHandler = onePointTapHandler
        self.twoPointTapHandler = twoPointTapHandler
        self.longPressHandler = longPressHandler
        self.dragHandler = dragHandler
        self.pinchHandler = pinchHandler
        self.rotationHandler = rotationHandler
    }

    public func connectGestures(_ mtkView: MTKView) {

        if onePointTapRecognizer == nil {
            onePointTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onePointTap))
            onePointTapRecognizer?.numberOfTouchesRequired = 1
            mtkView.addGestureRecognizer(onePointTapRecognizer!)
        }

        if twoPointTapRecognizer == nil {
            twoPointTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(twoPointTap))
            twoPointTapRecognizer?.numberOfTouchesRequired = 2
            mtkView.addGestureRecognizer(twoPointTapRecognizer!)
        }

        if longPressRecognizer == nil {
            longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
            mtkView.addGestureRecognizer(longPressRecognizer!)
        }

        if dragRecognizer == nil {
            dragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(drag))
            mtkView.addGestureRecognizer(dragRecognizer!)
        }

        if pinchRecognizer == nil {
            pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
            mtkView.addGestureRecognizer(pinchRecognizer!)
        }

        if rotationRecognizer == nil {
            rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotate))
            mtkView.addGestureRecognizer(rotationRecognizer!)
        }
    }

    public func disconnectGestures(_ mtkView: MTKView) {

        if let onePointTapRecognizer = self.onePointTapRecognizer {
            mtkView.removeGestureRecognizer(onePointTapRecognizer)
            self.onePointTapRecognizer = nil
        }

        if let twoPointTapRecognizer = self.twoPointTapRecognizer {
            mtkView.removeGestureRecognizer(twoPointTapRecognizer)
            self.twoPointTapRecognizer = nil
        }

        if let longPressRecognizer = self.longPressRecognizer {
            mtkView.removeGestureRecognizer(longPressRecognizer)
            self.longPressRecognizer = nil
        }

        if let dragRecognizer = self.dragRecognizer {
            mtkView.removeGestureRecognizer(dragRecognizer)
            self.dragRecognizer = nil
        }

        if let pinchRecognizer = self.pinchRecognizer {
            mtkView.removeGestureRecognizer(pinchRecognizer)
            self.pinchRecognizer = nil
        }

        if let rotationRecognizer = self.rotationRecognizer {
            mtkView.removeGestureRecognizer(rotationRecognizer)
            self.rotationRecognizer = nil
        }
    }

    @objc func onePointTap(_ gesture: UITapGestureRecognizer) {
        if var tapHandler = self.onePointTapHandler,
           let view = gesture.view {

            switch gesture.state {
            case .ended:
                tapHandler.tap(at: clipPoint(gesture.location(ofTouch: 0, in: view), view.bounds))
            default:
                break
            }
        }
    }

    @objc func twoPointTap(_ gesture: UITapGestureRecognizer) {
        if var tapHandler = self.twoPointTapHandler,
           let view = gesture.view {

            switch gesture.state {
            case .ended:
                tapHandler.tap(at: clipPoint(gesture.location(ofTouch: 0, in: view), view.bounds))
            default:
                break
            }
        }
    }

    @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
        if var longPressHandler = self.longPressHandler,
           let view = gesture.view {

            switch gesture.state {
            case .began:
                longPressHandler.longPressBegan(at: clipPoint(gesture.location(ofTouch: 0, in: view), view.bounds))
            case .ended:
                longPressHandler.longPressEnded()
            default:
                break
            }
        }
    }

    @objc func drag(_ gesture: UIPanGestureRecognizer) {
        if var dragHandler = self.dragHandler,
           let view = gesture.view {

            switch gesture.state {
            case .possible:
                break
            case .began:
                dragHandler.dragBegan(at: clipPoint(gesture.location(ofTouch: 0, in: view), view.bounds))
            case .changed:
                let translation = gesture.translation(in: view)
                // NOTE that factor on -1 on scroll
                dragHandler.dragChanged(pan: Float(translation.x / view.bounds.width),
                                        scroll: Float(-translation.y / view.bounds.height))
            default:
                dragHandler.dragEnded()
            }
        }
    }

    @objc func pinch(_ gesture: UIPinchGestureRecognizer) {
        if var pinchHandler = self.pinchHandler,
           let view = gesture.view {

            switch gesture.state {
            case .possible:
                break
            case .began:
                pinchHandler.pinchBegan(at: clipPoint(gesture.location(ofTouch: 0, in: view),
                                                      gesture.location(ofTouch: 1, in: view),
                                                      view.bounds))
            case .changed:
                pinchHandler.pinchChanged(by: Float(gesture.scale))
            default:
                pinchHandler.pinchEnded()
            }
        }
    }

    @objc func rotate(_ gesture: UIRotationGestureRecognizer) {
        if var rotationHandler = rotationHandler,
           let view = gesture.view {

            switch gesture.state {
            case .possible:
                break
            case .began:
                rotationHandler.rotationBegan(at: clipPoint(gesture.location(ofTouch: 0, in: view),
                                                            gesture.location(ofTouch: 1, in: view),
                                                            view.bounds))
            case .changed:
                rotationHandler.rotationChanged(by: Float(gesture.rotation))
            default:
                rotationHandler.rotationEnded()
            }
        }
    }

    /// needed in order to do  simultaneous pan & other gestures
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith: UIGestureRecognizer) -> Bool {
        // Disallow combos that include dragging, but allow anything else.
        if gestureRecognizer is UIPanGestureRecognizer || shouldRecognizeSimultaneouslyWith is UIPanGestureRecognizer {
            return false
        }
        return true
    }

    private func clipPoint(_ viewPt: CGPoint, _ viewSize: CGRect) -> SIMD2<Float> {
        return SIMD2<Float>(clipX(viewPt.x, viewSize.width), clipY(viewPt.y, viewSize.height))
    }

    private func clipPoint(_ viewPt0: CGPoint, _ viewPt1: CGPoint, _ viewSize: CGRect) -> SIMD2<Float> {
        return SIMD2<Float>(clipX((viewPt0.x + viewPt1.x)/2, viewSize.width),
                            clipY((viewPt0.y + viewPt1.y)/2, viewSize.height))
    }

    private func clipX(_ viewX: CGFloat, _ viewWidth: CGFloat) -> Float {
        return Float(2 * viewX / viewWidth - 1)
    }

    private func clipY(_ viewY: CGFloat, _ viewHeight: CGFloat) -> Float {
        // In iOS, viewY increases toward the TOP of the screen
        return Float(1 - 2 * viewY / viewHeight)
    }
}

#elseif os(macOS) // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// MARK: - macOS

public class GestureHandlers: NSObject, NSGestureRecognizerDelegate {

    public var onePointTapHandler: TapHandler?
    public var twoPointTapHandler: TapHandler?
    public var longPressHandler: LongPressHandler?
    public var dragHandler: DragHandler?
    public var pinchHandler: PinchHandler?
    public var rotationHandler: RotationHandler?

    private var onePointTapRecognizer: NSClickGestureRecognizer? = nil
    private var twoPointTapRecognizer: NSClickGestureRecognizer? = nil
    private var longPressRecognizer: NSPressGestureRecognizer? = nil
    private var dragRecognizer: NSPanGestureRecognizer? = nil
    private var pinchRecognizer: NSMagnificationGestureRecognizer? = nil
    private var rotationRecognizer: NSRotationGestureRecognizer? = nil

    public init(onePointTapHandler: TapHandler? = nil,
                twoPointTapHandler: TapHandler? = nil,
                longPressHandler: LongPressHandler? = nil,
                dragHandler: DragHandler? = nil,
                pinchHandler: PinchHandler? = nil,
                rotationHandler: RotationHandler? = nil) {

        self.onePointTapHandler = onePointTapHandler
        self.twoPointTapHandler = twoPointTapHandler
        self.longPressHandler = longPressHandler
        self.dragHandler = dragHandler
        self.pinchHandler = pinchHandler
        self.rotationHandler = rotationHandler
    }

    public func connectGestures(_ mtkView: MTKView) {

        if onePointTapRecognizer == nil {
            onePointTapRecognizer = NSClickGestureRecognizer(target: self, action: #selector(onePointTap))
            onePointTapRecognizer?.buttonMask = 0x1
            mtkView.addGestureRecognizer(onePointTapRecognizer!)
        }

        if twoPointTapRecognizer == nil {
            twoPointTapRecognizer = NSClickGestureRecognizer(target: self, action: #selector(twoPointTap))
            twoPointTapRecognizer?.buttonMask = 0x2
            mtkView.addGestureRecognizer(twoPointTapRecognizer!)
        }

        if longPressRecognizer == nil {
            longPressRecognizer = NSPressGestureRecognizer(target: self, action: #selector(longPress))
            mtkView.addGestureRecognizer(longPressRecognizer!)
        }

        if dragRecognizer == nil {
            dragRecognizer = NSPanGestureRecognizer(target: self, action: #selector(drag))
            mtkView.addGestureRecognizer(dragRecognizer!)
        }

        if pinchRecognizer == nil {
            pinchRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(pinch))
            mtkView.addGestureRecognizer(pinchRecognizer!)
        }

        if rotationRecognizer == nil {
            rotationRecognizer = NSRotationGestureRecognizer(target: self, action: #selector(rotate))
            mtkView.addGestureRecognizer(rotationRecognizer!)
        }
    }

    public func disconnectGestures(_ mtkView: MTKView) {

        if let onePointTapRecognizer = self.onePointTapRecognizer {
            mtkView.removeGestureRecognizer(onePointTapRecognizer)
            self.onePointTapRecognizer = nil
        }

        if let twoPointTapRecognizer = self.onePointTapRecognizer {
            mtkView.removeGestureRecognizer(twoPointTapRecognizer)
            self.twoPointTapRecognizer = nil
        }

        if let longPressRecognizer = self.longPressRecognizer {
            mtkView.removeGestureRecognizer(longPressRecognizer)
            self.longPressRecognizer = nil
        }

        if let dragRecognizer = self.dragRecognizer {
            mtkView.removeGestureRecognizer(dragRecognizer)
            self.dragRecognizer = nil
        }

        if let pinchRecognizer = self.pinchRecognizer {
            mtkView.removeGestureRecognizer(pinchRecognizer)
            self.pinchRecognizer = nil
        }

        if let rotationRecognizer = self.rotationRecognizer {
            mtkView.removeGestureRecognizer(rotationRecognizer)
            self.rotationRecognizer = nil
        }
    }

    @objc func onePointTap(_ gesture: NSClickGestureRecognizer) {
        if var tapHandler = self.onePointTapHandler,
           let view = gesture.view {
            switch gesture.state {
            case .ended:
                tapHandler.tap(at: clipPoint(gesture.location(in: view), view.bounds))
            default:
                break
            }
        }
    }

    @objc func twoPointTap(_ gesture: NSClickGestureRecognizer) {
        if var tapHandler = self.twoPointTapHandler,
           let view = gesture.view {
            switch gesture.state {
            case .ended:
                tapHandler.tap(at: clipPoint(gesture.location(in: view), view.bounds))
            default:
                break
            }
        }
    }

    @objc func longPress(_ gesture: NSPressGestureRecognizer) {
        if var longPressHandler = self.longPressHandler,
           let view = gesture.view  {

            switch gesture.state {
            case .began:
                longPressHandler.longPressBegan(at: clipPoint(gesture.location(in: view), view.bounds))
            case .ended:
                longPressHandler.longPressEnded()
            default:
                break
            }
        }
    }

    @objc func drag(_ gesture: NSPanGestureRecognizer) {
        if var dragHandler = self.dragHandler,
           let view  = gesture.view  {

            switch gesture.state {
            case .possible:
                break
            case .began:
                dragHandler.dragBegan(at: clipPoint(gesture.location(in: view), view.bounds))
            case .changed:
                let translation = gesture.translation(in: view)
                // macOS uses upside-down clip coords, so the scroll value is the opposite of that on iOS
                dragHandler.dragChanged(pan: Float(translation.x / view.bounds.width),
                                        scroll: Float(translation.y / view.bounds.height))
            default:
                dragHandler.dragEnded()
            }
        }
    }

    @objc func pinch(_ gesture: NSMagnificationGestureRecognizer) {
        if var pinchHandler = self.pinchHandler,
           let view  = gesture.view  {

            switch gesture.state {
            case .possible:
                break
            case .began:
                pinchHandler.pinchBegan(at: clipPoint(gesture.location(in: view), view.bounds))
            case .changed:
                // macOS gesture's magnification=0 corresponds to iOS gesture's scale=1
                pinchHandler.pinchChanged(by: Float(1 + gesture.magnification))
            default:
                pinchHandler.pinchEnded()
            }
        }
    }

    @objc func rotate(_ gesture: NSRotationGestureRecognizer) {
        if var rotationHandler = self.rotationHandler,
           let view  = gesture.view  {

            switch gesture.state {
            case .possible:
                break
            case .began:
                rotationHandler.rotationBegan(at: clipPoint(gesture.location(in: view), view.bounds))
            case .changed:
                // multiply by -1 because macOS gestures use upside-down clip space
                rotationHandler.rotationChanged(by: Float(-gesture.rotation))
            default:
                rotationHandler.rotationEnded()
            }
        }
    }

    /// needed in order to do simultaneous gestures
    public func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRecognizeSimultaneouslyWith: NSGestureRecognizer) -> Bool {
        // Disallow combos that include dragging, but allow anything else.
        if gestureRecognizer is NSPanGestureRecognizer || shouldRecognizeSimultaneouslyWith is NSPanGestureRecognizer {
            return false
        }
        return true
    }

    private func clipPoint(_ viewPt: CGPoint, _ viewSize: CGRect) -> SIMD2<Float> {
        return SIMD2<Float>(clipX(viewPt.x, viewSize.width), clipY(viewPt.y, viewSize.height))
    }

    private func clipPoint(_ viewPt0: CGPoint, _ viewPt1: CGPoint, _ viewSize: CGRect) -> SIMD2<Float> {
        return SIMD2<Float>(clipX((viewPt0.x + viewPt1.x)/2, viewSize.width),
                            clipY((viewPt0.y + viewPt1.y)/2, viewSize.height))
    }

    private func clipX(_ viewX: CGFloat, _ viewWidth: CGFloat) -> Float {
        return Float(2 * viewX / viewWidth - 1)
    }

    private func clipY(_ viewY: CGFloat, _ viewHeight: CGFloat) -> Float {
        // In macOS, viewY increaases toward the BOTTOM of the screen
        return Float(2 * viewY / viewHeight - 1)
    }
}

#endif  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

