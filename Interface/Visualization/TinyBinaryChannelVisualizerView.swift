//
//  TinyBinaryChannelVisualizerView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/22.
//

import Defaults
import SwiftUI

struct TinyBinaryChannelVisualizerView: View {
    @Environment(AudioVisualizerModel.self) private var audioVisualizer
    @Environment(GradientVisualizerModel.self) private var gradientVisualizer

    @Default(.gradientDynamics) private var gradientDynamics

    var body: some View {
        colorsView()
            .mask {
                SpectrumView(spectra: audioVisualizer.normalizedData)
                    .foregroundStyle(.white)
                    .animation(.smooth(duration: 0.2), value: audioVisualizer.normalizedData)
            }
    }

    @ViewBuilder private func colorsView() -> some View {
        if gradientVisualizer.dominantColors.isEmpty {
            Color.primary
        } else {
            LinearGradient(
                colors: gradientVisualizer.prefixedDominantColors(upTo: gradientDynamics.count),
                startPoint: .leading, endPoint: .trailing
            )
        }
    }
}

#if DEBUG
    #Preview(traits: .modifier(PreviewEnvironmentsModifier())) {
        TinyBinaryChannelVisualizerView()
            .frame(width: 20, height: 20)
            .padding()
    }
#endif
