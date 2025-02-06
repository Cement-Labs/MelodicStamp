//
//  Playlist+Canonical+CacheSegments.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/28.
//

import Defaults
import SwiftUI

extension CanonicalPlaylist {
    enum CacheSegmentIndex: String, MelodicStamp.CacheSegmentIndex {
        case info = ".info"
        case state = ".state"
        case artwork = ".artwork"
    }

    struct Info: CacheSegment {
        typealias Index = CacheSegmentIndex

        var index: Index { .info }

        var title: String = ""
        var description: String = ""
    }

    struct State: CacheSegment {
        typealias Index = CacheSegmentIndex

        var index: Index { .state }

        var currentTrackURL: URL?
        var currentTrackElapsedTime: TimeInterval = .zero
        var playbackMode: PlaybackMode = Defaults[.defaultPlaybackMode]
        var playbackLooping: Bool = false
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

extension CanonicalPlaylist {
    struct CacheSegments: MelodicStamp.CacheSegments {
        typealias Index = CacheSegmentIndex

        var info: Info
        var state: State
        var artwork: Artwork

        private init(info: Info, state: State, artwork: Artwork) {
            self.info = info
            self.state = state
            self.artwork = artwork
        }

        init(loadingFrom url: URL) throws {
            let info = try JSONDecoder().decode(Info.self, from: Self.read(segment: .info, fromDirectory: url))
            let state = try JSONDecoder().decode(State.self, from: Self.read(segment: .state, fromDirectory: url))
            let artwork = try JSONDecoder().decode(Artwork.self, from: Self.read(segment: .artwork, fromDirectory: url))
            self.init(info: info, state: state, artwork: artwork)

            logger.info("Successfully read cache segments for canonical playlist at \(url): \("\(info)"), \("\(state)"), \("\(artwork)")")
        }

        init() {
            self.init(info: .init(), state: .init(), artwork: .init())
        }
    }
}
