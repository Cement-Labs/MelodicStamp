//
//  Array+Extensions.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/5.
//

import Foundation

extension Array {
    init(alternating element: Element, count: Int) where Element: SignedNumeric {
        self = (0 ..< count).map { index in
            if index.isMultiple(of: 2) {
                element
            } else {
                -element
            }
        }
    }

    /// Blends an array of `[A, B, C]` to `[A, AB, B, BC, C, CA]` using a transformation function, which blends `A, B` into `AB`, etc.
    func blending(transform: @escaping (Element, Element) -> Element) -> Self {
        guard count > 1 else { return self }
        var result: Self = []

        for i in 0 ..< count {
            let current = self[i]
            let next = self[(i + 1) % count] // Cyclomatic transition
            result.append(current)
            result.append(transform(current, next)) // Insert blended element
        }

        return result
    }

    func padded(toCount count: Int, with element: Element) -> [Element] {
        if self.count >= count {
            return self
        }
        return self + Array(repeating: element, count: count - self.count)
    }
}
