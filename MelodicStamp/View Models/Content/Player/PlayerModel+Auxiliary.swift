//
//  PlayerModel+Auxiliary.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/22.
//

import SwiftUI

extension PlayerModel {
    var speakerImage: Image {
        if isMuted {
            Image(systemSymbol: .speakerSlashFill)
        } else {
            Image(systemSymbol: .speakerWave3Fill, variableValue: volume)
        }
    }

    var playPauseImage: Image {
        if isCurrentTrackPlayable, isPlaying {
            Image(systemSymbol: .pauseFill)
        } else {
            Image(systemSymbol: .playFill)
        }
    }

    @discardableResult func adjustProgress(delta: CGFloat = 0.01, multiplier: CGFloat = 1, sign: FloatingPointSign = .plus) -> Bool {
        let adjustedMultiplier = switch sign {
        case .plus:
            multiplier
        case .minus:
            -multiplier
        }
        let progress = progress + delta * adjustedMultiplier
        self.progress = progress

        return progress >= 0 && progress <= 1
    }

    @discardableResult func adjustTime(delta: TimeInterval = 1, multiplier: CGFloat = 1, sign: FloatingPointSign = .plus) -> Bool {
        guard unwrappedPlaybackTime.duration > .zero else { return false }
        return adjustProgress(
            delta: delta / TimeInterval(unwrappedPlaybackTime.duration),
            multiplier: multiplier, sign: sign
        )
    }

    @discardableResult func adjustVolume(delta: CGFloat = 0.01, multiplier: CGFloat = 1, sign: FloatingPointSign = .plus) -> Bool {
        let multiplier = switch sign {
        case .plus:
            multiplier
        case .minus:
            -multiplier
        }
        let volume = volume + delta * multiplier
        self.volume = volume

        return volume >= 0 && volume <= 1
    }
}
