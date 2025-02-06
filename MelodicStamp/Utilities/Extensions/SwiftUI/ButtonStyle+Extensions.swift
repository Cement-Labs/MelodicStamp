//
//  ButtonStyle+Extensions.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/27.
//

import SwiftUI

extension ButtonStyle where Self == AliveButtonStyle {
    static func alive(
        scaleFactor: CGFloat = 0.85, shadowRadius: CGFloat = 4, duration: TimeInterval = 0.45,
        enabledStyle: some ShapeStyle = .primary, hoveringStyle: some ShapeStyle, disabledStyle: some ShapeStyle = .quinary
    ) -> AliveButtonStyle {
        .init(
            scaleFactor: scaleFactor, shadowRadius: shadowRadius, duration: duration,
            enabledStyle: enabledStyle, hoveringStyle: hoveringStyle, disabledStyle: disabledStyle
        )
    }

    static func alive(
        scaleFactor: CGFloat = 0.85, shadowRadius: CGFloat = 4, duration: TimeInterval = 0.45,
        enabledStyle: some ShapeStyle = .primary, disabledStyle: some ShapeStyle = .quinary
    ) -> AliveButtonStyle {
        .init(
            scaleFactor: scaleFactor, shadowRadius: shadowRadius, duration: duration,
            enabledStyle: enabledStyle, disabledStyle: disabledStyle
        )
    }

    static func alive(
        scaleFactor: CGFloat = 0.85, shadowRadius: CGFloat = 4, duration: TimeInterval = 0.45,
        enabledStyle: some ShapeStyle = .primary, hoveringStyle: some ShapeStyle, disabledStyle: some ShapeStyle = .quinary,
        isOn: Binding<Bool>
    ) -> AliveButtonStyle {
        .init(
            scaleFactor: scaleFactor, shadowRadius: shadowRadius, duration: duration,
            enabledStyle: enabledStyle, hoveringStyle: hoveringStyle, disabledStyle: disabledStyle, isOn: isOn
        )
    }

    static func alive(
        scaleFactor: CGFloat = 0.85, shadowRadius: CGFloat = 4, duration: TimeInterval = 0.45,
        enabledStyle: some ShapeStyle = .primary, disabledStyle: some ShapeStyle = .quinary,
        isOn: Binding<Bool>
    ) -> AliveButtonStyle {
        .init(
            scaleFactor: scaleFactor, shadowRadius: shadowRadius, duration: duration,
            enabledStyle: enabledStyle, disabledStyle: disabledStyle, isOn: isOn
        )
    }

    static var alive: AliveButtonStyle { .init() }
}
