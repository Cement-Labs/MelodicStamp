//
//  Track+Referenced.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/6.
//

import Foundation

struct ReferencedTrack: Track {
    var url: URL
    var metadata: TrackMetadata
    
    init(url: URL, metadata: Metadata) {
        self.url = url
        self.metadata = .loaded(metadata)
    }
    
    @MainActor init(loadingFrom url: URL) async throws(MetadataError) {
        self.init(url: url, metadata: try await Metadata(loadingFrom: url))
    }
}
