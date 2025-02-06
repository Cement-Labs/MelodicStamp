//
//  SFBAudioEngine+PlaybackState.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/25.
//

import Foundation
import SFBAudioEngine

extension PlaybackState {
    init(_ playbackState: AudioPlayer.PlaybackState) {
        self = switch playbackState {
        case .playing: .playing
        case .paused: .paused
        case .stopped: .stopped
        @unknown default: .stopped
        }
    }
}

extension AudioPlayer.PlaybackState {
    init(_ playbackState: PlaybackState) {
        self = switch playbackState {
        case .playing: .playing
        case .paused: .paused
        case .stopped: .stopped
        }
    }
}
