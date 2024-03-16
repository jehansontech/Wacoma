//
//  Float+Extensions.swift
//  Wacoma
//
//  Created by Jim Hanson on 10/13/20.
//  Copyright © 2020 J.E. Hanson Technologies LLC. All rights reserved.
//

import Foundation
 
extension Float {
    
    public static let epsilon: Float = 1e-6

    public static let twoPi: Self = 2 * .pi

    public static let piOverTwo: Self = .pi / 2

    public static let threePiOverTwo: Self = 3 * .pi / 2

    public static let piOverThree: Self = .pi / 3

    public static let piOverFour: Self = .pi / 4

    public static let goldenRatio: Self = (1 + sqrt(5)) / 2

    public static let logTwo: Self = log(2)

//    public func nonNegative() -> Self {
//        return self > 0 ? self : 0
//    }

    public func fuzz(_ fuzzFactor: Double) -> Self {
        if self > 0 {
            let lo = Float((1 - fuzzFactor) * Double(self))
            let hi = Float((1 + fuzzFactor) * Double(self))
            return Float.random(in: lo...hi)

        }
        else if self < 0 {
            let hi = Float((1 - fuzzFactor) * Double(self))
            let lo = Float((1 + fuzzFactor) * Double(self))
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
