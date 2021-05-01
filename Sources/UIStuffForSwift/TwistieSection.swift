//
//  SectionButton.swift
//  ArcWorld
//
//  Created by Jim Hanson on 4/17/21.
//

import SwiftUI


struct TwistieButtonWidthPreferenceKey: PreferenceKey {
    typealias Value = CGFloat

    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public enum TwistieSectionButtonStyle {
    case fill
    case equalWidths
}

public struct TwistieGroup {

    public var selection: String? = nil

    var buttonMinWidth: CGFloat = 0

    var contentInsets = EdgeInsets(top: UIConstants.indentedContentTopInset,
                                   leading: UIConstants.indentedContentLeadingInset,
                                   bottom: UIConstants.indentedContentBottomInset,
                                   trailing: 0)

    var buttonMaxWidth: CGFloat {
        switch buttonStyle {
        case .fill:
            return .infinity
        case .equalWidths:
            return buttonMinWidth
        }
    }

    var buttonStyle: TwistieSectionButtonStyle = .equalWidths

    public init() {}

    public init(_ selection: String) {
        self.selection = selection
    }

    public func buttonStyle(_ style: TwistieSectionButtonStyle) -> Self {
        var view = self
        view.buttonStyle = style
        return view
    }

    public func contentInsets(_ insets: EdgeInsets) -> Self {
        var view = self
        view.contentInsets = insets
        return view
    }
 }

public struct TwistieSection<Content: View> : View {

    let sectionName: String

    @Binding var group: TwistieGroup

    var sectionContent: () -> Content

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Button(action: toggleSelection) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(UIConstants.controlColor)
                        .frame(width: UIConstants.twistieChevronSize, height: UIConstants.twistieChevronSize)
                        .rotated(by: .degrees(isSelected() ? 90 : 0))

                    Text(sectionName)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(UIConstants.offWhite)

                    Spacer()
                }
                .fixedSize()
                .overlay(GeometryReader { proxy in
                    Color.clear.preference(key: TwistieButtonWidthPreferenceKey.self, value: proxy.size.width)
                }).onPreferenceChange(TwistieButtonWidthPreferenceKey.self) { (value) in
                    $group.wrappedValue.buttonMinWidth = max(group.buttonMinWidth, value)
                }
                .frame(minWidth: group.buttonMinWidth, maxWidth: group.buttonMaxWidth, alignment: .leading)
                .modifier(TextButtonStyle())

                Spacer()
            }


            if isSelected() {
                sectionContent()
                    .padding(group.contentInsets)
            }
        }
    }

    public init(_ sectionName: String, _ group: Binding<TwistieGroup>, @ViewBuilder content: @escaping () -> Content) {
        self.sectionName = sectionName
        self._group = group
        self.sectionContent = content
    }

    func toggleSelection() {
        if group.selection == sectionName {
            $group.wrappedValue.selection = nil
        }
        else {
            $group.wrappedValue.selection = sectionName
        }
    }

    func isSelected() -> Bool {
        return group.selection == self.sectionName
    }
}
