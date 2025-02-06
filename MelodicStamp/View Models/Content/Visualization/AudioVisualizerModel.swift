//
//  AudioVisualizerModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/5.
//

import CSFBAudioEngine
import Foundation

@Observable final class AudioVisualizerModel {
    private(set) var data: [[Float]] = [[]]
    private(set) var normalizedData: [[Float]] = [[]]
    private(set) var average: Float = .zero

    func updateData(from data: [[Float]]) {
        self.data = data
        normalizedData = data.map(\.normalized)
        average = normalizedData.flatMap(\.self).reduce(0, +) / Float(normalizedData.count)
    }

    func clearData() {
        data = [[]]
        normalizedData = [[]]
        average = .zero
    }
}
