//
//  PlaylistIndexer.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/29.
//

import Foundation

struct PlaylistIndexer: Indexer {
    var folderURL: URL { .playlists }

    var value: [UUID] = []
}

extension PlaylistIndexer {
    func loadPlaylists() -> AsyncStream<Playlist> {
        .init { continuation in
            guard !value.isEmpty else { return continuation.finish() }

            Task {
                for element in value {
                    guard let playlist = await Playlist(loadingWith: element) else { continue }
                    continuation.yield(playlist)
                }

                continuation.finish()
            }
        }
    }
}
