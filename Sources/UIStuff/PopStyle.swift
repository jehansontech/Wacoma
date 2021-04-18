//
//  PopStyle.swift
//  ArcWorld
//
//  Created by Jim Hanson on 4/15/21.
//

import SwiftUI

struct PopStyle: ViewModifier {


    func body(content: Content) -> some View {
        ZStack {
            UIConstants.darkGray.scaleEffect(1.5)
            content
                .padding(UIConstants.pageInsets)
                .foregroundColor(UIConstants.offWhite)
                .background (
                    RoundedRectangle(cornerRadius: UIConstants.popoverCornerRadius)
                        .fill(UIConstants.offBlack)
                )
                .padding(UIConstants.popoverInsets)
        }
    }

}
