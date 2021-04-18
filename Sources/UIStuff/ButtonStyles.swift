//
//  Buttons.swift
//  ArcWorld
//
//  Created by Jim Hanson on 4/13/21.
//

import SwiftUI

struct SymbolButtonStyle: ViewModifier {

    func body(content: Content) -> some View {
        content
            .imageScale(.large)
            .padding(UIConstants.buttonPadding)
            .frame(minWidth: UIConstants.symbolButtonWidth, minHeight: UIConstants.symbolButtonHeight)
            .background(RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
                            .opacity(UIConstants.buttonOpacity))
    }

}

struct TextButtonStyle: ViewModifier {

    func body(content: Content) -> some View {
        content
            .padding(UIConstants.buttonPadding)
            .foregroundColor(UIConstants.controlColor)
            .background(RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
                            .opacity(UIConstants.buttonOpacity))
    }

}

