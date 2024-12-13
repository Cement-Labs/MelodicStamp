//
//  CommonMetadataExcerpt.swift
//  Melodic Stamp
//
//  Created by KrLite on 2024/11/25.
//

import SwiftUI

struct CommonMetadataExcerpt: View {
    var body: some View {
        VStack {
            EmptyMusicNoteView(systemSymbol: SidebarInspectorTab.commonMetadata.systemSymbol)
                .frame(height: 64)

            Text("Common")
                .font(.title3)
                .foregroundStyle(.quaternary)
        }
    }
}

#Preview {
    CommonMetadataExcerpt()
}
