//
//  Track+Canonical+CacheSegments.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/6.
//

import SwiftUI

extension CanonicalTrack {
    enum CacheSegmentIndex: String, MelodicStamp.CacheSegmentIndex {
        case info = ".info"
        case artwork = ".artwork"
    }

    struct Info: CacheSegment {
        typealias Index = CacheSegmentIndex

        var index: Index { .info }

        var title: String?
        var artist: String?
        var duration: Duration?
    }

    struct Artwork: CacheSegment {
        typealias Index = CacheSegmentIndex

        var index: Index { .artwork }

        var tiffRepresentation: Data?

        var image: NSImage? {
            guard let tiffRepresentation else { return nil }
            return NSImage(data: tiffRepresentation)
        }
    }
}

extension CanonicalTrack {
    struct CacheSegments: MelodicStamp.CacheSegments {
        typealias Index = CacheSegmentIndex

        var info: Info
        var artwork: Artwork

        private init(info: Info, artwork: Artwork) {
            self.info = info
            self.artwork = artwork
        }

        init(loadingFrom url: URL) throws {
            let info = try JSONDecoder().decode(Info.self, from: Self.read(segment: .info, fromDirectory: url))
            let artwork = try JSONDecoder().decode(Artwork.self, from: Self.read(segment: .artwork, fromDirectory: url))
            self.init(info: info, artwork: artwork)

            logger.info("Successfully read cache segments for canonical track at \(url): \("\(info)"), \("\(artwork)")")
        }

        init() {
            self.init(info: .init(), artwork: .init())
        }
    }
}
