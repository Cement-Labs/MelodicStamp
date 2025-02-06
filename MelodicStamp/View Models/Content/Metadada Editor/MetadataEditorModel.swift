//
//  MetadataEditorModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/24.
//

import SwiftUI

@Observable final class MetadataEditorModel: MetadataEditorProtocol {
    private weak var playlist: PlaylistModel?

    init(playlist: PlaylistModel) {
        self.playlist = playlist
    }

    var metadataSources: [any Track] {
        playlist?.selectedTracks ?? []
    }

    subscript<V: Equatable & Hashable>(extracting keyPath: WritableKeyPath<Metadata, MetadataEntry<V>>) -> MetadataBatchEditingEntries<V> {
        .init(keyPath: keyPath, metadatas: metadataSet)
    }
}

extension MetadataEditorModel {
    func updated(_ url: URL) {
        guard let index = playlist?.selectedTracks.firstIndex(where: { $0.url == url }) else { return }
        playlist?.selectedTracks[index]
    }
}
