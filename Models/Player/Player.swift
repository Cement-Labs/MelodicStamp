//
//  Player.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/31.
//

import CAAudioHardware
import CSFBAudioEngine
import Foundation
import SFSafeSymbols

protocol Player {
    var delegate: (any PlayerDelegate)? { get set }

    var isPlaying: Bool { get }
    var isRunning: Bool { get }
    var isMuted: Bool { get }

    var playbackState: PlaybackState { get }
    var playbackTime: PlaybackTime? { get }
    var playbackVolume: CGFloat { get }

    func play(_ track: any Track)
    func enqueue(_ track: any Track)

    func play()
    func pause()
    func stop()
    func mute()
    func unmute()

    func setPlaying(_ playing: Bool)
    func togglePlaying()
    func setMuted(_ muted: Bool)
    func toggleMuted()

    func seekTime(to time: TimeInterval)
    func seekProgress(to progress: CGFloat)
    func seekVolume(to volume: CGFloat)

    func withEngine(_ block: @escaping (AVAudioEngine) -> ())

    func availableOutputDevices() throws -> [AudioDevice]
    func defaultOutputDevice() throws -> AudioDevice?
    func defaultSystemOutputDevice() throws -> AudioDevice?

    func selectedOutputDevice() throws -> AudioDevice?
    func selectOutputDevice(_ device: AudioDevice) throws
}

extension Player {
    var playbackState: PlaybackState {
        if isRunning {
            if isPlaying {
                .playing
            } else {
                .paused
            }
        } else {
            .stopped
        }
    }

    func setPlaying(_ playing: Bool) {
        if playing {
            play()
        } else {
            pause()
        }
    }

    func togglePlaying() {
        setPlaying(!isPlaying)
    }

    func setMuted(_ muted: Bool) {
        if muted {
            mute()
        } else {
            unmute()
        }
    }

    func toggleMuted() {
        setMuted(!isMuted)
    }
}

protocol PlayerDelegate {
    func playerDidFinishPlaying(_ player: some Player)
}

// - Blank Implementations

class BlankPlayer: Player {
    var delegate: (any PlayerDelegate)?

    var isPlaying: Bool = false
    var isRunning: Bool = true
    var isMuted: Bool = false

    var playbackTime: PlaybackTime? = .init(duration: .seconds(60), elapsed: .zero)
    var playbackVolume: CGFloat = 1

    func play(_: any Track) {
        isPlaying = true
    }

    func enqueue(_: any Track) {}

    func play() {
        isPlaying = true
    }

    func pause() {
        isPlaying = false
    }

    func stop() {
        isPlaying = false
    }

    func mute() {
        isMuted = true
    }

    func unmute() {
        isMuted = false
    }

    func seekTime(to time: TimeInterval) {
        playbackTime = .init(duration: .seconds(60), elapsed: time)
    }

    func seekProgress(to progress: CGFloat) {
        playbackTime = .init(duration: .seconds(60), elapsed: progress * TimeInterval(Duration.seconds(60)))
    }

    func seekVolume(to volume: CGFloat) {
        playbackVolume = volume
    }

    func withEngine(_: @escaping (AVAudioEngine) -> ()) {}

    func availableOutputDevices() throws -> [AudioDevice] {
        try [.defaultOutputDevice]
    }

    func defaultOutputDevice() throws -> AudioDevice? {
        try .defaultOutputDevice
    }

    func defaultSystemOutputDevice() throws -> AudioDevice? {
        try .defaultSystemOutputDevice
    }

    func selectedOutputDevice() throws -> AudioDevice? {
        try .defaultOutputDevice
    }

    func selectOutputDevice(_: AudioDevice) throws {}
}
