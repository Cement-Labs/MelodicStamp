//
//  LyricsModel.swift
//  Melodic Stamp
//
//  Created by KrLite on 2024/12/1.
//

import Foundation
import RegexBuilder
import SwiftSoup

// MARK: - Lyric Line (Protocol)

protocol LyricLine: Equatable, Hashable, Identifiable {
    var beginTime: TimeInterval? { get }
    var endTime: TimeInterval? { get }

    var isValid: Bool { get }
}

extension LyricLine {
    var isValid: Bool {
        beginTime != nil || endTime != nil
    }
}

// MARK: - Lyrics Parser (Protocol)

protocol LyricsParser {
    associatedtype Line: LyricLine

    var lines: [Line] { get set }

    init(string: String) throws

    func highlight(at time: TimeInterval) -> Range<Int>
}

extension LyricsParser {
    func highlight(at time: TimeInterval) -> Range<Int> {
        // Lines that begin before (or equal) the target time, sorted by descending beginning times
        let prefixes = lines.enumerated()
            .filter {
                if let beginTime = $0.element.beginTime {
                    beginTime <= time
                } else { false }
            }
            .sorted {
                let lhsBeginTime = $0.element.beginTime ?? .nan
                let rhsBeginTime = $1.element.beginTime ?? .nan
                return lhsBeginTime > rhsBeginTime
            }
        
        // Lines that begin after the target time, sorted by ascending beginning times
        let suffixes = lines.enumerated()
            .filter {
                if let beginTime = $0.element.beginTime {
                    beginTime > time
                } else { false }
            }
            .sorted {
                let lhsBeginTime = $0.element.beginTime ?? .nan
                let rhsBeginTime = $1.element.beginTime ?? .nan
                return lhsBeginTime < rhsBeginTime
            }
        
        let lastPrefix = prefixes.first
        let firstSuffix = suffixes.first
        let endIndex = lines.endIndex
        
        if let lastPrefix {
            // Has a prefixing line
            
            if let endTime = lastPrefix.element.endTime {
                // The prefixing line specifies an ending time
                
                let reachedEndTime = endTime < time
                
                if reachedEndTime {
                    // Reached the prefixing line's ending time
                    
                    if let firstSuffix {
                        // Has a suffixing line
                        
                        let suspensionThreshold: TimeInterval = 1
                        let shouldSuspend = if let beginTime = firstSuffix.element.beginTime {
                            beginTime - endTime >= suspensionThreshold
                        } else { false }
                        
                        return if shouldSuspend {
                            // Suspend before the suffixing line begins
                            firstSuffix.offset ..< firstSuffix.offset
                        } else {
                            // Hold until the suffixing line begins
                            lastPrefix.offset ..< firstSuffix.offset
                        }
                    } else {
                        // Has no suffixing lines
                        
                        return endIndex ..< endIndex
                    }
                } else {
                    // Still in the range of the prefixing line
                    
                    let firstPrefix = prefixes
                        .prefix {
                            $0.element.endTime == endTime
                        }
                        .first
                    
                    return (firstPrefix?.offset ?? 0) ..< (lastPrefix.offset + 1)
                }
            } else {
                // The prefixing line specifies no ending times
                
                if let firstSuffix {
                    // Has a suffixing line
                    
                    return lastPrefix.offset ..< firstSuffix.offset
                } else {
                    // Has no suffixing lines
                    
                    let firstPrefix = prefixes
                        .prefix {
                            $0.element.endTime == nil
                        }
                        .first
                    
                    return (firstPrefix?.offset ?? 0) ..< (lastPrefix.offset + 1)
                }
            }
        } else {
            // Has no prefixing lines
            
            return 0 ..< 0
        }
    }
}

// MARK: Lyrics Type

enum LyricsType: String, Hashable, Identifiable, CaseIterable {
    case raw // Raw splitted string, unparsed
    case lrc // Line based
    case ttml // Word based

    var id: String {
        rawValue
    }
}

// MARK: Lyrics Storage

enum LyricsStorage {
    case raw(parser: RawLyricsParser)
    case lrc(parser: LRCParser)
    case ttml(parser: TTMLParser)

    var type: LyricsType {
        switch self {
        case .raw: .raw
        case .lrc: .lrc
        case .ttml: .ttml
        }
    }
    
    var parser: any LyricsParser {
        switch self {
        case .raw(let parser):
            parser
        case .lrc(let parser):
            parser
        case .ttml(let parser):
            parser
        }
    }
}

// MARK: Lyrics Model

@Observable class LyricsModel {
    private(set) var storage: LyricsStorage?
    private(set) var url: URL?
    var type: LyricsType?

    private var cache: String?
    
    var lines: [any LyricLine] {
        storage?.parser.lines ?? []
    }

    func identify(url: URL?) {
        self.url = url
    }

    func load(string: String?, autoRecognizes: Bool = true) {
        if autoRecognizes {
            if let string {
                do {
                    type = try recognize(string: string) ?? .raw
                } catch {
                    type = .raw
                }
            } else {
                type = nil
            }
        }

        // Debounce
        guard type != storage?.type || string != cache || url != url else { return }

        cache = string
        url = url
        guard let string else {
            storage = nil
            return
        }

        if let type {
            do {
                storage = switch type {
                case .raw:
                    try .raw(parser: .init(string: string))
                case .lrc:
                    try .lrc(parser: .init(string: string))
                case .ttml:
                    try .ttml(parser: .init(string: string))
                }
            } catch {
                storage = nil
            }
        }
    }

    func highlight(at time: TimeInterval, in url: URL? = nil) -> Range<Int> {
        guard let storage else { return 0 ..< 0 }
        let result = storage.parser.highlight(at: time)
        return if let url {
            if url == self.url {
                result
            } else {
                0..<0
            }
        } else {
            result
        }
    }
}

extension LyricsModel {
    func recognize(string: String?) throws -> LyricsType? {
        guard let string else { return nil }
        return if string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .starts(with: /\[.+].*/) {
            .lrc
        } else if
            let body = try SwiftSoup.parse(string).body(),
            try !body.getElementsByTag("tt").isEmpty {
            .ttml
        } else {
            .raw
        }
    }
}
