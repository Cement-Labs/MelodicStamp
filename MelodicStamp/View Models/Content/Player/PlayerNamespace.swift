//
//  PlayerNamespace.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/20.
//

import SwiftUI

enum PlayerNamespace: String, Equatable, Hashable, CaseIterable, Identifiable, Codable {
    case title
    case progressBar
    case volumeBar

    case playPauseButton
    case previousSongButton
    case nextSongButton
    case volumeButton
    case playlistButton

    case timeText
    case durationText

    case playbackModeButton
    case playbackLoopingButton
    case expandShrinkButton

    var id: Self { self }
}
