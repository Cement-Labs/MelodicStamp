//
//  LibraryToolbar.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/28.
//

import Defaults
import SwiftUI

struct LibraryToolbar: ToolbarContent {
    @Environment(LibraryModel.self) private var library
    @Environment(PresentationManagerModel.self) private var presentationManager
    @Environment(PlaylistModel.self) private var playlist

    @Environment(\.appearsActive) private var appearsActive
    @Environment(\.dismissWindow) private var dismissWindow

    @Default(.asksForPlaylistInformation) private var asksForPlaylistInformation

    var body: some ToolbarContent {
        @Bindable var playlist = playlist

        ToolbarItem {
            Button("Test") {}
        }
//        if !playlist.mode.isCanonical {
//            ToolbarItem {
//                Button {
//                    presentationManager.isPlaylistSegmentsSheetPresented = asksForPlaylistInformation
//                    Task.detached {
//                        try await playlist.makeCanonical()
//                    }
//                } label: {
//                    Label("Add to Library", systemSymbol: .trayFullFill)
//                }
//                .disabled(!playlist.canMakeCanonical)
//            }
//        } else {
//            ToolbarItem {
//                Button {
//                    presentationManager.isPlaylistRemovalAlertPresented = true
//                } label: {
//                    Label("Remove from Library", systemSymbol: .trashFill)
//                }
//                .foregroundStyle(.red)
//            }
//        }
    }
}
