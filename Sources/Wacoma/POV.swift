//
//  POV.swift
//  Wacoma
//
//  Created by Jim Hanson on 1/8/22.
//

import Foundation
import simd

enum POVError: Error {
    case notUnitVector(_ name: String, length: Float)
    case notOrthogonal(_ name1: String, _ name2: String, dotProduct: Float)
}

/// Point of View
public protocol POV {

    /// the POV's location in world coordinates
    var location: SIMD3<Float> { get }

    /// Unit vector giving the direction the POV is pointed
    var forward: SIMD3<Float> { get }

    /// Unit vector giving the POV's "up" direction. Orthogonal to forward.
    var up: SIMD3<Float> { get }
}

/// POV whose forward vector always points toward a fixed point in world coordinates.
public struct CenteredPOV: POV, Codable, Sendable, Hashable, Equatable, CustomStringConvertible   {

    public var description: String {
        "{ location: \(location.prettyString), center: \(center.prettyString), up: \(trueUp.prettyString) }"
    }

    public var radius: Float {
        simd_distance(location, center)
    }

    public var forward: SIMD3<Float> {
        normalize(center - location)
    }

    public var up: SIMD3<Float> {
        get { trueUp }
        set { trueUp = normalize(newValue - dot(forward, newValue) * forward) }
    }

    public var location: SIMD3<Float>

    public var center: SIMD3<Float>

    private var trueUp: SIMD3<Float>

    /// location is any point
    /// center can be any point not equal to location
    /// up can be any nonzero vector not parallel to the displacement between center and location
    public init(location: SIMD3<Float> = SIMD3<Float>(0, 0, -1),
                center: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
                up: SIMD3<Float> = SIMD3<Float>(0,1,0)) {
        self.location = location
        self.center = center
        let delta = center - location
        self.trueUp =  normalize(up - (simd_dot(delta, up) / simd_dot(delta, delta)) * delta)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(location: try container.decode(SIMD3<Float>.self, forKey: .location),
                  center: try container.decode(SIMD3<Float>.self, forKey: .center),
                  up: try container.decode(SIMD3<Float>.self, forKey: .up))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(location, forKey: .location)
        try container.encode(center, forKey: .center)
        try container.encode(trueUp, forKey: .up)
    }

    private enum CodingKeys: String, CodingKey {
        case location
        case center
        case up
    }

}

/// POV whose forward vector is directly settable.
public struct FlyingPOV: POV, Codable, Hashable, Equatable, CustomStringConvertible {

    public var description: String {
        "{ location: \(location.prettyString), forward: \(trueForward.prettyString), up: \(trueUp.prettyString) }"
    }

    public var location: SIMD3<Float>

    public var forward: SIMD3<Float> {
        get { trueForward }
        set { trueForward = normalize(newValue) }
    }

    private var trueForward: SIMD3<Float>

    public var up: SIMD3<Float> {
        get { trueUp }
        set { trueUp = normalize(newValue - dot(trueForward, newValue) * trueForward) }
    }

    private var trueUp: SIMD3<Float>

    /// location: any point
    /// forwardHint: any  nonzero vector
    /// upHint: any nonzero vector not parallel to forward
    public init(location: SIMD3<Float> = SIMD3<Float>(0, 0, -1),
                forward: SIMD3<Float> =  SIMD3<Float>(0, 0, 1),
                up: SIMD3<Float> = SIMD3<Float>(0, 1, 0)) {
        self.init(location: location,
                  trueForward: normalize(forward),
                  trueUp: normalize(up - (dot(forward, up) / dot(forward, forward)) * forward))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(location: try container.decode(SIMD3<Float>.self, forKey: .location),
                  forward: try container.decode(SIMD3<Float>.self, forKey: .forward),
                  up: try container.decode(SIMD3<Float>.self, forKey: .up))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(location, forKey: .location)
        try container.encode(trueForward, forKey: .forward)
        try container.encode(trueUp, forKey: .up)
    }

    /// location: any point
    /// trueForward: unit vector
    /// trueUp: unit vector orthogonal to trueForward
    internal init(location: SIMD3<Float>, trueForward: SIMD3<Float>, trueUp: SIMD3<Float>) {
        do {
            try Self.validate(location: location, forward: trueForward, up: trueUp)
            self.location = location
            self.trueForward = trueForward
            self.trueUp = trueUp
        }
        catch {
            print("Problem with POV -- \(error)")
            self.location = SIMD3<Float>(0, 0, -1)
            self.trueForward = SIMD3<Float>(0, 0, 1)
            self.trueUp = SIMD3<Float>(0, 1, 0)
        }
    }

