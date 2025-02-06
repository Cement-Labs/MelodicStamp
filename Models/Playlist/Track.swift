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
    
    var unwrapped: Metadata? {
        switch self {
        case .initialized:
            nil
        case let .loaded(metadata):
            metadata
        }
    }
}

protocol Track: Equatable, Hashable, Identifiable {
    var url: URL { get }
    var metadata: TrackMetadata { get }

    init(url: URL, metadata: Metadata)
}

extension Track {
    var id: URL { url }
}
