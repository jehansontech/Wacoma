//
//  File.swift
//  
//
//  Created by Jim Hanson on 5/2/21.
//

import Foundation

extension Double {

    func clamp(_ min: Self, _ max: Self) -> Self {
        return self < min ? min : (self > max ? max : self)
    }

    func clamp(_ range: ClosedRange<Self>) -> Self {
        return self < range.lowerBound ? range.lowerBound : (self > range.upperBound ? range.upperBound : self)
    }
}
