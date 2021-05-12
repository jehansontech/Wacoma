//
//  ColorSequence.swift
//  
//
//  Created by Jim Hanson on 5/12/21.
//

import SwiftUI

public protocol ColorSequence: Sequence where Element == Color {

}

public struct PresetColorSequence: ColorSequence {

    public typealias Element = Color
    public typealias Iterator = PresetColorIterator

    var colors: [Color]

    init() {
        self.colors = Self.makeDefaultColors()
    }

    public __consuming func makeIterator() -> PresetColorIterator {
        return PresetColorIterator(colors)
    }

    static func makeDefaultColors() -> [Color] {
        return [
            Color.red,
            Color.green,
            Color.blue,
            Color.yellow,
            Color.purple,
            Color.orange
        ]
    }
}

public struct PresetColorIterator: IteratorProtocol {
    public typealias Element = Color

    let colors: [Color]
    var nextIndex: Int = 0

    init(_ colors: [Color]) {
        self.colors = colors
    }

    public mutating func next() -> Color? {
        let index = nextIndex
        nextIndex += 1
        return colors[index % colors.count]
    }
}
