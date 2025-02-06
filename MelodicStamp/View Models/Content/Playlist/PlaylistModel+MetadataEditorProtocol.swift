//
//  PlaylistModel+MetadataEditorProtocol.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/31.
//

import Foundation

extension PlaylistModel: MetadataEditorProtocol {
    var metadataSet: Set<Metadata> {
        Set(tracks.map(\.metadata).filter(\.state.isLoaded))
    }
}
