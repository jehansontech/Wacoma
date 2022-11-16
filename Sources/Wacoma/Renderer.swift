//
//  Renderer.swift
//  
//
//  Created by Jim Hanson on 1/8/22.
//

import Foundation
import simd
import SwiftUI
import MetalKit

public enum RenderError: Error {
    case noDevice
    case noDefaultLibrary
    case noDepthStencilState
    case badVertexDescriptor
    case bufferCreationFailed
    case snapshotInProgress
}

public struct RenderSettings {

    public var pov: POV

    public var viewMatrix: float4x4

    public var fadeoutMidpoint: Float

    public var fadeoutDistance: Float

    public var projectionMatrix: float4x4

    public var preferredFramesPerSecond: Int
}

public protocol Renderable {

    /// Called at the beginning of every rendering cycle.
    mutating func prepareToDraw(_ mtkView: MTKView, _ renderSettings: RenderSettings)

    /// Called on every rendering cycle. Should execute as quickly as possible.
    func encodeDrawCommands(_ encoder: MTLRenderCommandEncoder)
}

public class RenderController: ObservableObject, DragHandler, PinchHandler, RotationHandler {

    public static let defaultDarkBackground = SIMD4<Double>(0.025, 0.025, 0.025, 1)

    public static let defaultLightBackground = SIMD4<Double>(0.975, 0.975, 0.975, 1)

    public var renderables = [Renderable]()

    public var povController: POVController

    public var fovController: FOVController

    /// distance in world coordinates between the POV's location and the plane on which a touch is located. Non-negative.
    public var touchPlaneDistance: Float = 0

    @Published public var backgroundColor: SIMD4<Double>

    @Published public private(set) var snapshotRequested: Bool = false

    private var snapshotCallback: ((String) -> Any?)? = nil

    public init(_ povController: POVController,
                _ fovController: FOVController,
                _ backgroundColor: SIMD4<Double> = RenderController.defaultDarkBackground) {
        self.povController = povController
        self.fovController = fovController
        self.backgroundColor = backgroundColor
    }

    public func requestSnapshot(_ callback: @escaping ((String) -> Any?)) throws {
        if snapshotRequested {
            throw RenderError.snapshotInProgress
        }
        snapshotRequested = true
        snapshotCallback = callback
    }

    public func snapshotTaken(_ response: String) {
        let callback = snapshotCallback
        snapshotRequested = false
        snapshotCallback = nil
        Task {
            if let callback {
                _ = callback(response)
            }
        }
    }

    public func touchRay(at touchLocation: SIMD2<Float>) -> TouchRay {
        let inverseProjectionMatrix = fovController.projectionMatrix.inverse
        let inverseViewMatrix = povController.viewMatrix.inverse

        let viewPoint1 = inverseProjectionMatrix * SIMD4<Float>(touchLocation.x, touchLocation.y, 0, 1)
        var ray1 = viewPoint1
        ray1.z = -1
        ray1.w = 0

        // FIXME: ray.range is totally wrong.
        // I don't know what's going on here.
        // * viewPoint1 is the point we touched, transformed into view coordinates.
        // * ray1 at first is that same point, but then we set its z and w components.
        //   EMPIRICAL: ray1.z is -1 already, but ray1.w is all over the place.
        // * I have verified that ray's origin as calculated in the code I copied this from
        //   is equal to pov.location:
        //   `let rayOrigin = (inverseViewMatrix * SIMD4<Float>(0, 0, 0, 1)).xyz`
        // * What I'm looking for are the z-components, in world coordinates,
        //   of nearest and farthest visible points
        // * I think what I'm returning are the DISTANCES from the glass to those points
        let visibleZ = fovController.visibleZ

        //        print("touchRay touchLocation: \(touchLocation.prettyString)")
        //        print("         viewPoint1: \(viewPoint1.prettyString)")
        //        print("         visibleZ: [\(visibleZ.lowerBound), \(visibleZ.upperBound)]")
        //
        //        let nearPoint = inverseProjectionMatrix * SIMD4<Float>(touchLocation.x, touchLocation.y, fovController.zNear, 1)
        //        let farPoint = inverseProjectionMatrix * SIMD4<Float>(touchLocation.x, touchLocation.y, fovController.zFar, 1)
        //        print("         nearPoint: \(nearPoint.prettyString)")
        //        print("         farPoint: \(farPoint.prettyString)")
        //
        //        let viewPoint2 = inverseProjectionMatrix * SIMD4<Float>(touchLocation.x, touchLocation.y, visibleZ.lowerBound, 1)
        //        let viewPoint3 = inverseProjectionMatrix * SIMD4<Float>(touchLocation.x, touchLocation.y, visibleZ.upperBound, 1)
        //        print("         viewPoint2: \(viewPoint2.prettyString)")
        //        print("         viewPoint3: \(viewPoint3.prettyString)")
        //
        //        let worldPoint2 = inverseViewMatrix * viewPoint2
        //        let worldPoint3 = inverseViewMatrix * viewPoint3
        //        print("         worldPoint2: \(worldPoint2.prettyString)")
        //        print("         worldPoint3: \(worldPoint3.prettyString)")

        return TouchRay(origin: povController.pov.location,
                        direction: normalize(inverseViewMatrix * ray1).xyz,
                        range: visibleZ)
    }

