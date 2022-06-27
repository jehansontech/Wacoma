//
//  File 2.swift
//  
//
//  Created by Jim Hanson on 6/18/22.
//

import Foundation

extension BinaryInteger {

    public func clamp(_ range: ClosedRange<Self>) -> Self {
        return (self < range.lowerBound) ? range.lowerBound : (self > range.upperBound ? range.upperBound : self)
    }

    public func clamp(_ min: Self, _ max: Self) -> Self {
        return (self < min) ? min : (self > max ? max : self)
    }
}

extension BinaryFloatingPoint {

    public func clamp(_ range: ClosedRange<Self>) -> Self {
        return (self < range.lowerBound) ? range.lowerBound : (self > range.upperBound ? range.upperBound : self)
    }

    public func clamp(_ min: Self, _ max: Self) -> Self {
        return (self < min) ? min : (self > max ? max : self)
    }
}

