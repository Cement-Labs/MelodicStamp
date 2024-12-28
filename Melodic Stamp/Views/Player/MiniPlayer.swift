//
//  MiniPlayer.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/20.
//

import SFSafeSymbols
import SwiftUI

struct MiniPlayer: View {
    enum ActiveControl: Equatable {
        case progress
        case volume

        var id: PlayerNamespace {
            switch self {
            case .progress: .progressBar
            case .volume: .volumeBar
            }
        }
    }

    enum HeaderControl: Equatable {
        case title
        case lyrics
    }

    @FocusState private var isFocused: Bool

    @Environment(WindowManagerModel.self) private var windowManager
    @Environment(PlayerModel.self) private var player
    @Environment(PlayerKeyboardControlModel.self) private var playerKeyboardControl

    var namespace: Namespace.ID

    @State private var activeControl: ActiveControl = .progress
    @State private var headerControl: HeaderControl = .title

    @State private var isTitleHovering: Bool = false
    @State private var isProgressBarHovering: Bool = false
    @State private var isProgressBarActive: Bool = false

    @State private var adjustmentPercentage: CGFloat = .zero
    @State private var shouldUseRemainingDuration: Bool = true

    @State private var playbackTime: PlaybackTime?

    var body: some View {
        VStack(spacing: 12) {
            header()
                .padding(.horizontal, 4)
                .onHover { hover in
                    withAnimation(.default.speed(2)) {
                        isTitleHovering = hover
                    }
                }

            HStack(alignment: .center, spacing: 12) {
                leadingControls()
                    .transition(.blurReplace)

                progressBar()

                trailingControls()
                    .transition(.blurReplace)
            }
            .frame(height: 16)
            .animation(.default, value: isProgressBarHovering)
            .animation(.default, value: isProgressBarActive)
            .animation(.default, value: activeControl)
            .animation(.default, value: headerControl)
        }
        .padding(12)
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onAppear {
            isFocused = true
        }

        // Receive playback time update
        .onReceive(player.playbackTimePublisher) { playbackTime in
            self.playbackTime = playbackTime
        }
        .onChange(of: player.currentIndex, initial: true) { _, newValue in
            guard newValue == nil else { return }
            playbackTime = nil
        }

        // Regain progress control on new track
        .onChange(of: player.currentIndex) { _, newValue in
            guard newValue != nil else { return }
            activeControl = .progress
        }

        // Handle space down/up -> toggle play pause
        .onKeyPress(keys: [.space], phases: .all) { key in
            playerKeyboardControl.handlePlayPause(
                in: player, phase: key.phase, modifiers: key.modifiers
            )
        }

        // Handle left arrow/right arrow down/repeat/up -> adjust progress and navigate track
        .onKeyPress(keys: [.leftArrow, .rightArrow], phases: .all) { key in
            let sign: FloatingPointSign = key.key == .leftArrow ? .minus : .plus

            return switch activeControl {
            case .progress:
                playerKeyboardControl.handleProgressAdjustment(
                    in: player, phase: key.phase, modifiers: key.modifiers,
                    sign: sign
                )
            case .volume:
                playerKeyboardControl.handleVolumeAdjustment(
                    in: player, phase: key.phase, modifiers: key.modifiers,
                    sign: sign
                )
            }
        }

        // Handle escape -> regain progress control
        .onKeyPress(.escape) {
            guard activeControl == .volume else { return .ignored }

            activeControl = .progress
            return .handled
        }

        // Handle m -> toggle mute
        .onKeyPress(keys: ["m"], phases: .down) { _ in
            player.isMuted.toggle()
            return .handled
        }
    }

    private var isProgressBarExpanded: Bool {
        guard player.hasCurrentTrack || activeControl == .volume else {
            return false
        }
        return isProgressBarHovering || isProgressBarActive
    }

