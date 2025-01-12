//
//  PlaylistItemView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/23.
//

import CSFBAudioEngine
import SwiftUI

struct PlayableItemView: View {
    @Environment(PlayerModel.self) private var player

    var track: Track
    var isSelected: Bool

    @State private var isHovering: Bool = false

    var body: some View {
        HStack(alignment: .center) {
            let isMetadataLoaded = track.metadata.state.isLoaded
            let isMetadataModified = track.metadata.isModified

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    if isMetadataLoaded {
                        if isPlaying {
                            MarqueeScrollView(animate: false) {
                                MusicTitle(track: track)
                            }
                        } else {
                            MusicTitle(track: track)
                        }
                    } else {
                        Text("Loading…")
                            .foregroundStyle(.placeholder)
                    }
                }
                .font(.title3)
                .frame(height: 24)
                .opacity(!player.isPlayable || isPlaying ? 1 : 0.5)

                HStack(alignment: .center, spacing: 4) {
                    if isMetadataModified {
                        Circle()
                            .foregroundStyle(.tint)
                            .tint(isSelected ? .primary : .accent)
                            .padding(2)
                            .animation(nil, value: isSelected)
                    }

                    Text(track.url.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.placeholder)
                }
                .frame(height: 12)
            }
            .transition(.blurReplace)
            .animation(.default.speed(2), value: isMetadataLoaded)
            .animation(.default.speed(2), value: isMetadataModified)
            .animation(.default.speed(2), value: isPlaying)

            Spacer()

            AliveButton {
                player.play(track: track)
            } label: {
                cover(isMetadataLoaded: isMetadataLoaded)
            }
        }
        .padding(.vertical, 10)
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .onHover { hover in
            withAnimation(.default.speed(5)) {
                isHovering = hover
            }
        }
    }

    private var isPlaying: Bool {
        player.track == track
    }

    @ViewBuilder private func cover(isMetadataLoaded: Bool) -> some View {
        ZStack {
            if isMetadataLoaded, let image = track.metadata.thumbnail {
                MusicCover(
                    images: [image], hasPlaceholder: false, cornerRadius: 8
                )
                .overlay {
                    if isHovering {
                        Rectangle()
                            .foregroundStyle(.black)
                            .opacity(0.25)
                            .blendMode(.darken)
                    }
                }

                if isHovering, isMetadataLoaded {
                    Image(systemSymbol: .playFill)
                        .foregroundStyle(.white)
                }
            } else {
                if isHovering, isMetadataLoaded {
                    Image(systemSymbol: .playFill)
                        .foregroundStyle(.primary)
                }
            }
        }
        .clipShape(.rect(cornerRadius: 8))
        .frame(width: 50, height: 50)
        .font(.title3)
        .contentTransition(.symbolEffect(.replace))
    }
}
