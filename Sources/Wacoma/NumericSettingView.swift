//
//  NumericSettingView.swift
//  Wacoma
//
//  Created by Jim Hanson on 8/22/22.

import Foundation
import SwiftUI

// fileprivate let noValue = "--"

public typealias NumericValue = Numeric & Comparable

public protocol DecimalConverter {

    associatedtype ValueType : NumericValue

    var minimumStepSize: ValueType { get }

    func valueToDecimal(_ value: ValueType) -> Decimal

    func decimalToValue(_ decimal: Decimal) -> ValueType

    func decimalToString(_ decimal: Decimal) -> String

    func valueToString(_ value: ValueType) -> String

    func makeStepSize(_ range: ClosedRange<ValueType>) -> Decimal

    // TODO: delete if not used
    func makeStepSize(decimalRange: ClosedRange<Decimal>) -> Decimal

}

extension DecimalConverter {

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

    public func decimalToString(_ decimal: Decimal) -> String {
        return "\(decimal)"
    }

    public func valueToString(_ value: ValueType) -> String {
        return decimalToString(valueToDecimal(value))
    }

    public func makeStepSize(_ range: ClosedRange<ValueType>) -> Decimal  {
        return stepSizeFromWidth(Double(range.upperBound - range.lowerBound))
    }

    public func makeStepSize(decimalRange: ClosedRange<Decimal>) -> Decimal {
        let width = decimalRange.upperBound - decimalRange.lowerBound
        return stepSizeFromWidth(Double(NSDecimalNumber(decimal: width).doubleValue))
    }

//    public func valueToSliderPosition(_ value: ValueType, _ lowerBound: ValueType, _ upperBound: ValueType) -> Double  where ValueType: BinaryInteger {
//        return Double(value - lowerBound)/Double(upperBound - lowerBound)
//    }

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

    public func decimalToString(_ decimal: Decimal) -> String {
        return "\(decimal)"
    }

    public func valueToString(_ value: ValueType) -> String {
        return decimalToString(valueToDecimal(value))
    }

    public func makeStepSize(_ range: ClosedRange<ValueType>) -> Decimal  {
        return stepSizeFromWidth(Double(range.upperBound - range.lowerBound))
    }

    public func makeStepSize(decimalRange: ClosedRange<Decimal>) -> Decimal {
        let width = decimalRange.upperBound - decimalRange.lowerBound
        return stepSizeFromWidth(Double(NSDecimalNumber(decimal: width).doubleValue))
    }

//    public func valueToSliderPosition(_ value: ValueType, _ lowerBound: ValueType, _ upperBound: ValueType) -> Double  where ValueType: BinaryFloatingPoint {
//        return Double(value - lowerBound)/Double(upperBound - lowerBound)
//    }

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

    public let maximumRange: ClosedRange<Decimal>

    public let maximumStepSize: Decimal

    public let minimumStepSize: Decimal

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

    // TODO: change this to be calibrated in step number
    public private(set) var sliderRange: ClosedRange<Decimal>

