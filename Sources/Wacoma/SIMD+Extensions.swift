//
//  SIMD+Extensions.swift
//  ArcWorld
//
//  Created by Jim Hanson on 10/17/20.
//  Copyright © 2020 J.E. Hanson Technologies LLC. All rights reserved.
//

import Foundation

extension SIMD3 {

    public var xy: SIMD2<Scalar> {
        return SIMD2<Scalar>(self.x, self.y)
    }

}

extension SIMD4 {

    public var xy: SIMD2<Scalar> {
        return SIMD2<Scalar>(self.x, self.y)
    }

    public var xyz: SIMD3<Scalar> {
        return SIMD3<Scalar>(self.x, self.y, self.z)
    }
}