    static func validate(location: SIMD3<Float>, forward: SIMD3<Float>, up: SIMD3<Float>) throws {
        if length(forward).differentFrom(1) {
            throw POVError.notUnitVector("forward", length: length(forward))
        }
        if length(up).differentFrom(1) {
            throw POVError.notUnitVector("up", length: length(up))
        }
        if dot(forward, up).differentFrom(0) {
            throw POVError.notOrthogonal("forward", "up", dotProduct: dot(forward, up))
        }
    }

    private enum CodingKeys: String, CodingKey {
        case forward
        case location
        case up
    }


}

public struct POVControllerSettings {

    public var scrollSensitivity: Float

    public var panSensitivity: Float

    public var rotationSensitivity: Float

    public var flyCoastingThreshold: Double

    public var flyNormalizedAcceleration: Double

    public var flyMinSpeed: Double

    public var flyMaxSpeed: Double

#if os(iOS) // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    public init() {
        self.scrollSensitivity = 1.5 * .piOverTwo
        self.panSensitivity = 1.5 * .pi
        self.rotationSensitivity = 1.25
        self.flyCoastingThreshold = 0.33
        self.flyNormalizedAcceleration = 6
        self.flyMinSpeed  = 0.01
        self.flyMaxSpeed = 10
    }
#elseif os(macOS) // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    public init() {
        self.scrollSensitivity = 1.5 * .piOverTwo
        self.panSensitivity = 1.5 * .pi
        self.rotationSensitivity = 1.25
        self.flyCoastingThreshold = 0.33
        self.flyNormalizedAcceleration = 6
        self.flyMinSpeed  = 0.01
        self.flyMaxSpeed = 10
    }
#endif // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

}

public protocol POVController {

    var settings: POVControllerSettings { get set }

    var pov: POV { get }

    var viewMatrix: float4x4 { get }

    /// Sets the POV's properties to the values they should have at the given system time.
    /// This is called during each rendering cycle as a way to support a POV that changes on its own
    func update(_ timestamp: Date)

    func dragGestureBegan(at: SIMD3<Float>)

    func dragGestureChanged(pan: Float, scroll: Float)

    func dragGestureEnded()

    func pinchGestureBegan(at: SIMD3<Float>)

    func pinchGestureChanged(scale: Float)

    func pinchGestureEnded()

    func rotationGestureBegan(at: SIMD3<Float>)

    func rotationGestureChanged(radians: Float)

    func rotationGestureEnded()

}

extension POVController {

    public var viewMatrix: float4x4 {

        // Adapted from:
        // https://stackoverflow.com/questions/9053377/ios-questions-about-camera-information-within-glkmatrix4makelookat-result
        // https://gist.github.com/CaptainRedmuff/5673450

        let pov = self.pov
        let n = -pov.forward
        let u = normalize(simd_cross(pov.up, n))
        let v = simd_cross(n, u)

        return float4x4(columns: (SIMD4<Float>(u.x, v.x, n.x,  0),
                                  SIMD4<Float>(u.y, v.y, n.y,  0),
                                  SIMD4<Float>(u.z, v.z, n.z,  0),
                                  SIMD4<Float>(simd_dot(-u, pov.location), simd_dot(-v, pov.location), simd_dot(-n, pov.location),  1)))
    }
}

public class OrbitingPOVController: ObservableObject, POVController {

    @Published public var orbitEnabled: Bool

    /// angular rotation rate in radians per second
    @Published public var orbitSpeed: Float

    public var pov: POV {
        currentPOV
    }

    public var frozen: Bool = false

    /// User-settable but not published because it changes too frequently
    public var currentPOV = CenteredPOV()

    public var defaultPOV = CenteredPOV()

    public var markedPOV: CenteredPOV? = nil

    public var markIsSet: Bool {
        return markedPOV != nil
    }

    public var flying: Bool {
        return flightInProgress != nil
    }

    public var getureInProgress: Bool {
        return dragInProgress != nil || pinchInProgress != nil || rotationInProgress != nil
    }

    public var settings = POVControllerSettings()

    /// Z-distance in world coordinates to the point in space where a gesture is centered.
    /// If unset, we use pov center.
    public var touchZDistance: Float? = nil

    private var _lastUpdateTimestamp: Date? = nil

    private var flightInProgress: CenteredPOVFlight? = nil

