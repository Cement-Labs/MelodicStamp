//
//  View+Animations.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/26.
//

import Defaults
import SwiftUI

// MARK: - Fancy or Higher

extension View {
    @ViewBuilder func wiggleAnimation(
        _ trigger: some Equatable,
        count: Int = 4,
        size: CGSize = .init(width: 5, height: 0),
        delay: TimeInterval = .zero,
        isActive: Bool = Defaults[.motionLevel].canBeFancy
    ) -> some View {
        let phases: [CGFloat?] = [0.0] + Array(alternating: 1.0, count: count) + [0.0] + [nil]
        if isActive {
            phaseAnimator(phases, trigger: trigger) { content, value in
                let value = value ?? .zero
                content
                    .offset(x: value * size.width, y: value * size.height)
            } animation: { value in
                value.flatMap {
                    if abs($0) > 0 {
                        .easeOut(duration: 0.1).delay(delay)
                    } else {
                        .easeIn(duration: 0.1).delay(delay)
                    }
                }
            }
        } else {
            self
        }
    }

    @ViewBuilder func bounceAnimation(
        _ trigger: some Equatable,
        scale: CGSize = .init(width: 1.1, height: 1.1),
        anchor: UnitPoint = .center,
        duration: Double = 0.5,
        delay: TimeInterval = .zero,
        isActive: Bool = Defaults[.motionLevel].canBeFancy
    ) -> some View {
        let phases: [Bool?] = [false, true, false, nil]
        if isActive {
            phaseAnimator(phases, trigger: trigger) { content, value in
                let value = value ?? false
                content
                    .scaleEffect(value ? scale : .init(width: 1, height: 1), anchor: anchor)
            } animation: { value in
                value.flatMap {
                    if $0 {
                        .smooth(duration: duration).delay(delay)
                    } else {
                        .bouncy(duration: duration, extraBounce: 0.25).delay(delay)
                    }
                }
            }
        } else {
            self
        }
    }
}

// MARK: - Reduced or Higher

extension View {
    @ViewBuilder func continuousRippleEffect(
        lerpFactor: CGFloat = 0.2, isActive: Bool = Defaults[.motionLevel].canBeReduced
    ) -> some View {
        if isActive {
            modifier(ContinuousRippleEffectModifier(lerpFactor: lerpFactor))
        } else {
            self
        }
    }

    @ViewBuilder func motionCard(
        scale: CGFloat = 1.02, angle: Angle = .degrees(3.5),
        shadowColor: Color = .black.opacity(0.1), shadowRadius: CGFloat = 10,
        glintColor: Color = .white.opacity(0.1), glintRadius: CGFloat = 50,
        isActive: Bool = Defaults[.motionLevel].canBeReduced
    ) -> some View {
        if isActive {
            modifier(MotionCardModifier(
                scale: scale, angle: angle,
                shadowColor: shadowColor, shadowRadius: shadowRadius,
                glintColor: glintColor, glintRadius: glintRadius
            ))
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview("Wiggle Animation") {
    @Previewable @State var trigger = false

    VStack {
        Image(systemSymbol: .appleLogo)
            .font(.largeTitle)
            .foregroundStyle(.tint)
            .wiggleAnimation(trigger)
            .padding()

        Button("Trigger") {
            trigger.toggle()
        }
    }
    .padding()
}

#Preview("Bounce Animation") {
    @Previewable @State var trigger = false

    VStack {
        Image(systemSymbol: .appleLogo)
            .font(.largeTitle)
            .foregroundStyle(.tint)
            .bounceAnimation(trigger, scale: .init(width: 2, height: 2))
            .padding()

        Button("Trigger") {
            trigger.toggle()
        }
    }
    .padding()
}
