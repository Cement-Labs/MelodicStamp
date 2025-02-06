//
//  LyricsModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/1.
//

import Foundation
import SwiftSoup

// MARK: - Lyrics Model

@Observable class LyricsModel {
    private(set) var storage: LyricsStorage?
    private(set) var raw: RawLyrics?
    var type: LyricsType?

    var lines: [any LyricLine] {
        storage?.parser.lines ?? []
    }

    var attachments: LyricsAttachments {
        storage?.parser.attachments ?? []
    }

    var metadata: [LyricsMetadata] {
        storage?.parser.metadata ?? []
    }

    func isIdentical(to url: URL) -> Bool {
        url == raw?.url
    }

    func clear(_ url: URL? = nil) {
        guard let url, !isIdentical(to: url) else {
            storage = nil
            raw = nil
            type = nil
            return
        }
    }

    func read(_ raw: RawLyrics?, autoRecognizes: Bool = true, forced: Bool = false) async {
        guard forced || raw != self.raw else { return }
        self.raw = raw

        guard let raw else {
            // Explicitly set to nothing
            clear()
            return
        }

        guard let content = raw.content else {
            // Implicitly fails, reading nothing
            clear()
            return
        }

        if autoRecognizes {
            do {
                type = try recognize(string: content) ?? .raw
            } catch {
                type = .raw
            }
        }

        if let type {
            do {
                storage = switch type {
                case .raw:
                    try .raw(parser: .init(string: content))
                case .lrc:
                    try .lrc(parser: .init(string: content))
                case .ttml:
                    try .ttml(parser: .init(string: content))
                }
            } catch {
                storage = nil
            }
        }
    }

    func highlight(at time: TimeInterval, in url: URL? = nil) -> Range<Int> {
        guard let storage else { return -1 ..< 0 }
        return if let url, !isIdentical(to: url) {
            // Not the same song
            -1 ..< 0
        } else {
            storage.parser.highlight(at: time)
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
