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

    func makeStepSize(decimalRange: ClosedRange<Decimal>) -> Decimal

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
        return stepSizeFromWidth(Double(range.upperBound - range.lowerBound))
    }

    public func makeStepSize(decimalRange: ClosedRange<Decimal>) -> Decimal {
        let width = decimalRange.upperBound - decimalRange.lowerBound
        return stepSizeFromWidth(Double(NSDecimalNumber(decimal: width).doubleValue))
    }

    public func valueToSliderPosition(_ value: ValueType, _ lowerBound: ValueType, _ upperBound: ValueType) -> Double  where ValueType: BinaryInteger {
        return Double(value - lowerBound)/Double(upperBound - lowerBound)
    }

    private func stepSizeFromWidth(_ width: Double) -> Decimal {
        let exponent = floor(log10(width)) - 2 // subtract 2 to get ~100 steps
        let size = pow(10, exponent)
        return size < 1 ? 1 : Decimal(size)
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
        return stepSizeFromWidth(Double(range.upperBound - range.lowerBound))
    }

    public func makeStepSize(decimalRange: ClosedRange<Decimal>) -> Decimal {
        let width = decimalRange.upperBound - decimalRange.lowerBound
        return stepSizeFromWidth(Double(NSDecimalNumber(decimal: width).doubleValue))
    }

    public func valueToSliderPosition(_ value: ValueType, _ lowerBound: ValueType, _ upperBound: ValueType) -> Double  where ValueType: BinaryFloatingPoint {
        return Double(value - lowerBound)/Double(upperBound - lowerBound)
    }

    private func stepSizeFromWidth(_ width: Double) -> Decimal {
        let exponent = floor(log10(width)) - 2 // subtract 2 to get ~100 steps
        let size = pow(10, exponent)
        return Decimal(size)
    }
}

public struct NumericSettingViewModel<T: DecimalConverter> {

    // ========================================================================
    // IMPL NOTE: Do not use an Int for the stepNumber because the arithmetic
    // screws up sometimes.
    // ========================================================================

    public let transformer: T

    // TODO: MAYBE convert to ClosedRange
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

    public private(set) var decimalValue: Decimal

    public private(set) var stepSize: Decimal

    /// Always an integer value, but it's a Decimal type for convenience
    private var stepNumber: Decimal

    // TODO: MAYBE convert to ClosedRange
    public private(set) var sliderLB: Decimal
    public private(set) var sliderUB: Decimal

    public init(_ transformer: T,
                _ value: T.ValueType,
                validRange: ClosedRange<T.ValueType>,
                initialSliderRange: ClosedRange<T.ValueType>? = nil,
                snapToStep: Bool) {

        // MAYBE: simplify the below by init'ing stuff to temp values where necessary, then calling setSliderRange


        let adjustedSliderRange: ClosedRange<T.ValueType>
        if let initialSliderRange {
            // If slider range extends beyond the valid range, shrink slider range to fit.
            // If initial value is outside slider range, expand slider range to cover it.
            let trueLB = min(value, max(initialSliderRange.lowerBound, validRange.lowerBound))
            let trueUB = max(value, min(initialSliderRange.upperBound, validRange.upperBound))
            adjustedSliderRange = trueLB...trueUB
        }
        else {
            adjustedSliderRange = validRange
        }

        let tmpDecimal = transformer.valueToDecimal(value)
        let tmpSliderLB = transformer.valueToDecimal(adjustedSliderRange.lowerBound)
        let tmpSliderUB = transformer.valueToDecimal(adjustedSliderRange.upperBound)

        let initialStepSize = transformer.makeStepSize(adjustedSliderRange)
        let initialStep = Self.getStep(tmpDecimal, initialStepSize)
        let initialDecimal = snapToStep ? initialStep * initialStepSize : tmpDecimal
        let initialSliderLB = snapToStep ? Self.getStep(tmpSliderLB, initialStepSize) * initialStepSize : tmpSliderLB
        var initialSliderUB = snapToStep ? Self.getStep(tmpSliderUB, initialStepSize) * initialStepSize : tmpSliderUB
        if initialSliderUB < tmpSliderUB {
            initialSliderUB += initialStepSize
        }

        self.transformer = transformer
        self.valueLB = transformer.valueToDecimal(validRange.lowerBound)
        self.valueUB = transformer.valueToDecimal(validRange.upperBound)
        self.decimalValue = initialDecimal
        self.snapToStep = snapToStep
        self.fieldText = transformer.decimalToString(initialDecimal)
        self.stepSize = initialStepSize
        self.stepNumber = initialStep
        self.sliderPosition = Self.getSliderPosition(initialDecimal, initialSliderLB, initialSliderUB)
        self.sliderLB = initialSliderLB
        self.sliderUB = initialSliderUB
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
        let tmpStep = stepNumber + Decimal(steps)
        let tmpDecimal = tmpStep * stepSize
        if tmpDecimal > valueUB {
            applyDecimalAndStep(valueUB, Self.getStep(valueUB, stepSize))
        }
        else {
            applyDecimalAndStep(tmpDecimal, tmpStep)
        }
    }

