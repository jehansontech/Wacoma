//
//  SettingsItemViews.swift
//  ArcWorld
//
//  Created by Jim Hanson on 4/1/21.
//

import SwiftUI
import Wacoma

struct LabelWidthPreferenceKey: PreferenceKey {
    typealias Value = CGFloat

    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FieldWidthPreferenceKey: PreferenceKey {
    typealias Value = CGFloat

    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public enum SettingsItemStyle {
    case wide
    case narrow
}

public struct SettingsGroup {

    var minimumLabelWidth: CGFloat = 0

    var minimumFieldWidth: CGFloat = UIConstants.settingValueWidth

    var itemStyle: SettingsItemStyle = .wide

    public init() {}

    public init(_ minLabelWidth: CGFloat, _ minimumFieldWidth: CGFloat) {
        self.minimumLabelWidth = minLabelWidth
        self.minimumFieldWidth = minimumFieldWidth
    }

    public func itemStyle(_ style: SettingsItemStyle) -> Self {
        var view = self
        view.itemStyle = style
        return view
    }
}


// =================================================================================
// MARK:- Constant
// =================================================================================

///
/// wide & narrow are the same
///
public struct ConstantSetting: View {

    let settingName: String

    @Binding var settingValue: String

    @Binding var group: SettingsGroup

    public var body: some View {

        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            Text(settingName + ":")
                .lineLimit(1)
                .fixedSize()
                .overlay(GeometryReader { proxy in
                    Color.clear.preference(key: LabelWidthPreferenceKey.self, value: proxy.size.width)
                }).onPreferenceChange(LabelWidthPreferenceKey.self) { (value) in
                    $group.wrappedValue.minimumLabelWidth = max(group.minimumLabelWidth, value)
                }
                .frame(width: group.minimumLabelWidth, alignment: .trailing)

            Text(settingValue)
                .font(.system(size: UIConstants.settingValueFontSize, design: .monospaced))
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
                .padding(UIConstants.buttonPadding)
                .frame(width: UIConstants.settingValueWidth)
                // .border(UIConstants.darkGray)

            Spacer()
        }
    }

    public init(_ name: String,
                _ value: Binding<String>,
                _ group: Binding<SettingsGroup>) {
        self.settingName = name
        self._settingValue = value
        self._group = group
    }
}

// =================================================================================
// MARK:- Tickybox
// =================================================================================

///
/// wide & narrow are the same
///
public struct TickyboxSetting: View {

    let settingName: String

    @Binding var settingValue: Bool

    @Binding var group: SettingsGroup

    let trueText: String

    let falseText: String

    public var body: some View {

        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            Text(settingName + ":")
                .lineLimit(1)
                .fixedSize()
                .overlay(GeometryReader { proxy in
                    Color.clear.preference(key: LabelWidthPreferenceKey.self, value: proxy.size.width)
                }).onPreferenceChange(LabelWidthPreferenceKey.self) { (value) in
                    $group.wrappedValue.minimumLabelWidth = max(group.minimumLabelWidth, value)
                }
                .frame(width: group.minimumLabelWidth, alignment: .trailing)

            Button(action: {
                $settingValue.wrappedValue = !settingValue
            }) {
                Text($settingValue.wrappedValue ? trueText : falseText)
                    .font(.system(size: UIConstants.settingValueFontSize))
                .padding(UIConstants.buttonPadding)
                .frame(width: UIConstants.settingValueWidth, alignment: .center)
                .foregroundColor(UIConstants.controlColor)
                .background(RoundedRectangle(cornerRadius: 5)
                                .opacity(0.05))
            }

            Spacer()
        }
    }

    public init(_ name: String,
                _ value: Binding<Bool>,
                _ group: Binding<SettingsGroup>,
                _ trueText: String,
                _ falseText: String) {
        self.settingName = name
        self._settingValue = value
        self._group = group
        self.trueText = trueText
        self.falseText = falseText
    }
}

// =================================================================================
// MARK:- Stepped
// =================================================================================


