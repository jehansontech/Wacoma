//
//  NumericSettingView.swift
//  Wacoma
//
//  Created by Jim Hanson on 8/22/22.

import Foundation
import SwiftUI

public typealias NumericValue = Numeric & Comparable

public protocol DecimalConverter {
    associatedtype ValueType : NumericValue

    var minimumStepSize: ValueType { get }

    func valueToDecimal(_ value: ValueType) -> Decimal

    func decimalToValue(_ decimal: Decimal) -> ValueType

    func makeStepSize(_ range: ClosedRange<ValueType>) -> Decimal
}

extension DecimalConverter {

    public func decimalToString(_ decimal: Decimal) -> String {
        return "\(decimal)"
    }

    public func valueToString(_ value: ValueType) -> String {
        return decimalToString(valueToDecimal(value))
    }

    public func valueToDecimal(_ range: ClosedRange<ValueType>) -> ClosedRange<Decimal> {
        return valueToDecimal(range.lowerBound)...valueToDecimal(range.upperBound)
    }
}

public struct DecimalIntegerConverter<V: BinaryInteger>: DecimalConverter {

    public typealias ValueType = V

    public var minimumStepSize: ValueType { return 1 }

    public init() {}

    public func valueToDecimal(_ value: ValueType) -> Decimal {
        return Decimal(Int(value))
    }

    public func decimalToValue(_ decimal: Decimal) -> ValueType {
        return ValueType(NSDecimalNumber(decimal: decimal).intValue)
    }

    public func makeStepSize(_ range: ClosedRange<ValueType>) -> Decimal  {
        let power = floor(log10(Double(range.upperBound - range.lowerBound))) - 2 // subtract 2 to get ~100 steps
        let size = Decimal(pow(10, power))
        return size < 1 ? 1 : size
    }

    public func valueToSliderPosition(_ value: ValueType, _ lowerBound: ValueType, _ upperBound: ValueType) -> Double  where ValueType: BinaryInteger {
        return Double(value - lowerBound)/Double(upperBound - lowerBound)
    }
}

public struct DecimalFloatingPointConverter<V: BinaryFloatingPoint>: DecimalConverter {

    public typealias ValueType = V

    public var minimumStepSize: ValueType { return 0 }

    public init() {}

    public func valueToDecimal(_ value: ValueType) -> Decimal {
        return Decimal(Double(value))
    }

    public func decimalToValue(_ decimal: Decimal) -> ValueType {
        return ValueType(NSDecimalNumber(decimal: decimal).doubleValue)
    }

    public func makeStepSize(_ range: ClosedRange<ValueType>) -> Decimal  {
        let exponent = floor(log10(Double(range.upperBound - range.lowerBound))) - 2 // subtract 2 to get ~100 steps
        let size = pow(10, exponent)
        return Decimal(size)
    }

    public func valueToSliderPosition(_ value: ValueType, _ lowerBound: ValueType, _ upperBound: ValueType) -> Double  where ValueType: BinaryFloatingPoint {
        return Double(value - lowerBound)/Double(upperBound - lowerBound)
    }
}

public struct NumericSettingViewModel<T: DecimalConverter> {

    // IMPL NOTE: Do not use an Int for the step because the arithmetic screws up sometimes.

    let transformer: T

    public private(set) var decimalValue: Decimal

    public var numericValue: T.ValueType {
        transformer.decimalToValue(decimalValue)
    }

    public var textValue: String {
        transformer.decimalToString(decimalValue)
    }

    public let valueLB: Decimal

    public let valueUB: Decimal

    public let snapToStep: Bool

    /// Publlc settable so we can bind it to a TextField
    public var fieldText: String

    /// Public settable so we can set it when a Slider's "editing" flag changes
    public var isSliderActive: Bool = false

    public var isSliderPresented: Bool = false

    /// Publlc settable so we can bind it to a Slider
    /// Changes to sliderPosition instantly change fieldText and decimalValue
    /// In range [0, 1]
    public var sliderPosition: Double {
        didSet {
            if isSliderActive {
                applySliderPosition(sliderPosition)
            }
        }
    }

    /// Always an integer value, but it's a Decimal type for convenience
    public private(set) var step: Decimal

    public private(set) var stepSize: Decimal

    public let initialStepSize: Decimal

    public private(set) var sliderLB: Decimal

    public private(set) var sliderUB: Decimal

