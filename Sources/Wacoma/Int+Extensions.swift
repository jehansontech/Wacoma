//
//  Int+Extensions.swift
//  Wacoma
//
//  Created by Jim Hanson on 3/30/21.
//

import Foundation

public func pow(_ base: Int, _ exponent: Int) -> Int {
    var t = 1
    for _ in 0..<exponent {
        t = base * t
    }
    return t
}

extension Int {

    public func clamp(_ min: Self, _ max: Self) -> Self {
        return self < min ? min : (self > max ? max : self)
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
