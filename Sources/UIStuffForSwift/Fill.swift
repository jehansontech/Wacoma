//
//  File.swift
//  
//
//  Created by Jim Hanson on 4/24/21.
//

import SwiftUI

public struct Fill<Content: View>: View {

    private let content: () -> Content

    public var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                content()
                Spacer()
            }
            Spacer()
        }
    }

    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
}
