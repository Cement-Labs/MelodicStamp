//
//  LibraryModel.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/29.
//

import SwiftUI

extension LibraryModel: TypeNameReflectable {}

@MainActor @Observable final class LibraryModel {
    private(set) var playlists: [Playlist] = []
    private(set) var indexer: PlaylistIndexer = .init()

    private(set) var isLoading: Bool = false

    init() {
        Task {
            loadIndexer()
        }
    }
}

extension LibraryModel: @preconcurrency Sequence {
    func makeIterator() -> Array<Playlist>.Iterator {
        playlists.makeIterator()
    }

    var count: Int {
        indexer.value.count
    }

    var loadedCount: Int {
        playlists.count
    }

    var isEmpty: Bool {
        count == 0
    }

    var isLoaded: Bool {
        loadedCount != 0
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

    func loadPlaylists() async {
        guard !isLoading else { return }
        isLoading = true
        loadIndexer()

        var playlists: [Playlist] = []
        for await playlist in indexer.loadPlaylists() {
            playlists.append(playlist)
        }
        self.playlists = playlists
        isLoading = false
    }
}

extension LibraryModel {
    func isExistingPlaylist(at url: URL) -> Bool {
        playlists.contains { $0.possibleURL == url }
    }

    private func deletePlaylist(at url: URL) throws {
        guard isExistingPlaylist(at: url) else { return }
        Task {
            self.playlists.removeAll { $0.possibleURL == url }
            try FileManager.default.removeItem(at: url)

            logger.info("Deleted playlist at \(url)")
        }
    }
}

extension LibraryModel {
    func move(fromOffsets indices: IndexSet, toOffset destination: Int) {
        playlists.move(fromOffsets: indices, toOffset: destination)

        try? indexPlaylists(with: captureIndices())
    }

    func add(_ playlists: [Playlist], at destination: Int? = nil) {
        let filteredPlaylists = playlists.filter { !self.playlists.contains($0) }

        if let destination, self.playlists.indices.contains(destination) {
            self.playlists.insert(contentsOf: filteredPlaylists, at: destination)
        } else {
            self.playlists.append(contentsOf: filteredPlaylists)
        }

        try? indexPlaylists(with: captureIndices())
    }

    func remove(_ playlists: [Playlist]) {
        for playlist in playlists {
            Task {
                try deletePlaylist(at: playlist.possibleURL)
            }
        }

        try? indexPlaylists(with: captureIndices())
    }
}
