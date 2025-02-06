//
//  PlaylistsContextMenu.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/2.
//

import SwiftUI

struct PlaylistsContextMenu: View {
    @Environment(LibraryModel.self) private var library

    @Environment(\.openWindow) private var openWindow

    var playlists: Set<Playlist>

    var body: some View {
        if playlists.isEmpty {
            EmptyView()
        } else if playlists.count == 1, let playlist = playlists.first {
            singularActions(playlist)
        } else {
            pluralActions(playlists)
        }
    }

    // MARK: - Singular

    @ViewBuilder private func singularActions(_ playlist: Playlist) -> some View {
        // MARK: Open

        Group {
            Button("Open in New Window") {
                open([playlist])
            }
        }
        .keyboardShortcut(.return, modifiers: [])

        // MARK: Copy

        Button("Copy Playlist") {
            try? copy([playlist])
        }

        Divider()

        if let url = playlist.unwrappedURL {
            // MARK: Reveal in Finder

            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
    }

    // MARK: - Plural

    @ViewBuilder private func pluralActions(_ playlists: Set<Playlist>) -> some View {
        // MARK: Open

        Group {
            Button("Open \(playlists.count) Playlists") {
                open(Array(playlists))
            }
        }
        .keyboardShortcut(.return, modifiers: [])

        // MARK: Copy

        Button("Copy \(playlists.count) Playlists") {
            try? copy(Array(playlists))
        }

        Divider()

        // MARK: Reveal in Finder

        Button("Reveal in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting(playlists.compactMap(\.unwrappedURL))
        }
    }

    // MARK: - Functions

    private func open(_ playlists: [Playlist]) {
        for playlist in playlists {
            openWindow(
                id: WindowID.content(),
                value: CreationParameters(playlist: .canonical(playlist.id))
            )
        }
    }

    private func copy(_ playlists: [Playlist]) throws {
        guard !playlists.isEmpty else { return }

        for playlist in playlists {
            guard
                let index = library.playlists.firstIndex(where: { $0.id == playlist.id }),
                let copiedPlaylist = try Playlist(copyingFrom: playlist)
            else { continue }
            library.add([copiedPlaylist], at: index + 1)
        }
    }
}
