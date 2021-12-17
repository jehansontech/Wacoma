//
//  Int+Extensions.swift
//  Wacoma
//
//  Created by Jim Hanson on 3/30/21.
//

import Foundation

extension Int {

    public func clamp(_ min: Self, _ max: Self) -> Self {
        return self < min ? min : (self > max ? max : self)
    }
}