///
/// narrow puts the buttons in a 2nd row
///
public struct SteppedSetting: View {
    
    let settingName: String

    @State var isEditing: Bool = false

    @Binding var settingValue: Int
    
    @Binding var group: SettingsGroup

    let minimum: Int
    
    let maximum: Int

    let decrements: [Int]

    let increments: [Int]

    var formatter: NumberFormatter = makeDefaultNumberFormatter()
    
    public var body: some View {
        switch group.itemStyle {
        case .wide:
            wide()
        case .narrow:
            narrow()
        }
    }

    public init(_ name: String,
                _ value: Binding<Int>,
                _ group: Binding<SettingsGroup>,
                _ minimum: Int,
                _ maximum: Int,
                _ deltas: [Int]) {
        self.settingName = name
        self._settingValue = value
        self._group = group
        self.minimum = minimum
        self.maximum = maximum
        (self.decrements, self.increments) = Self.unpackDeltas(deltas)
    }

    func wide() -> some View {
        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {
            name()
            value()
            decrementButtons()
            incrementButtons()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    func narrow() -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {
                name()
                value()
                Spacer()
            }

            if (decrements.count <= 2) {
                HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {
                    // Spacer().frame(width: group.minimumLabelWidth)
                    decrementButtons()
                    incrementButtons()
                    Spacer()
                }
            }
            else {
                HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {
                    // Spacer().frame(width: group.minimumLabelWidth)
                    incrementButtons()
                    Spacer()
                }
                HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {
                    // Spacer().frame(width: group.minimumLabelWidth)
                    reversedDecrementButtons()
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)

    }

    func name() -> some View {
        Text(settingName + ":")
            .lineLimit(1)
            .fixedSize()
            .overlay(GeometryReader { proxy in
                Color.clear.preference(key: LabelWidthPreferenceKey.self, value: proxy.size.width)
            }).onPreferenceChange(LabelWidthPreferenceKey.self) { (value) in
                $group.wrappedValue.minimumLabelWidth = max(group.minimumLabelWidth, value)
            }
            .frame(width: group.minimumLabelWidth, alignment: .trailing)
    }

    func value() -> some View {
        TextField("", value: $settingValue, formatter: formatter,
                  onEditingChanged: { editing in
                    isEditing = editing
                  },
                  onCommit: fixValue)
            .font(.system(size: UIConstants.settingValueFontSize, design: .monospaced))
            .lineLimit(1)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .multilineTextAlignment(.trailing)
            .padding(UIConstants.buttonPadding)
            .frame(width: UIConstants.settingValueWidth)
            .border(isEditing ? UIConstants.controlColor : UIConstants.darkGray)
    }

    func decrementButtons() -> some View {
        ForEach(decrements.indices, id: \.self) { idx in

            Button (action: {
                setValue(settingValue + decrements[idx])
            }) {
                Text("\(decrements[idx])")
                    .font(.system(size: UIConstants.settingValueFontSize, design: .monospaced))
            }
            .modifier(TextButtonStyle())
            .foregroundColor(UIConstants.controlColor)
        }
    }

    func reversedDecrementButtons() -> some View {
        ForEach(decrements.indices, id: \.self) { idx in
            let revIdx = decrements.indices.count - idx - 1
            Button (action: {
                setValue(settingValue + decrements[revIdx])
            }) {
                Text("\(decrements[revIdx])")
                    .font(.system(size: UIConstants.settingValueFontSize, design: .monospaced))
            }
            .modifier(TextButtonStyle())
            .foregroundColor(UIConstants.controlColor)
        }
    }

    func incrementButtons() -> some View {
        ForEach(increments.indices, id: \.self) { idx in

            Button (action: {
                setValue(settingValue + increments[idx])
            }) {
                Text("+\(increments[idx])")
                    .font(.system(size: UIConstants.settingValueFontSize, design: .monospaced))
            }
            .modifier(TextButtonStyle())
            .foregroundColor(UIConstants.controlColor)
        }
    }

    public func formatter(_ formatter: NumberFormatter) -> Self {
        var view = self
        view.formatter = formatter
        return self
    }
    
    private func setValue(_ newValue: Int) {
        $settingValue.wrappedValue = newValue.clamp(minimum, maximum)
    }

    private func fixValue() {
        let fixedValue = settingValue.clamp(minimum, maximum)
        if fixedValue != settingValue {
            $settingValue.wrappedValue = fixedValue
        }
    }

    private static func makeDefaultNumberFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }

    private static func unpackDeltas(_ deltas: [Int]) -> ([Int], [Int]) {
        var incrementSet = Set<Int>()
        var decrementSet = Set<Int>()
        for d in deltas {
            if (d != 0) {
                incrementSet.insert(d)
                decrementSet.insert(-d)
            }
        }

        var decrements = [Int]()
        decrements.append(contentsOf: decrementSet.sorted())

        var increments = [Int]()
        increments.append(contentsOf: incrementSet.sorted())
        return (decrements, increments)
    }
}


// =================================================================================
// MARK:- Range
// =================================================================================

///
/// narrow puts slider in 2nd row
///
public struct RangeSetting: View {
    
