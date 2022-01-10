//
//  GestureHandlers.swift
//  Wacoma
//
//  Created by Jim Hanson on 12/14/21.
//

import SwiftUI
import MetalKit

public enum GestureMode {
    case normal
    case option
}

public protocol TapHandler {

    /// called when the user executes a tap gesture
    /// location is in clip space: (-1, -1) to (+1, +1)
    mutating func tap(at location: SIMD2<Float>, mode: GestureMode)
}

public protocol LongPressHandler {

    /// called when the user executes a long-press gesture
    /// location is in clip space: (-1, -1) to (+1, +1)
    mutating func longPressBegan(at location: SIMD2<Float>, mode: GestureMode)

    mutating func longPressEnded()
}


public protocol DragHandler {

    /// called when the user starts executing a drag gesture
    /// location is in clip space: (-1, -1) to (+1, +1)
    mutating func dragBegan(at location: SIMD2<Float>, mode: GestureMode)

    /// pan is fraction of view width; negative means "to the left"
    /// scroll is fraction of view height; negative means "down"
    mutating func dragChanged(pan: Float, scroll: Float)

    mutating func dragEnded()
}

public protocol PinchHandler {

    /// called when the user starts executing a pinch gesture
    /// center is midpoint between two fingers
    mutating func pinchBegan(at location: SIMD2<Float>, mode: GestureMode)

    /// scale goes like 1 -> 0.1 when squeezing,  1 -> 10 when stretching
    mutating func pinchChanged(by scale: Float)

    mutating func pinchEnded()
}


public protocol RotationHandler {

    /// called when the user starts executing a rotation gesture
    /// center is midpoint between two fingers
    mutating func rotationBegan(at location: SIMD2<Float>, mode: GestureMode)

    /// increases as the fingers rotate counterclockwise
    mutating func rotationChanged(by radians: Float)

    mutating func rotationEnded()
}


#if os(iOS) // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

public class GestureHandlers: NSObject, UIGestureRecognizerDelegate {

    public var tapHandler: TapHandler?

    private var tapRecognizer: UITapGestureRecognizer? = nil

    public var longPressHandler: LongPressHandler?

    private var longPressRecognizer: UILongPressGestureRecognizer? = nil

    public var dragHandler: DragHandler?

    private var dragRecognizer: UIPanGestureRecognizer? = nil

    public var pinchHandler: PinchHandler?

    private var pinchRecognizer: UIPinchGestureRecognizer? = nil

    public var rotationHandler: RotationHandler?

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

        if tapHandler != nil {
            tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
            mtkView.addGestureRecognizer(tapRecognizer!)
        }

        if longPressHandler != nil {
            longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
            mtkView.addGestureRecognizer(longPressRecognizer!)
        }

