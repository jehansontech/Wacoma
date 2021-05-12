//
//  UIConstants.swift
//  ArcWorld
//
//  Created by Jim Hanson on 3/21/21.
//

import SwiftUI

public struct UIConstants {

    // Layout

    public static let buttonCornerRadius: CGFloat = 5

    public static let buttonSpacing: CGFloat = 10

    public static let buttonOpacity: Double = 0.1
    
    public static let buttonPadding = EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)

    public static let indentedContentBottomInset: CGFloat = 0

    public static let indentedContentLeadingInset: CGFloat = 30

    public static let indentedContentTopInset: CGFloat = 5

    public static let pageInsets = EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)

    public static let popoverCornerRadius: CGFloat = 10

    public static let popoverInsets: CGFloat = 3

    public static let settingsGridSpacing: CGFloat = 5

    public static let settingNameWidth: CGFloat = 180

    public static let settingValueWidth: CGFloat = 150

    public static let settingValueFontSize: CGFloat = 15
    
    public static let settingSliderWidth: CGFloat = 200

    public static let symbolButtonWidth: CGFloat = 45

    public static let symbolButtonHeight: CGFloat = 35

    public static let twistieChevronSize: CGFloat = 12


    // Colors

    public static let offWhite = Color(red: 180/255, green: 180/255, blue: 180/255, opacity: 1)

    public static let offBlack = Color(red: 30/255, green: 30/255, blue: 30/255, opacity: 1)

    public static let trueWhite = Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 1)
    
    public static let trueBlack = Color(red: 0, green: 0, blue: 0, opacity: 1)
    
    public static let darkGray = Color(red: 80/255, green: 80/255, blue: 80/255, opacity: 1)
    
    public static let controlColor = Color(red: 0/255, green: 127/255, blue: 255/255, opacity: 1)
}
