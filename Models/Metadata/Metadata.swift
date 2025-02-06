//
//  Metadata.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/24.
//

import Combine
@preconcurrency import CSFBAudioEngine
import MediaPlayer
import SwiftUI

enum MetadataError: Error {
    case readingPermissionNotGranted
    case writingPermissionNotGranted
    case fileNotFound
    case invalidFormat
}

// MARK: - Metadata

// MARK: Definition

extension Metadata: TypeNameReflectable {}

extension Metadata {
    enum State: Hashable, Equatable {
        case loading
        case fine
        case saving
        case interrupted(MetadataError)
        case dropped(MetadataError)

        var isLoaded: Bool {
            switch self {
            case .fine, .saving, .interrupted:
                true
            default:
                false
            }
        }

        var isFine: Bool {
            switch self {
            case .fine:
                true
            default:
                false
            }
        }

        var isError: Bool {
            switch self {
            case .interrupted, .dropped:
                true
            default:
                false
            }
        }

        func with(error: MetadataError) -> Self {
            switch self {
            case .loading, .dropped:
                .dropped(error)
            default:
                .interrupted(error)
            }
        }
    }
}

@MainActor @Observable final class Metadata: Identifiable {
    typealias Entry = MetadataEntry

    nonisolated var id: URL { url }
    nonisolated let url: URL

    private(set) var state: State
    private(set) var properties: AudioProperties

    private(set) var thumbnail: NSImage?
    private(set) var menuThumbnail: NSImage?

    var attachedPictures: Entry<Set<AttachedPicture>>!

    var title: Entry<String?>!
    var titleSortOrder: Entry<String?>!
    var artist: Entry<String?>!
    var artistSortOrder: Entry<String?>!
    var composer: Entry<String?>!
    var composerSortOrder: Entry<String?>!
    var genre: Entry<String?>!
    var genreSortOrder: Entry<String?>!
    var bpm: Entry<Int?>!

    var albumTitle: Entry<String?>!
    var albumTitleSortOrder: Entry<String?>!
    var albumArtist: Entry<String?>!
    var albumArtistSortOrder: Entry<String?>!

    var trackNumber: Entry<Int?>!
    var trackCount: Entry<Int?>!
    var discNumber: Entry<Int?>!
    var discCount: Entry<Int?>!

    var comment: Entry<String?>!
    var grouping: Entry<String?>!
    var isCompilation: Entry<Bool?>!

    var isrc: Entry<ISRC?>!
    var lyrics: Entry<RawLyrics?>!
    var mcn: Entry<String?>!

    var musicBrainzRecordingID: Entry<UUID?>!
    var musicBrainzReleaseID: Entry<UUID?>!

    var rating: Entry<Int?>!
    var releaseDate: Entry<String?>!

    var replayGainAlbumGain: Entry<Double?>!
    var replayGainAlbumPeak: Entry<Double?>!
    var replayGainTrackGain: Entry<Double?>!
    var replayGainTrackPeak: Entry<Double?>!
    var replayGainReferenceLoudness: Entry<Double?>!

    var additional: Entry<AdditionalMetadata?>!

    private var applySubject = PassthroughSubject<(), Never>()
    var applyPublisher: AnyPublisher<(), Never> {
        applySubject.eraseToAnyPublisher()
    }

    private var restoreSubject = PassthroughSubject<(), Never>()
    var restorePublisher: AnyPublisher<(), Never> {
        restoreSubject.eraseToAnyPublisher()
    }

    init(url: URL, metadata: AudioMetadata, properties: AudioProperties = .init()) {
        self.properties = properties
        self.state = .fine
        self.url = url

        load(from: metadata)

        Task.detached(priority: .background) {
            await self.generateThumbnail()
        }
    }

    init(initializingFrom url: URL) {
        self.properties = .init()
        self.state = .loading
        self.url = url
    }

    init(loadingFrom url: URL) async throws(MetadataError) {
        self.properties = .init()
        self.state = .loading
        self.url = url

        try await update()
    }

