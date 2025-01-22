//
//  ContinuousRippleEffectView.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/22.
//

import Metal
import SwiftUI

struct ContinuousRippleEffectView<Content>: View where Content: View {
    var alpha: CGFloat = 0.2
    @ViewBuilder var content: () -> Content

    @State private var isDragging = false
    @State private var dragLocation = CGPoint(x: 0, y: 0)
    @State private var dragVelocity = CGSize.zero
    @State private var timer: Timer? = nil

    var body: some View {
        // Make variables sendable
        let dragLocation = dragLocation
        let dragVelocity = dragVelocity

        content()
            .visualEffect { content, _ in
                content.layerEffect(
                    ShaderLibrary.w(
                        .float2(dragLocation),
                        .float2(dragVelocity)
                    ),
                    maxSampleOffset: .init(width: 600, height: 600)
                )
            }
            .gesture(DragGesture()
                .onChanged { value in
                    self.dragLocation = value.location
                    self.dragVelocity.width = alpha * value.velocity.width + (1 - alpha) * self.dragVelocity.width
                    self.dragVelocity.height = alpha * value.velocity.height + (1 - alpha) * self.dragVelocity.height
                }
                .onEnded { _ in
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
                        // Apply exponential deceleration for smoother stop
                        self.dragVelocity.width *= 0.85
                        self.dragVelocity.height *= 0.85

                        // Stop the timer when velocity is very low
                        if abs(self.dragVelocity.width) < 0.01, abs(self.dragVelocity.height) < 0.01 {
                            self.dragVelocity = .zero
                            timer.invalidate()
                        }
                    }
                }
            )
    }
}

struct ContinuousRippleEffectModifier: ViewModifier {
    var alpha: CGFloat = 0.2

    func body(content: Content) -> some View {
        ContinuousRippleEffectView(alpha: alpha) {
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
