//
//  Track+Canonical.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/6.
//

import Foundation

extension CanonicalTrack: TypeNameReflectable {}

struct CanonicalTrack: Track {
    var url: URL
    var metadata: TrackMetadata
    
    init(url: URL, metadata: Metadata) {
        self.url = url
        self.metadata = .loaded(metadata)
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
    }
}
