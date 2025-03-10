//
//  FileCommands.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/24.
//

import SwiftUI

struct FileCommands: Commands {
    @FocusedValue(FileManagerModel.self) private var fileManager

    var body: some Commands {
        CommandGroup(after: .newItem) {
            // MARK: Open

            Menu("Open File") {
                Button("In Current Playlist") {
                    fileManager?.emitOpen(style: .inCurrentPlaylist)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Replacing Current Playlist") {
                    fileManager?.emitOpen(style: .replacingCurrentPlaylistOrSelection)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                .modifierKeyAlternate(.option) {
                    Button("Forming New Playlist") {
                        fileManager?.emitOpen(style: .formingNewPlaylist)
                    }
                }
            }
            .disabled(fileManager == nil)

            // MARK: Add

            Menu("Add Files") {
                Button("To Current Playlist") {
                    fileManager?.emitAdd(style: .toCurrentPlaylist)
                }
                .keyboardShortcut("p", modifiers: .command)

                Button("Replacing Current Playlist") {
                    fileManager?.emitAdd(style: .replacingCurrentPlaylistOrSelection)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .modifierKeyAlternate(.option) {
                    Button("Forming New Playlist") {
                        fileManager?.emitAdd(style: .formingNewPlaylist)
                    }
                }
            }
            .disabled(fileManager == nil)
        }
    }
}
