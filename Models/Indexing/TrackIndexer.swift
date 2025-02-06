//
//  TrackIndexer.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/29.
//

import Collections
import Foundation

struct TrackIndexer: Indexer {
    let playlistID: UUID
    var folderURL: URL {
        .playlists.appending(path: playlistID.uuidString, directoryHint: .isDirectory)
    }

    // The keys are the file names, while the values are the path extensions
    var value: OrderedDictionary<UUID, String> = [:]
}

extension TrackIndexer {
    func trackURL(for element: Value.Element) -> URL {
        folderURL
            .appending(path: element.key.uuidString, directoryHint: .notDirectory)
            .appendingPathExtension(element.value)
    }

    func loadTracks() -> AsyncStream<(Int, CanonicalTrack)> {
        .init {
            continuation in
            guard !value.isEmpty else { return continuation.finish() }

            Task.detached {
                for (index, element) in value.enumerated() {
//                    let track = await CanonicalTrack(loadingFrom: trackURL(for: element))
//                    continuation.yield((index, track))
                }
            }
        }
    }
}
