//
//  Buttons.swift
//  ArcWorld
//
//  Created by Jim Hanson on 4/13/21.
//

import SwiftUI

public struct SpanningButtonStyle: ViewModifier {

    public func body(content: Content) -> some View {

        content
            .padding(UIConstants.buttonPadding)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
                            .opacity(UIConstants.buttonOpacity))
    }

    public init() {}
}


public struct SymbolButtonStyle: ViewModifier {

    public func body(content: Content) -> some View {
        content
            .imageScale(UIConstants.symbolButtonImageScale)
            // .padding(UIConstants.buttonPadding)
            .frame(width: UIConstants.symbolButtonWidth, height: UIConstants.symbolButtonHeight, alignment: .center)
            .background(RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
                            .opacity(UIConstants.buttonOpacity))
    }

    public init() {}

}

public struct TextButtonStyle: ViewModifier {

    public func body(content: Content) -> some View {
        content
            .padding(UIConstants.buttonPadding)
            .background(RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
                            .opacity(UIConstants.buttonOpacity))
    }

    public init() {}
}

