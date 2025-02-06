//
//  ModifiedMetadataList.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/26.
//

import SwiftUI

struct ModifiedMetadataList: View {
    @Environment(PlaylistModel.self) private var playlist

    var body: some View {
        List {
            ForEach(tracks) { track in
                Section {
                    HStack {
                        TrackPreview(track: track, titleEntry: \.current)

                        Spacer()

                        Button("Save") {
                            Task {
                                try await track.metadata.write()
                            }
                        }
                        .buttonStyle(.borderless)
                        .disabled(!track.metadata.state.isFine)
                        .foregroundStyle(.accent)
                    }
                } header: {
                    Text(track.url.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowSeparator(.hidden)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var tracks: [Track] {
        playlist.tracks
            .filter(\.metadata.isModified)
    }
}

#if DEBUG
    #Preview(traits: .modifier(PreviewEnvironmentsModifier())) {
        ModifiedMetadataList()
    }
#endif
