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

public enum TwistieSectionHeaderStyle {
    case fill
    case equalWidths
}

public struct TwistieGroup {

    public var selection: String? = nil

    var autoCollapseEnabled: Bool = true

    var currentHeaderStyle: TwistieSectionHeaderStyle = .equalWidths

    var currentContentInserts = EdgeInsets(top: UIConstants.indentedContentTopInset,
                                   leading: UIConstants.indentedContentLeadingInset,
                                   bottom: UIConstants.indentedContentBottomInset,
                                   trailing: 0)

    var buttonMinWidth: CGFloat = 0

    var buttonMaxWidth: CGFloat {
        switch currentHeaderStyle {
        case .fill:
            return .infinity
        case .equalWidths:
            return buttonMinWidth
        }
    }

    public init() {}

    public init(_ selection: String) {
        self.selection = selection
    }

    public func autoCollapse(_ enabled: Bool) -> Self {
        var view = self
        view.autoCollapseEnabled = enabled
        return view
    }

    public func headerStyle(_ style: TwistieSectionHeaderStyle) -> Self {
        var view = self
        view.currentHeaderStyle = style
        return view
    }

    public func contentInsets(_ insets: EdgeInsets) -> Self {
        var view = self
        view.currentContentInserts = insets
        return view
    }
 }

public struct TwistieSection<Content: View> : View {

    let sectionName: String

    @Binding var group: TwistieGroup

    @State var expandRequested = false

    var sectionContent: () -> Content

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Button(action: headerClicked) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(UIConstants.controlColor)
                        .frame(width: UIConstants.twistieChevronSize, height: UIConstants.twistieChevronSize)
                        .rotated(by: .degrees(isExpanded() ? 90 : 0))

                    Text(sectionName)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(UIConstants.offWhite)

                    Spacer()
                }
                .fixedSize()
                .modifier(TextButtonStyle())
                .overlay(GeometryReader { proxy in
                    Color.clear.preference(key: TwistieButtonWidthPreferenceKey.self, value: proxy.size.width)
                }).onPreferenceChange(TwistieButtonWidthPreferenceKey.self) { (value) in
                    group.buttonMinWidth = max(group.buttonMinWidth, value)
                }
                .frame(minWidth: group.buttonMinWidth, maxWidth: group.buttonMaxWidth, alignment: .leading)

                Spacer()
            }

            if isExpanded() {
                sectionContent()
                    .padding(group.currentContentInserts)
            }
        }
    }

    public init(_ sectionName: String, _ group: Binding<TwistieGroup>, @ViewBuilder content: @escaping () -> Content) {
        self.sectionName = sectionName
        self._group = group
        self.sectionContent = content
    }

    func headerClicked() {
        // print("\(sectionName) headerClicked: entered. selected=\(isSelected()) expandRequested=\(expandRequested)")
        if isSelected() {
            expandRequested = !expandRequested
        }
        else {
            expandRequested = true
            group.selection = sectionName
        }
        // print("\(sectionName) headerClicked: exiting. selected=\(isSelected()) expandRequested=\(expandRequested)")
    }

    func isSelected() -> Bool {
        return group.selection == sectionName
    }

    func isExpanded() -> Bool {
        return group.autoCollapseEnabled
            ? expandRequested && group.selection == self.sectionName
            : expandRequested
    }
}
