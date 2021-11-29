////
////  File.swift
////  
////
////  Created by Jim Hanson on 4/24/21.
////
//
//import SwiftUI
//
//public struct Fill<Content: View>: View {
//
//    private let content: () -> Content
//
//    public var body: some View {
//        HStack {
//            VStack {
//                content()
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            }
//        }
//        .foregroundColor(UIConstants.offWhite)
//        .background(UIConstants.offBlack)
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//
//    public init(@ViewBuilder _ content: @escaping () -> Content) {
//        self.content = content
//    }
//}