    private var dragInProgress: CenteredPOVTangentialMove? = nil

    private var pinchInProgress: CenteredPOVRadialMove? = nil

    private var rotationInProgress: CenteredPOVRoll? = nil

    public init(pov: CenteredPOV = CenteredPOV(),
                orbitEnabled: Bool = true,
                orbitSpeed: Float = 1/8) {
        self.currentPOV = pov
        self.defaultPOV = pov
        self.orbitEnabled = orbitEnabled
        self.orbitSpeed = orbitSpeed
    }

    public func markPOV() {
        markedPOV = currentPOV
    }

    public func unsetMark() {
        markedPOV = nil
    }

    public func jumpToDefault() {
        if !frozen {
            currentPOV = defaultPOV
        }
    }

    public func jumpToMark() {
        if !frozen {
            if let mark = markedPOV {
                currentPOV = mark
            }
        }
    }

    public func jumpTo(pov: CenteredPOV) {
        if !frozen {
            // print("OrbitingPOVController.jumpTo -- new pov: \(pov)")
            currentPOV = pov
        }
    }

    public func flyToDefault(_ callback: (() -> ())? = nil) {
        flyTo(pov: defaultPOV, callback)
    }

    public func flyToMark(_ callback: (() -> ())? = nil) {
        if let povMark = markedPOV {
            flyTo(pov: povMark, callback)
        }
    }

    public func flyTo(pov destination: CenteredPOV, _ callback: (() -> ())? = nil) {
        if !frozen && !flying {
            self.flightInProgress = CenteredPOVFlight(self.currentPOV, destination, settings, callback: callback)
        }
    }

    public func centerOn(_ newCenter: SIMD3<Float>, _ callback: (() -> ())? = nil) {
        flyTo(pov: CenteredPOV(location: currentPOV.location, center: newCenter, up: currentPOV.up), callback)
    }

    public func hoverOver(_ point: SIMD3<Float>, _ distance: Float, _ callback: (() -> ())? = nil) {
        self.orbitEnabled = false
        var displacementRTP = cartesianToSpherical(xyz: point - currentPOV.center)
        displacementRTP.x += distance
        let destination = sphericalToCartesian(rtp: displacementRTP)
        flyTo(pov: CenteredPOV(location: destination, center: currentPOV.center, up: currentPOV.up), callback)
    }

    public func dragGestureBegan(at location: SIMD3<Float>) {
        if !frozen && !flying {
            self.dragInProgress = CenteredPOVTangentialMove(self.currentPOV, location, settings)
        }
    }

    public func dragGestureChanged(pan: Float, scroll: Float) {
        if let handler = self.dragInProgress {
            if let newPOV = handler.locationChanged(pan: pan, scroll: scroll) {
                self.currentPOV = newPOV
            }
        }
    }

    public func dragGestureEnded() {
        self.dragInProgress = nil
    }


    public func pinchGestureBegan(at pinchLocation: SIMD3<Float>) {
        if !frozen && !flying {
            self.pinchInProgress = CenteredPOVRadialMove(self.currentPOV, pinchLocation)
        }
    }

    public func pinchGestureChanged(scale: Float) {
        if var povPinchHandler = self.pinchInProgress {
            if let newPOV = povPinchHandler.scaleChanged(self.pov, scale: scale) {
                self.currentPOV = newPOV
            }
        }
    }

    public func pinchGestureEnded() {
        pinchInProgress = nil
    }

    public func rotationGestureBegan(at: SIMD3<Float>) {
        if !frozen && !flying {
            self.rotationInProgress = CenteredPOVRoll(self.currentPOV, settings)
        }
    }

    public func rotationGestureChanged(radians: Float) {
        if var povRotationHandler = self.rotationInProgress {
            if let newPOV = povRotationHandler.rotationChanged(self.currentPOV, radians: radians) {
                self.currentPOV = newPOV
            }
        }
    }

    public func rotationGestureEnded() {
        self.rotationInProgress = nil
    }