    @ViewBuilder private func header() -> some View {
        HStack(alignment: .center, spacing: 12) {
            AliveButton(
                enabledStyle: .tertiary, hoveringStyle: .secondary
            ) {} label: {
                Image(systemSymbol: .squareAndArrowUp)
            }
            .opacity(isTitleHovering ? 1 : 0)

            AliveButton(
                enabledStyle: .tertiary, hoveringStyle: .secondary
            ) {
                let hasShift = NSEvent.modifierFlags.contains(.shift)
                player.playbackMode = player.playbackMode.cycle(
                    negate: hasShift)
            } label: {
                player.playbackMode.image
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 16)
            }
            .matchedGeometryEffect(
                id: PlayerNamespace.playbackModeButton, in: namespace
            )

            AliveButton(
                enabledStyle: .tertiary, hoveringStyle: .secondary
            ) {
                player.playbackLooping.toggle()
            } label: {
                PlaybackLoopingView(isEnabled: player.playbackLooping)
                    .font(.headline)
                    .frame(width: 16)
            }
            .matchedGeometryEffect(
                id: PlayerNamespace.playbackLoopingButton, in: namespace
            )

            AliveButton {
                headerControl =
                    switch headerControl {
                    case .title:
                        .lyrics
                    case .lyrics:
                        .title
                    }
            } label: {
                ShrinkableMarqueeScrollView {
                    switch headerControl {
                    case .title:
                        MusicTitle(item: player.current)
                    case .lyrics:
                        // TODO: Add lyrics control
                        Text("Lyrics")
                            .bold()
                    }
                }
//                .contentTransition(.numericText())
                .animation(.default, value: player.currentIndex)
                .matchedGeometryEffect(id: PlayerNamespace.title, in: namespace)
                .padding(.bottom, 2)
            }

            Group {
                switch headerControl {
                case .title:
                    if let thumbnail = player.current?.metadata.thumbnail {
                        MusicCover(images: [thumbnail], hasPlaceholder: false, cornerRadius: 2)
                    }
                default:
                    EmptyView()
                }
            }
            .padding(.bottom, 2)

            AliveButton(
                enabledStyle: .tertiary, hoveringStyle: .secondary
            ) {
                windowManager.style = .main
            } label: {
                Image(systemSymbol: .arrowUpLeftAndArrowDownRight)
            }
            .matchedGeometryEffect(
                id: PlayerNamespace.expandShrinkButton, in: namespace
            )
            .opacity(isTitleHovering ? 1 : 0)
        }
        .frame(height: 16)
    }

    @ViewBuilder private func leadingControls() -> some View {
        if !isProgressBarExpanded {
            Group {
                AliveButton {
                    player.previousTrack()
                    playerKeyboardControl.previousSongButtonBounceAnimation
                        .toggle()
                } label: {
                    Image(systemSymbol: .backwardFill)
                }
                .disabled(!player.hasPreviousTrack)
                .symbolEffect(
                    .bounce,
                    value: playerKeyboardControl
                        .previousSongButtonBounceAnimation
                )
                .matchedGeometryEffect(
                    id: PlayerNamespace.previousSongButton, in: namespace
                )

                AliveButton {
                    player.togglePlayPause()
                    playerKeyboardControl.isPressingSpace = false
                } label: {
                    player.playPauseImage
                        .font(.title2)
                        .contentTransition(.symbolEffect(.replace.upUp))
                        .frame(width: 16)
                }
                .scaleEffect(
                    playerKeyboardControl.isPressingSpace ? 0.75 : 1,
                    anchor: .center
                )
                .animation(
                    .bouncy, value: playerKeyboardControl.isPressingSpace
                )
                .matchedGeometryEffect(
                    id: PlayerNamespace.playPauseButton, in: namespace
                )

                AliveButton {
                    player.nextTrack()
                    playerKeyboardControl.nextSongButtonBounceAnimation.toggle()
                } label: {
                    Image(systemSymbol: .forwardFill)
                }
                .disabled(!player.hasNextTrack)
                .symbolEffect(
                    .bounce,
                    value: playerKeyboardControl.nextSongButtonBounceAnimation
                )
                .matchedGeometryEffect(
                    id: PlayerNamespace.nextSongButton, in: namespace
                )
            }
            .disabled(!player.hasCurrentTrack)
        }
    }

    @ViewBuilder private func trailingControls() -> some View {
        if activeControl == .volume {
            Group {
                if isProgressBarExpanded {
                    // Preserves spacing
                    Spacer()
                        .frame(width: 0)
                } else {
                    AliveButton {
                        activeControl = .progress
                    } label: {
                        Image(systemSymbol: .chevronLeft)
                    }
                }
            }
        }

        if activeControl == .volume || !isProgressBarExpanded {
            AliveButton(enabledStyle: .secondary) {
                switch activeControl {
                case .progress:
                    activeControl = .volume
                case .volume:
                    player.isMuted.toggle()
                }
            } label: {
                player.speakerImage
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 20, height: 16)
            }
            .symbolEffect(.bounce, value: activeControl)
            .symbolEffect(
                .bounce,
                value: playerKeyboardControl.speakerButtonBounceAnimation
            )
            .matchedGeometryEffect(
                id: PlayerNamespace.volumeButton, in: namespace
            )

            AliveButton(enabledStyle: .secondary) {} label: {
                Image(systemSymbol: .listTriangle)
            }
            .matchedGeometryEffect(
                id: PlayerNamespace.playlistButton, in: namespace
            )
        }
    }

    @ViewBuilder private func progressBar() -> some View {
        HStack(alignment: .center, spacing: 8) {
            Group {
                if activeControl == .progress {
                    let time: TimeInterval? = if isProgressBarActive {
                        // Use adjustment time
                        if shouldUseRemainingDuration {
                            (playbackTime?.duration).map {
                                $0.timeInterval * (1 - adjustmentPercentage)
                            }
                        } else {
                            (playbackTime?.duration).map {
                                $0.timeInterval * adjustmentPercentage
                            }
                        }
                    } else {
                        // Use track time
                        if shouldUseRemainingDuration {
                            playbackTime?.remaining
                        } else {
                            playbackTime?.elapsed
                        }
                    }

                    DurationText(
                        duration: time?.duration,
                        sign: shouldUseRemainingDuration ? .minus : .plus
                    )
                    .frame(width: 40)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 1)
                    .onTapGesture {
                        shouldUseRemainingDuration.toggle()
                    }
                }
            }
            .transition(.blurReplace)
            .matchedGeometryEffect(id: PlayerNamespace.timeText, in: namespace)

            Group {
                let value: Binding<CGFloat> =
                    switch activeControl {
                    case .progress:
                        player.hasCurrentTrack ? progressBinding : .constant(0)
                    case .volume:
                        volumeBinding
                    }

                ProgressBar(
                    value: value,
                    isActive: $isProgressBarActive,
                    isDelegated: activeControl == .progress,
                    externalOvershootSign: activeControl == .progress
                        ? playerKeyboardControl
                        .progressBarExternalOvershootSign
                        : playerKeyboardControl.volumeBarExternalOvershootSign
                ) { _, newValue in
                    adjustmentPercentage = newValue
                } onOvershootOffsetChange: { oldValue, newValue in
                    if activeControl == .volume, oldValue <= 0, newValue > 0 {
                        playerKeyboardControl.speakerButtonBounceAnimation
                            .toggle()
                    }
                }
                .disabled(activeControl == .progress && !player.hasCurrentTrack)
                .foregroundStyle(
                    isProgressBarActive
                        ? .primary
                        : activeControl == .volume && player.isMuted
                        ? .quaternary : .secondary
                )
                .backgroundStyle(.quinary)
            }
            .padding(
                .horizontal,
                !isProgressBarHovering || isProgressBarActive ? 0 : 12
            )
            .onHover { hover in
                let canHover =
                    player.hasCurrentTrack || activeControl == .volume
                guard canHover, hover else { return }

                isProgressBarHovering = true
            }
            .animation(.default.speed(2), value: player.isMuted)
            .matchedGeometryEffect(id: activeControl.id, in: namespace)

            Group {
                if activeControl == .progress {
                    DurationText(duration: playbackTime?.duration)
                        .frame(width: 40)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 1)
                }
            }
            .transition(.blurReplace)
            .matchedGeometryEffect(
                id: PlayerNamespace.durationText, in: namespace
            )
        }
        .frame(height: 12)
        .onHover { hover in
            guard !hover else { return }

            isProgressBarHovering = false
        }
    }

    private var progressBinding: Binding<CGFloat> {
        Binding {
            playbackTime?.progress ?? .zero
        } set: { newValue in
            player.progress = newValue
        }
    }

    private var volumeBinding: Binding<CGFloat> {
        Binding {
            player.volume
        } set: { newValue in
            player.volume = newValue
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace

    MiniPlayer(namespace: namespace)
}