    init(
        migratingFrom oldValue: Metadata, to url: URL? = nil,
        useFallbackTitleIfNotProvided useFallbackTitle: Bool = false
    ) throws(MetadataError) {
        let url = url ?? oldValue.url

        self.url = url
        self.state = oldValue.state

        self.properties = oldValue.properties
        self.thumbnail = oldValue.thumbnail
        self.menuThumbnail = oldValue.menuThumbnail

        self.attachedPictures = oldValue.attachedPictures

        self.title = oldValue.title
        self.titleSortOrder = oldValue.titleSortOrder
        self.artist = oldValue.artist
        self.artistSortOrder = oldValue.artistSortOrder
        self.composer = oldValue.composer
        self.composerSortOrder = oldValue.composerSortOrder
        self.genre = oldValue.genre
        self.genreSortOrder = oldValue.genreSortOrder
        self.bpm = oldValue.bpm

        self.albumTitle = oldValue.albumTitle
        self.albumTitleSortOrder = oldValue.albumTitleSortOrder
        self.albumArtist = oldValue.albumArtist
        self.albumArtistSortOrder = oldValue.albumArtistSortOrder

        self.trackNumber = oldValue.trackNumber
        self.trackCount = oldValue.trackCount
        self.discNumber = oldValue.discNumber
        self.discCount = oldValue.discCount

        self.comment = oldValue.comment
        self.grouping = oldValue.grouping
        self.isCompilation = oldValue.isCompilation

        self.isrc = oldValue.isrc
        self.lyrics = oldValue.lyrics.map {
            MetadataEntry(migratingFrom: $0) { $0.map {
                RawLyrics(url: url, content: $0.content)
            } }
        }
        self.mcn = oldValue.mcn

        self.musicBrainzRecordingID = oldValue.musicBrainzRecordingID
        self.musicBrainzReleaseID = oldValue.musicBrainzReleaseID

        self.rating = oldValue.rating
        self.releaseDate = oldValue.releaseDate

        self.replayGainAlbumGain = oldValue.replayGainAlbumGain
        self.replayGainAlbumPeak = oldValue.replayGainAlbumPeak
        self.replayGainTrackGain = oldValue.replayGainTrackGain
        self.replayGainTrackPeak = oldValue.replayGainTrackPeak
        self.replayGainReferenceLoudness = oldValue.replayGainReferenceLoudness

        self.additional = oldValue.additional

        // Automatically applies a fallback title based on file name for those don't have titles
        let hasInitialTitle = if let title = title?.initial { !title.isEmpty } else { false }
        let hasCurrentTitle = if let title = title?.current { !title.isEmpty } else { false }
        if useFallbackTitle, !hasInitialTitle {
            let fallbackTitle = oldValue.url.deletingPathExtension().lastPathComponent
            if !hasCurrentTitle {
                title?.current = fallbackTitle
            }

            Task.detached(priority: .background) {
                try await self.overwrite()

                Task { @MainActor in
                    self.title?.initial = fallbackTitle
                }
            }
        }
    }

    private var restorables: [any Restorable] {
        guard state.isLoaded else { return [] }
        return [
            attachedPictures,
            title, titleSortOrder, artist, artistSortOrder, composer,
            composerSortOrder, genre, genreSortOrder, bpm,
            albumTitle, albumTitleSortOrder, albumArtist, albumArtistSortOrder,
            trackNumber, trackCount, discNumber, discCount,
            comment, grouping, isCompilation,
            isrc, lyrics, mcn,
            musicBrainzRecordingID, musicBrainzReleaseID,
            rating, releaseDate,
            replayGainAlbumGain, replayGainAlbumPeak, replayGainTrackGain,
            replayGainTrackPeak, replayGainReferenceLoudness
        ]
    }

    private func updateState(to state: State) {
        self.state = state
    }
}

// MARK: Loading Functions

