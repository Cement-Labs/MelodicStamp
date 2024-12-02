//
//  MetadataView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/24.
//

import SwiftUI

struct MetadataView: View {
    @Bindable var metadataEditor: MetadataEditorModel

    var body: some View {
        EmptyMusicNoteView(systemSymbol: SidebarTab.metadata.systemSymbol)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