        if dragHandler != nil {
            dragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(drag))
            mtkView.addGestureRecognizer(dragRecognizer!)
        }

        if pinchHandler != nil {
            pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
            mtkView.addGestureRecognizer(pinchRecognizer!)
        }

        if rotationHandler != nil {
            rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotate))
            mtkView.addGestureRecognizer(rotationRecognizer!)
        }
    }

    public func disconnectGestures(_ mtkView: MTKView) {

        if let tapRecognizer = self.tapRecognizer {
            mtkView.removeGestureRecognizer(tapRecognizer)
            self.tapRecognizer = nil
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

    @objc func tap(_ gesture: UITapGestureRecognizer) {
        if var tapHandler = self.tapHandler,
           let view = gesture.view,
           gesture.numberOfTouches > 0 {

            debug("GestureHandlers(iOS)", "tap at \(gesture.location(ofTouch: 0, in: view)) -> \(clipPoint(gesture.location(ofTouch: 0, in: view), view.bounds).prettyString)")

            switch gesture.state {
            case .possible:
                break
            case .began:
                break
            case .changed:
                break
            case .ended:
                tapHandler.tap(at: clipPoint(gesture.location(ofTouch: 0, in: view), view.bounds),
                               mode: getMode(forGesture: gesture))
            case .cancelled:
                break
            case .failed:
                break
            @unknown default:
                break
            }
        }
    }

    @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
        if var longPressHandler = self.longPressHandler,
           let view = gesture.view,
           gesture.numberOfTouches > 0  {

            switch gesture.state {
            case .possible:
                break
            case .began:
                longPressHandler.longPressBegan(at: clipPoint(gesture.location(ofTouch: 0, in: view), view.bounds),
                                                mode: getMode(forGesture: gesture))
            case .changed:
                longPressHandler.longPressEnded()
                break
            case .ended:
                longPressHandler.longPressEnded()
            case .cancelled:
                break
            case .failed:
                break
            @unknown default:
                break
            }
        }
    }

    @objc func drag(_ gesture: UIPanGestureRecognizer) {
        if var dragHandler = self.dragHandler,
           let view  = gesture.view,
           gesture.numberOfTouches > 0  {

            switch gesture.state {
            case .possible:
                break
            case .began:
                dragHandler.dragBegan(at: clipPoint(gesture.location(ofTouch: 0, in: view), view.bounds),
                                      mode: getMode(forGesture: gesture))
            case .changed:
                let translation = gesture.translation(in: view)
                // NOTE that factor on -1 on scroll
                dragHandler.dragChanged(pan: Float(translation.x / view.bounds.width),
                                        scroll: Float(-translation.y / view.bounds.height))
            case .ended:
                dragHandler.dragEnded()
            case .cancelled:
                dragHandler.dragEnded()
            case .failed:
                dragHandler.dragEnded()
            @unknown default:
                break
            }
        }
    }

    @objc func pinch(_ gesture: UIPinchGestureRecognizer) {
        if var pinchHandler = self.pinchHandler,
           let view  = gesture.view,
           gesture.numberOfTouches > 1  {

            switch gesture.state {
            case .possible:
                break
            case .began:
                pinchHandler.pinchBegan(at: clipPoint(gesture.location(ofTouch: 0, in: view),
                                                      gesture.location(ofTouch: 1, in: view),
                                                      view.bounds),
                                        mode: getMode(forGesture: gesture))
            case .changed:
                pinchHandler.pinchChanged(by: Float(gesture.scale))
            case .ended:
                pinchHandler.pinchEnded()
            case .cancelled:
                break
            case .failed:
                break
            @unknown default:
                break
            }
        }
    }

    @objc func rotate(_ gesture: UIRotationGestureRecognizer) {
        if var rotationHandler = rotationHandler,
           let view  = gesture.view,
           gesture.numberOfTouches > 1  {

            switch gesture.state {
            case .possible:
                break
            case .began:
                rotationHandler.rotationBegan(at: clipPoint(gesture.location(ofTouch: 0, in: view),
                                                            gesture.location(ofTouch: 1, in: view),
                                                            view.bounds),
                                              mode: getMode(forGesture: gesture))
            case .changed:
                rotationHandler.rotationChanged(by: Float(gesture.rotation))
            case .ended:
                rotationHandler.rotationEnded()
            case .cancelled:
                break
            case .failed:
                break
            @unknown default:
                break
            }
        }
    }

    /// needed in order to do simultaneous gestures
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer || shouldRecognizeSimultaneouslyWith is UIPanGestureRecognizer {
            return false
        }

        return true
    }
    private func getMode(forGesture gesture: UIGestureRecognizer) -> GestureMode {
        switch gesture.numberOfTouches {
        case 1:
            return .normal
        default:
            return .option
        }
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

public class GestureHandlers: NSObject, NSGestureRecognizerDelegate {

    public var tapHandler: TapHandler?

    private var tapRecognizer: NSClickGestureRecognizer? = nil

    public var longPressHandler: LongPressHandler?

    private var longPressRecognizer: NSPressGestureRecognizer? = nil

    public var dragHandler: DragHandler?

    private var dragRecognizer: NSPanGestureRecognizer? = nil

    public var pinchHandler: PinchHandler?

    private var pinchRecognizer: NSMagnificationGestureRecognizer? = nil

    public var rotationHandler: RotationHandler?

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

        if tapHandler != nil {
            tapRecognizer = NSClickGestureRecognizer(target: self, action: #selector(tap))
            mtkView.addGestureRecognizer(tapRecognizer!)
        }

        if longPressHandler != nil {
            longPressRecognizer = NSPressGestureRecognizer(target: self, action: #selector(longPress))
            mtkView.addGestureRecognizer(longPressRecognizer!)
        }

        if dragHandler != nil {
            dragRecognizer = NSPanGestureRecognizer(target: self, action: #selector(drag))
            mtkView.addGestureRecognizer(dragRecognizer!)
        }

        if pinchHandler != nil {
            pinchRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(pinch))
            mtkView.addGestureRecognizer(pinchRecognizer!)
        }

        if rotationHandler != nil {
            rotationRecognizer = NSRotationGestureRecognizer(target: self, action: #selector(rotate))
            mtkView.addGestureRecognizer(rotationRecognizer!)
        }
    }

    public func disconnectGestures(_ mtkView: MTKView) {

        if let tapRecognizer = self.tapRecognizer {
            mtkView.removeGestureRecognizer(tapRecognizer)
            self.tapRecognizer = nil
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

    @objc func tap(_ gesture: NSClickGestureRecognizer) {
        if var tapHandler = self.tapHandler,
           let view = gesture.view {
            switch gesture.state {
            case .possible:
                break
            case .began:
                break
            case .changed:
                break
            case .ended:
                tapHandler.tap(at: clipPoint(gesture.location(in: view), view.bounds), mode: getMode(forGesture: gesture))
            case .cancelled:
                break
            case .failed:
                break
            @unknown default:
                break
            }
        }
    }

    @objc func longPress(_ gesture: NSPressGestureRecognizer) {
        if var longPressHandler = self.longPressHandler,
           let view = gesture.view  {

            switch gesture.state {
            case .possible:
                break
            case .began:
                longPressHandler.longPressBegan(at: clipPoint(gesture.location(in: view), view.bounds),
                                                mode: getMode(forGesture: gesture))
            case .changed:
                longPressHandler.longPressEnded()
                break
            case .ended:
                longPressHandler.longPressEnded()
            case .cancelled:
                break
            case .failed:
                break
            @unknown default:
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
                dragHandler.dragBegan(at: clipPoint(gesture.location(in: view), view.bounds),
                                      mode: getMode(forGesture: gesture))
            case .changed:
                let translation = gesture.translation(in: view)
                // macOS uses upside-down clip coords, so the scroll value is the opposite of that on iOS
                dragHandler.dragChanged(pan: Float(translation.x / view.bounds.width),
                                        scroll: Float(translation.y / view.bounds.height))
            case .ended:
                dragHandler.dragEnded()
            case .cancelled:
                break
            case .failed:
                break
            @unknown default:
                break
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
                pinchHandler.pinchBegan(at: clipPoint(gesture.location(in: view), view.bounds),
                                        mode: getMode(forGesture: gesture))
            case .changed:
                // macOS gesture's magnification=0 corresponds to iOS gesture's scale=1
                pinchHandler.pinchChanged(by: Float(1 + gesture.magnification))
            case .ended:
                pinchHandler.pinchEnded()
            case .cancelled:
                break
            case .failed:
                break
            @unknown default:
                break
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
                rotationHandler.rotationBegan(at: clipPoint(gesture.location(in: view), view.bounds),
                                              mode: getMode(forGesture: gesture))
            case .changed:
                // multiply by -1 because macOS gestures use upside-down clip space
                rotationHandler.rotationChanged(by: Float(-gesture.rotation))
            case .ended:
                rotationHandler.rotationEnded()
            case .cancelled:
                break
            case .failed:
                break
            @unknown default:
                break
            }
        }
    }

    /// needed in order to do simultaneous gestures
    public func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRecognizeSimultaneouslyWith: NSGestureRecognizer) -> Bool {
        if gestureRecognizer is NSPanGestureRecognizer || shouldRecognizeSimultaneouslyWith is NSPanGestureRecognizer {
            return false
        }

        return true
    }

    private func getMode(forGesture gesture: NSGestureRecognizer) -> GestureMode {
        //        switch gesture.numberOfTouches {
        //        case 1:
        return .normal
        //        default:
        //            return .option
        //        }
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