    public init(_ transformer: T,
                _ value: T.ValueType,
                range: ClosedRange<T.ValueType>,
                snapToStep: Bool) {

        // print("NumericSettingViewModel.init value=\(value) range=\(range)")
        
        let tmpDecimal = transformer.valueToDecimal(value)
        let tmpLB = transformer.valueToDecimal(range.lowerBound)
        let tmpUB = transformer.valueToDecimal(range.upperBound)

        let initialStepSize = transformer.makeStepSize(range)
        let initialStep = Self.getStep(tmpDecimal, initialStepSize)
        let initialDecimal = snapToStep ? initialStep * initialStepSize : tmpDecimal
        let initialLB = snapToStep ? Self.getStep(tmpLB, initialStepSize) * initialStepSize : tmpLB
        var initialUB = snapToStep ? Self.getStep(tmpUB, initialStepSize) * initialStepSize : tmpUB
        if initialUB < tmpUB {
            initialUB += initialStepSize
        }
        self.transformer = transformer
        self.decimalValue = initialDecimal
        self.valueLB = initialLB
        self.valueUB = initialUB
        self.snapToStep = snapToStep
        self.fieldText = transformer.decimalToString(initialDecimal)
        self.stepSize = initialStepSize
        self.initialStepSize = initialStepSize
        self.step = initialStep
        self.sliderPosition = Self.getSliderPosition(initialDecimal, initialLB, initialUB)
        self.sliderLB = initialLB
        self.sliderUB = initialUB
    }

    public mutating func applyFieldText() {
        if let newDecimal = Decimal(string: fieldText) {
            // STET: do not clamp or snap tmpDecimal; allow user to override the constraints.
            applyDecimalAndStep(newDecimal, Self.getStep(newDecimal, stepSize))
        }
        else {
            self.fieldText = textValue
        }
    }

    public mutating func applyIncrement(_ steps: Int = 1) {
        let tmpStep = step + Decimal(steps)
        let tmpDecimal = tmpStep * stepSize
        if tmpDecimal > valueUB {
            applyDecimalAndStep(valueUB, Self.getStep(valueUB, stepSize))
        }
        else {
            applyDecimalAndStep(tmpDecimal, tmpStep)
        }
    }

    public mutating func applyDecrement(_ steps: Int = 1) {
        let tmpStep = step - Decimal(steps)
        let tmpDecimal = tmpStep * stepSize
        if tmpDecimal < valueLB {
            applyDecimalAndStep(valueLB, Self.getStep(valueLB, stepSize))
        }
        else {
            applyDecimalAndStep(tmpDecimal, tmpStep)
        }
    }

    public mutating func valueChanged(_ newValue: T.ValueType) {
        let tmpDecimal = transformer.valueToDecimal(newValue)
        if snapToStep {
            let tmpStep = Self.getStep(tmpDecimal, stepSize)
            decimalValue = tmpStep * stepSize
            step = tmpStep
        }
        else {
            decimalValue = tmpDecimal
            step = Self.getStep(decimalValue, stepSize)
        }

        fieldText = transformer.decimalToString(decimalValue)

        let newSliderPosition = Self.getSliderPosition(decimalValue, sliderLB, sliderUB)
        if newSliderPosition != sliderPosition {
            sliderPosition = newSliderPosition
        }
    }

    public mutating func recomputeSliderPosition() {
        self.sliderPosition = Self.getSliderPosition(decimalValue, sliderLB, sliderUB)
    }

    public mutating func resetStepSize() {
        let newStepSize = initialStepSize
        if newStepSize != self.stepSize {
            self.stepSize = newStepSize
            self.step = Self.getStep(decimalValue, newStepSize)
            self.sliderLB = valueLB
            self.sliderUB = valueUB
            self.sliderPosition = Self.getSliderPosition(decimalValue, sliderLB, sliderUB)
        }
    }

    public mutating func decreaseStepSize() {
        let tmpStepSize = stepSize / 10
        let minStepSize = transformer.valueToDecimal(transformer.minimumStepSize)
        let newStepSize = tmpStepSize < minStepSize ? minStepSize : tmpStepSize
        if newStepSize != self.stepSize {
            let tmpSliderPercent = Decimal(floor(100 * sliderPosition))
            self.stepSize = newStepSize
            self.step = Self.getStep(decimalValue, newStepSize)
            self.sliderLB = decimalValue - tmpSliderPercent * newStepSize
            self.sliderUB = self.sliderLB + 100 * newStepSize
            self.sliderPosition = Self.getSliderPosition(decimalValue, sliderLB, sliderUB)
        }
    }

    public mutating func increaseStepSize() {
        let tmpStepSize = stepSize * 10
        let maxStepSize = (valueUB - valueLB) / 10
        let newStepSize = tmpStepSize > maxStepSize ? maxStepSize : tmpStepSize
        if newStepSize != self.stepSize {
            let tmpSliderPercent = floor(100 * sliderPosition)
            let tmpSliderLB = decimalValue -  Decimal(tmpSliderPercent) * newStepSize
            let tmpSliderUB = tmpSliderLB + 100 * newStepSize

            self.stepSize = newStepSize
            self.step = Self.getStep(decimalValue, newStepSize)
            self.sliderLB = tmpSliderLB < valueLB ? valueLB : tmpSliderLB
            self.sliderUB = tmpSliderUB > valueUB ? valueUB : tmpSliderUB
            self.sliderPosition = Self.getSliderPosition(decimalValue, sliderLB, sliderUB)
        }
    }