    //    public func dragBegan(at location: SIMD2<Float>) {
    //        if !frozen && !flying {
    //
    //            // Find the point in 3-space where the touch occurred. use touchZDistance as world-coordinate distance from
    //            // eye to the point
    //            self.dragInProgress = CenteredPOVTangentialMove(self.currentPOV, location, settings, zDistance: touchZDistance)
    //        }
    //    }
    //
    //    public func dragChanged(pan: Float, scroll: Float) {
    //        if var povDragHandler = self.dragInProgress {
    //            if let newPOV = povDragHandler.dragChanged(self.currentPOV, pan: pan, scroll: scroll) {
    //                self.currentPOV = newPOV
    //            }
    //        }
    //    }
    //
    //    public func dragMoved(to location: SIMD2<Float>) {
    //        // NOP
    //    }
    //
    //    public func dragEnded() {
    //        // print("dragEnded")
    //        self.dragInProgress = nil
    //    }
    //
    //    public func pinchBegan(at touchLocation: SIMD2<Float>) {
    //        if !frozen && !flying {
    //            let pinchLocation: SIMD3<Float>
    //            if let touchZDistance {
    //                pinchLocation = currentPOV.location + touchZDistance * pov.forward
    //            }
    //            else {
    //                pinchLocation = currentPOV.center
    //            }
    //            self.pinchInProgress = CenteredPOVRadialMove(self.currentPOV, pinchLocation)
    //        }
    //    }
    //
    //    public func pinchChanged(by scale: Float) {
    //        if var povPinchHandler = self.pinchInProgress {
    //            if let newPOV = povPinchHandler.scaleChanged(self.pov, scale: scale) {
    //                self.currentPOV = newPOV
    //            }
    //        }
    //    }
    //
    //    public func pinchEnded() {
    //        // print("pinchEnded")
    //        pinchInProgress = nil
    //    }
    //
    //    public func rotationBegan(at location: SIMD2<Float>) {
    //        if !frozen && !flying {
    //            self.rotationInProgress = CenteredPOVRoll(self.currentPOV, settings)
    //        }
    //    }
    //
    //    public func rotationChanged(by radians: Float) {
    //        if var povRotationHandler = self.rotationInProgress {
    //            if let newPOV = povRotationHandler.rotationChanged(self.currentPOV, radians: radians) {
    //                self.currentPOV = newPOV
    //            }
    //        }
    //    }
    //
    //    public func rotationEnded() {
    //        // print("rotationEnded")
    //        self.rotationInProgress = nil
    //    }

    public func update(_ timestamp: Date) {
        var updatedPOV: CenteredPOV
        if let newPOV = flightInProgress?.update(timestamp) {
            updatedPOV = newPOV
        }
        else {
            self.flightInProgress = nil
            updatedPOV = self.currentPOV
        }

        // ==================================================================
        // Q: orbital motion even if we're flying?
        // A: No, it's confusing
        // Q: how about if we're handling a gesture?
        // A: I'd rather not because it looks jerky. But on iOS we never
        // get notified when drag ends, so if I check for gesture in progress
        // after dragging it always returns true.
        // ==================================================================

        if orbitEnabled && !frozen && !flying,
           let t0 = _lastUpdateTimestamp {
            // Multiply by -1 so that positive speed looks like earth's direction of rotation
            let dPhi = -1 * orbitSpeed * Float(timestamp.timeIntervalSince(t0))
            let transform = float4x4(translationBy: updatedPOV.center)
            * float4x4(rotationAround: updatedPOV.up, by: dPhi)
            * float4x4(translationBy: -updatedPOV.center)
            let newLocation = (transform * SIMD4<Float>(updatedPOV.location, 1)).xyz
            updatedPOV = CenteredPOV(location: newLocation, center: updatedPOV.center, up: updatedPOV.up)
        }
        _lastUpdateTimestamp = timestamp

        // debug("POVController.updatePOV", "new POV = \(updatedPOV)")
        self.currentPOV = updatedPOV
    }
}

// ===========================================================
// MARK: - POV Actions
// ===========================================================

///
///
///
class CenteredPOVFlight {

    enum Phase: Double {
        case new
        case accelerating
        case coasting
        case decelerating
        case arrived
    }

    // Needed for multi-step flying, only first and last are used at present.
    let povSequence: [CenteredPOV]

    // Needed for multi-step flying, NOT USED yet.
    let totalDistance: Float

    let coastingThreshold: Double

    let normalizedAcceleration: Double

    let minSpeed: Double

    let maxSpeed: Double

    var lastUpdateTime: Date = .distantPast

    var normalizedSpeed: Double = 0

    var currentStepIndex: Int = 0

    /// fraction of the distance in the current step has been covered
    var currentStepFractionalDistance: Double = 0

    var phase: Phase = .new

    var callback: (() -> ())?

