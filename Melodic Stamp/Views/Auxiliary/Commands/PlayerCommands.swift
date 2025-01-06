//
//  PlayerCommands.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/8.
//

import CAAudioHardware
import SwiftUI

struct PlayerCommands: Commands {
    @FocusedValue(\.player) private var player
    @FocusedValue(\.playerKeyboardControl) private var playerKeyboardControl

    var body: some Commands {
        CommandMenu("Player") {
            Group {
                Button(player?.isPlaying ?? false ? "Pause" : "Play") {
                    player?.togglePlayPause()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(player?.hasCurrentTrack != true)

                Group {
                    Button("Fast Forward") {
                        guard let player else { return }
                        playerKeyboardControl?.handleProgressAdjustment(
                            in: player, phase: .down, sign: .plus
                        )
                    }
                    .keyboardShortcut(.rightArrow, modifiers: .command)
                    .modifierKeyAlternate(.shift) {
                        Button("Fast Forward") {
                            guard let player else { return }
                            playerKeyboardControl?.handleProgressAdjustment(
                                in: player, phase: .down, modifiers: .shift,
                                sign: .plus
                            )
                        }
                        .badge("×5")
                    }
                    .modifierKeyAlternate(.option) {
                        Button("Fast Forward") {
                            guard let player else { return }
                            playerKeyboardControl?.handleProgressAdjustment(
                                in: player, phase: .down, modifiers: .option,
                                sign: .plus
                            )
                        }
                        .badge("×0.1")
                    }

                    Button("Rewind") {
                        guard let player else { return }
                        playerKeyboardControl?.handleProgressAdjustment(
                            in: player, phase: .down, sign: .minus
                        )
                    }
                    .keyboardShortcut(.leftArrow, modifiers: .command)
                    .modifierKeyAlternate(.shift) {
                        Button("Rewind") {
                            guard let player else { return }
                            playerKeyboardControl?.handleProgressAdjustment(
                                in: player, phase: .down, modifiers: .shift,
                                sign: .minus
                            )
                        }
                        .badge("×5")
                    }
                    .modifierKeyAlternate(.option) {
                        Button("Rewind") {
                            guard let player else { return }
                            playerKeyboardControl?.handleProgressAdjustment(
                                in: player, phase: .down, modifiers: .option,
                                sign: .minus
                            )
                        }
                        .badge("×0.1")
                    }
                }
                .disabled(!hasCurrentTrack)

                Divider()

                Group {
                    Group {
                        if let player {
                            @Bindable var player = player
                            
                            Toggle("Mute", isOn: $player.isMuted)
                        } else {
                            Button("Mute") {
                                // Do nothing
                            }
                        }
                    }
                    .keyboardShortcut("m", modifiers: [.command, .control])
                    
                    Button("Louder") {
                        guard let player else { return }
                        playerKeyboardControl?.handleVolumeAdjustment(
                            in: player, phase: .down, sign: .plus
                        )
                    }
                    .keyboardShortcut(.upArrow, modifiers: .command)
                    .modifierKeyAlternate(.shift) {
                        Button("Louder") {
                            guard let player else { return }
                            playerKeyboardControl?.handleVolumeAdjustment(
                                in: player, phase: .down, modifiers: .shift,
                                sign: .plus
                            )
                        }
                        .badge("×5")
                    }
                    .modifierKeyAlternate(.option) {
                        Button("Louder") {
                            guard let player else { return }
                            playerKeyboardControl?.handleVolumeAdjustment(
                                in: player, phase: .down, modifiers: .option,
                                sign: .plus
                            )
                        }
                        .badge("×0.1")
                    }
                    
                    Button("Quieter") {
                        guard let player else { return }
                        playerKeyboardControl?.handleVolumeAdjustment(
                            in: player, phase: .down, sign: .minus
                        )
                    }
                    .keyboardShortcut(.downArrow, modifiers: .command)
                    .modifierKeyAlternate(.shift) {
                        Button("Quieter") {
                            guard let player else { return }
                            playerKeyboardControl?.handleVolumeAdjustment(
                                in: player, phase: .down, modifiers: .shift,
                                sign: .minus
                            )
                        }
                        .badge("×5")
                    }
                    .modifierKeyAlternate(.option) {
                        Button("Quieter") {
                            guard let player else { return }
                            playerKeyboardControl?.handleVolumeAdjustment(
                                in: player, phase: .down, modifiers: .option,
                                sign: .minus
                            )
                        }
                        .badge("×0.1")
                    }
                }
                .disabled(!hasCurrentTrack)

                Divider()

                Button("Next Song") {
                    player?.nextTrack()
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .control])
                .disabled(!hasNextTrack)

                Button("Previous Song") {
                    player?.previousTrack()
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .control])
                .disabled(!hasPreviousTrack)

                if let player {
                    @Bindable var player = player
                    let playbackName = PlaybackModeView.name(of: player.playbackMode)

                    Menu("Playback") {
                        ForEach(PlaybackMode.allCases) { mode in
                            let binding: Binding<Bool> = Binding {
                                player.playbackMode == mode
                            } set: { newValue in
                                guard newValue else { return }
                                player.playbackMode = mode
                            }

                            Toggle(isOn: binding) {
                                PlaybackModeView(mode: mode)
                            }
                        }

                        Divider()

                        Toggle(isOn: $player.playbackLooping) {
                            Image(systemSymbol: .repeat1)

                            Text("Infinite Loop")
                        }
                    }
                    .badge(playbackName)
                } else {
                    Button("Playback") {
                        // Do nothing
                    }
                }
            }
            .disabled(!hasPlayer || !hasPlayerKeyboardControl)

            if let player {
                @Bindable var player = player
                if let binding = ~$player.selectedOutputDevice {
                    let outputDeviceName = try? binding.wrappedValue.name

                    Picker("Output Device", selection: binding) {
                        OutputDeviceList(devices: player.outputDevices)
                            .onAppear {
                                player.updateOutputDevices()
                            }
                    }
                    .badge(outputDeviceName)
                }
            }
        }
    }
    
    private var hasPlayer: Bool { player != nil }
    
    private var hasPlayerKeyboardControl: Bool { playerKeyboardControl != nil }
    
    private var hasCurrentTrack: Bool { player?.hasCurrentTrack ?? false }
    
    private var hasPreviousTrack: Bool { player?.hasPreviousTrack ?? false }
    
    private var hasNextTrack: Bool { player?.hasNextTrack ?? false }
    
}
