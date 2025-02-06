//
//  GradientVisualizerModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/13.
//

import DominantColors
import Foundation
import SwiftUI

@Observable final class GradientVisualizerModel {
    static let fallbackDominantColors: [Color] = [
        .init(hex: 0x929292), .init(hex: 0xFFFFFF), .init(hex: 0x929292)
    ]
    private(set) var dominantColors: [Color] = []

    var dominantColorsWithFallback: [Color] {
        dominantColors.isEmpty ? GradientVisualizerModel.fallbackDominantColors : dominantColors
    }

    static func extractDominantColors(from image: NSImage) async throws -> [Color] {
        let colors = try DominantColors.dominantColors(
            nsImage: image, quality: .fair,
            algorithm: .CIEDE2000, maxCount: 8,
            options: [.excludeBlack], sorting: .frequency,
            deltaColors: 6
        )
        return colors.map(Color.init)
    }

    func updateDominantColors(from image: NSImage? = nil) async {
        if let image {
            do {
                dominantColors = try await GradientVisualizerModel.extractDominantColors(from: image)
            } catch {
                dominantColors = []
            }
        } else {
            dominantColors = []
        }
    }

    func prefixedDominantColors(upTo count: Int) -> [Color] {
        let limitedCount = max(0, min(count, dominantColors.count))
        return Array(dominantColors.prefix(upTo: limitedCount))
    }

    func prefixedDominantColorsWithFallback(upTo count: Int) -> [Color] {
        let limitedCount = max(0, min(count, dominantColorsWithFallback.count))
        return Array(dominantColorsWithFallback.prefix(upTo: limitedCount))
    }
}
