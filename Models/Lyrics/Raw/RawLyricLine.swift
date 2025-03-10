//
//  RawLyricLine.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/15.
//

import Foundation

struct RawLyricLine: LyricLine, AnimatedString {
    typealias Animated = Self

    var beginTime: TimeInterval?
    var endTime: TimeInterval?
    var content: String

    let id: UUID = .init()
}
