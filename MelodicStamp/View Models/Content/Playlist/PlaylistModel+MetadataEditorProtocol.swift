//
//  PlaylistModel+MetadataEditorProtocol.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/31.
//

import Foundation

extension PlaylistModel: MetadataEditorProtocol {
    var metadataSources: [any Track] {
        playlist.tracks
    }
}
