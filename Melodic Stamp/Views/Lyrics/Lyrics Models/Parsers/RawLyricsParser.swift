//
//  RawLyricsParser.swift
//  Melodic Stamp
//
//  Created by KrLite on 2024/12/1.
//

import Foundation

struct RawLyricLine: LyricLine {
    var startTime: TimeInterval?
    var endTime: TimeInterval?
    var content: String
    
    let id: UUID = .init()
}

@Observable class RawLyricsParser: LyricsParser {
    typealias Line = RawLyricLine
    
    var lines: [RawLyricLine]
    
    required init(string: String) throws {
        self.lines = string
            .split(separator: .newlineSequence)
            .map(String.init(_:))
            .map { .init(content: $0) }
    }
}
