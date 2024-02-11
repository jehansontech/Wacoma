//
//  GestureHandlers.swift
//  Wacoma
//
//  Created by Jim Hanson on 12/14/21.
//

import SwiftUI
import MetalKit

public protocol TapHandler {

    /// called when the user executes a primary tap gesture: one-finger tap in iOS, button-1 mouse click in macOS
    /// location is in clip space: (-1, -1) to (+1, +1)
    /// 
    @MainActor
    mutating func primaryTap(at location: SIMD2<Float>)

    /// called when the user executes a secondary tap gesture: two-finger tap in iOS, button-2 mouse click in macOS
    /// location is in clip space: (-1, -1) to (+1, +1)
    @MainActor
    mutating func secondaryTap(at location: SIMD2<Float>)
}

public protocol LongPressHandler {

    /// called when the user starts executing a long-press gesture
    /// location is in clip space: (-1, -1) to (+1, +1)
    mutating func longPressBegan(at location: SIMD2<Float>)

    mutating func longPressMoved(to location: SIMD2<Float>)

    mutating func longPressEnded(at location: SIMD2<Float>)
}


public protocol DragHandler {

    /// called when the user starts executing a drag gesture
    /// location is in clip space: (-1, -1) to (+1, +1)
    mutating func dragBegan(at location: SIMD2<Float>)

    /// panFraction is in [-1, 1]. It's fraction of view width; negative means "to the left"
    /// scrollFraction is in [-1, 1]. It's fraction of view height; negative means "down"
    mutating func dragChanged(panFraction: Float, scrollFraction: Float)

    mutating func dragEnded()
}

public protocol PinchHandler {

    /// called when the user starts executing a pinch gesture
    /// loation is midpoint between two fingers, in clip space: (-1, -1) to (+1, +1)
    mutating func pinchBegan(at location: SIMD2<Float>)

    /// scale goes like 1 -> 0.1 when squeezing,  1 -> 10 when stretching
    mutating func pinchChanged(scale: Float)

    mutating func pinchEnded()
}


public protocol RotationHandler {

    /// called when the user starts executing a rotation gesture
    /// center is midpoint between two fingers, in clip space: (-1, -1) to (+1, +1)
    mutating func rotationBegan(at location: SIMD2<Float>)

    /// increases as the fingers rotate counterclockwise
    mutating func rotationChanged(radians: Float)

    mutating func rotationEnded()
}


#if os(iOS) // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// ============================================================================
// MARK: - iOS
// ============================================================================

public class GestureHandlers: NSObject, UIGestureRecognizerDelegate {

    public var tapHandler: TapHandler?
    public var longPressHandler: LongPressHandler?
    public var dragHandler: DragHandler?
    public var pinchHandler: PinchHandler?
    public var rotationHandler: RotationHandler?

    private var singleTapRecognizer: UITapGestureRecognizer? = nil
    private var twoTouchRecognizer: UITapGestureRecognizer? = nil
    private var longPressRecognizer: UILongPressGestureRecognizer? = nil
    private var dragRecognizer: UIPanGestureRecognizer? = nil
    private var pinchRecognizer: UIPinchGestureRecognizer? = nil
    private var rotationRecognizer: UIRotationGestureRecognizer? = nil

    public init(tapHandler: TapHandler? = nil,
                longPressHandler: LongPressHandler? = nil,
                dragHandler: DragHandler? = nil,
                pinchHandler: PinchHandler? = nil,
                rotationHandler: RotationHandler? = nil) {

        self.tapHandler = tapHandler
        self.longPressHandler = longPressHandler
        self.dragHandler = dragHandler
        self.pinchHandler = pinchHandler
        self.rotationHandler = rotationHandler
    }

    public func connectGestures(_ mtkView: MTKView) {

        if singleTapRecognizer == nil {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
            recognizer.numberOfTapsRequired = 1
            recognizer.numberOfTouchesRequired = 1
            mtkView.addGestureRecognizer(recognizer)
            self.singleTapRecognizer = recognizer
        }

        if twoTouchRecognizer == nil {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(twoPointTap))
            recognizer.numberOfTapsRequired = 1
            recognizer.numberOfTouchesRequired = 2
            mtkView.addGestureRecognizer(recognizer)
            self.twoTouchRecognizer = recognizer
        }

        if longPressRecognizer == nil {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
            recognizer.numberOfTouchesRequired = 1
            mtkView.addGestureRecognizer(recognizer)
            self.longPressRecognizer = recognizer
        }