    public init(_ transformer: T,
                _ initialValue: T.ValueType,
                initialRange: ClosedRange<T.ValueType>? = nil,
                maximumRange: ClosedRange<T.ValueType>,
                minimumStepSize: T.ValueType,
                snapToStep: Bool) {

        // TODO: init(transformer, range, initialValue, initialSliderRange) // No snap to step
        // ???: simplify the below by init'ing stuff to temp values where necessary, then calling setSliderRange


        let adjustedSliderRange: ClosedRange<T.ValueType>
        if let initialRange {
            // If slider range extends beyond the valid range, shrink slider range to fit.
            // If initial value is outside slider range, expand slider range to cover it.
            let adjustedSliderLB = min(initialValue, max(initialRange.lowerBound, maximumRange.lowerBound))
            let adjustedSliderUB = max(initialValue, min(initialRange.upperBound, maximumRange.upperBound))
            adjustedSliderRange = adjustedSliderLB...adjustedSliderUB
        }
        else {
            adjustedSliderRange = maximumRange
        }

        let tmpDecimal = transformer.valueToDecimal(initialValue)
        let tmpSliderLB = transformer.valueToDecimal(adjustedSliderRange.lowerBound)
        let tmpSliderUB = transformer.valueToDecimal(adjustedSliderRange.upperBound)

        let initialStepSize = transformer.makeStepSize(adjustedSliderRange)
        let initialStep = Self.getStepNumber(tmpDecimal, initialStepSize)
        let initialDecimal = snapToStep ? initialStep * initialStepSize : tmpDecimal
        let initialSliderLB = snapToStep ? Self.getStepNumber(tmpSliderLB, initialStepSize) * initialStepSize : tmpSliderLB
        var initialSliderUB = snapToStep ? Self.getStepNumber(tmpSliderUB, initialStepSize) * initialStepSize : tmpSliderUB
        if initialSliderUB < tmpSliderUB {
            initialSliderUB += initialStepSize
        }

        let overallLB = transformer.valueToDecimal(maximumRange.lowerBound)
        let overallUB = transformer.valueToDecimal(maximumRange.upperBound)

        self.transformer = transformer
        self.maximumRange = overallLB...overallUB
        self.maximumStepSize = overallUB - overallLB
        self.minimumStepSize = transformer.valueToDecimal(minimumStepSize)
        self.decimalValue = initialDecimal
        self.snapToStep = snapToStep
        self.fieldText = transformer.decimalToString(initialDecimal)
        self.stepSize = initialStepSize
        self.stepNumber = initialStep
        self.sliderPosition = Self.getSliderPosition(initialDecimal, initialSliderLB, initialSliderUB)
        self.sliderRange = initialSliderLB...initialSliderUB
    }

    public mutating func setStepSize(_ newStepSize: Decimal) {
        if newStepSize < minimumStepSize || newStepSize > maximumStepSize {
            return
        }

        // TODO: make sure newSliderLB <= decimalValue
        var newSliderLB = newStepSize * Self.getStepNumber(sliderRange.lowerBound, self.stepSize)

        // TODO: make sure newSliderUB >= decimalValue
        var newSliderUB = newStepSize * Self.getStepNumber(sliderRange.upperBound, self.stepSize)

        self.stepSize = newStepSize
        self.stepNumber = Self.getStepNumber(decimalValue, newStepSize)
        self.sliderRange = newSliderLB...newSliderUB
        self.sliderPosition = Self.getSliderPosition(decimalValue, newSliderLB, newSliderUB)
    }


    public mutating func applyFieldText() {
        if let newDecimal = Decimal(string: fieldText) {
            // STET: do not clamp or snap tmpDecimal; allow user to override the constraints.
            applyDecimalAndStep(newDecimal, Self.getStepNumber(newDecimal, stepSize))
        }
        else {
            self.fieldText = textValue
        }
    }

    public mutating func applyIncrement(_ steps: Int = 1) {
        let tmpStep = stepNumber + Decimal(steps)
        let tmpDecimal = tmpStep * stepSize
        if tmpDecimal > maximumRange.upperBound {
            applyDecimalAndStep(maximumRange.upperBound, Self.getStepNumber(maximumRange.upperBound, stepSize))
        }
        else {
            applyDecimalAndStep(tmpDecimal, tmpStep)
        }
    }

    public mutating func applyDecrement(_ steps: Int = 1) {
        let tmpStep = stepNumber - Decimal(steps)
        let tmpDecimal = tmpStep * stepSize
        if tmpDecimal < maximumRange.lowerBound {
            applyDecimalAndStep(maximumRange.lowerBound, Self.getStepNumber(maximumRange.lowerBound, stepSize))
        }
        else {
            applyDecimalAndStep(tmpDecimal, tmpStep)
        }
    }

    public mutating func valueChanged(_ newValue: T.ValueType) {
        let tmpDecimal = transformer.valueToDecimal(newValue)
        if snapToStep {
            let tmpStep = Self.getStepNumber(tmpDecimal, stepSize)
            decimalValue = tmpStep * stepSize
            stepNumber = tmpStep
        }
        else {
            decimalValue = tmpDecimal
            stepNumber = Self.getStepNumber(decimalValue, stepSize)
        }

        fieldText = transformer.decimalToString(decimalValue)

        let newSliderPosition = Self.getSliderPosition(decimalValue, sliderRange.lowerBound, sliderRange.upperBound)
        if newSliderPosition != sliderPosition {
            sliderPosition = newSliderPosition
        }
    }