private extension Metadata {
    func load(
        attachedPictures: Set<AttachedPicture> = [],
        title: String? = nil, titleSortOrder: String? = nil,
        artist: String? = nil, artistSortOrder: String? = nil,
        composer: String? = nil, composerSortOrder: String? = nil,
        genre: String? = nil, genreSortOrder: String? = nil,
        bpm: Int? = nil,
        albumTitle: String? = nil, albumTitleSortOrder: String? = nil,
        albumArtist: String? = nil, albumArtistSortOrder: String? = nil,
        trackNumber: Int? = nil, trackCount: Int? = nil,
        discNumber: Int? = nil, discCount: Int? = nil,
        comment: String? = nil,
        grouping: String? = nil,
        isCompilation: Bool? = nil,
        isrc: String? = nil,
        lyrics: String? = nil,
        mcn: String? = nil,
        musicBrainzRecordingID: String? = nil,
        musicBrainzReleaseID: String? = nil,
        rating: Int? = nil,
        releaseDate: String? = nil,
        replayGainAlbumGain: Double? = nil, replayGainAlbumPeak: Double? = nil,
        replayGainTrackGain: Double? = nil, replayGainTrackPeak: Double? = nil,
        replayGainReferenceLoudness: Double? = nil,
        additional: AdditionalMetadata? = nil
    ) {
        self.attachedPictures = .init(
            attachedPictures
        )

        self.title = .init(
            title
        )
        self.titleSortOrder = .init(
            titleSortOrder
        )
        self.artist = .init(
            artist
        )
        self.artistSortOrder = .init(
            artistSortOrder
        )
        self.composer = .init(
            composer
        )
        self.composerSortOrder = .init(
            composerSortOrder
        )
        self.genre = .init(
            genre
        )
        self.genreSortOrder = .init(
            genreSortOrder
        )
        self.bpm = .init(
            bpm
        )

        self.albumTitle = .init(
            albumTitle
        )
        self.albumTitleSortOrder = .init(
            albumTitleSortOrder
        )
        self.albumArtist = .init(
            albumArtist
        )
        self.albumArtistSortOrder = .init(
            albumArtistSortOrder
        )

        self.trackNumber = .init(
            trackNumber
        )
        self.trackCount = .init(
            trackCount
        )
        self.discNumber = .init(
            discNumber
        )
        self.discCount = .init(
            discCount
        )

        self.comment = .init(
            comment
        )
        self.grouping = .init(
            grouping
        )
        self.isCompilation = .init(
            isCompilation
        )

        self.isrc = .init(
            isrc.flatMap { ISRC(parsing: $0) }
        )
        self.lyrics = .init(
            RawLyrics(url: url, content: lyrics)
        )
        self.mcn = .init(
            mcn
        )

        self.musicBrainzRecordingID = .init(
            musicBrainzRecordingID.flatMap(UUID.init(uuidString:))
        )
        self.musicBrainzReleaseID = .init(
            musicBrainzReleaseID.flatMap(UUID.init(uuidString:))
        )

        self.rating = .init(
            rating
        )
        self.releaseDate = .init(
            releaseDate
        )

        self.replayGainAlbumGain = .init(
            replayGainAlbumGain
        )
        self.replayGainAlbumPeak = .init(
            replayGainAlbumPeak
        )
        self.replayGainTrackGain = .init(
            replayGainTrackGain
        )
        self.replayGainTrackPeak = .init(
            replayGainTrackPeak
        )
        self.replayGainReferenceLoudness = .init(
            replayGainReferenceLoudness
        )

        self.additional = .init(
            additional
        )
    }

