////
////  File.swift
////  
////
////  Created by Jim Hanson on 11/24/21.
////
//
//import SwiftUI
//
//public struct SpanningButtonStyle: ViewModifier {
//
//    public func body(content: Content) -> some View {
//
//        content
//            .padding(UIConstants.buttonPadding)
//            .frame(maxWidth: .infinity)
//            .background(RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
//                            .opacity(UIConstants.buttonOpacity))
//    }
//}
//
//
//public struct SymbolButtonStyle: ViewModifier {
//
//    public init() {}
//
//    public func body(content: Content) -> some View {
//        content
//            .imageScale(UIConstants.symbolButtonImageScale)
//            // .padding(UIConstants.buttonPadding)
//            .frame(width: UIConstants.symbolButtonWidth, height: UIConstants.symbolButtonHeight, alignment: .center)
//            .background(RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
//                            .opacity(UIConstants.buttonOpacity))
//    }
//}
//
//public struct TextButtonStyle: ViewModifier {
//
//    public init() {}
//
//    public func body(content: Content) -> some View {
//        content
//            .padding(UIConstants.buttonPadding)
//            .background(RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
//                            .opacity(UIConstants.buttonOpacity))
//    }
//}
//
//
//public struct SettingNameStyle: ViewModifier {
//
//    var width: CGFloat
//
//    public init(width: CGFloat) {
//        self.width = width
//    }
//
//    public func body(content: Content) -> some View {
//        content
//            .font(.system(size: UIConstants.settingNameFontSize))
//            .lineLimit(1)
//            .fixedSize()
//            .frame(width: width, alignment: .trailing)
//    }
//
//}
//
//public struct IntSettingTextFieldStyle: ViewModifier {
//
//    public static var formatter: NumberFormatter = makeFormatter()
//
//    public init() {}
//
//    public func body(content: Content) -> some View {
//        content
//            .font(.system(size: UIConstants.settingValueFontSize, design: .monospaced))
//            .lineLimit(1)
//            .disableAutocorrection(true)
//            .multilineTextAlignment(.trailing)
//            .padding(UIConstants.buttonPadding)
//            .frame(width: UIConstants.settingValueWidth)
//    }
//
//    private static func makeFormatter() -> NumberFormatter {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .none
//        return formatter
//    }
//}
//
//
//public struct FloatSettingTextFieldStyle: ViewModifier {
//
//    public static var formatter: NumberFormatter = makeFormatter()
//
//    public init() {}
//
//    public func body(content: Content) -> some View {
//        content
//            .font(.system(size: UIConstants.settingValueFontSize, design: .monospaced))
//            .lineLimit(1)
//            .disableAutocorrection(true)
//            .multilineTextAlignment(.trailing)
//            .padding(UIConstants.buttonPadding)
//            .frame(width: UIConstants.settingValueWidth)
//    }
//
//    private static func makeFormatter() -> NumberFormatter {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//        formatter.maximumSignificantDigits = 3
//        return formatter
//    }
//}
//
//public struct BoolSettingButtonStyle: ViewModifier {
//
//    public init() {}
//
//    public func body(content: Content) -> some View {
//        content
//            .font(.system(size: UIConstants.settingValueFontSize, design: .monospaced))
//            .padding(UIConstants.buttonPadding)
//            .frame(width: UIConstants.settingValueWidth)
//    }
//}
//
//public struct ChoiceSettingButtonStyle: ViewModifier {
//
//    public init() {}
//
//    public func body(content: Content) -> some View {
//        content
//            .font(.system(size: UIConstants.settingValueFontSize, design: .monospaced))
//            .padding(UIConstants.buttonPadding)
//            .frame(width: UIConstants.settingValueWidth)
//    }
//}
