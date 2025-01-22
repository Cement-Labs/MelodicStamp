//
//  MiniPlayerView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/20.
//

import CAAudioHardware
import Luminare
import SFSafeSymbols
import SwiftUI

struct MiniPlayerView: View {
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

        var hasThumbnail: Bool {
            switch self {
            case .title: true
            case .lyrics: false
            }
        }
    }

    // MARK: - Environments

    @Environment(WindowManagerModel.self) private var windowManager
    @Environment(FileManagerModel.self) private var fileManager
    @Environment(PlayerModel.self) private var player
    @Environment(PlayerKeyboardControlModel.self) private var playerKeyboardControl

    @Environment(\.appearsActive) private var appearsActive

    @FocusState private var isFocused: Bool

    // MARK: - Fields

    var namespace: Namespace.ID

    // MARK: Models

    @State private var lyrics: LyricsModel = .init()

    // MARK: Controls

    @State private var activeControl: ActiveControl = .progress
    @State private var headerControl: HeaderControl = .title

    // MARK: Appearance

    @State private var isTitleHovering: Bool = false
    @State private var isProgressBarHovering: Bool = false
    @State private var isProgressBarActive: Bool = false

    // MARK: Progress Bar

    @State private var adjustmentPercentage: CGFloat = .zero
    @State private var shouldUseRemainingDuration: Bool = true

    // MARK: - Body

    var body: some View {
        @Bindable var windowManager = windowManager

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
        .onChange(of: appearsActive, initial: true) { _, newValue in
            isFocused = newValue
        }

        // MARK: Window Customizations

        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .windowFullScreenBehavior(.disabled)
        .background(MakeAlwaysOnTop(
            isAlwaysOnTop: $windowManager.isAlwaysOnTop
        ))

        // MARK: Lyrics

        // Don't extract this logic or modify the tasks!
        .onAppear {
            guard let track = player.track else { return }

            Task {
                let raw = await track.metadata.poll(for: \.lyrics).current
                await lyrics.read(raw)
            }
        }
        .onChange(of: player.track) { _, newValue in
            guard let newValue else { return }
            lyrics.clear(newValue.url)

            Task {
                let raw = await newValue.metadata.poll(for: \.lyrics).current
                await lyrics.read(raw)
            }
        }

        // MARK: Observations

        // Regain progress control on new track
        .onChange(of: player.track) { _, newValue in
            guard newValue != nil else { return }
            activeControl = .progress
        }

        // MARK: Keyboard Handlers

        // Handle [space / ⏎] -> toggle play / pause
        .onKeyPress(keys: [.space, .return], phases: .all) { key in
            playerKeyboardControl.handlePlayPause(
                phase: key.phase, modifiers: key.modifiers
            )
        }

        // Handle [← / →] -> adjust progress & volume
        .onKeyPress(keys: [.leftArrow, .rightArrow], phases: .all) { key in
            let sign: FloatingPointSign = key.key == .leftArrow ? .minus : .plus

            return switch activeControl {
            case .progress:
                playerKeyboardControl.handleProgressAdjustment(
                    phase: key.phase, modifiers: key.modifiers, sign: sign
                )
            case .volume:
                playerKeyboardControl.handleVolumeAdjustment(
                    phase: key.phase, modifiers: key.modifiers, sign: sign
                )
            }
        }

        // Handle [escape] -> regain progress control
        .onKeyPress(.escape) {
            guard activeControl == .volume else { return .ignored }

            activeControl = .progress
            return .handled
        }

        // Handle [m] -> toggle muted
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

    // MARK: - Header

    @ViewBuilder private func header() -> some View {
        @Bindable var player = player

        HStack(alignment: .center, spacing: 12) {
            if isTitleHovering {
                // MARK: Playlist

                Menu {
                    Button("Open in Playlist") {
                        fileManager.emitOpen(style: .inCurrentPlaylist)
                    }

                    Button("Add to Playlist") {
                        fileManager.emitAdd(style: .toCurrentPlaylist)
                    }

                    Divider()

                    playlistMenu()
                } label: {
                    Image(systemSymbol: .listTriangle)
                }
                .buttonStyle(.borderless)
                .tint(.secondary.opacity(0.5))
            }

            // MARK: Playback Mode

            AliveButton(
                enabledStyle: .tertiary, hoveringStyle: .secondary
            ) {
                let hasShift = NSEvent.modifierFlags.contains(.shift)
                player.playbackMode = player.playbackMode.cycle(negate: hasShift)
            } label: {
                Image(systemSymbol: player.playbackMode.systemSymbol)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 16)
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
                    .frame(width: 16, height: 16)
                    .aliveHighlight(player.playbackLooping)
            }
            .matchedGeometryEffect(
                id: PlayerNamespace.playbackLoopingButton, in: namespace
            )

            AliveButton {
                headerControl = switch headerControl {
                case .title:
                    .lyrics
                case .lyrics:
                    .title
                }
            } label: {
                ShrinkableMarqueeScrollView {
                    switch headerControl {
                    case .title:
                        MusicTitle(track: player.track)
                    case .lyrics:
                        ComposedLyricsView()
                            .environment(lyrics)
                    }
                }
                .animation(.default, value: player.track)
                .matchedGeometryEffect(id: PlayerNamespace.title, in: namespace)
                .padding(.bottom, 2)
            }

            if headerControl.hasThumbnail, let thumbnail = player.track?.metadata.thumbnail {
                MusicCover(images: [thumbnail], hasPlaceholder: false, cornerRadius: 2)
                    .padding(.bottom, 2)
            }

            // MARK: Pin / Unpin

            if isTitleHovering || windowManager.isAlwaysOnTop {
                AliveButton(
                    enabledStyle: .tertiary, hoveringStyle: .secondary
                ) {
                    windowManager.isAlwaysOnTop.toggle()
                } label: {
                    Image(systemSymbol: .pinFill)
                        .frame(width: 16, height: 16)
                        .contentTransition(.symbolEffect(.replace))
                        .aliveHighlight(windowManager.isAlwaysOnTop)
                }
                .transition(.blurReplace)
            }

            if isTitleHovering {
                // MARK: Expand / Shrink

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
                .transition(.blurReplace)
            }
        }
        .frame(height: 16)
    }

    // MARK: - Leading Controls

    @ViewBuilder private func leadingControls() -> some View {
        if !isProgressBarExpanded {
            Group {
                // MARK: Previous Track

                AliveButton {
                    player.playPreviousTrack()
                    playerKeyboardControl.previousSongButtonBounceAnimation
                        .toggle()
                } label: {
                    Image(systemSymbol: .backwardFill)
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

                // MARK: Next Track

                AliveButton {
                    player.playNextTrack()
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

    // MARK: - Trailing Controls

    @ViewBuilder private func trailingControls() -> some View {
        @Bindable var player = player
        let isVolumeControlActive = activeControl == .volume

        if isVolumeControlActive {
            if isProgressBarExpanded {
                // Preserves spacing
                Spacer()
                    .frame(width: 0)
            } else {
                // MARK: Output Device

                Menu {
                    OutputDevicePicker(
                        devices: player.outputDevices,
                        defaultSystemDevice: player.defaultSystemOutputDevice,
                        selection: $player.selectedOutputDevice
                    )
                } label: {
                    Image(systemSymbol: .airplayaudio)
                }
                .buttonStyle(.borderless)
                .tint(.secondary)
            }
        }

        if isVolumeControlActive || !isProgressBarExpanded {
            // MARK: Speaker

            AliveButton(enabledStyle: .secondary) {
                activeControl = switch activeControl {
                case .progress:
                    .volume
                case .volume:
                    .progress
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
            .contextMenu {
                if player.isPlayable {
                    Toggle("Mute", isOn: $player.isMuted)
                }
            }
        }
    }

    // MARK: - Progress Bar

    @ViewBuilder private func progressBar() -> some View {
        @Bindable var player = player
        let isProgressControlActive = activeControl == .progress
        let isVolumeControlActive = activeControl == .volume

        HStack(alignment: .center, spacing: 8) {
            Group {
                if isProgressControlActive {
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
                }
            }
            .transition(.blurReplace)
            .matchedGeometryEffect(id: PlayerNamespace.timeText, in: namespace)

            Group {
                let value: Binding<CGFloat> =
                    switch activeControl {
                    case .progress:
                        player.isPlayable ? $player.progress : .constant(0)
                    case .volume:
                        $player.volume
                    }

                ProgressBar(
                    value: value,
                    isActive: $isProgressBarActive,
                    isDelegated: isProgressControlActive,
                    externalOvershootSign: isProgressControlActive
                        ? playerKeyboardControl.progressBarExternalOvershootSign
                        : playerKeyboardControl.volumeBarExternalOvershootSign
                ) { _, newValue in
                    adjustmentPercentage = newValue
                } onOvershootOffsetChange: { oldValue, newValue in
                    if isVolumeControlActive, oldValue <= 0, newValue > 0 {
                        playerKeyboardControl.speakerButtonBounceAnimation.toggle()
                    }
                }
                .disabled(!player.isPlayable)
                .foregroundStyle(
                    isProgressBarActive
                        ? .primary
                        : isVolumeControlActive && player.isMuted
                        ? .quaternary : .secondary
                )
                .backgroundStyle(.quinary)
            }
            .padding(
                .horizontal,
                !isProgressBarHovering || isProgressBarActive ? 0 : 12
            )
            .onHover { hover in
                guard player.isPlayable, hover else { return }

                isProgressBarHovering = true
            }
            .animation(.default.speed(2), value: player.isMuted)
            .matchedGeometryEffect(id: activeControl.id, in: namespace)

            Group {
                if isProgressControlActive {
                    DurationText(duration: player.playbackTime?.duration)
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

    // MARK: - Playlist Menu

    @ViewBuilder private func playlistMenu() -> some View {
        let selection: Binding<Track?> = Binding {
            player.track
        } set: { newValue in
            if let newValue {
                player.play(track: newValue)
            } else {
                player.stop()
            }
        }

        Menu {
            ForEach(player.playlist) { track in
                let binding: Binding<Bool> = Binding {
                    selection.wrappedValue == track
                } set: { newValue in
                    guard newValue else { return }
                    selection.wrappedValue = track
                }

                Toggle(isOn: binding) {
                    if let thumbnail = track.metadata.menuThumbnail {
                        Image(nsImage: thumbnail)
                    }

                    let title = MusicTitle.stringifiedTitle(mode: .title, for: track)
                    Text(title)

                    let subtitle = MusicTitle.stringifiedTitle(mode: .artists, for: track)
                    Text(subtitle)
                }
            }
        } label: {
            if let current = selection.wrappedValue {
                let title = MusicTitle.stringifiedTitle(for: current)
                Text("Playing \(title)")
            } else {
                Text("Playlist")
            }
        }
    }
}

#if DEBUG
    #Preview(traits: .modifier(SampleEnvironmentsPreviewModifier())) {
        @Previewable @Namespace var namespace

        MiniPlayerView(namespace: namespace)
    }
#endif
