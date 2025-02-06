//
//  PlayerModel+NowPlaying.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/22.
//

import Foundation
import MediaPlayer

extension PlayerModel {
    func updateNowPlayingState(with playbackState: PlaybackState) {
        let infoCenter = MPNowPlayingInfoCenter.default()

        infoCenter.playbackState = .init(playbackState)
    }

    func updateNowPlayingInfo(with playbackState: PlaybackState) {
        let infoCenter = MPNowPlayingInfoCenter.default()
        var info = infoCenter.nowPlayingInfo ?? .init()

        switch playbackState {
        case .playing, .paused:
            info[MPMediaItemPropertyPlaybackDuration] = TimeInterval(unwrappedPlaybackTime.duration)
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = unwrappedPlaybackTime.elapsed
        case .stopped:
            info[MPMediaItemPropertyPlaybackDuration] = nil
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = nil
        }

        infoCenter.nowPlayingInfo = info
    }

    func updateNowPlayingMetadataInfo(from track: Track?) {
        Task { @MainActor in
            if let track {
                track.metadata.updateNowPlayingInfo()
            } else {
                Metadata.resetNowPlayingInfo()
            }
        }
    }

    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play
        commandCenter.playCommand.addTarget { [unowned self] _ in
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }

            if isPlaying {
                return .commandFailed
            } else {
                play()
                return .success
            }
        }

        // Pause
        commandCenter.pauseCommand.addTarget { [unowned self] _ in
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }

            if !isPlaying {
                return .commandFailed
            } else {
                pause()
                return .success
            }
        }

        // Toggle play pause
        commandCenter.togglePlayPauseCommand.addTarget { [unowned self] _ in
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }

            togglePlayPause()
            return .success
        }

        // Skip forward
        commandCenter.skipForwardCommand.preferredIntervals = [1.0, 5.0, 15.0]
        commandCenter.skipForwardCommand.addTarget { [unowned self] event in
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }

            adjustTime(delta: event.interval, sign: .plus)
            return .success
        }

        // Skip backward
        commandCenter.skipBackwardCommand.preferredIntervals = [1.0, 5.0, 15.0]
        commandCenter.skipBackwardCommand.addTarget { [unowned self] event in
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }

            adjustTime(delta: event.interval, sign: .minus)
            return .success
        }

        // Seek
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }

            progress = event.positionTime / TimeInterval(unwrappedPlaybackTime.duration)
            return .success
        }

        // Next track
        commandCenter.nextTrackCommand.addTarget { [unowned self] _ in
            guard hasNextTrack else { return .noSuchContent }

            playNextTrack()
            return .success
        }

        // Previous track
        commandCenter.previousTrackCommand.addTarget { [unowned self] _ in
            guard hasPreviousTrack else { return .noSuchContent }

            playPreviousTrack()
            return .success
        }
    }
}
