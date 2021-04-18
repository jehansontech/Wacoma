//
//  Buttons.swift
//  ArcWorld
//
//  Created by Jim Hanson on 4/13/21.
//

import SwiftUI

public struct SymbolButtonStyle: ViewModifier {

    public func body(content: Content) -> some View {
        content
            .imageScale(.large)
            .padding(UIConstants.buttonPadding)
            .frame(minWidth: UIConstants.symbolButtonWidth, minHeight: UIConstants.symbolButtonHeight)
            .background(RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
                            .opacity(UIConstants.buttonOpacity))
    }

    public init() {}

}

public struct TextButtonStyle: ViewModifier {

    public func body(content: Content) -> some View {
        content
            .padding(UIConstants.buttonPadding)
            .foregroundColor(UIConstants.controlColor)
            .background(RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
                            .opacity(UIConstants.buttonOpacity))
    }

    public init() {}
}

