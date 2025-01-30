//
//  TrackView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/23.
//

import CSFBAudioEngine
import Luminare
import SwiftUI

struct TrackView: View {
    @Environment(PlayerModel.self) private var player

    @Environment(\.luminareAnimationFast) private var animationFast

    var track: Track
    var isSelected: Bool

    @State private var isHovering: Bool = false
    @State private var isAboutToDoubleClick: Bool = false
    @State private var cancelDoubleClickDispatch: DispatchWorkItem?

    @State private var wiggleAnimationTrigger: Bool = false
    @State private var bounceAnimationTrigger: Bool = false

    var body: some View {
        HStack(alignment: .center) {
            let metadataState = track.metadata.state
            let isMetadataModified = track.metadata.isModified

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Group {
                        switch metadataState {
                        case .loading:
                            Text("Loading…")
                                .foregroundStyle(.placeholder)
                        case .fine, .saving, .interrupted:
                            titleView()
                        case .dropped:
                            Text(MusicTitle.fallbackTitle(for: track))
                                .redacted(reason: .placeholder)
                        }
                    }
                    .onDoubleClick(handler: play)

                    switch metadataState {
                    case let .interrupted(error), let .dropped(error):
                        Image(systemSymbol: .exclamationmarkCircleFill)
                            .foregroundStyle(.red)
                            .luminarePopover {
                                MetadataErrorView(error: error)
                                    .padding()
                            }
                    default:
                        EmptyView()
                    }

                    Spacer()
                }
                .frame(height: 24)
                .font(.title3)

                HStack(alignment: .center, spacing: 4) {
                    if isMetadataModified {
                        Circle()
                            .foregroundStyle(.tint)
                            .tint(isSelected ? .primary : .accent)
                            .padding(2)
                            .animation(nil, value: isSelected)
                    }

                    if let duration = track.metadata.properties.duration.flatMap(Duration.init) {
                        DurationText(duration: duration)
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }

                    Text(track.url.lastPathComponent)
                        .foregroundStyle(.placeholder)

                    Spacer()
                }
                .frame(height: 12)
                .font(.caption)
                .onDoubleClick(handler: play)
            }
            .lineLimit(1)
            .transition(.blurReplace)
            .opacity(opacity)
            .animation(.default.speed(2), value: metadataState)
            .animation(.default.speed(2), value: isMetadataModified)
            .animation(.default.speed(2), value: isCurrentTrack)
            .animation(.default.speed(2), value: hasControl)
            .animation(.default.speed(2), value: player.isPlayable)
            .animation(.default.speed(2), value: player.isPlaying)

            Spacer()

            if hasControl {
                Button {
                    play()
                } label: {
                    coverView()
                }
                .buttonStyle(.alive)
            }
        }
        .frame(height: 50)
        .padding(6)
        .padding(.trailing, -1)
        .wiggleAnimation(wiggleAnimationTrigger)
        .bounceAnimation(bounceAnimationTrigger, scale: .init(width: 1.01, height: 1.01))
        .animation(animationFast, value: isHovering)
        .background {
            Color.clear
                .onDoubleClick(handler: play)
        }
        .onHover { hover in
            isHovering = hover
        }
        .onChange(of: track.metadata.state) { _, newValue in
            guard newValue.isError else { return }
            wiggleAnimationTrigger.toggle()
        }
        .onReceive(track.metadata.applyPublisher) { _ in
            bounceAnimationTrigger.toggle()

            guard isCurrentTrack else { return }
            track.metadata.updateNowPlayingInfo()
        }
    }

    private var opacity: CGFloat {
        if isSelected {
            1
        } else if player.isPlayable {
            if isCurrentTrack {
                1
            } else {
                if player.isPlaying {
                    0.45
                } else {
                    0.65
                }
            }
        } else {
            1
        }
    }

    private var isCurrentTrack: Bool {
        player.currentTrack == track
    }

    private var hasControl: Bool {
        isHovering || (track.metadata.state.isInitialized && track.metadata.thumbnail != nil)
    }

    @ViewBuilder private func titleView() -> some View {
        if isCurrentTrack {
            ShrinkableMarqueeScrollView {
                MusicTitle(track: track)
            }
        } else {
            MusicTitle(track: track)
        }
    }

    @ViewBuilder private func coverView() -> some View {
        let isInitialized = track.metadata.state.isInitialized

        ZStack {
            if isInitialized, let thumbnail = track.metadata.thumbnail {
                MusicCover(
                    images: [thumbnail], hasPlaceholder: false, cornerRadius: 4
                )
                .overlay {
                    if isHovering, isInitialized {
                        Rectangle()
                            .foregroundStyle(.black)
                            .opacity(0.25)
                            .blendMode(.darken)
                    }
                }

                if isHovering, isInitialized {
                    Image(systemSymbol: .playFill)
                        .foregroundStyle(.white)
                }
            } else {
                if isHovering, isInitialized {
                    Image(systemSymbol: .playFill)
                        .foregroundStyle(.primary)
                }
            }
        }
        .clipShape(.rect(cornerRadius: 4))
        .frame(width: 50, height: 50)
        .font(.title3)
        .contentTransition(.symbolEffect(.replace))
    }

    private func play() {
        player.play(track.url)
        bounceAnimationTrigger.toggle()
    }
}

#if DEBUG
    #Preview(traits: .modifier(SampleEnvironmentsPreviewModifier())) {
        TrackView(track: SampleEnvironmentsPreviewModifier.sampleTrack, isSelected: false)
    }
#endif
