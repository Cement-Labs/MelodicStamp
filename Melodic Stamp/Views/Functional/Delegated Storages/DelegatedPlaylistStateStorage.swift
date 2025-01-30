//
//  DelegatedPlaylistStateStorage.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/30.
//

import SwiftUI

struct DelegatedPlaylistStateStorage: View {
    @Environment(PlayerModel.self) private var player

    var body: some View {
        ZStack {
            stateObservations()
        }
    }

    @ViewBuilder private func stateObservations() -> some View {
        Color.clear
            .onChange(of: player.playlistSegments.state) { _, _ in
                guard player.playlist.mode.isCanonical else { return }
                Task.detached {
                    try await player.playlist.write(segments: [.state])
                }
            }
    }
}
