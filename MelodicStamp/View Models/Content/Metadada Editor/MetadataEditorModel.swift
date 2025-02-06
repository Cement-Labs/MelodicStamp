//
//  MetadataEditorModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/24.
//

import SwiftUI

@Observable class MetadataEditorModel: MetadataEditorProtocol {
    private weak var playlist: PlaylistModel?

    init(playlist: PlaylistModel) {
        self.playlist = playlist
    }

    var metadataSet: Set<Metadata> {
        guard let playlist else {
            return []
        }
        return Set(playlist.selectedTracks.map(\.metadata).filter(\.state.isLoaded))
    }

    subscript<V: Equatable & Hashable>(extracting keyPath: WritableKeyPath<Metadata, MetadataEntry<V>>) -> MetadataBatchEditingEntries<V> {
        .init(keyPath: keyPath, metadatas: metadataSet)
    }
}