    public func touchPoint(_ location: SIMD2<Float>) -> SIMD3<Float> {

        // I want to find the world coordinates of the point where the
        // touch ray intersects the touch plane
        //
        // touch plane is normal to pov.forward (which is given in world coordinates)
        // touchPlaneDistance is distance btw POV and touch plane, in world coordinates
        // touch ray's origin and direction are given in world coordinates

        let ray = touchRay(at: location)
        let distanceToPoint: Float = touchPlaneDistance / simd_dot(povController.pov.forward, ray.direction)
        let touchPoint = ray.origin + distanceToPoint * ray.direction

//        print("RenderController.touchPoint")
//        print("    pov.forward: \(povController.pov.forward.prettyString)")
//        print("    touchPlaneDistance: \(touchPlaneDistance)")
//        print("    ray.origin: \(ray.origin.prettyString)")
//        print("    ray.direction: \(ray.origin.prettyString)")
//        print("    fwd*ray: \(simd_dot(povController.pov.forward, ray.direction))")
//        print("    distanceToPoint: \(distanceToPoint)")
//        print("    touchPoint: \(touchPoint.prettyString)")

        return touchPoint
    }


    public func dragBegan(at location: SIMD2<Float>) {
        povController.dragGestureBegan(at: touchPoint(location))
    }

    public func dragChanged(panFraction: Float, scrollFraction: Float) {
        // Convert pan & scroll from fractions of the screen (-1...1)
        // to distances in view coordinates.
        let fovSize = fovController.fovSize(touchPlaneDistance)
        povController.dragGestureChanged(panDistance: panFraction * Float(fovSize.width),
                                         scrollDistance: scrollFraction * Float(fovSize.height))
    }

    public func dragEnded() {
        povController.dragGestureEnded()
    }

    public func pinchBegan(at location: SIMD2<Float>) {
        // HACK HACK HACK HACK use center of screen, not location
        povController.pinchGestureBegan(at: touchPoint(.zero))
    }

    public func pinchChanged(scale: Float) {
        povController.pinchGestureChanged(scale: scale)
    }

    public func pinchEnded() {
        povController.pinchGestureEnded()
    }

    public func rotationBegan(at location: SIMD2<Float>) {
        // HACK HACK HACK HACK use center of screen, not location
        povController.rotationGestureBegan(at: touchPoint(.zero))
    }

    public func rotationChanged(radians: Float) {
        povController.rotationGestureChanged(radians: radians)
    }

    public func rotationEnded() {
        povController.rotationGestureEnded()
    }

}

public struct TouchRay {

    /// Ray's point of origin in world coordinates
    public var origin: SIMD3<Float>

    /// Unit vector giving ray's direction in world coordinates
    public var direction :SIMD3<Float>

    public var range: ClosedRange<Float>
}

public class Renderer: NSObject, MTKViewDelegate {

    public static let maxBuffersInFlight = 3

    weak var controller: RenderController!

    var gestureHandlers: GestureHandlers

    var viewSize: CGSize

    let device: MTLDevice!

    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)

    let commandQueue: MTLCommandQueue

    var depthState: MTLDepthStencilState

    public init(_ controller: RenderController, _ gestureHandlers: GestureHandlers?) throws {
        self.controller = controller
        self.gestureHandlers = gestureHandlers ?? GestureHandlers()

        self.viewSize = CGSize(width: 1, height: 1) // dummy values, must be > 0

        if let device = MTLCreateSystemDefaultDevice() {
            self.device = device
        }
        else {
            throw RenderError.noDevice
        }

        self.commandQueue = device.makeCommandQueue()!

        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDesciptor.isDepthWriteEnabled = true

        if let state = device.makeDepthStencilState(descriptor:depthStateDesciptor) {
            depthState = state
        }
        else {
            throw RenderError.noDepthStencilState
        }

        super.init()

    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

        // Docco sez, "Use this method to recompute any view or projection matrices, or to
        // regenerate any buffers to be compatible with the view’s new size." However, we're
        // going to do all that in draw(), because the matrices depend on user-settable properties
        // that may change anytime, not just when something happens to trigger this method.

        controller.fovController.viewSize = size
    }

    public func draw(in view: MTKView) {
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)

        // _drawCount += 1
        // let t0 = Date()

        // Swift compiler sez that the snapshot needs to be taken before the current drawable
        // is presented. This means it will capture the figure that was drawn the in PREVIOUS
        // call to this method.
        if controller.snapshotRequested {
            controller.snapshotTaken(saveSnapshot(view))
        }

        // Make sure all the renderables get exactly the same values
        let date = Date()
        controller.povController.update(date)
        controller.fovController.update(date)
        let renderSettings = RenderSettings(pov: controller.povController.pov,
                                            viewMatrix: controller.povController.viewMatrix,
                                            fadeoutMidpoint: controller.fovController.fadeoutMidpoint,
                                            fadeoutDistance: controller.fovController.fadeoutDistance,
                                            projectionMatrix: controller.fovController.projectionMatrix,
                                            preferredFramesPerSecond: view.preferredFramesPerSecond)

        for var renderable in controller.renderables {
            renderable.prepareToDraw(view, renderSettings)
        }

        if let commandBuffer = commandQueue.makeCommandBuffer() {

            let semaphore = inFlightSemaphore
            commandBuffer.addCompletedHandler { (_ commandBuffer) -> Swift.Void in
                semaphore.signal()
            }

            // Delay getting the current Drawable and RenderPassDescriptor until we absolutely
            // them, in order to avoid holding onto the drawable and therby blocking the display
            // pipeline any longer than necessary
            if let drawable = view.currentDrawable,
               let renderPassDescriptor = view.currentRenderPassDescriptor,
               let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {

                // The figure's background is opaque and we doing single-pass rendering, so we don't
                // need to do anything for loadAction or storeAction.
                renderPassDescriptor.colorAttachments[0].loadAction = .dontCare
                renderPassDescriptor.colorAttachments[0].storeAction = .dontCare

                renderEncoder.setDepthStencilState(depthState)

                for renderable in controller.renderables {
                    renderable.encodeDrawCommands(renderEncoder)
                }
                renderEncoder.endEncoding()
                commandBuffer.present(drawable)
            }
            commandBuffer.commit()
        }
    }

    func saveSnapshot(_ view: MTKView) -> String {
        if let cgImage = view.takeSnapshot() {
            return cgImage.save()

            // Docco sez: "You are responsible for releasing this object by calling CGImageRelease"
            // but I get a compiler error: "'CGImageRelease' is unavailable: Core Foundation objects are automatically memory managed"
            // CGImageRelease(cgImage)
        }
        else {
            return "Image capture failed"
        }
    }
}

