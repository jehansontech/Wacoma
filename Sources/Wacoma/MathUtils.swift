//
//  MathUtils.swift
//  
//
//  Created by Jim Hanson on 5/10/21.
//

import Foundation

/// returns the exponent: for 10 <= x < 100, returns 2. If x == 0 returns 0
public func orderOfMagnitude(_ x: Double) -> Int {
    return (x == 0) ? 0 : Int(floor(log10(abs(x))))
}

