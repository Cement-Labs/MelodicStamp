//
//  DynamicTypeSize+Extensions.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/9.
//

import SwiftUI

extension DynamicTypeSize: @retroactive Strideable {
    public typealias Stride = Int

    public func distance(to other: DynamicTypeSize) -> Int {
        let selfIndex = Self.allCases.firstIndex(of: self)!
        let otherIndex = Self.allCases.firstIndex(of: other)!
        return otherIndex.distance(to: selfIndex)
    }

    public func advanced(by n: Int) -> DynamicTypeSize {
        let index = Self.allCases.firstIndex(of: self)!
        let targetIndex = index.advanced(by: n)
        let clampedTargetIndex = max(Self.allCases.indices.lowerBound, min(Self.allCases.indices.upperBound, targetIndex))
        return Self.allCases[clampedTargetIndex]
    }
}

extension DynamicTypeSize {
    static postfix func ++ (lhs: inout DynamicTypeSize) {
        lhs = lhs.advanced(by: 1)
    }

    static postfix func -- (lhs: inout DynamicTypeSize) {
        lhs = lhs.advanced(by: -1)
    }
}

infix operator +~: AdditionPrecedence
infix operator -~: AdditionPrecedence
extension DynamicTypeSize {
    static func +~ (lhs: inout DynamicTypeSize, rhs: DynamicTypeSize) {
        lhs = min(lhs.advanced(by: 1), rhs)
    }

    static func -~ (lhs: inout DynamicTypeSize, rhs: DynamicTypeSize) {
        lhs = max(lhs.advanced(by: -1), rhs)
    }
}
