//
//  SettingsItemViews.swift
//  ArcWorld
//
//  Created by Jim Hanson on 4/1/21.
//

import SwiftUI


struct LabelWidthPreferenceKey: PreferenceKey {
    typealias Value = CGFloat

    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct SettingsGroup {

    var minimumLabelWidth: CGFloat = 0

    var fieldWidth: CGFloat = UIConstants.settingValueWidth

    public init() {}

    public init(_ minLabelWidth: CGFloat, _ fieldWidth: CGFloat) {
        self.minimumLabelWidth = minLabelWidth
        self.fieldWidth = fieldWidth
    }
}


// =================================================================================
// MARK:- Tickybox
// =================================================================================

///
///
///
public struct TickyboxSetting: View {

    let settingName: String

    let value: Binding<Bool>

    @Binding var group: SettingsGroup

    let trueText: String

    let falseText: String

    public var body: some View {

        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            Text(settingName)
                .lineLimit(1)
                .fixedSize()
                .overlay(GeometryReader { proxy in
                    Color.clear.preference(key: LabelWidthPreferenceKey.self, value: proxy.size.width)
                }).onPreferenceChange(LabelWidthPreferenceKey.self) { (value) in
                    $group.wrappedValue.minimumLabelWidth = max(group.minimumLabelWidth, value)
                }
                .frame(width: group.minimumLabelWidth, alignment: .trailing)

            Button(action: {
                value.wrappedValue = !value.wrappedValue
            }) {
                HStack {
                    // Spacer()
                    Text(value.wrappedValue ? trueText : falseText)
                }
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
        self.value = value
        self._group = group
        self.trueText = trueText
        self.falseText = falseText
    }
}

// =================================================================================
// MARK:- Stepped
// =================================================================================


///
///
///
public struct SteppedSetting: View {
    
    let settingName: String

    let value: Binding<Int>
    
    @Binding var group: SettingsGroup

    let minimum: Int
    
    let maximum: Int
    
    let deltas: [Int]
    
    var formatter: NumberFormatter = makeDefaultNumberFormatter()
    
    public var body: some View {
        
        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            Text(settingName)
                .lineLimit(1)
                .fixedSize()
                .overlay(GeometryReader { proxy in
                    Color.clear.preference(key: LabelWidthPreferenceKey.self, value: proxy.size.width)
                }).onPreferenceChange(LabelWidthPreferenceKey.self) { (value) in
                    $group.wrappedValue.minimumLabelWidth = max(group.minimumLabelWidth, value)
                }
                .frame(width: group.minimumLabelWidth, alignment: .trailing)

            TextField("", value: value, formatter: formatter)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
                .padding(UIConstants.buttonPadding)
                .frame(width: UIConstants.settingValueWidth)
                .border(UIConstants.darkGray)
                .disabled(true)
            
            ForEach(deltas.indices, id: \.self) { idx in
                
                Button (action: {
                    setValue(value.wrappedValue + deltas[idx])
                }) {
                    let label = (deltas[idx] < 0) ? "\(deltas[idx])" : "+\(deltas[idx])"
                    Text(label)
                        .padding(UIConstants.buttonPadding)

                }
                .modifier(SymbolButtonStyle())
                .foregroundColor(UIConstants.controlColor)
            }

            Spacer()
        }
    }
    
    public init(_ name: String,
                _ value: Binding<Int>,
                _ group: Binding<SettingsGroup>,
                _ minimum: Int,
                _ maximum: Int,
                _ deltas: [Int]) {
        self.settingName = name
        self.value = value
        self._group = group
        self.minimum = minimum
        self.maximum = maximum
        self.deltas = Self.unpackDeltas(deltas)
    }


    public func formatter(_ formatter: NumberFormatter) -> Self {
        var view = self
        view.formatter = formatter
        return self
    }
    
    private func setValue(_ newValue: Int) {
        value.wrappedValue = newValue.clamp(minimum, maximum)
    }

    private static func makeDefaultNumberFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }

