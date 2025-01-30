//
//  LibraryModel.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/29.
//

import SwiftUI

@MainActor @Observable final class LibraryModel {
    private(set) var playlists: [Playlist] = []
    private(set) var indexer: PlaylistIndexer = .init()

    init() {
        Task.detached {
            await self.loadIndexer()
        }
    }
}

extension LibraryModel: @preconcurrency Sequence {
    func makeIterator() -> Array<Playlist>.Iterator {
        playlists.makeIterator()
    }

    var isEmpty: Bool {
        playlists.isEmpty
    }

    var count: Int {
        playlists.count
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
        loadIndexer()

        playlists.removeAll()
        for await playlist in indexer.loadPlaylists() {
            playlists.append(playlist)
        }
    }
}

extension LibraryModel {
    func move(fromOffsets indices: IndexSet, toOffset destination: Int) {
        playlists.move(fromOffsets: indices, toOffset: destination)

        try? indexPlaylists(with: captureIndices())
    }

    func add(_ playlists: [Playlist]) {
        for playlist in playlists {
            guard !self.playlists.contains(playlist) else { continue }
            self.playlists.append(playlist)
        }

        try? indexPlaylists(with: captureIndices())
    }

    func remove(_ playlists: [Playlist]) {
        self.playlists.removeAll { playlists.contains($0) }

        try? indexPlaylists(with: captureIndices())
    }
}
