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

    private var sectionCount: Int = 0

    var selectedSection: Int = 0

    var labelWidths = [CGFloat]()

    public init() {}

    mutating func nextSectionID() -> Int {
        let id = sectionCount
        sectionCount += 1
        return id
    }
 }

public struct TwistieSection<Content: View> : View {

    let twistieSize: CGFloat = 40

    let sectionName: String

    let sectionID: Int

    // var selectedSection: Binding<Int>

    var group: Binding<TwistieGroup>

    var sectionContent: () -> Content

    public var body: some View {
        HStack(alignment: .top, spacing: UIConstants.sectionSpacing) {

            Button(action: { group.wrappedValue.selectedSection = sectionID }) {
                Image(systemName: "chevron.right")
                    .frame(width: twistieSize, height: twistieSize)
                    .rotated(by: .degrees((sectionID == group.wrappedValue.selectedSection ? 90 : 0)))

                Text(sectionName)
                    .lineLimit(1)

            }

            // .modifier(TextButtonStyle())

            Group {
                if sectionID == group.wrappedValue.selectedSection {
                    sectionContent()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    public init(_ sectionName: String, _ group: Binding<TwistieGroup>, @ViewBuilder content: @escaping () -> Content) {
        self.sectionName = sectionName
        self.sectionID = group.wrappedValue.nextSectionID()
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
