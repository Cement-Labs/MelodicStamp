//
//  LibraryModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/29.
//

import SwiftUI

extension LibraryModel: TypeNameReflectable {}

@Observable final class LibraryModel {
    private(set) var playlists: [Playlist] = []
    private(set) var indexer: PlaylistIndexer = .init()

    private(set) var isLoading: Bool = false
    private(set) var loadingProgress: CGFloat?

    init() {
        Task {
            loadIndexer()
        }
    }
}

extension LibraryModel: Sequence {
    func makeIterator() -> Array<Playlist>.Iterator {
        playlists.makeIterator()
    }

    var count: Int {
        indexer.value.count
    }

    var loadedPlaylistsCount: Int {
        playlists.count
    }

    var isEmpty: Bool {
        count == 0
    }

    var isLoadedPlaylistsEmpty: Bool {
        loadedPlaylistsCount == 0
    }
}

extension LibraryModel {
    private func captureIndices() -> PlaylistIndexer.Value {
        playlists.map(\.id)
    }

    private func indexPlaylists(with value: PlaylistIndexer.Value) throws {
        indexer.value = value
        try indexer.write()
    }

    func loadIndexer() {
        indexer.value = indexer.read() ?? []
    }

    @MainActor func loadPlaylists() async {
        guard !isLoading else { return }
        loadingProgress = nil
        isLoading = true

        loadIndexer()
        playlists.removeAll()
        loadingProgress = .zero
        for await (index, playlist) in indexer.loadPlaylists() {
            playlists.append(playlist)
            loadingProgress = CGFloat(index) / CGFloat(count)

            if index == count - 1 {
                isLoading = false // A must to update views
            }
        }
    }
}

extension LibraryModel {
    private func deletePlaylist(at url: URL) throws {
        try FileManager.default.removeItem(at: url)

        logger.info("Deleted playlist at \(url)")
    }
}

extension LibraryModel {
    @MainActor func move(fromOffsets indices: IndexSet, toOffset destination: Int) {
        playlists.move(fromOffsets: indices, toOffset: destination)

        try? indexPlaylists(with: captureIndices())
    }

    @MainActor func add(_ playlists: [Playlist], at destination: Int? = nil) {
        let filteredPlaylists = playlists.filter { !self.playlists.contains($0) }

        if let destination, 0...self.playlists.endIndex ~= destination {
            self.playlists.insert(contentsOf: filteredPlaylists, at: destination)
        } else {
            self.playlists.append(contentsOf: filteredPlaylists)
        }

        try? indexPlaylists(with: captureIndices())
    }

    @MainActor func remove(_ playlists: [Playlist]) {
        self.playlists.removeAll(where: playlists.contains)
        playlists.forEach { try? deletePlaylist(at: $0.url) }

        try? indexPlaylists(with: captureIndices())
    }
}
