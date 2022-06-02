//
//  Int+Extensions.swift
//  Wacoma
//
//  Created by Jim Hanson on 3/30/21.
//

import Foundation

public func pow(_ base: Int, _ exponent: Int) -> Int {
    var t = 1
    // We really want to count from 1 to exponent, but that's
    // the same as counting from 0 to exponent-1.
    for _ in 0..<exponent {
        t = base * t
    }
    return t
}

extension Int {

    public func nonNegative() -> Self {
        return self > 0 ? self : 0
    }

    public func positiveDefinite() -> Self {
        return self > 0 ? self : 1
    }

    public func clamp(_ min: Self, _ max: Self) -> Self {
        return self < min ? min : (self > max ? max : self)
    }

    public func fuzz(_ scale: Int, _ variability: Double) -> Self {
        let width = Int(variability * Double(scale))
        return Int.random(in: self-width...self+width)
    }

    public func fuzz(_ fuzzFactor: Double) -> Self {
        if self > 0 {
            let lo = Int((1 - fuzzFactor) * Double(self))
            let hi = Int((1 + fuzzFactor) * Double(self))
            return (lo < hi) ? Int.random(in: lo...hi) : lo
        }
        else if self < 0 {
            let hi = Int((1 - fuzzFactor) * Double(self))
            let lo = Int((1 + fuzzFactor) * Double(self))
            return (lo < hi) ? Int.random(in: lo...hi) : lo
        }
        else {
            return 0
        }
    }

}