    // TODO: STOP USING AND DELETE
    public mutating func rescaleSlider(factor: Decimal) {
        let oldLowerPart = decimalValue - sliderRange.lowerBound
        let oldUpperPart = sliderRange.upperBound - decimalValue
        let newLB = decimalValue - factor * oldLowerPart
        let newUB = decimalValue + factor * oldUpperPart
        setSliderRange(newLB...newUB)
    }

    // TODO: STOP USING AND DELETE
    public mutating func setSliderRange(_ newSliderRange: ClosedRange<Decimal>) {
        let tmpLB = max(newSliderRange.lowerBound, maximumRange.lowerBound)
        let tmpUB = min(newSliderRange.upperBound, maximumRange.upperBound)

        let newStepSize = transformer.makeStepSize(decimalRange: tmpLB...tmpUB)
        let newSliderLB = snapToStep ? Self.getStepNumber(tmpLB, newStepSize) * newStepSize : tmpLB
        var newSliderUB = snapToStep ? Self.getStepNumber(tmpUB, newStepSize) * newStepSize : tmpUB
        if newSliderUB < tmpUB {
            newSliderUB += newStepSize
        }

        self.stepSize = newStepSize
        self.stepNumber = Self.getStepNumber(decimalValue, newStepSize)
        self.sliderRange = newSliderLB...newSliderUB
        self.sliderPosition = Self.getSliderPosition(decimalValue, newSliderLB, newSliderUB)
    }

    private mutating func applySliderPosition(_ newSliderPosition: Double) {
        let tmpDecimal = sliderRange.lowerBound + Decimal(newSliderPosition) * (sliderRange.upperBound - sliderRange.lowerBound)
        let newStep = Self.getStepNumber(tmpDecimal, self.stepSize)
        let newDecimal = newStep * stepSize
        self.stepNumber = newStep
        self.decimalValue = newDecimal
        self.fieldText = transformer.decimalToString(newDecimal)
    }

    private mutating func applyDecimalAndStep(_ newDecimal: Decimal, _ newStep: Decimal) {
        decimalValue = newDecimal
        stepNumber = newStep
        fieldText = transformer.decimalToString(decimalValue)

        let newSliderPosition = Self.getSliderPosition(decimalValue, sliderRange.lowerBound, sliderRange.upperBound)
        if sliderPosition != newSliderPosition {
            sliderPosition = newSliderPosition
        }
    }

    private static func getStepNumber(_ value: Decimal, _ stepSize: Decimal) -> Decimal {
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

    public var sliderLBText: String {
        transformer.decimalToString(sliderRange.lowerBound)
    }

    public var sliderUBText: String {
        transformer.decimalToString(sliderRange.upperBound)
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

    // TODO: (value, range, initialSliderRange) no snapToStep
    // Or maybe even (value, range, initialStepSize) and then set up the sliderRange based on 100 steps.
    public init<V>(_ value: Binding<V>,
                   initialRange: ClosedRange<V>? = nil,
                   maximumRange: ClosedRange<V>,
                   snapToStep: Bool = true,
                   @ViewBuilder contentBuilder: @escaping (_ model: Binding<NumericSettingViewModel<DecimalIntegerConverter<V>>>) -> Content)
    where V: BinaryInteger, T == DecimalIntegerConverter<V> {

        self._value = value
        self._model = State(initialValue: NumericSettingViewModel(DecimalIntegerConverter<V>(),
                                                                  value.wrappedValue,
                                                                  initialRange: initialRange,
                                                                  maximumRange: maximumRange,
                                                                  minimumStepSize: 1,
                                                                  snapToStep: snapToStep))
        self.contentBuilder = contentBuilder
    }

    public init<V>(_ value: Binding<V>,
                   initialRange: ClosedRange<V>? = nil,
                   maximumRange: ClosedRange<V>,
                   snapToStep: Bool = true,
                   @ViewBuilder contentBuilder: @escaping (_ model: Binding<NumericSettingViewModel<DecimalFloatingPointConverter<V>>>) -> Content)
    where V: BinaryFloatingPoint, T == DecimalFloatingPointConverter<V> {

        self._value = value
        self._model = State(initialValue: NumericSettingViewModel(DecimalFloatingPointConverter<V>(),
                                                                  value.wrappedValue,
                                                                  initialRange: initialRange,
                                                                  maximumRange: maximumRange,
                                                                  minimumStepSize: 0,
                                                                  snapToStep: snapToStep))
        self.contentBuilder = contentBuilder
    }
}
