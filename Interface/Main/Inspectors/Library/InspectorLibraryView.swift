//
//  InspectorLibraryView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/28.
//

import QuickLook
import SwiftUI

struct InspectorLibraryView: View {
    // MARK: - Environments

    @Environment(LibraryModel.self) private var library

    @Environment(\.openWindow) private var openWindow
    @Environment(\.appearsActive) private var appearsActive

    // MARK: - Fields

    @State private var selectedPlaylists: Set<Playlist> = []
    @State private var quickLookSelection: URL?

    // MARK: - Body

    var body: some View {
        if library.isLoadedPlaylistsEmpty {
            ExcerptView(tab: SidebarInspectorTab.library)
        } else {
            List(selection: $selectedPlaylists) {
                // MARK: Playlists

                ForEach(library.playlists) { playlist in
                    playlistView(for: playlist)
                        .id(playlist)
                }
                .onMove { indices, destination in
                    withAnimation {
                        library.move(fromOffsets: indices, toOffset: destination)
                    }
                }
                .transition(.slide)
            }
            .scrollClipDisabled()
            .scrollContentBackground(.hidden)
            .contextMenu(forSelectionType: Playlist.self) { playlists in
                PlaylistsContextMenu(playlists: playlists)
            } primaryAction: { playlists in
                open(Array(playlists))
            }

            // MARK: Quick Look

            .quickLookPreview($quickLookSelection, in: library.playlists.map(\.url))
            .onChange(of: selectedPlaylists) { _, newValue in
                guard quickLookSelection != nil else { return }
                guard newValue.count == 1 else {
                    quickLookSelection = nil
                    return
                }
                quickLookSelection = newValue.first?.url
            }

            // MARK: Keyboard Handlers

            // Handles [escape] -> clear selection
            .onKeyPress(.escape) {
                if handleEscape() {
                    .handled
                } else {
                    .ignored
                }
            }

            // Handles [⏎] -> open selection
            .onKeyPress(.return) {
                guard !selectedPlaylists.isEmpty else { return .ignored }

                open(Array(selectedPlaylists))
                return .handled
            }

            // Handles [space] -> quick look
            .onKeyPress(.space) {
                if quickLookSelection != nil {
                    quickLookSelection = nil
                    return .handled
                } else if selectedPlaylists.count == 1 {
                    quickLookSelection = selectedPlaylists.first?.url
                    return .handled
                } else {
                    return .ignored
                }
            }
        }
    }

    private var canEscape: Bool {
        !selectedPlaylists.isEmpty
    }

    // MARK: - Playlist View

    @ViewBuilder private func playlistView(for playlist: Playlist) -> some View {
        let isSelected = selectedPlaylists.contains(playlist)

        LibraryItemView(
            item: playlist,
            isSelected: isSelected
        )
        .swipeActions(edge: .leading) {
            // MARK: Open

            Button {
                open([playlist])
            } label: {
                Image(systemSymbol: .rectangleStackFill)
            }
            .tint(.accent)
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

    @discardableResult private func handleEscape() -> Bool {
        guard canEscape else { return false }
        selectedPlaylists.removeAll()
        return true
    }
}

#if DEBUG

    // MARK: - Preview

    #Preview(traits: .modifier(PreviewEnvironmentsModifier())) {
        InspectorLibraryView()
    }
#endif
