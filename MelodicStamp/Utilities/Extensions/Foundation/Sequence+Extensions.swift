//
//  Sequence+Extensions.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/21.
//

import Foundation

extension Sequence where Element: Comparable {
    var span: ClosedRange<Element>? {
        guard let min = self.min(), let max = self.max() else { return nil }
        guard min < max else { return nil }
        return min...max
    }
}

extension Sequence where Element: Comparable & FloatingPoint {
    var normalized: [Element] {
        guard let span else { return map { _ in .zero } }
        return map { value in
            (value - span.lowerBound) / (span.upperBound - span.lowerBound)
        }
    }
}
