//
//  PlaylistView.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/22.
//

import AppKit
import Luminare
import SFSafeSymbols
import SwiftUI

struct PlaylistView: View {
    // MARK: - Environments

    @Environment(PresentationManagerModel.self) private var presentationManager
    @Environment(KeyboardControlModel.self) private var keyboardControl
    @Environment(PlaylistModel.self) private var playlist
    @Environment(PlayerModel.self) private var player
    @Environment(MetadataEditorModel.self) private var metadataEditor

    @Environment(\.resetFocus) private var resetFocus
    @Environment(\.luminareMinHeight) private var minHeight
    @Environment(\.luminareAnimation) private var animation
    @Environment(\.luminareAnimationFast) private var animationFast
    @Environment(\.namespace) private var namespace

    // MARK: - Body

    var body: some View {
        @Bindable var playlist = playlist

        Group {
            if playlist.isEmpty {
                // MARK: Excerpt

                VStack(spacing: 0) {
                    // MARK: Controls Placeholder

                    Spacer()
                        .frame(height: minHeight)

                    if playlist.mode.isCanonical {
                        // MARK: Metadata

                        PlaylistMetadataView()
                            .frame(height: metadataHeight)
                            .padding(.horizontal)
                    }

                    ExcerptView(tab: SidebarContentTab.playlist)
                        .expandContextMenuActivationArea()
                        .contextMenu {
                            TracksContextMenu(tracks: [])
                        }
                }
                .padding(.horizontal)
                .padding(.vertical, 14) // The inset of the `List`
            } else {
                // MARK: List

                List(selection: $playlist.selectedTracks) {
                    VStack(spacing: 0) {
                        // MARK: Controls Placeholder

                        // This is much more stable than `.contentMargins()`
                        Spacer()
                            .frame(height: minHeight)

                        if playlist.mode.isCanonical {
                            // MARK: Metadata

                            PlaylistMetadataView()
                                .frame(height: metadataHeight)
                                .padding(.horizontal)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .selectionDisabled()

                    // MARK: Tracks

                    ForEach(playlist.tracks) { track in
                        trackView(for: track)
                            .id(track)
                            .draggable(track) {
                                TrackPreview(track: track)
                            }
                    }
                    .onMove { indices, destination in
                        withAnimation {
                            playlist.move(fromOffsets: indices, toOffset: destination)
                        }
                    }
                    .transition(.slide)
                }
                .scrollClipDisabled()
                .scrollContentBackground(.hidden)
                .contextMenu(forSelectionType: Track.self) { tracks in
                    TracksContextMenu(tracks: tracks)
                } primaryAction: { tracks in
                    guard let firstTrack = tracks.first else { return }
                    player.play(firstTrack)
                }
            }
        }
        .overlay(alignment: .top) {
            // MARK: Controls

            HStack(spacing: 0) {
                Group {
                    LuminareSection(hasPadding: false) {
                        leadingActions()
                            .frame(height: minHeight)
                    }

                    Spacer()

                    LuminareSection(hasPadding: false) {
                        trailingActions()
                            .frame(height: minHeight)
                    }
                }
                .luminareBordered(false)
                .luminareButtonMaterial(.thin)
                .luminareSectionMasked(true)
                .luminareSectionMaxWidth(nil)
                .shadow(color: .black.opacity(0.1), radius: 15)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .overlay {
            if playlist.isLoading {
                loadingView()
                    .padding()
                    .ignoresSafeArea()
                    .background(.regularMaterial)
            }
        }
        .animation(animationFast, value: playlist)
        .animation(animationFast, value: playlist.selectedTracks)
        .animation(.default, value: playlist.isLoading)

        // MARK: Keyboard Handlers

        // Handles [escape] -> clear selection
        .onKeyPress(.escape) {
            if handleEscape() {
                .handled
            } else {
                .ignored
            }
        }

        // Handles [􁂒] -> remove selection
        .onKeyPress(.deleteForward) {
            if handleRemove(playlist.selectedTracks.map(\.url)) {
                .handled
            } else {
                .ignored
            }
        }

        // Handles [⏎] -> play
        .onKeyPress(.return) {
            if playlist.selectedTracks.count == 1, let track = playlist.selectedTracks.first {
                player.play(track)
                return .handled
            } else {
                return .ignored
            }
        }

        // Handles [space] -> toggle play / pause
        .onKeyPress(keys: [.space], phases: .all) { key in
            keyboardControl.handlePlayPause(
                phase: key.phase, modifiers: key.modifiers
            )
        }

        // Handles [← / →] -> adjust progress
        .onKeyPress(keys: [.leftArrow, .rightArrow], phases: .all) { key in
            let sign: FloatingPointSign = key.key == .leftArrow ? .minus : .plus

            return keyboardControl.handleProgressAdjustment(
                phase: key.phase, modifiers: key.modifiers, sign: sign
            )
        }

        // Handles [↑ / ↓] -> adjust volume
        .onKeyPress(keys: [.leftArrow, .rightArrow], phases: .all) { key in
            let sign: FloatingPointSign = key.key == .leftArrow ? .minus : .plus

            return keyboardControl.handleVolumeAdjustment(
                phase: key.phase, modifiers: key.modifiers, sign: sign
            )
        }

        // Handles [m] -> toggle muted
        .onKeyPress(keys: ["m"], phases: .down) { _ in
            player.isMuted.toggle()
            return .handled
        }
    }

    private var canEscape: Bool {
        metadataEditor.hasMetadata
    }

    private var canRemove: Bool {
        !playlist.isLoadedTracksEmpty
    }

    private var metadataHeight: CGFloat {
        switch playlist.mode {
        case .referenced:
            .zero
        case .canonical:
            300
        }
    }

    // MARK: - Leading Actions

    @ViewBuilder private func leadingActions() -> some View {
        HStack(spacing: 2) {
            // MARK: Clear Selection

            Button {
                handleEscape()
            } label: {
                Image(systemSymbol: .xmark)
            }
            .disabled(!canEscape)
            .aspectRatio(6 / 5, contentMode: .fit)

            // MARK: Remove from Playlist

            Group {
                if playlist.selectedTracks.isEmpty {
                    Button(role: .destructive) {
                        presentationManager.isTrackRemovalAlertPresented = true
                    } label: {
                        HStack {
                            Image(systemSymbol: .trashFill)

                            Text("Clear Playlist")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                } else if playlist.selectedTracks.count <= 1 {
                    Button(role: .destructive) {
                        handleRemove(playlist.selectedTracks.map(\.url))
                        resetFocus(in: namespace!)
                    } label: {
                        HStack {
                            Image(systemSymbol: .trashFill)

                            Text("Remove from Playlist")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                } else {
                    Button(role: .destructive) {
                        handleRemove(playlist.selectedTracks.map(\.url))
                        resetFocus(in: namespace!)
                    } label: {
                        HStack {
                            Image(systemSymbol: .trashFill)

                            Text("Remove \(playlist.selectedTracks.count) Tracks from Playlist")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
            .buttonStyle(.luminareProminent)
            .foregroundStyle(.red)
            .fixedSize(horizontal: true, vertical: false)
            .disabled(!canRemove)
        }
        .buttonStyle(.luminare)
    }

    // MARK: - Trailing Actions

    @ViewBuilder private func trailingActions() -> some View {
        HStack(spacing: 2) {
            // MARK: Playback Mode

            Button {
                let hasShift = NSEvent.modifierFlags.contains(.shift)
                playlist.playbackMode = playlist.playbackMode.cycle(negate: hasShift)
            } label: {
                PlaybackModeView(mode: playlist.playbackMode)
                    .padding()
            }
            .fixedSize(horizontal: true, vertical: false)

            // MARK: Playback Looping

            Button {
                playlist.playbackLooping.toggle()
            } label: {
                Image(systemSymbol: .repeat1)
                    .aliveHighlight(playlist.playbackLooping)
                    .luminareAnimation(.instant)
            }
            .aspectRatio(6 / 5, contentMode: .fit)
        }
        .buttonStyle(.luminare)
    }

    // MARK: - Track View

    @ViewBuilder private func trackView(for track: Track) -> some View {
        let isLoaded = track.metadata.state.isLoaded
        let isModified = track.metadata.isModified

        TrackView(
            track: track,
            isSelected: playlist.selectedTracks.contains(track)
        )
        .redacted(reason: track.metadata.state == .loading ? .placeholder : [])
        .swipeActions {
            if isLoaded {
                // MARK: Play

                Button {
                    player.play(track)
                } label: {
                    Image(systemSymbol: .play)
                }
                .tint(.accent)

                // MARK: Remove from Playlist

                Button(role: .destructive) {
                    handleRemove([track.url])
                } label: {
                    Image(systemSymbol: .trash)
                }
                .tint(.red)
            }
        }
        .swipeActions(edge: .leading) {
            if isLoaded {
                // MARK: Save Metadata

                if isModified {
                    Button {
                        Task {
                            try await track.metadata.write()
                        }
                    } label: {
                        Image(systemSymbol: .trayAndArrowDown)
                        Text("Save Metadata")
                    }
                    .tint(.green)
                }

                // MARK: Restore Metadata

                if isModified {
                    Button {
                        track.metadata.restore()
                    } label: {
                        Image(systemSymbol: .arrowUturnLeft)
                        Text("Restore Metadata")
                    }
                    .tint(.red)
                }

                // MARK: Reload Metadata

                Button {
                    Task {
                        try await track.metadata.update()
                    }
                } label: {
                    Image(systemSymbol: .trayAndArrowUp)
                    Text("Reload Metadata")
                }
                .tint(.accent)
            }
        }
    }

    // MARK: Loading View

    @ViewBuilder private func loadingView() -> some View {
        LoadingExcerptView(progress: playlist.loadingProgress) {
            if playlist.loadingProgress != nil {
                Text("Loading \(playlist.loadedTracksCount) of \(playlist.count) Tracks…")
            } else {
                Text("Loading Tracks…")
            }
        }
    }

    // MARK: - Functions

    @discardableResult private func handleEscape() -> Bool {
        guard canEscape else { return false }
        playlist.selectedTracks.removeAll()
        return true
    }

    @discardableResult private func handleRemove(_ urls: [URL]) -> Bool {
        guard canRemove else { return false }
        Task {
            await playlist.remove(urls)
        }
        return true
    }
}

#if DEBUG

    // MARK: - Preview

    #Preview(traits: .modifier(PreviewEnvironmentsModifier())) {
        PlaylistView()
    }
#endif
