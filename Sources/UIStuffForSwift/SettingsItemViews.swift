//
//  SettingsItemViews.swift
//  ArcWorld
//
//  Created by Jim Hanson on 4/1/21.
//

import SwiftUI


// =================================================================================
// MARK:- Setting name
// =================================================================================

struct SettingName: View {

    var settingName: String

    var body: some View {
        GeometryReader { geometry in
            Text(settingName)
        }
    }

    init(_ name: String) {
        self.settingName = name
    }
}

// =================================================================================
// MARK:- Text
// =================================================================================


///
///
///
public struct TextSetting : View {

    let settingName: String

    let value: Binding<String>
    
    @State var isEditing: Bool = false
    
    public var body: some View {
        
        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            SettingName(settingName)

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
        // end HStack
    }
    
    public init(_ name: String, _ value: Binding<String>) {
        self.settingName = name
        self.value = value
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
    
    let minimum: Int
    
    let maximum: Int
    
    let deltas: [Int]
    
    var formatter: NumberFormatter = makeDefaultNumberFormatter()
    
    public var body: some View {
        
        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            SettingName(settingName)

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
        // end HStack
        
    }
    
    public init(_ name: String, _ value: Binding<Int>, _ minimum: Int, _ maximum: Int, _ deltas: [Int]) {
        self.settingName = name
        self.value = value
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
    
    var formatter: NumberFormatter = makeDefaultNumberFormatter()

    var range: ClosedRange<Double>
    
    var step: Double
    
    public var body: some View {
        
        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            SettingName(settingName)

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
    
    public init(_ name: String, _ value: Binding<Double>, _ minimum: Double, _ maximum: Double, _ step: Double) {
        self.settingName = name
        self.value = value
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
    
    let choices: [String]
    
    @State var selectorShowing: Bool = false
    
    public var body: some View {
        
        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            SettingName(settingName)

            Button(action: { selectorShowing = true }) {
                HStack {
                    Text(value.wrappedValue)
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                    Image(systemName: "chevron.right")
                }
                .padding(UIConstants.buttonPadding)
                .frame(width: UIConstants.settingValueWidth, alignment: .trailing)
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
    
    public init(_ name: String, _ value: Binding<String>, _ choices: [String]) {
        self.settingName = name
        self.value = value
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
// MARK:- Tickybox
// =================================================================================

///
///
///
public struct TickyboxSetting: View {

    let settingName: String

    let value: Binding<Bool>

    let trueText: String

    let falseText: String

    public var body: some View {

        HStack(alignment: .center, spacing: UIConstants.settingsGridSpacing) {

            SettingName(settingName)

            Button(action: {
                value.wrappedValue = !value.wrappedValue
            }) {
                HStack {
                    Spacer()
                    Text(value.wrappedValue ? trueText : falseText)
                }
                .padding(UIConstants.buttonPadding)
                .frame(width: UIConstants.settingValueWidth, alignment: .trailing)
                .foregroundColor(UIConstants.controlColor)
                .background(RoundedRectangle(cornerRadius: 5)
                                .opacity(0.05))
            }

            Spacer()
        }
    }

    public init(_ name: String, _ value: Binding<Bool>, _ trueText: String, _ falseText: String) {
        self.settingName = name
        self.value = value
        self.trueText = trueText
        self.falseText = falseText
    }
}