    public mutating func applyDecrement(_ steps: Int = 1) {
        let tmpStep = stepNumber - Decimal(steps)
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
            stepNumber = tmpStep
        }
        else {
            decimalValue = tmpDecimal
            stepNumber = Self.getStep(decimalValue, stepSize)
        }

        fieldText = transformer.decimalToString(decimalValue)

        let newSliderPosition = Self.getSliderPosition(decimalValue, sliderLB, sliderUB)
        if newSliderPosition != sliderPosition {
            sliderPosition = newSliderPosition
        }
    }

    public mutating func rescaleSlider(factor: Decimal) {
        let oldLowerPart = decimalValue - sliderLB
        let oldUpperPart = sliderUB - decimalValue
        let newLB = decimalValue - factor * oldLowerPart
        let newUB = decimalValue + factor * oldUpperPart
        setSliderRange(decimalRange: newLB...newUB)
    }

    public mutating func setSliderRange(decimalRange: ClosedRange<Decimal>) {
        let tmpLB = max(decimalRange.lowerBound, valueLB)
        let tmpUB = min(decimalRange.upperBound, valueUB)

        let newStepSize = transformer.makeStepSize(decimalRange: tmpLB...tmpUB)
        let newSliderLB = snapToStep ? Self.getStep(tmpLB, newStepSize) * newStepSize : tmpLB
        var newSliderUB = snapToStep ? Self.getStep(tmpUB, newStepSize) * newStepSize : tmpUB
        if newSliderUB < tmpUB {
            newSliderUB += newStepSize
        }

        self.stepSize = newStepSize
        self.stepNumber = Self.getStep(decimalValue, newStepSize)
        self.sliderLB = newSliderLB
        self.sliderUB = newSliderUB
        self.sliderPosition = Self.getSliderPosition(decimalValue, newSliderLB, newSliderUB)
    }

    private mutating func applySliderPosition(_ newSliderPosition: Double) {
        let tmpDecimal = sliderLB + Decimal(newSliderPosition) * (sliderUB - sliderLB)
        let newStep = Self.getStep(tmpDecimal, self.stepSize)
        let newDecimal = newStep * stepSize
        self.stepNumber = newStep
        self.decimalValue = newDecimal
        self.fieldText = transformer.decimalToString(newDecimal)
    }

    private mutating func applyDecimalAndStep(_ newDecimal: Decimal, _ newStep: Decimal) {
        decimalValue = newDecimal
        stepNumber = newStep
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

/// Syntactic sugar
extension NumericSettingViewModel {

    public var numericValue: T.ValueType {
        transformer.decimalToValue(decimalValue)
    }

    public var textValue: String {
        transformer.decimalToString(decimalValue)
    }

    public var sliderDecimalRange: ClosedRange<Decimal> {
        sliderLB...sliderUB
    }

    public var sliderLBText: String {
        transformer.decimalToString(sliderLB)
    }

    public var sliderUBText: String {
        transformer.decimalToString(sliderUB)
    }

    public var stepSizeText: String {
        transformer.decimalToString(stepSize)
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
    }

    public init<V>(_ value: Binding<V>,
                   in validRange: ClosedRange<V>,
                   initialSliderRange: ClosedRange<V>? = nil,
                   snapToStep: Bool = false,
                   @ViewBuilder contentBuilder: @escaping (_ model: Binding<NumericSettingViewModel<DecimalIntegerConverter<V>>>) -> Content)
    where V: BinaryInteger, T == DecimalIntegerConverter<V> {

        self._value = value
        self._model = State(initialValue: NumericSettingViewModel(DecimalIntegerConverter<V>(),
                                                                  value.wrappedValue,
                                                                  validRange: validRange,
                                                                  initialSliderRange: initialSliderRange,
                                                                  snapToStep: snapToStep))
        self.contentBuilder = contentBuilder
    }

    public init<V>(_ value: Binding<V>,
                   in validRange: ClosedRange<V>,
                   initialSliderRange: ClosedRange<V>? = nil,
                   snapToStep: Bool = false,
                   @ViewBuilder contentBuilder: @escaping (_ model: Binding<NumericSettingViewModel<DecimalFloatingPointConverter<V>>>) -> Content)
    where V: BinaryFloatingPoint, T == DecimalFloatingPointConverter<V> {

        self._value = value
        self._model = State(initialValue: NumericSettingViewModel(DecimalFloatingPointConverter<V>(),
                                                                  value.wrappedValue,
                                                                  validRange: validRange,
                                                                  initialSliderRange: initialSliderRange,
                                                                  snapToStep: snapToStep))
        self.contentBuilder = contentBuilder
    }
}
