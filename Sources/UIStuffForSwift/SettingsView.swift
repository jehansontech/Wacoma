//
//  File.swift
//  
//
//  Created by Jim Hanson on 4/24/21.
//

import SwiftUI

// Container view
// like a grid w/ 2 columns
// autodetects when you add a setting item in 2nd column

// What about TabView?
// that Text("").tabItem { ... } looks stupid


public struct SettingsView<Content: View>: View {

    private let content: () -> Content

    public var body: some View {
        VStack {
            content()
        }
    }

    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
}
