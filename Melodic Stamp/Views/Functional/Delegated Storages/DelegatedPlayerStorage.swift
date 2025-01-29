//
//  DelegatedPlayerStorage.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/12.
//

import Defaults
import SwiftUI

extension DelegatedPlayerStorage: TypeNameReflectable {}

extension DelegatedPlayerStorage {
    enum DelegatedPlaylist: Equatable, Hashable, Codable {
        case handled
        case unhandled(
            bookmarks: [Data],
            currentTrackURL: URL?,
            currentTrackElapsedTime: TimeInterval,
            playbackMode: PlaybackMode,
            playbackLooping: Bool
        )
    }
}

struct DelegatedPlayerStorage: View {
    @Environment(PlayerModel.self) private var player

    // MARK: Storages

    @SceneStorage(AppSceneStorage.playlist()) private var playlist: Data?

    @SceneStorage(AppSceneStorage.playbackVolume()) private var playbackVolume: Double?
    @SceneStorage(AppSceneStorage.playbackMuted()) private var playbackMuted: Bool?

    // MARK: States

    @State private var playlistState: DelegatedStorageState<Data?> = .init()

    @State private var playbackVolumeState: DelegatedStorageState<Double?> = .init()
    @State private var playbackMutedState: DelegatedStorageState<Bool?> = .init()

    var body: some View {
        ZStack {
            playlistObservations()
            playbackVolumeObservations()
        }
        .onAppear {
            playlistState.isReady = true
        }
    }

    // MARK: Playlist

    @ViewBuilder private func playlistObservations() -> some View {
        Color.clear
            .onChange(of: playlist) { _, newValue in
                playlistState.value = newValue
            }
            .onChange(of: player.playlist) { _, newValue in
                print(newValue)
                playlistState.isReady = false

                Task {
                    try storePlaylist(from: newValue)
                }
            }
            .onChange(of: playlistState.preparedValue) { _, newValue in
                guard let newValue else { return }

                if let data = newValue {
                    Task {
                        try restorePlaylist(from: data)

                        logger.log("Successfully restored playlist")

                        // Dependents
                        playbackVolumeState.isReady = true
                        playbackMutedState.isReady = true
                    }
                }

                playlistState.isReady = false
            }
    }

    // MARK: Playback Volume

    @ViewBuilder private func playbackVolumeObservations() -> some View {
        Color.clear
            .onChange(of: playbackVolume) { _, newValue in
                playbackVolumeState.value = newValue
            }
            .onChange(of: player.volume) { _, newValue in
                playbackVolumeState.isReady = false
                playbackVolume = newValue
            }
            .onChange(of: playbackVolumeState.preparedValue) { _, newValue in
                guard let newValue else { return }

                if let volume = newValue {
                    player.volume = volume

                    logger.log("Successfully restored playback volume to \(volume)")
                }

                playbackVolumeState.isReady = false
            }

            .onChange(of: playbackMuted) { _, newValue in
                playbackMutedState.value = newValue
            }
            .onChange(of: player.isMuted) { _, newValue in
                playbackMutedState.isReady = false
                playbackMuted = newValue
            }
            .onChange(of: playbackMutedState.preparedValue) { _, newValue in
                guard let newValue else { return }

                if let isMuted = newValue {
                    player.isMuted = isMuted

                    logger.log("Successfully restored playback muted state to \(isMuted)")
                }

                playbackMutedState.isReady = false
            }
    }

    private func restorePlaylist(from data: Data) throws {
        guard let delegatedPlaylist = try? JSONDecoder().decode(DelegatedPlaylist.self, from: data) else { return }
        switch delegatedPlaylist {
        case .handled:
            break
        case let .unhandled(bookmarks, currentTrackURL, currentTrackElapsedTime, playbackMode, playbackLooping):
            guard !player.playlist.mode.isCanonical else { break }

            try bookmarks.forEach {
                var isStale = false
                let url = try URL(resolvingBookmarkData: $0, options: [], bookmarkDataIsStale: &isStale)
                guard !isStale else { return }
                player.addToPlaylist([url])
            }

            player[playlistMetadata: \.state] = .init(
                currentTrackURL: currentTrackURL,
                currentTrackElapsedTime: currentTrackElapsedTime,
                playbackMode: playbackMode,
                playbackLooping: playbackLooping
            )
        }
    }

    private func storePlaylist(from playlist: Playlist) throws {
        let delegatedPlaylist: DelegatedPlaylist
        switch playlist.mode {
        case .canonical:
            delegatedPlaylist = .handled
        case .referenced:
            let bookmarks: [Data] = try playlist.map(\.url).compactMap { url in
                try url.bookmarkData(options: [])
            }

            delegatedPlaylist = .unhandled(
                bookmarks: bookmarks,
                currentTrackURL: playlist[metadata: \.state].currentTrackURL,
                currentTrackElapsedTime: playlist[metadata: \.state].currentTrackElapsedTime,
                playbackMode: playlist[metadata: \.state].playbackMode,
                playbackLooping: playlist[metadata: \.state].playbackLooping
            )
        }
        self.playlist = try? JSONEncoder().encode(delegatedPlaylist)
    }
}
