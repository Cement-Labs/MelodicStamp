//
//  Playlist+Canonical.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/6.
//

import AppKit

extension CanonicalPlaylist: TypeNameReflectable {}

struct CanonicalPlaylist: Playlist {
    typealias Track = CanonicalTrack

    let id: UUID
    var cache: CacheSegments
    var indexer: TrackIndexer

    private(set) var tracks: [Track] = []
    var currentTrack: Track?

    var playbackMode: PlaybackMode = .loop
    var playbackLooping: Bool = false

    init(id: UUID) {
        let url = Self.url(forID: id)
        self.id = id
        self.indexer = .init(playlistID: id)
        self.cache = (try? .init(loadingFrom: url)) ?? .init()
    }
}

extension CanonicalPlaylist {
    static func url(forID id: UUID) -> URL {
        URL.playlists.appending(component: id.uuidString, directoryHint: .isDirectory)
    }

    var url: URL { Self.url(forID: id) }
}

extension CanonicalPlaylist {
    func write(segments: [CacheSegmentIndex] = CacheSegmentIndex.allCases) throws {
        guard !segments.isEmpty else { return }

        for segment in segments {
            let data = switch segment {
            case .info:
                try JSONEncoder().encode(cache.info)
            case .state:
                try JSONEncoder().encode(cache.state)
            case .artwork:
                try JSONEncoder().encode(cache.artwork)
            }
            try CacheSegments.write(segment: segment, ofData: data, toDirectory: url)
        }

        logger.info("Successfully written cache segments \(segments) for playlist at \(url)")

        if segments.contains(.artwork) {
            updateFolderIcon()
        }
    }

    private func updateFolderIcon() {
        Task.detached(priority: .background) {
            NSWorkspace.shared.setIcon(
                cache.artwork.image?.squared(),
                forFile: url.standardizedFileURL.path(percentEncoded: false)
            )
            logger.info("Successfully updated folder icon for playlist at \(url)")
        }
    }
}
