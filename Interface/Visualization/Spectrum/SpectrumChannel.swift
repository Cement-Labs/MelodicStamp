//
//  SpectrumChannel.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/21.
//

import SwiftUI

struct SpectrumChannel: View {
    var spectra: [Float]
    var barWidth: CGFloat = 2
    var verticalBaselineFactor: CGFloat = .zero

    @State private var containerSize: CGSize = .zero

    var body: some View {
        Path { path in
            let flippedVerticalBaselineFactor = 1 - verticalBaselineFactor
            let availableBarWidth = containerSize.width / CGFloat(spectra.count)
            let verticalBaseline = lerp(0, containerSize.height, factor: flippedVerticalBaselineFactor)

            for (i, amplitude) in spectra.enumerated() {
                let height = height(ofAmplitude: amplitude)
                let x = (CGFloat(i) + 0.5) * availableBarWidth - barWidth / 2
                let y = verticalBaseline - flippedVerticalBaselineFactor * height

                let upperBar = CGRect(x: x, y: y, width: barWidth, height: height)
                path.addRect(upperBar)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            containerSize = newValue
        }
    }

    private func height(ofAmplitude amplitude: Float) -> CGFloat {
        CGFloat(amplitude) * containerSize.height
    }
}

#Preview {
    @Previewable @State var verticalBaselineFactor: CGFloat = .zero

    VStack {
        SpectrumChannel(
            spectra: [
                0.1, 0.4, 0.24, 0.7, 0.45,
                0.32, 0.88, 0.91, 0.56, 0.4,
                0.72, 0.66, 0.21, 0.8, 0.23
            ],
            verticalBaselineFactor: verticalBaselineFactor
        )
        .border(.blue)

        Slider(value: $verticalBaselineFactor)
    }
    .padding()
}