        if dragRecognizer == nil {
            let recognizer = UIPanGestureRecognizer(target: self, action: #selector(drag))
            mtkView.addGestureRecognizer(recognizer)
            self.dragRecognizer = recognizer
        }

        if pinchRecognizer == nil {
            let recognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
            mtkView.addGestureRecognizer(recognizer)
            self.pinchRecognizer = recognizer
        }

        if rotationRecognizer == nil {
            let recognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotate))
            mtkView.addGestureRecognizer(recognizer)
            self.rotationRecognizer = recognizer
        }
    }

    public func disconnectGestures(_ mtkView: MTKView) {

        if let singleTapRecognizer {
            mtkView.removeGestureRecognizer(singleTapRecognizer)
            self.singleTapRecognizer = nil
        }

        if let twoTouchRecognizer {
            mtkView.removeGestureRecognizer(twoTouchRecognizer)
            self.twoTouchRecognizer = nil
        }

        if let longPressRecognizer {
            mtkView.removeGestureRecognizer(longPressRecognizer)
            self.longPressRecognizer = nil
        }

        if let dragRecognizer {
            mtkView.removeGestureRecognizer(dragRecognizer)
            self.dragRecognizer = nil
        }

        if let pinchRecognizer {
            mtkView.removeGestureRecognizer(pinchRecognizer)
            self.pinchRecognizer = nil
        }

        if let rotationRecognizer {
            mtkView.removeGestureRecognizer(rotationRecognizer)
            self.rotationRecognizer = nil
        }
    }

    @objc func singleTap(_ gesture: UITapGestureRecognizer) {
        if let view = gesture.view {
            switch gesture.state {
            case .ended:
                tapHandler?.primaryTap(at: RenderController.clipPoint(gesture.location(in: view), view.bounds))
            default:
                break
            }
        }
    }

    @objc func twoPointTap(_ gesture: UITapGestureRecognizer) {
        if let view = gesture.view {
            switch gesture.state {
            case .ended:
                tapHandler?.secondaryTap(at: RenderController.clipPoint(gesture.location(in: view), view.bounds))
            default:
                break
            }
        }
    }

    @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
        if let view = gesture.view {
            switch gesture.state {
            case .began:
                longPressHandler?.longPressBegan(at: RenderController.clipPoint(gesture.location(in: view), view.bounds))
            case .changed:
                longPressHandler?.longPressMoved(to: RenderController.clipPoint(gesture.location(in: view), view.bounds))
            case .ended:
                longPressHandler?.longPressEnded(at: RenderController.clipPoint(gesture.location(in: view), view.bounds))
            default:
                break
            }
        }
    }

    @objc func drag(_ gesture: UIPanGestureRecognizer) {
        if let view = gesture.view {
            switch gesture.state {
            case .possible:
                break
            case .began:
                dragHandler?.dragBegan(at: RenderController.clipPoint(gesture.location(in: view), view.bounds))
            case .changed:
                let translation = gesture.translation(in: view)
                // NOTE that factor of -1 on the scroll
                dragHandler?.dragChanged(panFraction: Float(translation.x / view.bounds.width),
                                         scrollFraction: Float(-translation.y / view.bounds.height))
            default:
                dragHandler?.dragEnded()
            }
        }
    }

    @objc func pinch(_ gesture: UIPinchGestureRecognizer) {
        if let view = gesture.view {
            switch gesture.state {
            case .possible:
                break
            case .began:
                if gesture.numberOfTouches >= 2 {
                    pinchHandler?.pinchBegan(at: RenderController.clipPoint(gesture.location(ofTouch: 0, in: view),
                                                                           gesture.location(ofTouch: 1, in: view),
                                                                           view.bounds))
                }
            case .changed:
                pinchHandler?.pinchChanged(scale: Float(gesture.scale))
            default:
                pinchHandler?.pinchEnded()
            }
        }
    }

    @objc func rotate(_ gesture: UIRotationGestureRecognizer) {
        if let view = gesture.view {
            switch gesture.state {
            case .possible:
                break
            case .began:
                if gesture.numberOfTouches >= 2 {
                    rotationHandler?.rotationBegan(at: RenderController.clipPoint(gesture.location(ofTouch: 0, in: view),
                                                                                 gesture.location(ofTouch: 1, in: view),
                                                                                 view.bounds))
                }
            case .changed:
                rotationHandler?.rotationChanged(radians: Float(gesture.rotation))
            default:
                rotationHandler?.rotationEnded()
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
}

#elseif os(macOS) // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// ============================================================================
// MARK: - macOS
// ============================================================================

public class GestureHandlers: NSObject, NSGestureRecognizerDelegate {

    public var tapHandler: TapHandler?
    public var longPressHandler: LongPressHandler?
    public var dragHandler: DragHandler?
    public var pinchHandler: PinchHandler?
    public var rotationHandler: RotationHandler?

    private var button1Recognizer: NSClickGestureRecognizer? = nil
    private var button2Recognizer: NSClickGestureRecognizer? = nil
    private var longPressRecognizer: NSPressGestureRecognizer? = nil
    private var dragRecognizer: NSPanGestureRecognizer? = nil
    private var pinchRecognizer: NSMagnificationGestureRecognizer? = nil
    private var rotationRecognizer: NSRotationGestureRecognizer? = nil

    public init(tapHandler: TapHandler? = nil,
                longPressHandler: LongPressHandler? = nil,
                dragHandler: DragHandler? = nil,
                pinchHandler: PinchHandler? = nil,
                rotationHandler: RotationHandler? = nil) {

        self.tapHandler = tapHandler
        self.longPressHandler = longPressHandler
        self.dragHandler = dragHandler
        self.pinchHandler = pinchHandler
        self.rotationHandler = rotationHandler
    }

    public func connectGestures(_ mtkView: MTKView) {

        if button1Recognizer == nil {
            let recognizer = NSClickGestureRecognizer(target: self, action: #selector(button1Click))
            recognizer.numberOfClicksRequired = 1
            recognizer.buttonMask = 0x1
            mtkView.addGestureRecognizer(recognizer)
            self.button1Recognizer = recognizer
        }

        if button2Recognizer == nil {
            let recognizer = NSClickGestureRecognizer(target: self, action: #selector(button2Click))
            recognizer.numberOfClicksRequired = 1
            recognizer.buttonMask = 0x2
            mtkView.addGestureRecognizer(recognizer)
            self.button2Recognizer = recognizer
        }

        if longPressRecognizer == nil {
            let recognizer = NSPressGestureRecognizer(target: self, action: #selector(longPress))
            recognizer.buttonMask = 0x1
            mtkView.addGestureRecognizer(recognizer)
            self.longPressRecognizer = recognizer
        }

        if dragRecognizer == nil {
            let recognizer = NSPanGestureRecognizer(target: self, action: #selector(drag))
            mtkView.addGestureRecognizer(recognizer)
            self.dragRecognizer = recognizer
        }

        if pinchRecognizer == nil {
            let recognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(pinch))
            mtkView.addGestureRecognizer(recognizer)
            self.pinchRecognizer = recognizer
        }

        if rotationRecognizer == nil {
            let recognizer = NSRotationGestureRecognizer(target: self, action: #selector(rotate))
            mtkView.addGestureRecognizer(recognizer)
            self.rotationRecognizer = recognizer
        }
    }

    public func disconnectGestures(_ mtkView: MTKView) {

        if let button1Recognizer = self.button1Recognizer {
            mtkView.removeGestureRecognizer(button1Recognizer)
            self.button1Recognizer = nil
        }

        if let button2Recognizer = self.button1Recognizer {
            mtkView.removeGestureRecognizer(button2Recognizer)
            self.button2Recognizer = nil
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

    @MainActor
    @objc func button1Click(_ gesture: NSClickGestureRecognizer) {
        // print("button1Click")
        if let view = gesture.view {
            switch gesture.stepState {
            case .ended:
                tapHandler?.primaryTap(at: clipPoint(gesture.location(in: view), view.bounds))
            default:
                break
            }
        }
    }

    @MainActor
    @objc func button2Click(_ gesture: NSClickGestureRecognizer) {
        if let view = gesture.view {
            switch gesture.stepState {
            case .ended:
                tapHandler?.secondaryTap(at: clipPoint(gesture.location(in: view), view.bounds))
            default:
                break
            }
        }
    }

    @objc func longPress(_ gesture: NSPressGestureRecognizer) {
        if let view = gesture.view  {
            switch gesture.stepState {
            case .began:
                longPressHandler?.longPressBegan(at: clipPoint(gesture.location(in: view), view.bounds))
            case .changed:
                longPressHandler?.longPressMoved(to: clipPoint(gesture.location(in: view), view.bounds))
            case .ended:
                longPressHandler?.longPressEnded(at: clipPoint(gesture.location(in: view), view.bounds))
            default:
                break
            }
        }
    }

    @objc func drag(_ gesture: NSPanGestureRecognizer) {
        if let view = gesture.view  {
            switch gesture.stepState {
            case .possible:
                break
            case .began:
                dragHandler?.dragBegan(at: clipPoint(gesture.location(in: view), view.bounds))
            case .changed:
                let translation = gesture.translation(in: view)
                // macOS uses upside-down clip coords, so the scroll value is the opposite of that on iOS
                dragHandler?.dragChanged(panFraction: Float(translation.x / view.bounds.width),
                                         scrollFraction: Float(translation.y / view.bounds.height))
            default:
                dragHandler?.dragEnded()
            }
        }
    }

    @objc func pinch(_ gesture: NSMagnificationGestureRecognizer) {
        if let view = gesture.view  {
            switch gesture.stepState {
            case .possible:
                break
            case .began:
                pinchHandler?.pinchBegan(at: clipPoint(gesture.location(in: view), view.bounds))
            case .changed:
                // macOS gesture's magnification=0 corresponds to iOS gesture's scale=1
                pinchHandler?.pinchChanged(scale: Float(1 + gesture.magnification))
            default:
                pinchHandler?.pinchEnded()
            }
        }
    }

    @objc func rotate(_ gesture: NSRotationGestureRecognizer) {
        if let view = gesture.view  {
            switch gesture.stepState {
            case .possible:
                break
            case .began:
                rotationHandler?.rotationBegan(at: clipPoint(gesture.location(in: view), view.bounds))
            case .changed:
                // multiply by -1 because macOS gestures use upside-down clip space
                rotationHandler?.rotationChanged(radians: Float(-gesture.rotation))
            default:
                rotationHandler?.rotationEnded()
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
}

#endif  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
