//
//  PlaybackState.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/25.
//

import Foundation
import MediaPlayer

enum PlaybackState: String, Equatable, Hashable, CaseIterable, Identifiable, Codable {
    case playing
    case paused
    case stopped

    var id: Self { self }
}

extension PlaybackState {
    init(_ playbackState: MPNowPlayingPlaybackState) {
        self = switch playbackState {
        case .playing: .playing
        case .paused: .paused
        case .stopped: .stopped
        default: .stopped
        }
    }
}

extension MPNowPlayingPlaybackState {
    init(_ playbackState: PlaybackState) {
        self = switch playbackState {
        case .playing: .playing
        case .paused: .paused
        case .stopped: .stopped
        }
    }
}
