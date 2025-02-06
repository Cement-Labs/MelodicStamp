//
//  KeyboardControlModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/8.
//

import SwiftUI

@Observable final class KeyboardControlModel {
    private weak var player: PlayerModel?

    var previousSongButtonBounceAnimation: Bool = false
    var nextSongButtonBounceAnimation: Bool = false
    var speakerButtonBounceAnimation: Bool = false

    var isPressingSpace: Bool = false
    var progressBarExternalOvershootSign: OvershootSign = .none
    var volumeBarExternalOvershootSign: OvershootSign = .none

    init(player: PlayerModel) {
        self.player = player
    }

    @MainActor @discardableResult func handlePlayPause(
        phase: KeyPress.Phases, modifiers: EventModifiers = []
    ) -> KeyPress.Result {
        guard let player else { return .ignored }
        guard player.hasCurrentTrack else { return .ignored }

        switch phase {
        case .all:
            handlePlayPause(phase: .down, modifiers: modifiers)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.handlePlayPause(phase: .up, modifiers: modifiers)
            }
            return .handled
        case .down:
            guard !isPressingSpace else { return .ignored }

            player.togglePlayPause()
            isPressingSpace = true
            return .handled
        case .up:
            isPressingSpace = false
            return .handled
        default:
            return .ignored
        }
    }

    @MainActor @discardableResult func handleProgressAdjustment(
        phase: KeyPress.Phases, modifiers: EventModifiers = [], sign: FloatingPointSign
    ) -> KeyPress.Result {
        guard let player else { return .ignored }
        switch phase {
        case .all:
            handleProgressAdjustment(phase: .down, modifiers: modifiers, sign: sign)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.handleProgressAdjustment(phase: .up, modifiers: modifiers, sign: sign)
            }
            return .handled
        case .down, .repeat:
            guard player.isCurrentTrackPlayable else { return .ignored }

            if modifiers.contains(.command) {
                switch sign {
                case .plus:
                    player.playNextTrack()
                    nextSongButtonBounceAnimation.toggle()
                case .minus:
                    player.playPreviousTrack()
                    previousSongButtonBounceAnimation.toggle()
                }

                return .handled
            }

            let hasShift = modifiers.contains(.shift)
            let hasOption = modifiers.contains(.option)
            let multiplier: CGFloat = if hasShift, !hasOption {
                5
            } else if hasOption, !hasShift {
                0.1
            } else { 1 }

            let inRange = player.adjustTime(multiplier: multiplier, sign: sign)

            if !inRange {
                progressBarExternalOvershootSign = .init(sign)
            }

            return .handled
        case .up:
            progressBarExternalOvershootSign = .none
            return .handled
        default:
            return .ignored
        }
    }

    @MainActor @discardableResult func handleVolumeAdjustment(
        phase: KeyPress.Phases, modifiers: EventModifiers = [], sign: FloatingPointSign
    ) -> KeyPress.Result {
        guard let player else { return .ignored }
        switch phase {
        case .all:
            handleVolumeAdjustment(phase: .down, modifiers: modifiers, sign: sign)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.handleVolumeAdjustment(phase: .up, modifiers: modifiers, sign: sign)
            }
            return .ignored
        case .down, .repeat:
            guard player.isCurrentTrackPlayable else { return .ignored }

            let hasShift = modifiers.contains(.shift)
            let hasOption = modifiers.contains(.option)
            let multiplier: CGFloat = if hasShift, !hasOption {
                5
            } else if hasOption, !hasShift {
                0.1
            } else { 1 }

            let inRange = player.adjustVolume(multiplier: multiplier, sign: sign)

            if !inRange {
                volumeBarExternalOvershootSign = .init(sign)
                speakerButtonBounceAnimation.toggle()
            }

            return .handled
        case .up:
            volumeBarExternalOvershootSign = .none
            return .handled
        default:
            return .ignored
        }
    }
}