public struct RendererView {

    @ObservedObject var controller: RenderController

    var gestureHandlers: GestureHandlers?

    public init(_ controller: RenderController,
                _ gestureHandlers: GestureHandlers? = nil) {
        self.controller = controller
        self.gestureHandlers = gestureHandlers
    }

    public func makeCoordinator() -> Renderer {
        // Docco sez, "Implement this method if changes to your view might affect other
        // parts of your app. In your implementation, create a custom Swift instance that
        // can communicate with other parts of your interface. For example, you might
        // provide an instance that binds its variables to SwiftUI properties, causing
        // the two to remain synchronized."
        do {
            return try Renderer(controller, gestureHandlers)
        }
        catch {
            fatalError("Problem creating render coordinator: \(error)")
        }
    }

    public func makeMTKView(_ coordinator: Renderer) -> MTKView {
        // "Creates the view object and configures its initial state."

        let mtkView = MTKView()

        // Stop it from drawing while we're setting things up
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true

        mtkView.delegate = coordinator
        mtkView.device = coordinator.device
        mtkView.drawableSize = mtkView.frame.size
        mtkView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        mtkView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb

        mtkView.framebufferOnly = false // necessary for screenshots

        coordinator.gestureHandlers.connectGestures(mtkView)

        //  update and unpause
        updateMTKView(mtkView, coordinator)
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false

        return mtkView
    }

    public func updateMTKView(_ mtkView: MTKView, _ coordinator: Renderer) {
        // Docco sez, "Updates the state of the specified view with new information from SwiftUI."
        // The RendererView struct gets recreated many many times, but makeMTKView should
        // get executed only once. I think makeMTKView is called the first time this struct is
        // created and this method is called all the subsequent times.

        // backgroundColor MIGHT have changed
        mtkView.clearColor = MTLClearColorMake(coordinator.controller.backgroundColor.x,
                                               coordinator.controller.backgroundColor.y,
                                               coordinator.controller.backgroundColor.z,
                                               coordinator.controller.backgroundColor.w)
    }

    static public func dismantleMTKView(_ mtkView: MTKView, _ coordinator: Renderer) {
        coordinator.gestureHandlers.disconnectGestures(mtkView)
    }
}

#if os(iOS) // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

extension RendererView: UIViewRepresentable {
    public typealias UIViewType = MTKView
    public typealias Coordinator = Renderer

    public func makeUIView(context: Context) -> MTKView {
        let mtkView = makeMTKView(context.coordinator)
        mtkView.isMultipleTouchEnabled = true
        return mtkView
    }

    public func updateUIView(_ mtkView: MTKView, context: Context) {
        return updateMTKView(mtkView, context.coordinator)
    }

    static public func dismantleUIView(_ mtkView: MTKView, coordinator: Renderer) {
        dismantleMTKView(mtkView, coordinator)
    }
}

#elseif os(macOS) // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

extension RendererView: NSViewRepresentable {
    public typealias NSViewType = MTKView
    public typealias Coordinator = Renderer

    public func makeNSView(context: Context) -> MTKView {
        return makeMTKView(context.coordinator)
    }

    public func updateNSView(_ mtkView: MTKView, context: Context) {
        return updateMTKView(mtkView, context.coordinator)
    }

    static public func dismantleNSView(_ mtkView: MTKView, coordinator: Renderer) {
        dismantleMTKView(mtkView, coordinator)
    }
}

#endif // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

