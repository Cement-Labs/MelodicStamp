//
//  AudioVisualizerModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/5.
//

import Foundation

@Observable final class AudioVisualizerModel {
    var historyWindowSize = 10

    private(set) var normalizedData: [[Float]] = [[]]
    private(set) var maxHistories: [CGFloat] = []
    private(set) var minHistories: [CGFloat] = []
    /*
     func normalizeData(fftData: [CGFloat]) {
         let epsilon: CGFloat = 1e-6

         let validFFTData = fftData.filter(\.isFinite)
         let validMinHistories = minHistories.filter(\.isFinite)
         let validMaxHistories = maxHistories.filter(\.isFinite)

         let currentMin = validFFTData.min() ?? 0
         let currentMax = validFFTData.max() ?? 0

         let dynamicMax = max((validMaxHistories + [currentMax]).max() ?? 0, epsilon)
         let dynamicMin = min((validMinHistories + [currentMin]).min() ?? 0, dynamicMax - epsilon)

         func normalize() -> (normalized: CGFloat, min: CGFloat, max: CGFloat) {
             if !dynamicMin.isFinite || !dynamicMax.isFinite || dynamicMax <= dynamicMin {
                 return (0.5, 0, epsilon)
             } else {
                 let fftPeak = validFFTData.max() ?? 0
                 let normalizedValue = (fftPeak - dynamicMin) / (dynamicMax - dynamicMin)

                 return if normalizedValue.isNaN {
                     (0.5, dynamicMin, dynamicMax)
                 } else {
                     (normalizedValue, currentMin, currentMax)
                 }
             }
         }
         let data = normalize()

         normalizedData = data.normalized
         updateHistories(min: data.min, max: data.max)
     }
     */
    func normalizeData(_ data: [[Float]]) -> Float {
        let flatData = data.flatMap(\.self)

        let sum = flatData.reduce(0, +)
        let average = sum / Float(flatData.count)

        let normalizedValue = min(max(average / 1, 0), 1)

        let finalValue = 10 * normalizedValue + 0.1

        return finalValue
    }

    private func updateHistories(min: CGFloat, max: CGFloat) {
        guard historyWindowSize > 0 else { return }

        if minHistories.count >= historyWindowSize {
            minHistories.removeFirst()
        }

        if maxHistories.count >= historyWindowSize {
            maxHistories.removeFirst()
        }

        minHistories.append(min)
        maxHistories.append(max)
    }
}

extension [Float] {
    func minMax() -> (min: Float, max: Float)? {
        guard let min = self.min(), let max = self.max() else { return nil }
        return (min, max)
    }
}