    let settingName: String

    @State var isEditing: Bool = false

    @Binding var settingValue: Double
    
    @Binding var group: SettingsGroup

    var formatter: NumberFormatter = makeDefaultNumberFormatter()

    var range: ClosedRange<Double>
    
    var step: Double
    
    public var body: some View {
        Group {
            switch group.itemStyle {
            case .wide:
                wide()
            case .narrow:
                narrow()
            }
        }
    }

    func wide() -> some View {
        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {
            name()
            value()
            slider()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    func narrow() -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {
                name()
                value()
                Spacer()
            }
            HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {
                // Spacer().frame(width: group.minimumLabelWidth)
                slider()
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }

    public func name() -> some View {
        Text(settingName + ":")
            .lineLimit(1)
            .fixedSize()
            .overlay(GeometryReader { proxy in
                Color.clear.preference(key: LabelWidthPreferenceKey.self, value: proxy.size.width)
            }).onPreferenceChange(LabelWidthPreferenceKey.self) { (value) in
                $group.wrappedValue.minimumLabelWidth = max(group.minimumLabelWidth, value)
            }
            .frame(width: group.minimumLabelWidth, alignment: .trailing)
    }

    public func value() -> some View {
        TextField("", value: $settingValue, formatter: formatter,
                  onEditingChanged: { editing in
                    isEditing = editing
                  },
                  onCommit: fixValue)
            .font(.system(size: UIConstants.settingValueFontSize, design: .monospaced))
            .lineLimit(1)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .multilineTextAlignment(.trailing)
            .padding(UIConstants.buttonPadding)
            .frame(width: UIConstants.settingValueWidth)
            .border(isEditing ? UIConstants.controlColor : UIConstants.darkGray)
    }

    public func slider() -> some View {
        Slider(value: $settingValue, in: range, step: step)
            .accentColor(UIConstants.controlColor)
            .foregroundColor(UIConstants.controlColor)
            .frame(minWidth: UIConstants.settingSliderWidth, maxWidth: .infinity)
    }

    public init(_ name: String,
                _ value: Binding<Double>,
                _ group: Binding<SettingsGroup>,
                _ minimum: Double,
                _ maximum: Double,
                _ step: Double) {
        self.settingName = name
        self._settingValue = value
        self._group = group
        self.range = minimum...maximum
        self.step = step
    }

    private func fixValue() {
        let fixedValue = settingValue.clamp(range)
        if fixedValue != settingValue {
            $settingValue.wrappedValue = fixedValue
        }
    }

    public func formatter(_ formatter: NumberFormatter) -> Self {
        var view = self
        view.formatter = formatter
        return self
    }

    private static func makeDefaultNumberFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumSignificantDigits = 3
        return formatter
    }

}

// =================================================================================
// MARK:- Choice
// =================================================================================

///
/// ChoiceSetting: Select an item from a given list, which is presented in a popover
///
public struct ChoiceSetting: View {
    
