//
//  MotionCardView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/23.
//

import SwiftUI

struct MotionCardView<Content>: View where Content: View {
    var scale: CGFloat = 1.065
    var angle: Angle = .degrees(10)
    var shadowColor: Color = .black.opacity(0.45)
    var shadowRadius: CGFloat = 25
    var glintColor: Color = .white.opacity(0.1)
    var glintRadius: CGFloat = 50
    @ViewBuilder var content: () -> Content

    @State private var size: CGSize = .zero
    @State private var isHovering = false
    @State private var hoverPosition: CGPoint = .zero

    var body: some View {
        content()
            .overlay(alignment: .center) {
                if isHovering {
                    Circle()
                        .fill(glintColor)
                        .frame(width: glintRadius * 2, height: glintRadius * 2)
                        .blur(radius: glintRadius)
                        .blendMode(.screen)
                        .offset(x: translation.x, y: translation.y)
                        .transition(.blurReplace)
                        .animation(nil, value: translation) // Important!
                }
            }
            .clipped()
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newValue in
                size = newValue
            }
            .scaleEffect(isHovering ? scale : 1)
            .rotation3DEffect(
                normalizedAngle,
                axis: (x: translation.y, y: -translation.x, z: 0)
            )
            // Coordinating:
            // 0 --> +x
            // |
            // v
            // +y
            .onContinuousHover(coordinateSpace: .local) { phase in
                switch phase {
                case let .active(location):
                    hoverPosition = location
                    isHovering = true
                case .ended:
                    isHovering = false
                }
            }
            .shadow(
                color: shadowColor.opacity(isHovering ? 1 : 0),
                radius: isHovering ? shadowRadius : 0
            )
            .animation(.smooth(duration: 0.45), value: isHovering)
            .animation(.smooth(duration: 0.45), value: translation)
    }

    private var center: CGPoint {
        .init(x: size.width / 2, y: size.height / 2)
    }

    private var translation: CGPoint {
        guard isHovering else { return .zero }
        return hoverPosition.applying(.init(translationX: -center.x, y: -center.y))
    }

    private var normalizedAngle: Angle {
        guard isHovering else { return .zero }

        let distance = pow(translation.x, 2) + pow(translation.y, 2)
        let maxDistance = pow(center.x, 2) + pow(center.y, 2)
        let factor = min(1.0, distance / maxDistance)

        return angle * factor
    }
}

struct MotionCardModifier: ViewModifier {
    var scale: CGFloat = 1.065
    var angle: Angle = .degrees(10)
    var shadowColor: Color = .black.opacity(0.45)
    var shadowRadius: CGFloat = 25
    var glintColor: Color = .white.opacity(0.1)
    var glintRadius: CGFloat = 50

    func body(content: Content) -> some View {
        MotionCardView(
            scale: scale,
            angle: angle,
            shadowColor: shadowColor,
            shadowRadius: shadowRadius,
            glintColor: glintColor,
            glintRadius: glintRadius
        ) {
            content
        }
    }
}

#if DEBUG
    #Preview {
        MotionCardView {
            Image(.templateArtwork)
                .resizable()
                .scaledToFill()
                .frame(width: 450)
        }
        .padding(100)
    }
#endif
