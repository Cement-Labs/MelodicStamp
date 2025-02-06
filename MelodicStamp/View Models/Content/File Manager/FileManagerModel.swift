//
//  FileManagerModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/25.
//

import CSFBAudioEngine
import SwiftUI
import UniformTypeIdentifiers

enum FileOpenerPresentationStyle {
    case inCurrentPlaylist
    case replacingCurrentPlaylistOrSelection
    case formingNewPlaylist
}

enum FileAdderPresentationStyle {
    case toCurrentPlaylist
    case replacingCurrentPlaylistOrSelection
    case formingNewPlaylist
}

@Observable final class FileManagerModel {
    private weak var playlist: PlaylistModel?
    private weak var player: PlayerModel?

    var isFileOpenerPresented: Bool = false
    private var fileOpenerPresentationStyle: FileOpenerPresentationStyle = .inCurrentPlaylist

    var isFileAdderPresented: Bool = false
    private var fileAdderPresentationStyle: FileAdderPresentationStyle = .toCurrentPlaylist

    init(player: PlayerModel, playlist: PlaylistModel) {
        self.player = player
        self.playlist = playlist
    }

    func emitOpen(style: FileOpenerPresentationStyle = .inCurrentPlaylist) {
        isFileOpenerPresented = true
        fileOpenerPresentationStyle = style
    }

    func emitAdd(style: FileAdderPresentationStyle = .toCurrentPlaylist) {
        isFileAdderPresented = true
        fileAdderPresentationStyle = style
    }

    func open(url: URL, openWindow: OpenWindowAction) {
        guard url.canAccessSecurityScopedResourceOrIsReachable() else { return }

        Task { @MainActor in
            switch fileOpenerPresentationStyle {
            case .inCurrentPlaylist:
                await player?.play(url)
            case .replacingCurrentPlaylistOrSelection:
                await playlist?.clear()
                await player?.play(url)
            case .formingNewPlaylist:
                openWindow(id: WindowID.content(), value: CreationParameters(
                    playlist: .referenced([url]), shouldPlay: true,
                    initialWindowStyle: .miniPlayer
                ))
            }
        }
    }

    func add(urls: [URL], openWindow: OpenWindowAction) {
        let urls = urls.flatMap { url in
            FileHelper.flatten(contentsOf: url)
        }

        Task { @MainActor in
            switch fileAdderPresentationStyle {
            case .toCurrentPlaylist:
                await playlist?.append(urls)
            case .replacingCurrentPlaylistOrSelection:
                await playlist?.clear()
                await playlist?.append(urls)
            case .formingNewPlaylist:
                openWindow(id: WindowID.content(), value: CreationParameters(
                    playlist: .referenced(urls)
                ))
            }
        }
    }
}
