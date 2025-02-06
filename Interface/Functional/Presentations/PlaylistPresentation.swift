//
//  PlaylistPresentation.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/1.
//

import SwiftUI

struct PlaylistPresentation: View {
    @Environment(LibraryModel.self) private var library
    @Environment(WindowManagerModel.self) private var windowManager
    @Environment(PresentationManagerModel.self) private var presentationManager
    @Environment(PlaylistModel.self) private var playlist

    var body: some View {
        @Bindable var presentationManager = presentationManager

        Color.clear
            .sheet(isPresented: $presentationManager.isPlaylistSegmentsSheetPresented) {
                PlaylistMetadataView()
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, -8)
                    .presentationAttachmentBar(edge: .bottom) {
                        Group {
                            Text("Playlist Information")

                            Spacer()

                            Button {
                                presentationManager.isPlaylistSegmentsSheetPresented = false
                            } label: {
                                Text("Done")
                            }
                            .foregroundStyle(.tint)
                        }
                        .buttonStyle(.alive)
                    }
                    .frame(width: 600)
            }
            .alert("Removing Playlist from Library", isPresented: $presentationManager.isPlaylistRemovalAlertPresented) {
                Button("Proceed", role: .destructive) {
                    library.remove([playlist.playlist])
                    close()
                }
            } message: {
                Text("This will permanently delete the corresponding directory.")
            }
            .alert("Removing All Tracks from Playlist", isPresented: $presentationManager.isTrackRemovalAlertPresented) {
                Button("Proceed", role: .destructive) {
                    Task {
                        await playlist.clear()
                        presentationManager.nextStep()
                    }
                }
            }
    }

    private func close() {
        presentationManager.state = .idle
        windowManager.state = .willClose
    }
}
