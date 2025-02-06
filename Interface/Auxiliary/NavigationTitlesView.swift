//
//  NavigationTitlesView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/2.
//

import Defaults
import SwiftUI

struct NavigationTitlesView: View {
    @Environment(PlaylistModel.self) private var playlist
    @Environment(PlayerModel.self) private var player

    @Default(.dynamicTitleBar) private var dynamicTitleBar

    var body: some View {
        Color.clear
            .navigationTitle(title)
            .navigationSubtitle(subtitle)
    }

    // MARK: - Title

    private var title: String {
        trackTitle ?? playlistTitle ?? Bundle.main[localized: .displayName]
    }

    private var trackTitle: String? {
        if player.isCurrentTrackPlayable, let track = playlist.currentTrack {
            switch dynamicTitleBar {
            case
                .always,
                .whilePlaying where player.isPlaying:
                MusicTitle.stringifiedTitle(mode: .title, for: track)
            default:
                nil
            }
        } else {
            nil
        }
    }

    private var playlistTitle: String? {
        let title = playlist.segments.info.title
        return if playlist.mode.isCanonical, !title.isEmpty {
            title
        } else {
            nil
        }
    }

    // MARK: - Subtitle

    private var subtitle: String {
        trackSubtitle ?? playlistSubtitle ?? ""
    }

    private var trackSubtitle: String? {
        if player.isCurrentTrackPlayable, let track = playlist.currentTrack {
            switch dynamicTitleBar {
            case
                .always,
                .whilePlaying where player.isPlaying:
                MusicTitle.stringifiedTitle(mode: .artists, for: track)
            default:
                nil
            }
        } else {
            nil
        }
    }

    private var playlistSubtitle: String? {
        if !playlist.isEmpty {
            String(localized: "\(playlist.count) Tracks")
        } else {
            nil
        }
    }
}