    private mutating func applySliderPosition(_ newSliderPosition: Double) {
        let tmpDecimal = sliderLB + Decimal(newSliderPosition) * (sliderUB - sliderLB)
        let newStep = Self.getStep(tmpDecimal, self.stepSize)
        let newDecimal = newStep * stepSize
        self.step = newStep
        self.decimalValue = newDecimal
        self.fieldText = transformer.decimalToString(newDecimal)
    }

    private mutating func applyDecimalAndStep(_ newDecimal: Decimal, _ newStep: Decimal) {
        decimalValue = newDecimal
        step = newStep
        fieldText = transformer.decimalToString(decimalValue)

        let newSliderPosition = Self.getSliderPosition(decimalValue, sliderLB, sliderUB)
        if sliderPosition != newSliderPosition {
            sliderPosition = newSliderPosition
        }
    }

    private static func getStep(_ value: Decimal, _ stepSize: Decimal) -> Decimal {
        return (value/stepSize).nearestWhole
    }

    private static func getSliderPosition(_ value: Decimal, _ lowerBound: Decimal, _ upperBound: Decimal) -> Double {
        return NSDecimalNumber(decimal: (value - lowerBound)/(upperBound - lowerBound)).doubleValue
    }
}

public struct NumericSettingView<T: DecimalConverter, Content: View>: View {

    @Binding var value: T.ValueType

    @ViewBuilder var contentBuilder: (_ model: Binding<NumericSettingViewModel<T>>) -> Content

    @State var model: NumericSettingViewModel<T>

    @State var internalValueChange: Bool = false

    public var body: some View {
        Group {
            contentBuilder($model)
        }
        .onChange(of: value) { newValue in
            // Messages.debug("NumericSettingView", "bound value changed to \(newValue)")
            if internalValueChange {
                // Messages.debug("NumericSettingView", "bound value changed. newValue: \(newValue), IGNORING")
                internalValueChange = false
            }
            else {
                // Messages.debug("NumericSettingView", "bound value changed. newValue: \(newValue), APPLYING")
                model.valueChanged(newValue)
            }
        }
        .onChange(of: model.decimalValue) { newValue in
            // Messages.debug("NumericSettingView", "valueDecimal changed. newValue: \(newValue)")
            let tmpValue = model.numericValue
            if tmpValue != value {
                internalValueChange = true
                value = tmpValue
            }
        }
        // THESE DON'T DO ANYTHING b/c model is a @State so it's never changed from outside.
        //        .onChange(of: model.sliderLB) { newValue in
        //            // Messages.debug("NumericSettingView", "sliderLB changed. newValue: \(newValue)")
        //            model.recomputeSliderPosition()
        //        }
        //        .onChange(of: model.sliderUB) { newValue in
        //            // Messages.debug("NumericSettingView", "sliderUB changed. newValue: \(newValue)")
        //            model.recomputeSliderPosition()
        //        }
    }

    public init<V>(_ value: Binding<V>,
                   in range: ClosedRange<V>,
                   snapToStep: Bool = false,
                   initialValueSnapToStep: Bool = true,
                   @ViewBuilder contentBuilder: @escaping (_ model: Binding<NumericSettingViewModel<DecimalIntegerConverter<V>>>) -> Content)
    where V: BinaryInteger, T == DecimalIntegerConverter<V> {

        self._value = value
        self._model = State(initialValue: NumericSettingViewModel(DecimalIntegerConverter<V>(),
                                                                  value.wrappedValue,
                                                                  range: range,
                                                                  snapToStep: snapToStep))
        self.contentBuilder = contentBuilder
    }

    public init<V>(_ value: Binding<V>,
                   in range: ClosedRange<V>,
                   snapToStep: Bool = false,
                   initialValueSnapToStep: Bool = true,
                   @ViewBuilder contentBuilder: @escaping (_ model: Binding<NumericSettingViewModel<DecimalFloatingPointConverter<V>>>) -> Content)
    where V: BinaryFloatingPoint, T == DecimalFloatingPointConverter<V> {

        self._value = value
        self._model = State(initialValue: NumericSettingViewModel(DecimalFloatingPointConverter<V>(),
                                                                  value.wrappedValue,
                                                                  range: range,
                                                                  snapToStep: snapToStep))
        self.contentBuilder = contentBuilder
    }
}
