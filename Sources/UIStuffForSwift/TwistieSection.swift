//
//  SectionButton.swift
//  ArcWorld
//
//  Created by Jim Hanson on 4/17/21.
//

import SwiftUI


//struct SectionStatePreferenceKey: PreferenceKey {
//    typealias Value = [SectionState]
//
//    static var defaultValue: [SectionState] = []
//
//    static func reduce(value: inout [SectionState], nextValue: () -> [SectionState]) {
//        value.append(contentsOf: nextValue())
//    }
//}
//
//struct SectionState: Equatable {
//    let nameWidth: CGFloat
//    // let selectedSection: Int
//}

public struct TwistieGroup {

    var selection: String = ""

    public init() {}

 }

public struct TwistieSection<Content: View> : View {

    let leftInset: CGFloat = 40
    let twistieSize: CGFloat = 20

    let sectionName: String

    var group: Binding<TwistieGroup>

    var sectionContent: () -> Content

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { group.wrappedValue.selection = sectionName }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(UIConstants.controlColor)
                    .background(RoundedRectangle(cornerRadius: UIConstants.buttonCornerRadius)
                                    .opacity(UIConstants.buttonOpacity))
                    .frame(width: twistieSize, height: twistieSize)
                    .rotated(by: .degrees((sectionName == group.wrappedValue.selection ? 90 : 0)))

                Text(sectionName)
                    .lineLimit(1)
            }
            .padding(UIConstants.buttonPadding)

            if sectionName == group.wrappedValue.selection {
                sectionContent()
                    .padding(EdgeInsets(top: UIConstants.buttonSpacing, leading: leftInset, bottom: 0, trailing: 0))
            }
        }
    }

    public init(_ sectionName: String, _ group: Binding<TwistieGroup>, @ViewBuilder content: @escaping () -> Content) {
        self.sectionName = sectionName
        self.group = group
        self.sectionContent = content
    }
}

//extension VerticalAlignment {
//
//    enum SectionName: AlignmentID {
//        static func defaultValue(in d: ViewDimensions) -> CGFloat {
//            d[.top]
//        }
//    }
//
//    static let sectionName = VerticalAlignment(SectionName.self)
//}

struct SectionButton: View {

    var sectionName: String

    var sectionID: Int

    var selectedSection: Binding<Int>

    var body: some View {

        Button(action: {
            selectedSection.wrappedValue = sectionID
        }) {
            Image(systemName: "chevron.right")
                .rotated(by: .degrees((sectionID == selectedSection.wrappedValue ? 90 : 0)))

            Text(sectionName)
                .lineLimit(1)

            Spacer()

        }
    }

    init(_ name: String, _ id: Int, _ selectedSection: Binding<Int>) {
        self.sectionName = name
        self.sectionID = id
        self.selectedSection = selectedSection
    }
}
