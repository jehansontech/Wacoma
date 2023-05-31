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

public struct Hidden: ViewModifier {

    private var condition: Bool
    
    public init(_ condition: Bool) {
        self.condition = condition
    }

    public func body(content: Content) -> some View {
        if condition {
            content.hidden()
        }
        else {
            content
        }
    }
}

extension View {

    public func hidden(_ condition: Bool) -> some View {
        return self.modifier(Hidden(condition))
    }

}