    let settingName: String

    @Binding var settingValue: String
    
    @Binding var group: SettingsGroup

    let choices: [String]
    
    @State var selectorShowing: Bool = false
    
    public var body: some View {
        
        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            Text(settingName + ":")
                .lineLimit(1)
                .fixedSize()
                .overlay(GeometryReader { proxy in
                    Color.clear.preference(key: LabelWidthPreferenceKey.self, value: proxy.size.width)
                }).onPreferenceChange(LabelWidthPreferenceKey.self) { (value) in
                    $group.wrappedValue.minimumLabelWidth = max(group.minimumLabelWidth, value)
                }
                .frame(width: group.minimumLabelWidth, alignment: .trailing)

            Button(action: { selectorShowing = true }) {
                HStack(alignment: .center, spacing: 0) {
                    Text(settingValue)
                        .font(.system(size: UIConstants.settingValueFontSize))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Image(systemName: "arrowtriangle.down.fill")
                        .imageScale(.small)
                }
                .padding(UIConstants.buttonPadding)
                .frame(width: UIConstants.settingValueWidth, alignment: .center)
                .foregroundColor(UIConstants.controlColor)
                .background(RoundedRectangle(cornerRadius: 5)
                                .opacity(0.05))
            }
            .popover(isPresented: $selectorShowing, arrowEdge: .leading) {
                ChoiceSettingSelector($settingValue, choices)
                    .modifier(PopStyle())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)

    }
    
    public init(_ name: String,
                _ value: Binding<String>,
                _ group: Binding<SettingsGroup>,
                _ choices: [String]) {
        self.settingName = name
        self._settingValue = value
        self._group = group
        self.choices = choices
    }
}


///
/// Contents of popover in a ChoiceSetting
///
struct ChoiceSettingSelector: View {
    
    @Environment(\.presentationMode) var presentationMode

    let value: Binding<String>
    
    let choices: [String]
    
    var body: some View {
        VStack {
            ForEach(choices, id:\.self) { name in
                Button(action: { choose(name) }) {
                    Text(name)
                        .foregroundColor(UIConstants.controlColor)
                }
                .padding(UIConstants.buttonPadding)
            }
        }
    }
    
    init(_ value: Binding<String>, _ choices: [String]) {
        self.value = value
        self.choices = choices
    }
    
    func choose(_ name: String) {
        value.wrappedValue = name
        presentationMode.wrappedValue.dismiss()
    }
}


// =================================================================================
// MARK:- Text
// =================================================================================

///
///
///
public struct TextSetting: View {

    let settingName: String

    @Binding var settingValue: String

    @Binding var group: SettingsGroup

    @State var isEditing: Bool = false

    public var body: some View {

        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            Text(settingName + ":")
                .lineLimit(1)
                .fixedSize()
                .overlay(GeometryReader { proxy in
                    Color.clear.preference(key: LabelWidthPreferenceKey.self, value: proxy.size.width)
                }).onPreferenceChange(LabelWidthPreferenceKey.self) { (value) in
                    $group.wrappedValue.minimumLabelWidth = max(group.minimumLabelWidth, value)
                }
                .frame(width: group.minimumLabelWidth, alignment: .trailing)

            TextField("",
                      text: $settingValue,
                      onEditingChanged: { editing in
                        isEditing = editing
                      })
                .font(.system(size: UIConstants.settingValueFontSize))
                .lineLimit(1)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .multilineTextAlignment(.leading)
                .padding(UIConstants.buttonPadding)
                .frame(minWidth: UIConstants.settingValueWidth)
                .border(isEditing ? UIConstants.controlColor : UIConstants.darkGray)

        }
    }

    public init(_ name: String,
                _ value: Binding<String>,
                _ group: Binding<SettingsGroup>) {
        self.settingName = name
        self._settingValue = value
        self._group = group
    }

}


