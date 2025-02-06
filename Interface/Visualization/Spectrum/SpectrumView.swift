//
//  SpectrumView.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2025/1/21.
//

import SwiftUI

struct SpectrumView: View {
    var spectra: [[Float]]
    var barWidth: CGFloat = 2
    var leftChannelCount: Int = 3
    var rightChannelCount: Int = 3

    @State private var containerSize: CGSize = .zero

    var body: some View {
        HStack(spacing: 0) {
            spectrumView(sorted: leftSpectra.sorted(), count: leftChannelCount)

            spectrumView(sorted: rightSpectra.sorted().reversed(), count: rightChannelCount)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            containerSize = newValue
        }
    }

    private var leftSpectra: [Float] {
        if let firstSpectra = spectra.first {
            firstSpectra.padded(toCount: leftChannelCount, with: .zero)
        } else {
            Array(repeating: .zero, count: leftChannelCount)
        }
    }

    private var rightSpectra: [Float] {
        if spectra.count > 1, let lastSpectra = spectra.last {
            lastSpectra.padded(toCount: rightChannelCount, with: .zero)
        } else {
            Array(repeating: .zero, count: rightChannelCount)
        }
    }

    @ViewBuilder private func spectrumView(sorted: [Float], count: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0 ..< count, id: \.self) { index in
                let amplitude = averageAmplitude(in: sorted, index: index, count: count)
                barView(amplitude: amplitude)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder private func barView(amplitude: Float) -> some View {
        VStack {
            let height = height(ofAmplitude: amplitude)

            Capsule()
                .frame(width: barWidth, height: height)
        }
    }

    private func averageAmplitude(in data: [Float], index: Int, count: Int) -> Float {
        let segmentLength = data.count / count
        let start = segmentLength * index
        let end = min(start + segmentLength, data.count)
        let segment = data[start ..< end]

        let sum = segment.reduce(0, +)
        let average = sum / Float(segment.count)
        return max(0, min(1, average))
    }

    private func height(ofAmplitude amplitude: Float) -> CGFloat {
        max(CGFloat(amplitude) * containerSize.height, barWidth)
    }
}

#Preview {
    LinearGradient(
        colors: [.red, .green, .blue],
        startPoint: .leading, endPoint: .trailing
    )
    .mask {
        SpectrumView(spectra: [
            [0.1, 0.3, 0.5, 0.7, 0.9, 0.2, 0.5, 0.8, 0.3, 0.6],
            [0.9, 0.7, 0.5, 0.3, 0.1, 0.8, 0.6, 0.4, 0.2, 0.5]
        ])
        .foregroundStyle(.white)
    }
    .border(.blue)
    .frame(width: 100, height: 100)
    .padding()
}

#Preview {
    SpectrumView(spectra: [[]], leftChannelCount: 5, rightChannelCount: 5)
        .padding()
}
