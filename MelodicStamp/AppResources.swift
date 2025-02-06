//
//  AppResources.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/21.
//

import SwiftUI

// MARK: - URL Resources

extension URL {
    static let github = URL(string: "https://github.com")!
    static let organization = github.appending(component: "Cement-Labs")
    static let repository = organization.appending(component: "MelodicStamp")
}

extension URL {
    static let playlists = musicDirectory
        .appending(component: Bundle.main[.displayName], directoryHint: .isDirectory)
        .appending(component: "Playlists", directoryHint: .isDirectory)
}

// MARK: - Window ID

enum WindowID: String, Equatable, Hashable, CaseIterable, Identifiable, Codable, RawValueCallableAsFunction {
    case content
    case about

    var id: Self { self }
}

// MARK: - Scene Storage ID

enum SceneStorageID: String, Hashable, Equatable, CaseIterable, Identifiable, Codable, RawValueCallableAsFunction {
    // MARK: Playlist

    case playlistData

    // MARK: Player

    case playbackVolume, playbackMuted

    var id: Self { self }
}

// MARK: - Toolbar Item ID

enum ToolbarItemID: String, Equatable, Hashable, CaseIterable, Identifiable, Codable, RawValueCallableAsFunction {
    // MARK: Editor

    case editorSaveUpdate, editorRestore

    // MARK: File

    case fileOpen, fileAdd

    // MARK: Library

    case libraryAdd, libraryRemove

    // MARK: Lyrics

    case lyricsEdit

    var id: Self { self }
}
