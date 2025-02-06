//
//  TracksContextMenu.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/2/2.
//

import SwiftUI

struct TracksContextMenu: View {
    @Environment(FileManagerModel.self) private var fileManager
    @Environment(PlaylistModel.self) private var playlist
    @Environment(PlayerModel.self) private var player

    var tracks: Set<Track>

    var body: some View {
        if tracks.isEmpty {
            emptyActions()
        } else if tracks.count == 1, let track = tracks.first {
            singularActions(track)
        } else if tracks.count > 1 {
            pluralActions(tracks)
        }
    }

    // MARK: - Empty

    @ViewBuilder private func emptyActions() -> some View {
        // MARK: Open

        Button("Open in Playlist") {
            fileManager.emitOpen(style: .inCurrentPlaylist)
        }

        // MARK: Add

        Button("Add to Playlist") {
            fileManager.emitAdd(style: .toCurrentPlaylist)
        }
    }

    // MARK: - Singular

    @ViewBuilder private func singularActions(_ track: Track) -> some View {
        let isLoaded = track.metadata.state.isLoaded
        let isModified = track.metadata.isModified

        let title = MusicTitle.stringifiedTitle(mode: .title, for: track)

        // MARK: Play

        Button {
            player.play(track)
        } label: {
            if playlist.currentTrack == track {
                Text("Replay \(title)")
            } else {
                Text("Play \(title)")
            }
        }
        .disabled(!isLoaded)
        .keyboardShortcut(.return, modifiers: [])

        if playlist.mode.isCanonical {
            // MARK: Copy

            Button("Copy Track") {
                Task {
                    await copy([track])
                }
            }
        }

        // MARK: Remove from Playlist

        Button("Remove from Playlist") {
            Task {
                await playlist.remove([track.url])
            }
        }
        .keyboardShortcut(.deleteForward, modifiers: [])

        Divider()

        // MARK: Save Metadata

        Button("Save Metadata") {
            Task {
                try await track.metadata.write()
            }
        }
        .disabled(!isLoaded || !isModified)
        .keyboardShortcut("s", modifiers: .command)

        // MARK: Restore Metadata

        Button("Restore Metadata") {
            track.metadata.restore()
        }
        .disabled(!isLoaded || !isModified)

        // MARK: Reload Metadata

        Button("Reload Metadata") {
            Task {
                try await track.metadata.update()
            }
        }
        .keyboardShortcut("r", modifiers: .command)

        Divider()

        Button("Reveal in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting([track.url])
        }
    }

    // MARK: - Plural

    @ViewBuilder private func pluralActions(_ tracks: Set<Track>) -> some View {
        let hasInitializedTrack = tracks.contains(where: \.metadata.state.isLoaded)
        let hasModifiedTrack = tracks.contains(where: \.metadata.isModified)

        if playlist.mode.isCanonical {
            // MARK: Copy

            Button("Copy \(tracks.count) Tracks") {
                Task {
                    await copy(Array(tracks))
                }
            }
        }

        // MARK: Remove from Playlist

        Button("Remove \(tracks.count) Tracks from Playlist") {
            Task {
                await playlist.remove(tracks.map(\.url))
            }
        }
        .keyboardShortcut(.deleteForward, modifiers: [])

        Divider()

        // MARK: Save Metadata

        Button("Save Metadata") {
            for track in tracks {
                Task {
                    try await track.metadata.write()
                }
            }
        }
        .disabled(!hasInitializedTrack || !hasModifiedTrack)
        .keyboardShortcut("s", modifiers: .command)

        // MARK: Restore Metadata

        Button("Restore Metadata") {
            for track in tracks {
                track.metadata.restore()
            }
        }
        .disabled(!hasInitializedTrack || !hasModifiedTrack)

        // MARK: Reload Metadata

        Button("Reload Metadata") {
            for track in tracks {
                Task {
                    try await track.metadata.update()
                }
            }
        }
        .keyboardShortcut("r", modifiers: .command)

        Divider()

        Button("Reveal in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting(tracks.map(\.url))
        }
    }

    // MARK: - Functions

    private func copy(_ tracks: [Track]) async {
        guard !tracks.isEmpty else { return }

        for track in tracks {
            guard
                let index = playlist.tracks.firstIndex(where: { $0.id == track.id }),
                let copiedTrack = await playlist.createTrack(from: track.url)
            else { continue }
            await playlist.add([copiedTrack.url], at: index + 1)
        }
    }
}
