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

public struct TwistieSection<Content: View> : View {

    let sectionName: String

    let sectionID: Int

    var selectedSection: Binding<Int>

    var sectionContent: () -> Content

    public var body: some View {
        HStack(alignment: .top, spacing: UIConstants.sectionSpacing) {

//            GeometryReader { geometry in
                Button(action: { selectedSection.wrappedValue = sectionID })
                {
                    Image(systemName: "chevron.right")
                        .rotated(by: .degrees((sectionID == selectedSection.wrappedValue ? 90 : 0)))

                    Text(sectionName)
                        .lineLimit(1)

                }
//                .preference(
//                    key: SectionStatePreferenceKey.self,
//                    value: [SectionState(nameWidth: geometry.frame(in: CoordinateSpace.global).width)]
//                )
                .border(Color.gray)
//            }

            if sectionID == selectedSection.wrappedValue {
                sectionContent()
                    .border(Color.gray)
            }
//            else {
//                Spacer()
//            }
        }
        .animation(.easeInOut)

    }

    public init(_ sectionName: String, _ sectionID: Int, _ selectedSection: Binding<Int>, @ViewBuilder content: @escaping () -> Content) {
        self.sectionName = sectionName
        self.sectionID = sectionID
        self.selectedSection = selectedSection
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
