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

public class TwistieGroup: ObservableObject {


    @Published var selection: String = "" {
        didSet {
            print("selection = \(selection)")
        }
    }

    var labelWidths = [CGFloat]()

    public init() {}

 }

public struct TwistieSection<Content: View> : View {

    let twistieSize: CGFloat = 40

    let sectionName: String

    // var selectedSection: Binding<Int>

    @ObservedObject var group: TwistieGroup

    var sectionContent: () -> Content

    public var body: some View {
        HStack(alignment: .top, spacing: UIConstants.sectionSpacing) {

            Button(action: { group.selection = sectionName }) {
                Image(systemName: "chevron.right")
                    .frame(width: twistieSize, height: twistieSize)
                    .rotated(by: .degrees((sectionName == group.selection ? 90 : 0)))

                Text(sectionName)
                    .lineLimit(1)

            }
            .modifier(TextButtonStyle())

            Group {
                if sectionName == group.selection {
                    sectionContent()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    public init(_ sectionName: String, _ group: TwistieGroup, @ViewBuilder content: @escaping () -> Content) {
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
