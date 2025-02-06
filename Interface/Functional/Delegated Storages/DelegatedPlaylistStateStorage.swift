//
//  DelegatedPlaylistStateStorage.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/30.
//

import SwiftUI

struct DelegatedPlaylistStateStorage: View {
    @Environment(PlaylistModel.self) private var playlist

    var body: some View {
        ZStack {
            stateObservations()
        }
    }

    @ViewBuilder private func stateObservations() -> some View {
        Color.clear
            .onChange(of: playlist.segments.state) { _, _ in
                guard playlist.mode.isCanonical else { return }
                Task.detached {
                    try await playlist.write(segments: [.state])
                }
            }
    }
}
