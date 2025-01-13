//
//  PlayerView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/22.
//

import CAAudioHardware
import Luminare
import SFSafeSymbols
import SwiftUI

struct PlayerView: View {
    // MARK: - Environments

    @Environment(WindowManagerModel.self) private var windowManager
    @Environment(PlayerModel.self) private var player
    @Environment(PlayerKeyboardControlModel.self) private var playerKeyboardControl

    // MARK: - Fields

    var namespace: Namespace.ID

    // MARK: Appearance

    @State private var isProgressBarActive: Bool = false
    @State private var isVolumeBarActive: Bool = false

    // MARK: Progress Bar

    @State private var adjustmentPercentage: CGFloat = .zero
    @State private var shouldUseRemainingDuration: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            header()

            HStack(alignment: .center, spacing: 24) {
                HStack(alignment: .center, spacing: 12) {
                    leadingControls()
                }

                Divider()

                HStack(alignment: .center, spacing: 8) {
                    progressBar()
                }

                Divider()

                HStack(alignment: .center, spacing: 24) {
                    trailingControls()
                }
            }
            .frame(height: 32)
            .animation(.default, value: isProgressBarActive)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background {
            DelegatedRemainingDurationSceneStorage(shouldUseRemainingDuration: $shouldUseRemainingDuration)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Header

    @ViewBuilder private func header() -> some View {
        @Bindable var player = player

        HStack(alignment: .center, spacing: 12) {
            // MARK: Playback Mode

            AliveButton(
                enabledStyle: .tertiary, hoveringStyle: .secondary
            ) {
                let hasShift = NSEvent.modifierFlags.contains(.shift)
                player.playbackMode = player.playbackMode.cycle(
                    negate: hasShift)
            } label: {
                Image(systemSymbol: player.playbackMode.systemSymbol)
                    .font(.headline)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 20)
            }
            .matchedGeometryEffect(
                id: PlayerNamespace.playbackModeButton, in: namespace
            )
            .contextMenu {
                PlaybackModePicker(selection: $player.playbackMode)
            }

            // MARK: Playback Looping

            AliveButton(
                enabledStyle: .tertiary, hoveringStyle: .secondary
            ) {
                player.playbackLooping.toggle()
            } label: {
                Image(systemSymbol: .repeat1)
                    .font(.headline)
                    .frame(width: 20, height: 20)
                    .aliveHighlight(player.playbackLooping)
            }
            .matchedGeometryEffect(
                id: PlayerNamespace.playbackLoopingButton, in: namespace
            )

            Spacer()

            Group {
                ShrinkableMarqueeScrollView {
                    MusicTitle(track: player.track)
                }
                .animation(.default, value: player.currentIndex)
                .matchedGeometryEffect(id: PlayerNamespace.title, in: namespace)
            }
            .padding(.bottom, 2)

            Spacer()

            // MARK: Output Device

            Menu {
                OutputDevicePicker(
                    devices: player.outputDevices,
                    selection: $player.selectedOutputDevice
                )
            } label: {
                Image(systemSymbol: .airplayaudio)
            }
            .buttonStyle(.borderless)
            .tint(.secondary.opacity(0.5))
            .onHover { hover in
                guard hover else { return }
                player.updateOutputDevices()
            }

            // MARK: Expand / Shrink

            AliveButton(
                enabledStyle: .tertiary, hoveringStyle: .secondary
            ) {
                windowManager.style = .miniPlayer
            } label: {
                Image(systemSymbol: .arrowDownRightAndArrowUpLeft)
                    .font(.headline)
                    .frame(width: 20)
            }
            .matchedGeometryEffect(
                id: PlayerNamespace.expandShrinkButton, in: namespace
            )
        }
        .frame(height: 20)
    }

    // MARK: - Leading Controls

