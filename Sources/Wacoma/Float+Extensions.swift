//
//  Float+Extensions.swift
//  Wacoma
//
//  Created by Jim Hanson on 10/13/20.
//  Copyright © 2020 J.E. Hanson Technologies LLC. All rights reserved.
//

import Foundation
 
extension Float {
    
    public static let twoPi: Float = 2 * .pi
    
    public static let piOverTwo: Float = 0.5 * .pi
    
    public static let threePiOverTwo: Float = 1.5 * .pi

    public static let piOverFour: Float = 0.25 * .pi

    public static let epsilon: Float = 1e-6
    
    public static let goldenRatio: Float = (0.5 * (1 + sqrt(5)))
    
    public static let logTwo: Float = log(2)
    
//    public func clamp(_ min: Self, _ max: Self) -> Self {
//        return self < min ? min : (self > max ? max : self)
//    }

    public func fuzz(_ fuzzFactor: Self) -> Self {
        if self > 0 {
            let lo = (1 - fuzzFactor) * self
            let hi = (1 + fuzzFactor) * self
            return Float.random(in: lo...hi)

        }
        else if self < 0 {
            let hi = (1 - fuzzFactor) * self
            let lo = (1 + fuzzFactor) * self
            return Float.random(in: lo...hi)
        }
        else {
            return self
        }
    }

    public func differentFrom(_ x: Self) -> Bool {
        return abs(x - self) > .epsilon
    }
 }
