//
//  WindowTerminationPresentationInjector.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/26.
//

import SwiftUI

struct WindowTerminationPresentationInjector: View {
    @Environment(WindowManagerModel.self) private var windowManager
    @Environment(PresentationManagerModel.self) private var presentationManager
    @Environment(PlaylistModel.self) private var playlist
    @Environment(PlayerModel.self) private var player

    @Environment(\.appDelegate) private var appDelegate

    var window: NSWindow?

    var body: some View {
        Color.clear
            .background(MakeCloseDelegated(shouldClose: windowShouldClose) { window, shouldClose in
                if shouldClose {
                    player.stop()
                    appDelegate?.destroy(window: window)
                } else {
                    presentationManager.startStaging()
                    appDelegate?.suspend(window: window)
                }
            })
    }

    private var hasUnsavedChanges: Bool {
        playlist.metadataSet.contains(where: \.isModified)
    }

    private var hasUnsavedPlaylist: Bool {
        playlist.canMakeCanonical
    }

    private var windowShouldClose: Bool {
        windowManager.state.shouldForceClose || (!hasUnsavedChanges && playlist.mode.isCanonical)
    }
}
