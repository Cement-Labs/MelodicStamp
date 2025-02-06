//
//  Track.swift
//  Models
//
//  Created by KrLite on 2024/11/20.
//

import Foundation

enum TrackMetadata {
    case initialized
    case loaded(Metadata)
}

protocol Track: Identifiable {
    var url: URL { get }
    var metadata: TrackMetadata { get }

    init(url: URL, metadata: Metadata)
}

extension Track {
    var id: URL { url }
}

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

struct CanonicalTrack: Track {
    var url: URL
    var metadata: TrackMetadata
    
    init(url: URL, metadata: Metadata) {
        self.url = url
        self.metadata = .loaded(metadata)
    }
}
