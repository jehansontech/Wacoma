//
//  Numeric+Extensions.swift
//  Wacoma
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

    public func clamp(lowerBound: Self) -> Self {
        return self < lowerBound ? lowerBound : self
    }

    public func clamp(upperBound: Self) -> Self {
        return self > upperBound ? upperBound : self
    }

    public func nonNegative() -> Self {
        return self > Self.zero ? self : Self.zero
    }
}

extension BinaryFloatingPoint {

    public func clamp(_ range: ClosedRange<Self>) -> Self {
        return (self < range.lowerBound) ? range.lowerBound : (self > range.upperBound ? range.upperBound : self)
    }

    public func clamp(_ min: Self, _ max: Self) -> Self {
        return (self < min) ? min : (self > max ? max : self)
    }

    public func clamp(lowerBound: Self) -> Self {
        return self < lowerBound ? lowerBound : self
    }

    public func clamp(upperBound: Self) -> Self {
        return self > upperBound ? upperBound : self
    }

    public func nonNegative() -> Self {
        return self > Self.zero ? self : Self.zero
    }
}

/// from https://stackoverflow.com/questions/31396301/getting-the-decimal-part-of-a-double-in-swift/55010456#55010456
///
extension Decimal {

    public var nearestWhole: Decimal {
        let below = rounded(.down)
        let above = rounded(.up)
        return (self - below) <= (above - self) ? below : above
    }
    
    public var whole: Decimal {
        return rounded(sign == .minus ? .up : .down)
    }

    public var fraction: Decimal { self - whole }

    public func rounded(_ roundingMode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var result = Decimal()
        var number = self
        NSDecimalRound(&result, &number, 0, roundingMode)
        return result
    }
}
