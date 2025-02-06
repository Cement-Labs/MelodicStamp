//
//  Playlist+Referenced.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/6.
//

import Defaults
import Foundation

struct ReferencedPlaylist: Playlist {
    typealias Track = ReferencedTrack

    let id: UUID

    private(set) var tracks: [Track] = []
    var currentTrack: Track?

    var playbackMode: PlaybackMode = Defaults[.defaultPlaybackMode]
    var playbackLooping: Bool = false

    init(id: UUID) {
        self.id = id
    }
}
