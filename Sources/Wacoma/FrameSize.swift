//
//  FrameSize.swift
//  Wacoma
//
//  Created by Jim Hanson on 12/3/21.
//

import SwiftUI

// ==========================================================================
// MARK: - width
// ==========================================================================

public struct FrameWidth {

    public var minimum: CGFloat
    public var maximum: CGFloat

    public init(_ minimum: CGFloat = 0, _ maximum: CGFloat = .infinity) {
        self.minimum = minimum
        self.maximum = maximum
    }

    public mutating func adjust(_ value: CGFloat) {
        self.minimum = min(max(self.minimum, value), maximum)
    }
}

public struct WidthModifier: ViewModifier {

    @Binding var frameWidth: FrameWidth

    var alignment: Alignment

    public func body(content: Content) -> some View {
        content
            .fixedSize()
            .overlay(GeometryReader { proxy in
                Color.clear.preference(key: FrameWidthPreferenceKey.self, value: proxy.size.width)
            }).onPreferenceChange(FrameWidthPreferenceKey.self) { (value) in
                frameWidth.adjust(value)
            }
        // Don't set minWidth & maxWidth here.
        // if we set maxWidth then Text labels etc expand, so rows don't line up properly
            .frame(width: frameWidth.minimum, alignment: alignment)
    }

    public init(_ frameWidth: Binding<FrameWidth>, _ alignment: Alignment) {
        self._frameWidth = frameWidth
        self.alignment = alignment
    }
}

struct FrameWidthPreferenceKey: PreferenceKey {
    typealias Value = CGFloat

    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {

    public func width(_ frameWidth: Binding<FrameWidth>, alignment: Alignment = .center) -> some View {
        self.modifier(WidthModifier(frameWidth, alignment))
    }
}


// ==========================================================================
// MARK: - height
// ==========================================================================

public struct FrameHeight {

    public var minimum: CGFloat
    public var maximum: CGFloat

    public init(_ minimum: CGFloat = 0, _ maximum: CGFloat = .infinity) {
        self.minimum = minimum
        self.maximum = maximum
    }

    public mutating func adjust(_ value: CGFloat) {
        self.minimum = max(self.minimum, value)
    }
}


public struct HeightModifier: ViewModifier {

    @Binding var frameHeight: FrameHeight

    var alignment: Alignment

    public func body(content: Content) -> some View {
        content
            .fixedSize()
            .overlay(GeometryReader { proxy in
                Color.clear.preference(key: FrameHeightPreferenceKey.self, value: proxy.size.height)
            }).onPreferenceChange(FrameHeightPreferenceKey.self) { (value) in
                frameHeight.adjust(value)
            }
        // Don't set minHeight & maxHeight here.
        // if we set maxHeight then Text labels etc expand, so columns don't line up properly
            .frame(height: frameHeight.minimum, alignment: alignment)
    }

    public init(_ frameHeight: Binding<FrameHeight>, _ alignment: Alignment) {
        self._frameHeight = frameHeight
        self.alignment = alignment
    }
}

struct FrameHeightPreferenceKey: PreferenceKey {
    typealias Value = CGFloat

    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {

    public func height(_ frameHeight: Binding<FrameHeight>, alignment: Alignment = .center) -> some View {
        self.modifier(HeightModifier(frameHeight, alignment))
    }
}


// ==========================================================================
// MARK: - both width and height
// ==========================================================================

public struct FrameSize {

    public var minimumWidth: CGFloat
    public var maximumWidth: CGFloat

    public var minimumHeight: CGFloat
    public var maximumHeight: CGFloat

    public init(_ minimumWidth: CGFloat = 0,
                _ maximumWidth: CGFloat = .infinity,
                _ minimumHeight: CGFloat = 0,
                _ maximumHeight: CGFloat = .infinity) {
        self.minimumWidth = minimumWidth
        self.maximumWidth = maximumWidth
        self.minimumHeight = minimumHeight
        self.maximumHeight = maximumHeight
    }

    public mutating func adjustWidth(_ value: CGFloat) {
        self.minimumWidth = min(max(self.minimumWidth, value), maximumWidth)
    }

    public mutating func adjustHeight(_ value: CGFloat) {
        self.minimumHeight = min(max(self.minimumHeight, value), maximumHeight)
    }

}

public struct SizeModifier: ViewModifier {

    @Binding var frameSize: FrameSize

    var alignment: Alignment

    public func body(content: Content) -> some View {
        content
            .fixedSize()
            .overlay(GeometryReader { proxy in
                Color.clear
                    .preference(key: FrameWidthPreferenceKey.self, value: proxy.size.width)
                    .preference(key: FrameHeightPreferenceKey.self, value: proxy.size.height)
            }).onPreferenceChange(FrameWidthPreferenceKey.self) { (value) in
                frameSize.adjustWidth(value)
            }.onPreferenceChange(FrameHeightPreferenceKey.self) { (value) in
                frameSize.adjustHeight(value)
            }
        // Don't set minWidth & maxWidth here.
        // if we set maxWidth then Text labels etc expand, so rows don't line up properly
        // Don't set minHeight & maxHeight here.
        // if we set maxHeight then Text labels etc expand, so columns don't line up properly
            .frame(width: frameSize.minimumWidth, height: frameSize.minimumHeight, alignment: alignment)
    }

    public init(_ frameSize: Binding<FrameSize>, _ alignment: Alignment) {
        self._frameSize = frameSize
        self.alignment = alignment
    }
}

extension View {

    public func size(_ frameSize: Binding<FrameSize>, alignment: Alignment = .center) -> some View {
        self.modifier(SizeModifier(frameSize, alignment))
    }
}

