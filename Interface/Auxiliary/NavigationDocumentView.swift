//
//  NavigationDocumentView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/2.
//

import SwiftUI

struct NavigationDocumentView: View {
    @Environment(PlaylistModel.self) private var playlist
    @Environment(PlayerModel.self) private var player

    var body: some View {
        if player.isCurrentTrackPlayable, let track = playlist.currentTrack {
            Color.clear
                .navigationDocument(track.url)
        } else if playlist.mode.isCanonical {
            Color.clear
                .navigationDocument(playlist.url)
        } else {
            Color.clear
        }
    }
}
