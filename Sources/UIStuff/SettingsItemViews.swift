//
//  SettingsItemViews.swift
//  ArcWorld
//
//  Created by Jim Hanson on 4/1/21.
//

import SwiftUI

///
///
///
struct SettingTextFieldStyle: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            // .autocapitalization(.none)
            .disableAutocorrection(true)
            .padding(UIConstants.buttonPadding)
            .frame(width: UIConstants.settingValueWidth)
            .border(UIConstants.darkGray)
    }
}


///
///
///
public struct TextSetting : View {
    
    let value: Binding<String>
    
    @State var isEditing: Bool = false
    
    public var body: some View {
        
        HStack {
            TextField("",
                      text: value,
                      onEditingChanged: { editing in
                        isEditing = editing
                      })
                .modifier(SettingTextFieldStyle())
                .multilineTextAlignment(.trailing)
                .border(isEditing ? UIConstants.controlColor : UIConstants.darkGray)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        // .border(Color.gray)
        // end HStack
    }
    
    public init(_ value: Binding<String>) {
        self.value = value
    }
}


///
///
///
public struct SteppedSetting: View {
    
    let value: Binding<Int>
    
    let minimum: Int
    
    let maximum: Int
    
    let deltas: [Int]
    
    var formatter: NumberFormatter = makeDefaultNumberFormatter()
    
    public var body: some View {
        
        HStack {
            TextField("", value: value, formatter: formatter)
                .modifier(SettingTextFieldStyle())
                .multilineTextAlignment(.trailing)
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
        .frame(maxWidth: .infinity)
        // .border(Color.gray)
        // end HStack
        
    }
    
    public init(_ value: Binding<Int>, _ minimum: Int, _ maximum: Int, _ deltas: [Int]) {
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
        value.wrappedValue = newValue //.clamp(minimum, maximum)
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


///
///
///
public struct RangeSetting: View {
    
    let value: Binding<Double>
    
    var formatter: NumberFormatter = makeDefaultNumberFormatter()

    var range: ClosedRange<Double>
    
    var step: Double
    
    public var body: some View {
        
        HStack {

            TextField("", value: value, formatter: formatter)
                .modifier(SettingTextFieldStyle())
                .multilineTextAlignment(.trailing)
                .disabled(true)
            
            Slider(value: value, in: range, step: step)
                .accentColor(UIConstants.controlColor)
                // .foregroundColor(UIConstants.controlColor)
                .frame(minWidth: UIConstants.settingSliderWidth, maxWidth: .infinity)
            
            // Spacer()
        }
        .frame(maxWidth: .infinity)
        // .border(Color.gray)
    }
    
    public init(_ value: Binding<Double>, _ minimum: Double, _ maximum: Double, _ step: Double) {
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


///
///
///
public struct ChoiceSetting: View {
    
    let value: Binding<String>
    
    let choices: [String]
    
    @State var selectorShowing: Bool = false
    
    public var body: some View {
        
        HStack {
            Button(action: { selectorShowing = true }) {
                HStack {
                    TextField("", text: value)
                        .lineLimit(1)
                        // .autocapitalization(.none)
                        .disableAutocorrection(true)
                        // .multilineTextAlignment(.trailing)
                        .disabled(true)
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
    
    public init(_ value: Binding<String>, _ choices: [String]) {
        self.value = value
        self.choices = choices
    }
}


///
///
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


///
///
///
public struct TickyboxSetting: View {

    let value: Binding<Bool>

    let trueText: String

    let falseText: String

    public var body: some View {

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

        // Spacer()
    }

    public init(_ value: Binding<Bool>, _ trueText: String, _ falseText: String) {
        self.value = value
        self.trueText = trueText
        self.falseText = falseText
    }
}