    func load(from metadata: AudioMetadata?) {
        load(
            attachedPictures: metadata?.attachedPictures ?? [],
            title: metadata?.title,
            titleSortOrder: metadata?.titleSortOrder,
            artist: metadata?.artist,
            artistSortOrder: metadata?.artistSortOrder,
            composer: metadata?.composer,
            composerSortOrder: metadata?.composerSortOrder,
            genre: metadata?.genre,
            genreSortOrder: metadata?.genreSortOrder,
            bpm: metadata?.bpm,
            albumTitle: metadata?.albumTitle,
            albumTitleSortOrder: metadata?.albumTitleSortOrder,
            albumArtist: metadata?.albumArtist,
            albumArtistSortOrder: metadata?.albumArtistSortOrder,
            trackNumber: metadata?.trackNumber,
            trackCount: metadata?.trackTotal,
            discNumber: metadata?.discNumber,
            discCount: metadata?.discTotal,
            comment: metadata?.comment,
            grouping: metadata?.grouping,
            isCompilation: metadata?.isCompilation,
            isrc: metadata?.isrc,
            lyrics: metadata?.lyrics,
            mcn: metadata?.mcn,
            musicBrainzRecordingID: metadata?.musicBrainzRecordingID,
            musicBrainzReleaseID: metadata?.musicBrainzReleaseID,
            rating: metadata?.rating,
            releaseDate: metadata?.releaseDate,
            replayGainAlbumGain: metadata?.replayGainAlbumGain,
            replayGainAlbumPeak: metadata?.replayGainAlbumPeak,
            replayGainTrackGain: metadata?.replayGainTrackGain,
            replayGainTrackPeak: metadata?.replayGainTrackPeak,
            replayGainReferenceLoudness: metadata?.replayGainReferenceLoudness,
            additional: metadata?.additionalMetadata.map(AdditionalMetadata.init)
        )
    }

    func pack() -> AudioMetadata {
        let metadata = AudioMetadata()
        guard state.isLoaded else { return metadata }

        metadata.title = title.current
        metadata.titleSortOrder = titleSortOrder.current
        metadata.artist = artist.current
        metadata.artistSortOrder = artistSortOrder.current
        metadata.composer = composer.current
        metadata.composerSortOrder = composerSortOrder.current
        metadata.genre = genre.current
        metadata.genreSortOrder = genreSortOrder.current
        metadata.bpm = bpm.current
        metadata.albumTitle = albumTitle.current
        metadata.albumArtist = albumArtist.current
        metadata.trackNumber = trackNumber.current
        metadata.trackTotal = trackCount.current
        metadata.discNumber = discNumber.current
        metadata.discTotal = discCount.current
        metadata.comment = comment.current
        metadata.grouping = grouping.current
        metadata.isCompilation = isCompilation.current
        metadata.isrc = isrc.current?.formatted()
        metadata.lyrics = lyrics.current?.content
        metadata.mcn = mcn.current
        metadata.musicBrainzRecordingID = musicBrainzRecordingID.current?.uuidString
        metadata.musicBrainzReleaseID = musicBrainzReleaseID.current?.uuidString
        metadata.rating = rating.current
        metadata.releaseDate = releaseDate.current
        metadata.replayGainAlbumGain = replayGainAlbumGain.current
        metadata.replayGainAlbumPeak = replayGainAlbumPeak.current
        metadata.replayGainTrackGain = replayGainTrackGain.current
        metadata.replayGainTrackPeak = replayGainTrackPeak.current
        metadata.replayGainReferenceLoudness = replayGainReferenceLoudness.current
        metadata.additionalMetadata = additional.current

        attachedPictures.current.forEach(metadata.attachPicture)

        return metadata
    }
}

// MARK: Manipulating Functions

extension Metadata: Modifiable {
    var isModified: Bool {
        guard state.isLoaded else { return false }
        return restorables.contains(where: \.isModified)
    }
}

extension Metadata {
    func restore() {
        guard state.isLoaded else { return }
        for var restorable in self.restorables {
            restorable.restore()
        }

        restoreSubject.send()

        Task.detached(priority: .background) {
            await self.generateThumbnail()
        }
    }

