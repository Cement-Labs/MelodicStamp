//
//  ContinuousRippleEffectView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/22.
//

import Metal
import SwiftUI

struct ContinuousRippleEffectView<Content>: View where Content: View {
    var lerpFactor: CGFloat = 0.2
    @ViewBuilder var content: () -> Content

    @State private var isDragging = false

    @State private var dragLocation: CGPoint = .zero
    @State private var dragVelocity: CGSize = .zero
    @State private var animatedDragVelocity: CGSize = .zero

    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .default).autoconnect()

    var body: some View {
        // Make variables sendable
        let animatedDragLocation = dragLocation
        let animatedDragVelocity = animatedDragVelocity

        content()
            .visualEffect { content, _ in
                content.layerEffect(
                    ShaderLibrary.continuousRipple(
                        .float2(animatedDragLocation),
                        .float2(animatedDragVelocity)
                    ),
                    maxSampleOffset: .init(width: 600, height: 600)
                )
            }
            .gesture(DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragLocation = value.location
                    dragVelocity = value.velocity
                }
                .onEnded { _ in
                    isDragging = false
                }
            )
            .onReceive(timer) { _ in
                let dragVelocity = isDragging ? dragVelocity : .zero
                withAnimation(.linear(duration: 0.05)) {
                    self.animatedDragVelocity = .init(
                        width: lerp(animatedDragVelocity.width, dragVelocity.width, factor: lerpFactor),
                        height: lerp(animatedDragVelocity.height, dragVelocity.height, factor: lerpFactor)
                    )
                }
            }
    }
}

struct ContinuousRippleEffectModifier: ViewModifier {
    var lerpFactor: CGFloat = 0.2

    func body(content: Content) -> some View {
        ContinuousRippleEffectView(lerpFactor: lerpFactor) {
            content
        }
    }
}

#if DEBUG
    #Preview {
        ContinuousRippleEffectView {
            Image(.templateArtwork)
                .resizable()
                .scaledToFit()
                .frame(width: 500)
        }
    }
#endif