    @ViewBuilder private func leadingControls() -> some View {
        Group {
            // MARK: Previous Track

            AliveButton {
                player.previousTrack()
                playerKeyboardControl.previousSongButtonBounceAnimation.toggle()
            } label: {
                Image(systemSymbol: .backwardFill)
                    .font(.headline)
            }
            .disabled(!player.hasPreviousTrack)
            .symbolEffect(
                .bounce,
                value: playerKeyboardControl.previousSongButtonBounceAnimation
            )
            .matchedGeometryEffect(
                id: PlayerNamespace.previousSongButton, in: namespace
            )

            // MARK: Play / Pause

            AliveButton {
                player.isPlaying.toggle()
                playerKeyboardControl.isPressingSpace = false
            } label: {
                player.playPauseImage
                    .font(.title)
                    .contentTransition(.symbolEffect(.replace.upUp))
                    .frame(width: 20)
            }
            .scaleEffect(
                playerKeyboardControl.isPressingSpace ? 0.75 : 1,
                anchor: .center
            )
            .animation(.bouncy, value: playerKeyboardControl.isPressingSpace)
            .matchedGeometryEffect(
                id: PlayerNamespace.playPauseButton, in: namespace
            )

            // MARK: Next Track

            AliveButton {
                player.nextTrack()
                playerKeyboardControl.nextSongButtonBounceAnimation.toggle()
            } label: {
                Image(systemSymbol: .forwardFill)
                    .font(.headline)
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

    // MARK: - Trailing Controls

    @ViewBuilder private func trailingControls() -> some View {
        @Bindable var player = player

        ProgressBar(
            value: $player.volume,
            isActive: $isVolumeBarActive,
            externalOvershootSign: playerKeyboardControl.volumeBarExternalOvershootSign,
            onOvershootOffsetChange: { oldValue, newValue in
                if oldValue <= 0, newValue > 0 {
                    playerKeyboardControl.speakerButtonBounceAnimation.toggle()
                }
            }
        )
        .disabled(!player.isPlayable)
        .foregroundStyle(
            isVolumeBarActive
                ? .primary : player.isMuted ? .quaternary : .secondary
        )
        .backgroundStyle(.quinary)
        .frame(width: 72, height: 12)
        .animation(.default.speed(2), value: player.isMuted)
        .matchedGeometryEffect(id: PlayerNamespace.volumeBar, in: namespace)

        // MARK: Speaker

        AliveButton(enabledStyle: .secondary) {
            player.isMuted.toggle()
        } label: {
            player.speakerImage
                .font(.headline)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 16)
        }
        .disabled(!player.isPlayable)
        .symbolEffect(
            .bounce, value: playerKeyboardControl.speakerButtonBounceAnimation
        )
        .matchedGeometryEffect(id: PlayerNamespace.volumeButton, in: namespace)
        .contextMenu {
            Toggle("Mute", isOn: $player.isMuted)
        }
    }

    // MARK: - Progress Bar

    @ViewBuilder private func progressBar() -> some View {
        @Bindable var player = player
        let time: TimeInterval? = if isProgressBarActive {
            // Use adjustment time
            if shouldUseRemainingDuration {
                (player.playbackTime?.duration).map {
                    TimeInterval($0) * (1 - adjustmentPercentage)
                }
            } else {
                (player.playbackTime?.duration).map {
                    TimeInterval($0) * adjustmentPercentage
                }
            }
        } else {
            // Use track time
            if shouldUseRemainingDuration {
                player.playbackTime?.remaining
            } else {
                player.playbackTime?.elapsed
            }
        }

        DurationText(
            duration: time.flatMap(Duration.init),
            sign: shouldUseRemainingDuration ? .minus : .plus
        )
        .frame(width: 40)
        .foregroundStyle(.secondary)
        .padding(.bottom, 1)
        .onTapGesture {
            shouldUseRemainingDuration.toggle()
        }
        .matchedGeometryEffect(id: PlayerNamespace.timeText, in: namespace)

        ProgressBar(
            value: $player.progress,
            isActive: $isProgressBarActive,
            isDelegated: true,
            externalOvershootSign: playerKeyboardControl.progressBarExternalOvershootSign,
            onPercentageChange: { _, newValue in
                adjustmentPercentage = newValue
            }
        )
        .disabled(!player.isPlayable)
        .foregroundStyle(isProgressBarActive ? .primary : .secondary)
        .backgroundStyle(.quinary)
        .frame(height: 12)
        .matchedGeometryEffect(id: PlayerNamespace.progressBar, in: namespace)
        .padding(.horizontal, isProgressBarActive ? 0 : 12)

        DurationText(duration: player.playbackTime?.duration)
            .frame(width: 40)
            .foregroundStyle(.secondary)
            .padding(.bottom, 1)
            .matchedGeometryEffect(
                id: PlayerNamespace.durationText, in: namespace
            )
    }
}

#Preview(traits: .modifier(SampleEnvironmentsPreviewModifier())) {
    @Previewable @Namespace var namespace

    PlayerView(namespace: namespace)
}