    init(_ pov: CenteredPOV, _ destination: CenteredPOV, _ settings: POVControllerSettings, callback:(() -> ())? = nil) {
        self.povSequence = [pov, destination]
        self.totalDistance = Self.calculateTotalDistance([pov, destination])
        self.coastingThreshold = settings.flyCoastingThreshold
        self.normalizedAcceleration = settings.flyNormalizedAcceleration
        self.minSpeed = settings.flyMinSpeed
        self.maxSpeed = settings.flyMaxSpeed
        self.callback = callback
    }

    static func calculateTotalDistance(_ povSequence: [POV]) -> Float {
        var distance: Float = 0
        for i in 1..<povSequence.count {
            distance += simd_distance(povSequence[i-1].location, povSequence[i].location)
        }
        return distance
    }

    /// returns nil when finished
    func update(_ timestamp: Date) -> CenteredPOV? {
        // debug("POVFlightAction.update", "phase = \(phase)")

        // ===============================================================================
        // FIXME: This impl ONLY works if povSequence.count == 2 and currentStepIndex == 0
        // ===============================================================================

        // It's essential that the first time this func is called,
        // phase = .new and currentStepFractionalDistance = 0

        let dt = timestamp.timeIntervalSince(lastUpdateTime)
        lastUpdateTime = timestamp

        currentStepFractionalDistance += normalizedSpeed * dt

        switch phase {
        case .new:
            phase = .accelerating
        case .accelerating:
            if currentStepFractionalDistance >= coastingThreshold {
                phase = .coasting
            }
            else {
                normalizedSpeed += normalizedAcceleration * dt
                if normalizedSpeed > maxSpeed {
                    normalizedSpeed = maxSpeed
                    phase = .coasting
                }
            }
        case .coasting:
            if currentStepFractionalDistance >= (1 - coastingThreshold) {
                phase = .decelerating
            }
        case .decelerating:
            if currentStepFractionalDistance >= 1  {
                currentStepFractionalDistance = 1
                phase = .arrived
            }
            else {
                normalizedSpeed -= (normalizedAcceleration * dt)
                if normalizedSpeed < minSpeed {
                    normalizedSpeed = minSpeed
                }
            }
        case .arrived:
            if let callback = callback {
                // debug("POVFlightAction.update", "executing callback")
                callback()
            }
            // debug("POVFlightAction.update", "returning nil")
            return nil
        }

        let initialPOV = povSequence[currentStepIndex]
        let finalPOV = povSequence[currentStepIndex+1]
        let newLocation = Float(currentStepFractionalDistance) * (finalPOV.location - initialPOV.location) + initialPOV.location
        let newCenter  = Float(currentStepFractionalDistance) * (finalPOV.center - initialPOV.center) + initialPOV.center
        let newUp       = Float(currentStepFractionalDistance) * (finalPOV.up - initialPOV.up) + initialPOV.up
        return CenteredPOV(location: newLocation,
                           center: newCenter,
                           up: newUp)
    }
}

///
/// PAN is a rotation of the POV's location about an axis that is
/// parallel to the POV's up axis and that passes through the POV's
/// center point
///
/// SCROLL is a rotation of the location and up vectors.
/// --location rotates about an axis that is perpendicular to both
///   forward and up axes and that passes through the center point
/// --up vector rotates about the same axis
///
struct CenteredPOVTangentialMove {

    let initialPOV: CenteredPOV

    let initialTouch: SIMD3<Float>

    /// displacement of initialTouch from pov.center
    // let initialDisplacement: SIMD3<Float>

    let initialTheta: Float

    let initialPhi: Float

    /// unit vector perpendicular to initial POV's forward and up vectors
    let scrollRotationAxis: SIMD3<Float>

    let panRotationAxis: SIMD3<Float>

    let scrollFactor: Float
    let panFactor: Float

