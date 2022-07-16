//
//  UIStyles.swift
//  Wacoma
//
//  Created by Jim Hanson on 7/16/22.
//

import SwiftUI

public struct GrayTitle: ViewModifier {

    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .font(.title)
            .foregroundColor(.gray)
    }
}
