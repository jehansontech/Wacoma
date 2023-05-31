//
//  Double+Extensions.swift
//  Wacoma
//
//  Created by Jim Hanson on 5/2/21.
//

import Foundation

extension Double {

    public static let epsilon: Self = 1e-12

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

//    public func clamp(_ min: Self, _ max: Self) -> Self {
//        return self < min ? min : (self > max ? max : self)
//    }
//
//    public func clamp(_ range: ClosedRange<Self>) -> Self {
//        return self < range.lowerBound ? range.lowerBound : (self > range.upperBound ? range.upperBound : self)
//    }

    public func fuzz(_ scale: Double, _ variability: Double) -> Self {
        let width = variability * scale
        return Double.random(in: self-width...self+width)
    }

    public func fuzz(_ fuzzFactor: Self) -> Self {
        if self > 0 {
            let lo = (1 - fuzzFactor) * self
            let hi = (1 + fuzzFactor) * self
            return Double.random(in: lo...hi)
        }
        else if self < 0 {
            let hi = (1 - fuzzFactor) * self
            let lo = (1 + fuzzFactor) * self
            return Double.random(in: lo...hi)
        }
        else {
            return self
        }
    }

    public func differentFrom(_ x: Self) -> Bool {
        return abs(x - self) > .epsilon
    }

    /// returns the exponent: for 10 <= x < 100, returns 2. If x == 0 returns 0
    public static func orderOfMagnitude(_ x: Double) -> Int {
        return (x == 0) ? 0 : Int(floor(log10(abs(x))))
    }

    /// returns ln(a choose b) for a > b > 0
    /// For b <= 3 use exact formula for (a choose b)
    /// For b >  3 use Stirling's approximation. Returns 0 on invalid input
    public static func logBinomial(_ a: Int, _ b: Int) -> Double {
        if (a <= 0 || b <= 0 || a <= b) {
            return 0
        }

        let aa = Double(a)
        let bb = Double(b)
        let cc = Double(a-b)

        if (b == 1) {
            return log(aa)
        }
        if (b == 2) {
            return log(aa) + log(aa-1) - log(bb)
        }
        if (b == 3) {
            return log(aa) + log(aa-1) + log(aa-2) - log(bb) - log(bb-1)
        }

        return aa * log(aa) - bb * log(bb) - cc * log(cc)
            + 0.5 * (log(aa) - log(bb) - log(cc) - log(Double.twoPi))
    }

    /// Returns ln(1-e^(-x)) for x > 0, avoiding loss of precision
    /// Assumes x is a finite number
    public static func log1mexp(_ x: Double) -> Double {
        // From https://cran.r-project.org/web/packages/Rmpfr/vignettes/log1mexp-note.pdf (accessed 5/10/2018)
        return (x <= Double.logTwo) ? log(-expm1(-x)) : log1p(-exp(-x))
    }


    /// Returns ln(1+e^x) for all x, avoiding loss of precision
    /// Assumes x is a finite number
    public static func log1pexp(_ x: Double) -> Double {

        // From https://cran.r-project.org/web/packages/Rmpfr/vignettes/log1mexp-note.pdf (accessed 5/10/2018)

        if (x <= -37) {
            return exp(x)
        }
        if (x <= 18) {
            return log1p(exp(x))
        }
        if (x <= 33.3) {
            return x + exp(-x)
        }
        return x
    }


    /// Returns ln(x1 + x2) given w1 = ln(x1) and w2 = ln(x2)
    /// Uses convention that ln(x) is NaN iff x is 0
    public static func addLogs(_ w1: Double, _ w2: Double) -> Double {
        return (w1.isNaN) ? w2 : ( (w2.isNaN) ? w1 : w1 + log1pexp(w2-w1) )
    }


    /// Returns the approximate value of  ln(x1 - x2) given w1 = ln(x1) and w2 = ln(x2)
    /// Uses convention that ln(x) is NaN iff x is 0
    public static func subtractLogs(_ w1: Double, _ w2: Double) -> Double {
        // ln( exp(w1) - exp(w2) ) for w1 finite number and w1 > w2
        // = ln ( exp(w1) * (1 - exp(w2)/exp(w1) )
        // = ln(exp(w1)) + ln(1 - exp(w2-w1))
        // = w1 + ln(1 - exp(-(w1-w2))
        // = w1 + log1mexp(w1-w2)
        return (w2.isNaN) ? w1 : w1 + log1mexp(w1-w2)
    }

}