    private static func unpackDeltas(_ deltas: [Int]) -> [Int] {
        var set = Set<Int>()
        for d in deltas {
            if (d != 0) {
                set.insert(d)
                set.insert(-d)
            }
        }

        var unpacked = [Int]()
        unpacked.append(contentsOf: set.sorted())
        return unpacked
    }
}


// =================================================================================
// MARK:- Range
// =================================================================================

///
///
///
public struct RangeSetting: View {
    
    let settingName: String

    let value: Binding<Double>
    
    @Binding var group: SettingsGroup

    var formatter: NumberFormatter = makeDefaultNumberFormatter()

    var range: ClosedRange<Double>
    
    var step: Double
    
    public var body: some View {
        
        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            Text(settingName)
                .lineLimit(1)
                .fixedSize()
                .overlay(GeometryReader { proxy in
                    Color.clear.preference(key: LabelWidthPreferenceKey.self, value: proxy.size.width)
                }).onPreferenceChange(LabelWidthPreferenceKey.self) { (value) in
                    $group.wrappedValue.minimumLabelWidth = max(group.minimumLabelWidth, value)
                }
                .frame(width: group.minimumLabelWidth, alignment: .trailing)

            TextField("", value: value, formatter: formatter)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
                .padding(UIConstants.buttonPadding)
                .frame(width: UIConstants.settingValueWidth)
                .border(UIConstants.darkGray)
                .disabled(true)

            Slider(value: value, in: range, step: step)
                .accentColor(UIConstants.controlColor)
                .foregroundColor(UIConstants.controlColor)
                .frame(minWidth: UIConstants.settingSliderWidth, maxWidth: .infinity)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        // .border(Color.gray)
    }
    
    public init(_ name: String,
                _ value: Binding<Double>,
                _ group: Binding<SettingsGroup>,
                _ minimum: Double,
                _ maximum: Double,
                _ step: Double) {
        self.settingName = name
        self.value = value
        self._group = group
        self.range = minimum...maximum
        self.step = step
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

    let value: Binding<String>
    
    @Binding var group: SettingsGroup

    let choices: [String]
    
    @State var selectorShowing: Bool = false
    
    public var body: some View {
        
        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            Text(settingName)
                .lineLimit(1)
                .fixedSize()
                .overlay(GeometryReader { proxy in
                    Color.clear.preference(key: LabelWidthPreferenceKey.self, value: proxy.size.width)
                }).onPreferenceChange(LabelWidthPreferenceKey.self) { (value) in
                    $group.wrappedValue.minimumLabelWidth = max(group.minimumLabelWidth, value)
                }
                .frame(width: group.minimumLabelWidth, alignment: .trailing)

            Button(action: { selectorShowing = true }) {
                Text(value.wrappedValue)
                    .lineLimit(1)
                .padding(UIConstants.buttonPadding)
                .frame(width: UIConstants.settingValueWidth, alignment: .center)
                .foregroundColor(UIConstants.controlColor)
                .background(RoundedRectangle(cornerRadius: 5)
                                .opacity(0.05))
            }
            .popover(isPresented: $selectorShowing, arrowEdge: .leading) {
                ChoiceSettingSelector(value, choices)
                    .modifier(PopStyle())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        // .border(Color.gray)
        
    }
    
    public init(_ name: String,
                _ value: Binding<String>,
                _ group: Binding<SettingsGroup>,
                _ choices: [String]) {
        self.settingName = name
        self.value = value
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

    let value: Binding<String>

    @Binding var group: SettingsGroup

    @State var isEditing: Bool = false

    public var body: some View {

        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            Text(settingName)
                .lineLimit(1)
                .fixedSize()
                .overlay(GeometryReader { proxy in
                    Color.clear.preference(key: LabelWidthPreferenceKey.self, value: proxy.size.width)
                }).onPreferenceChange(LabelWidthPreferenceKey.self) { (value) in
                    $group.wrappedValue.minimumLabelWidth = max(group.minimumLabelWidth, value)
                }
                .frame(width: group.minimumLabelWidth, alignment: .trailing)

            TextField("",
                      text: value,
                      onEditingChanged: { editing in
                        isEditing = editing
                      })
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
        self.value = value
        self._group = group
    }

}


