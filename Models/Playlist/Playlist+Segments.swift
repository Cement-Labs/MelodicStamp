//
//  Playlist+Segments.swift
//  Models
//
//  Created by KrLite on 2025/1/28.
//

import Defaults
import SwiftUI

extension Playlist {
    enum Segment: String, CaseIterable {
        case info = ".info"
        case state = ".state"
        case artwork = ".artwork"

        func url(relativeTo root: URL) -> URL {
            root.appending(path: rawValue, directoryHint: .notDirectory)
        }
    }

    struct State: Equatable, Hashable, Codable {
        var currentTrackURL: URL?
        var currentTrackElapsedTime: TimeInterval = .zero
        var playbackMode: PlaybackMode = Defaults[.defaultPlaybackMode]
        var playbackLooping: Bool = false
    }

    struct Info: Equatable, Hashable, Codable {
        var title: String = ""
        var description: String = ""
    }

    struct Artwork: Equatable, Hashable, Codable {
        var tiffRepresentation: Data?

        var image: NSImage? {
            guard let tiffRepresentation else { return nil }
            return NSImage(data: tiffRepresentation)
        }
    }
}

extension Playlist {
    struct Segments {
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

            logger.info("Successfully read segments for playlist at \(url): \("\(info)"), \("\(state)"), \("\(artwork)")")
        }

        init() {
            self.init(info: .init(), state: .init(), artwork: .init())
        }
    }
}

extension Playlist.Segments: Equatable {
    static func == (lhs: Playlist.Segments, rhs: Playlist.Segments) -> Bool {
        lhs.info == rhs.info
            && lhs.state == rhs.state
            && lhs.artwork == rhs.artwork
    }
}

extension Playlist.Segments: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(info)
        hasher.combine(state)
        hasher.combine(artwork)
    }
}

extension Playlist.Segments {
    static func read(segment: Playlist.Segment, fromDirectory root: URL) throws -> Data {
        let url = segment.url(relativeTo: root)
        return try Data(contentsOf: url)
    }

    static func write(segment: Playlist.Segment, ofData fileData: Data, toDirectory root: URL) throws {
        let url = segment.url(relativeTo: root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try fileData.write(to: url)
    }
}
