//
//  UnsavedPlaylistPresentation.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/1.
//

import SwiftUI

struct UnsavedPlaylistPresentation: View {
    @Environment(PresentationManagerModel.self) private var presentationManager
    @Environment(PlaylistModel.self) private var playlist

    var body: some View {
        @Bindable var presentationManager = presentationManager

        if playlist.canMakeCanonical {
            Color.clear
                .alert("Unsaved Playlist", isPresented: $presentationManager.isUnsavedPlaylistAlertPresented) {
                    Button("Add to Library") {
                        Task {
                            try? await playlist.makeCanonical() // Do not fail hard
                            presentationManager.nextStage()
                        }
                    }

                    Button("Proceed Anyway", role: .destructive) {
                        presentationManager.nextStage()
                    }

                    Button("Cancel", role: .cancel) {
                        presentationManager.cancelStaging()
                    }
                }
        } else {
            Color.clear
                .onChange(of: presentationManager.state) { _, newValue in
                    guard newValue == .unsavedPlaylistAlert else { return }
                    presentationManager.nextStage()
                }
        }
    }
}