    init(_ pov: CenteredPOV, _ touchLocation: SIMD3<Float>, _ settings: POVControllerSettings) {
        let initialDisplacementRTP = cartesianToSpherical(xyz: touchLocation - pov.center)

        self.initialPOV = pov
        self.initialTouch = touchLocation
        self.initialTheta = initialDisplacementRTP.y
        self.initialPhi = initialDisplacementRTP.z
        self.scrollRotationAxis = normalize(simd_cross(initialPOV.forward, initialPOV.up))
        self.panRotationAxis = initialPOV.up

        let inverseRadius = 1 / sqrt(distance(pov.location, pov.center))
        self.scrollFactor = inverseRadius * settings.scrollSensitivity
        self.panFactor = inverseRadius * settings.panSensitivity
    }

//    func locationChanged(to newTouchLocation: SIMD3<Float>) -> CenteredPOV? {
//        let newDisplacementRTP = cartesianToSpherical(xyz: newTouchLocation - initialPOV.center)
//        let dTheta = newDisplacementRTP.y - initialTheta
//        let dPhi = newDisplacementRTP.z - initialPhi
//
//        print("dTouch=\((newTouchLocation-initialTouch).prettyString), dTheta=\(dTheta), dPhi=\(dPhi)")
//
////        let newLocation =  (
////            float4x4(translationBy: initialPOV.center)
////            * float4x4(rotationAround: thetaRotationAxis, by: dTheta)
////            * float4x4(rotationAround: phiRotationAxis, by: dPhi)
////            * float4x4(translationBy: -initialPOV.center)
////            * SIMD4<Float>(initialPOV.location, 1)
////        ).xyz
////
////        let newUp = (
////            float4x4(rotationAround: thetaRotationAxis, by: dTheta)
////            * SIMD4<Float>(initialPOV.up, 1)
////        ).xyz
//
//        let newLocation = initialPOV.location
//        let newUp = initialPOV.up
//
//        return CenteredPOV(location: newLocation,
//                           center: initialPOV.center,
//                           up: newUp)
//    }

    func locationChanged(pan: Float, scroll: Float) -> CenteredPOV? {
        /// unit vector perpendicular to POV's forward and up vectors

        let newLocation = (
            float4x4(translationBy: initialPOV.center)
            * float4x4(rotationAround: panRotationAxis, by: -pan * panFactor)
            * float4x4(rotationAround: scrollRotationAxis, by: scroll * scrollFactor)
            * float4x4(translationBy: -initialPOV.center)
            * SIMD4<Float>(initialPOV.location, 1)
        ).xyz

        let newUp = (
            float4x4(rotationAround: scrollRotationAxis, by: scroll * scrollFactor)
            * SIMD4<Float>(initialPOV.up, 1)
        ).xyz

        return CenteredPOV(location: newLocation,
                           center: initialPOV.center,
                           up: newUp)
    }
}

///
/// This is a translation of POV's location toward or away from a given center that it's pointed toward
///
struct CenteredPOVRadialMove {


    let initialPOV: CenteredPOV

    let pinchLocation: SIMD3<Float>

    let initialDisplacement: SIMD3<Float>

    init(_ pov: CenteredPOV, _ pinchLocation: SIMD3<Float>) {
        self.initialPOV = pov
        self.pinchLocation = pinchLocation
        self.initialDisplacement = pov.location - pinchLocation
    }

    //    /// ASSUMES pov.forward is pointed toward center
    //    /// zDistance is the (positive definite) distance from the POV's location to the place in 3D space where we want the pinch to originate.
    //    init(_ pov: CenteredPOV, _ touchLocation: SIMD2<Float>, _ settings: POVControllerSettings, zDistance: Float? = nil) {
    //
    //        let pinchLocation: SIMD3<Float>
    //        if let zDistance {
    //            pinchLocation = pov.location + zDistance * pov.forward
    //        }
    //        else {
    //            pinchLocation = pov.center
    //        }
    //
    //        self.initialPOV = pov
    //        self.pinchLocation = pinchLocation
    //        self.initialDisplacement = pov.location - pinchLocation
    //    }

    mutating func scaleChanged(_ pov: POV, scale: Float) -> CenteredPOV? {
        let newDisplacement = initialDisplacement / scale
        let newLocation = newDisplacement + pinchLocation
        return CenteredPOV(location: newLocation,
                           center: initialPOV.center,
                           up: pov.up)
    }
}


///
/// This is a rotation of the POV's up vector about its forward vector
///
struct CenteredPOVRoll {

    let initialPOV: CenteredPOV

    let rotationSensitivity: Float

    init(_ pov: CenteredPOV, _ settings: POVControllerSettings) {
        self.initialPOV = pov
        self.rotationSensitivity = settings.rotationSensitivity
    }

    mutating func rotationChanged(_ pov: CenteredPOV, radians: Float) -> CenteredPOV? {
        let upMatrix = float4x4(rotationAround: pov.forward, by: Float(-rotationSensitivity * radians))
        let newUp = (upMatrix * SIMD4<Float>(initialPOV.up, 1)).xyz
        return CenteredPOV(location: pov.location,
                           center: pov.center,
                           up: newUp)
    }
}
