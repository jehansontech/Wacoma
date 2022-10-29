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

public class RenderController: ObservableObject {

    public static let defaultDarkBackground = SIMD4<Double>(0.025, 0.025, 0.025, 1)

    public static let defaultLightBackground = SIMD4<Double>(0.975, 0.975, 0.975, 1)

    public var renderables = [Renderable]()

    public var povController: POVController

    public var fovController: FOVController

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
}

public struct TouchRay {

    public var origin: SIMD3<Float>
    public var direction:SIMD3<Float>
    public var range: ClosedRange<Float>
}

extension RenderController {

    public func touchRay(at touchLocation: SIMD2<Float>) -> TouchRay {
        // print("RenderController.ray -- touchLocation: \(touchLocation.prettyString)")

        let point0 = SIMD4<Float>(touchLocation.x, touchLocation.y, 0, 1)
        var point1 = fovController.projectionMatrix.inverse * point0
        point1.z = -1
        point1.w = 0

        // I don't know what's going on here.
        //
        // point0 is the point we touched in screen coordinates with a z-component
        // set to 0. I was thinking that meant it was somwehere on the near face
        // of the frustum but now I'm not sure.
        //
        // ¿ point1 at first is that same point transformed into modelview coordinates
        // (in which the origin is the POV's location and the z axis gives the POV's
        // direction of gaze). Then we move it along the POV's direction of gaze (i.e.,
        // either ahead of or behind the eye, I don't know which).
        //
        // But point1.z was -1 already . . . is that a coincidence because of my zNear and zFar?
        // point1.w was NOT 0
        //
        // Is point1 on the BACK face of the frustum?
        //
        //        let zz0 = fovController.projectionMatrix.inverse *  SIMD4<Float>(touchLocation.x, touchLocation.y, 0, 1)
        //        let zz1 = fovController.projectionMatrix.inverse *  SIMD4<Float>(touchLocation.x, touchLocation.y, 1, 1)
        //        let zz2 = fovController.projectionMatrix.inverse * SIMD4<Float>(touchLocation.x, touchLocation.y, -1, 1)
        //        print("zz0: \(zz0.prettyString)")
        //        print("zz1: \(zz1.prettyString)")
        //        print("zz2: \(zz2.prettyString)")
        //
        // The values I'm seeing for x coords are all in, -1.3 to 1.3
        // The y's are all in -1 to 1.
        // The z's are ALL -1.
        // The w coord is quite big, at least the ones I remember.
        //
        // I have verified that rayOrigin is equal to pov.location.
        // let rayOrigin = (povController.viewMatrix.inverse * SIMD4<Float>(0, 0, 0, 1)).xyz

        // FIXME: this is totally wrong.
        // What I'm looking for are the distances, in world coordinates,
        // to the nearest and farthest visible points *along the ray*.
        let zRange = fovController.visibleZ

        // The "origin" of the ray is the POV's location in world coordinates.
        // Its "direction" is the displacement vector from the POV's location
        // to point1, transformed to world coordinates and normalized.
        return TouchRay(origin: povController.pov.location,
                        direction: normalize(povController.viewMatrix.inverse * point1).xyz,
                        range: zRange)
    }
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

