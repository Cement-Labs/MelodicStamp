//
//  Track+Canonical.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/6.
//

import AppKit

extension CanonicalTrack: TypeNameReflectable {}

struct CanonicalTrack: Track {
    let url: URL
    private(set) var metadata: TrackMetadata
    private(set) var cache: CacheSegments
    
    init(url: URL, metadata: Metadata) {
        self.url = url
        self.metadata = .loaded(metadata)
        self.cache = (try? .init(loadingFrom: url.deletingPathExtension())) ?? .init()
    }
    
    @MainActor init?(
        migratingFrom oldValue: some Track, to url: URL?,
        useFallbackTitleIfNotProvided useFallbackTitle: Bool = false
    ) throws(MetadataError) {
        guard let metadata = oldValue.metadata.unwrapped else { return nil }
        self.init(
            url: url ?? oldValue.url,
            metadata: try Metadata(migratingFrom: metadata, to: url, useFallbackTitleIfNotProvided: useFallbackTitle)
        )
        updateCache()
    }
}

extension CanonicalTrack {
    @MainActor mutating func updateCache() {
        cache.info.title = metadata.unwrapped?[extracting: \.title]?.initial
        cache.info.artist = metadata.unwrapped?[extracting: \.artist]?.initial
        cache.info.duration = if let duration = metadata.unwrapped?.properties.duration {
            Duration(duration)
        } else { nil }
        cache.artwork.tiffRepresentation = if let attachedPictures = metadata.unwrapped?[extracting: \.attachedPictures]?.initial {
            ThumbnailMaker.getCover(from: attachedPictures)?.image?.tiffRepresentation
        } else { nil }
    }
    
    @MainActor mutating func loadMetadata() {
        switch self.metadata {
        case .initialized:
            metadata = .loaded(Metadata(initializingFrom: url))
        case .loaded:
            return
        }
    }
}

extension CanonicalTrack {
    func write(segments: [CacheSegmentIndex] = CacheSegmentIndex.allCases) throws {
        guard !segments.isEmpty else { return }
        
        for segment in segments {
            let data = switch segment {
            case .info:
                try JSONEncoder().encode(cache.info)
            case .artwork:
                try JSONEncoder().encode(cache.artwork)
            }
            try CacheSegments.write(segment: segment, ofData: data, toDirectory: url)
        }
        
        logger.info("Successfully written cache segments \(segments) for track at \(url)")
        
        if segments.contains(.artwork) {
            updateFolderIcon()
        }
    }
    
    private func updateFolderIcon() {
        Task.detached(priority: .background) {
            NSWorkspace.shared.setIcon(
                cache.artwork.image?.squared(),
                forFile: url.standardizedFileURL.path(percentEncoded: false)
            )
            logger.info("Successfully updated folder icon for track at \(url)")
        }
    }
}
