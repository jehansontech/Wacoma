//
//  Array+Extensions.swift
//  Wacoma
//
//  Created by Jim Hanson on 7/8/22.
//

extension Array {

    public func truncate(_ maxLength: Int) -> Self {
        return self.count <= maxLength ? self : self.dropLast(self.count - maxLength)
    }
}