    func apply() {
        guard state.isLoaded else { return }
        for var restorable in self.restorables {
            restorable.apply()
        }

        applySubject.send()

        Task.detached(priority: .background) {
            await self.generateThumbnail()
        }
    }

    func generateThumbnail() async {
        guard
            state.isLoaded,
            let attachedPictures = self[extracting: \.attachedPictures]?.current
        else {
            thumbnail = nil
            menuThumbnail = nil
            return
        }

        if let image = ThumbnailMaker.getCover(from: attachedPictures)?.image {
            let thumbnail = await ThumbnailMaker.make(image)
            let menuThumbnail = await ThumbnailMaker.make(image, resolution: 20)

            self.thumbnail = thumbnail
            self.menuThumbnail = menuThumbnail
        } else {
            thumbnail = nil
            menuThumbnail = nil
        }
    }

    nonisolated func update() async throws(MetadataError) {
        guard url.isFileExist else {
            await updateState(to: state.with(error: .fileNotFound))
            throw .fileNotFound
        }

        guard let file = try? AudioFile(readingPropertiesAndMetadataFrom: url) else {
            await updateState(to: state.with(error: .readingPermissionNotGranted))
            throw .readingPermissionNotGranted
        }

        Task { @MainActor in
            properties = file.properties
        }

        await load(from: file.metadata)

        switch await state {
        case .loading:
            logger.info("Loaded metadata from \(self.url)")
        default:
            logger.info("Updated metadata from \(self.url)")
        }

        await updateState(to: .fine)
        await apply()
        await generateThumbnail()
    }

    nonisolated func write() async throws(MetadataError) {
        guard await state.isLoaded, await isModified else { return }

        guard url.isFileExist else {
            await updateState(to: state.with(error: .fileNotFound))
            throw .fileNotFound
        }

        guard !url.isFileReadOnly else {
            await updateState(to: state.with(error: .writingPermissionNotGranted))
            throw .writingPermissionNotGranted
        }

        await updateState(to: .saving)
        await apply()

        logger.info("Started writing metadata to \(self.url)")

        try await overwrite()
        await updateState(to: .fine)

        logger.info("Successfully written metadata to \(self.url)")
    }

    // Overwrites the metadata file using only values from the `initial` fields
    private nonisolated func overwrite() async throws(MetadataError) {
        logger.info("Started overwriting initial metadata values to \(self.url)")

        guard let file = try? AudioFile(url: url) else {
            await updateState(to: state.with(error: .fileNotFound))
            throw .fileNotFound
        }

        file.metadata = await pack()

        do {
            if file.metadata.comment != nil {
                try file.writeMetadata()
            } else {
                // This is crucial for `.flac` file types
                // In these files, if all fields except `attachedPictures` field are `nil`, audio decoding will encounter great issues after writing metadata
                // so hereby always providing an empty `comment` if it is `nil`
                file.metadata.comment = ""
                try file.writeMetadata()
            }
        } catch {
            await updateState(to: state.with(error: .writingPermissionNotGranted))
            throw .writingPermissionNotGranted
        }

        logger.info("Successfully overwritten initial metadata values to \(self.url)")
    }

    func poll<V>(for keyPath: WritableKeyPath<Metadata, Entry<V>>) async -> MetadataBatchEditingEntry<V> {
        logger.info("Started polling metadata for \("\(keyPath)")")

        while !state.isLoaded {
            try? await Task.sleep(for: .milliseconds(100))
        }

        var entry: MetadataBatchEditingEntry<V>?
        repeat {
            entry = self[extracting: keyPath]
        } while entry == nil

        logger.info("Succeed polling metadata for \("\(keyPath)")")

        return entry!
    }

    subscript<V>(extracting keyPath: WritableKeyPath<Metadata, Entry<V>>)
        -> MetadataBatchEditingEntry<V>? {
        guard state.isLoaded else { return nil }
        return .init(keyPath: keyPath, metadata: self)
    }
}

// MARK: Extensions

