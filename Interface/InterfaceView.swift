//
//  InterfaceView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/2.
//

import Defaults
import SwiftUI

struct InterfaceView: View {
    @Environment(LibraryModel.self) private var library
    @Environment(WindowManagerModel.self) private var windowManager
    @Environment(PlaylistModel.self) private var playlist

    @Environment(\.appearsActive) private var appearsActive

    @Default(.mainWindowBackgroundStyle) private var mainWindowBackgroundStyle
    @Default(.miniPlayerBackgroundStyle) private var miniPlayerBackgroundStyle

    var window: NSWindow?
    @State private var floatingWindowsTargetWindow: NSWindow?

    @State private var playlistIsLoading: Bool = false

    var body: some View {
        Group {
            switch windowManager.style {
            case .main:
                mainView(window)
            case .miniPlayer:
                miniPlayerView(window)
            }
        }
        .background {
            FileImporters()

            DelegatedPlaylistStorage()
            DelegatedPlaylistStateStorage()

            UnsavedChangesPresentation()
            UnsavedPlaylistPresentation()
            PlaylistPresentation()

            WindowTerminationPresentationInjector(window: window)
            FloatingWindowsView(window: floatingWindowsTargetWindow)
            NavigationTitlesView()
            NavigationDocumentView()
        }
    }

    // MARK: - Main View

    @ViewBuilder private func mainView(_ window: NSWindow? = nil) -> some View {
        MainView()
            .background {
                Group {
                    if windowManager.isInFullScreen {
                        OpaqueBackgroundView()
                    } else {
                        switch mainWindowBackgroundStyle {
                        case .opaque:
                            OpaqueBackgroundView()
                        case .vibrant:
                            VibrantBackgroundView()
                        case .ethereal:
                            EtherealBackgroundView()
                        }
                    }
                }
                .ignoresSafeArea()
            }
            .onDisappear {
                floatingWindowsTargetWindow = nil
            }
            .onChange(of: playlist.isLoading) { _, newValue in
                if newValue {
                    floatingWindowsTargetWindow = nil
                } else {
                    floatingWindowsTargetWindow = appearsActive ? window : nil
                }
            }
            .onChange(of: window) { _, newValue in
                let needAdd = !playlist.isLoading && appearsActive
                if newValue != nil {
                    floatingWindowsTargetWindow = needAdd ? window : nil
                } else {
                    floatingWindowsTargetWindow = nil
                }
            }
            .onChange(of: appearsActive, initial: true) { _, newValue in
                if newValue {
                    floatingWindowsTargetWindow = playlist.isLoading ? nil : window
                } else {
                    floatingWindowsTargetWindow = nil
                }
            }
            .onChange(of: appearsActive, initial: true) { _, newValue in
                guard newValue else { return }

                Task.detached {
                    await library.loadPlaylists()
                }
            }
    }

    // MARK: - Mini Player View

    @ViewBuilder private func miniPlayerView(_: NSWindow? = nil) -> some View {
        MiniPlayerView()
            .padding(12)
            .padding(.top, 4)
            .padding(.bottom, -32)
            .ignoresSafeArea()
            .frame(minWidth: 500, idealWidth: 500)
            .fixedSize(horizontal: false, vertical: true)
            .background {
                Group {
                    switch miniPlayerBackgroundStyle {
                    case .opaque:
                        OpaqueBackgroundView()
                    case .vibrant:
                        VibrantBackgroundView()
                    case .ethereal:
                        EtherealBackgroundView()
                    case .chroma:
                        ChromaBackgroundView()
                            .overlay(.ultraThinMaterial)
                    }
                }
                .ignoresSafeArea()
            }
            .onAppear {
                floatingWindowsTargetWindow = nil
            }
    }
}

#if DEBUG
    #Preview(traits: .modifier(PreviewEnvironmentsModifier())) {
        InterfaceView()
    }
#endif
