//
//  PlaylistModel.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/31.
//

import Collections
import SwiftUI

@Observable final class PlaylistModel {
    #if DEBUG
        var playlist: Playlist
    #else
        private(set) var playlist: Playlist
    #endif
    private weak var library: LibraryModel?

    var selectedTracks: Set<Track> = []

    private(set) var isLoading: Bool = false
    private(set) var loadingProgress: CGFloat?

    init(bindingTo id: UUID = .init(), library: LibraryModel) {
        self.playlist = .referenced(bindingTo: id)
        self.library = library
    }
}

extension PlaylistModel {
    var id: UUID { playlist.id }
    var mode: Playlist.Mode { playlist.mode }
    var tracks: [Track] { playlist.tracks }

    var url: URL { playlist.url }
    var unwrappedURL: URL? { playlist.unwrappedURL }

    var currentTrack: Track? {
        get { playlist.currentTrack }
        set { playlist.currentTrack = newValue }
    }

    var nextTrack: Track? { playlist.nextTrack }
    var previousTrack: Track? { playlist.previousTrack }

    var hasCurrentTrack: Bool { playlist.hasCurrentTrack }
    var hasNextTrack: Bool { playlist.hasNextTrack }
    var hasPreviousTrack: Bool { playlist.hasPreviousTrack }

    var count: Int { playlist.count }
    var loadedTracksCount: Int { playlist.loadedTracksCount }
    var isEmpty: Bool { playlist.isEmpty }
    var isLoadedTracksEmpty: Bool { playlist.isLoadedTracksEmpty }

    var canMakeCanonical: Bool { playlist.canMakeCanonical }
}

extension PlaylistModel: Equatable {
    static func == (lhs: PlaylistModel, rhs: PlaylistModel) -> Bool {
        lhs.playlist == rhs.playlist
    }
}

extension PlaylistModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(playlist)
    }
}

extension PlaylistModel: Sequence {
    func makeIterator() -> Playlist.Iterator {
        playlist.makeIterator()
    }
}

extension PlaylistModel {
    var segments: Playlist.Segments {
        get { playlist.segments }
        set { playlist.segments = newValue }
    }

    var playbackMode: PlaybackMode {
        get { segments.state.playbackMode }
        set { segments.state.playbackMode = newValue }
    }

    var playbackLooping: Bool {
        get { segments.state.playbackLooping }
        set { segments.state.playbackLooping = newValue }
    }
}

extension PlaylistModel {
    private func captureIndices() -> TrackIndexer.Value {
        OrderedDictionary(
            uniqueKeysWithValues: tracks
                .map(\.url)
                .compactMap { url in
                    guard let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent) else { return nil }
                    return (id, url.pathExtension)
                }
        )
    }

    private func indexTracks(with value: TrackIndexer.Value) throws {
        guard mode.isCanonical else { return }
        playlist.indexer.value = value
        try playlist.indexer.write()
    }

    @MainActor func loadTracks() async {
        guard mode.isCanonical, !isLoading else { return }
        loadingProgress = nil
        isLoading = true

        playlist.loadIndexer()
        playlist.tracks.removeAll()
        loadingProgress = .zero
        for await (index, track) in playlist.indexer.loadTracks() {
            playlist.tracks.append(track)
            loadingProgress = CGFloat(index) / CGFloat(count)

            if index == count - 1 {
                isLoading = false // A must to update views
            }
        }
    }
}

extension PlaylistModel {
    @MainActor func bindTo(_ id: UUID, mode: Playlist.Mode = .referenced) {
        guard !playlist.mode.isCanonical else { return }
        if mode.isCanonical, let playlist = Playlist(loadingWith: id) {
            self.playlist = playlist
        } else {
            playlist = .referenced(bindingTo: id)
        }
    }

    @MainActor func makeCanonical() async throws {
        guard let canonicalPlaylist = try await Playlist(makingCanonical: playlist) else { return }
        playlist = canonicalPlaylist
        try indexTracks(with: captureIndices())
        library?.add([canonicalPlaylist])
    }

    func write(segments: [Playlist.Segment] = Playlist.Segment.allCases) throws {
        try playlist.write(segments: segments)
    }
}

extension PlaylistModel {
    func getTrack(at url: URL) -> Track? {
        playlist.getTrack(at: url)
    }

    func createTrack(from url: URL) async -> Track? {
        await playlist.createTrack(from: url)
    }

    func getOrCreateTrack(at url: URL) async -> Track? {
        await playlist.getOrCreateTrack(at: url)
    }
}

extension PlaylistModel {
    @MainActor func move(fromOffsets indices: IndexSet, toOffset destination: Int) {
        playlist.move(fromOffsets: indices, toOffset: destination)

        try? indexTracks(with: captureIndices())
    }

    @MainActor func play(_ url: URL) async -> Track? {
        guard let track = await getOrCreateTrack(at: url) else { return nil }
        playlist.add([track])
        currentTrack = track

        try? indexTracks(with: captureIndices())
        return track
    }

    @MainActor func add(_ urls: [URL], at destination: Int? = nil) async {
        var tracks: [Track] = []
        for url in urls {
            guard let track = await getOrCreateTrack(at: url) else { continue }
            tracks.append(track)
        }
        playlist.add(tracks, at: destination)

        try? indexTracks(with: captureIndices())
    }

    @MainActor func append(_ urls: [URL]) async {
        for url in urls {
            guard let track = await getOrCreateTrack(at: url) else { continue }
            playlist.add([track])
        }

        try? indexTracks(with: captureIndices())
    }

    @MainActor func remove(_ urls: [URL]) async {
        for url in urls {
            guard let track = await getOrCreateTrack(at: url) else { continue }
            playlist.remove([track])
            selectedTracks.remove(track)
        }

        try? indexTracks(with: captureIndices())
    }

    @MainActor func clear() async {
        await remove(playlist.map(\.url))
    }
}