extension Metadata: Equatable {
    nonisolated static func == (lhs: Metadata, rhs: Metadata) -> Bool {
        lhs.id == rhs.id
    }
}

extension Metadata: Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Metadata {
    func updateNowPlayingInfo() {
        let infoCenter = MPNowPlayingInfoCenter.default()
        var info = infoCenter.nowPlayingInfo ?? .init()

        if state.isLoaded {
            updateNowPlayingInfo(for: &info)
        } else {
            Self.resetNowPlayingInfo(for: &info)
        }

        infoCenter.nowPlayingInfo = info
    }

    func updateNowPlayingInfo(for dict: inout [String: Any]) {
        guard state.isLoaded else {
            return Self.resetNowPlayingInfo(for: &dict)
        }

        dict[MPMediaItemPropertyArtwork] = ThumbnailMaker.getCover(
            from: attachedPictures.initial
        )
        .flatMap(\.image)
        .map(\.mediaItemArtwork)

        dict[MPMediaItemPropertyTitle] = if let title = title.initial, !title.isEmpty {
            title
        } else {
            url.deletingPathExtension().lastPathComponent
        }

        dict[MPMediaItemPropertyArtist] = artist.initial
        dict[MPMediaItemPropertyComposer] = composer.initial
        dict[MPMediaItemPropertyGenre] = genre.initial
        dict[MPMediaItemPropertyBeatsPerMinute] = bpm.initial

        dict[MPMediaItemPropertyAlbumTitle] = albumTitle.initial
        dict[MPMediaItemPropertyAlbumArtist] = albumArtist.initial

        dict[MPMediaItemPropertyAlbumTrackNumber] = trackNumber.initial
        dict[MPMediaItemPropertyAlbumTrackCount] = trackCount.initial
        dict[MPMediaItemPropertyDiscNumber] = discNumber.initial
        dict[MPMediaItemPropertyDiscCount] = discCount.initial

        dict[MPMediaItemPropertyComments] = comment.initial
        dict[MPMediaItemPropertyUserGrouping] = grouping.initial
        dict[MPMediaItemPropertyIsCompilation] = isCompilation.initial

        dict[MPNowPlayingInfoPropertyInternationalStandardRecordingCode] =
            isrc.initial
        dict[MPMediaItemPropertyLyrics] = lyrics.initial

        dict[MPMediaItemPropertyReleaseDate] = releaseDate.initial
    }

    static func resetNowPlayingInfo() {
        let infoCenter = MPNowPlayingInfoCenter.default()
        var info = infoCenter.nowPlayingInfo ?? .init()

        Self.resetNowPlayingInfo(for: &info)

        infoCenter.nowPlayingInfo = info
    }

    static func resetNowPlayingInfo(for dict: inout [String: Any]) {
        dict[MPMediaItemPropertyArtwork] = nil

        dict[MPMediaItemPropertyTitle] = nil
        dict[MPMediaItemPropertyArtist] = nil
        dict[MPMediaItemPropertyComposer] = nil
        dict[MPMediaItemPropertyGenre] = nil
        dict[MPMediaItemPropertyBeatsPerMinute] = nil

        dict[MPMediaItemPropertyAlbumTitle] = nil
        dict[MPMediaItemPropertyAlbumArtist] = nil

        dict[MPMediaItemPropertyAlbumTrackNumber] = nil
        dict[MPMediaItemPropertyAlbumTrackCount] = nil
        dict[MPMediaItemPropertyDiscNumber] = nil
        dict[MPMediaItemPropertyDiscCount] = nil

        dict[MPMediaItemPropertyComments] = nil
        dict[MPMediaItemPropertyUserGrouping] = nil
        dict[MPMediaItemPropertyIsCompilation] = nil

        dict[MPNowPlayingInfoPropertyInternationalStandardRecordingCode] = nil
        dict[MPMediaItemPropertyLyrics] = nil

        dict[MPMediaItemPropertyReleaseDate] = nil
    }
}
