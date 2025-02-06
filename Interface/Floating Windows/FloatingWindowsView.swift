//
//  FloatingWindowsView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/2.
//

import SwiftUI

struct FloatingWindowsView: View {
    @Environment(FloatingWindowsModel.self) private var floatingWindows
    @Environment(WindowManagerModel.self) private var windowManager
    @Environment(PresentationManagerModel.self) private var presentationManager: PresentationManagerModel
    @Environment(FileManagerModel.self) private var fileManager: FileManagerModel
    @Environment(PlaylistModel.self) private var playlist: PlaylistModel
    @Environment(PlayerModel.self) private var player: PlayerModel
    @Environment(KeyboardControlModel.self) private var keyboardControl: KeyboardControlModel
    @Environment(MetadataEditorModel.self) private var metadataEditor: MetadataEditorModel
    @Environment(AudioVisualizerModel.self) private var audioVisualizer: AudioVisualizerModel
    @Environment(GradientVisualizerModel.self) private var gradientVisualizer: GradientVisualizerModel

    @Environment(\.namespace) private var namespace

    var window: NSWindow?

    @State private var initializationDispatch: DispatchWorkItem?

    var body: some View {
        Color.clear
            .onChange(of: window) { oldValue, newValue in
                if let newValue {
                    floatingWindows.observe(newValue)
                    initializeFloatingWindows(to: newValue)
                } else if let oldValue {
                    destroyFloatingWindows(from: oldValue)
                }
            }
    }

    @ViewBuilder private func floatingTabBarView(mainWindow: NSWindow?) -> some View {
        @Bindable var windowManager = windowManager

        FloatingTabBarView(
            selectedContentTab: $windowManager.selectedContentTab,
            selectedInspectorTab: $windowManager.selectedInspectorTab
        )
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            floatingWindows.updateTabBarPosition(size: newValue, in: mainWindow, animate: true)
        }
    }

    @ViewBuilder private func floatingPlayerView(mainWindow: NSWindow?) -> some View {
        FloatingPlayerView()
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newValue in
                floatingWindows.updatePlayerPosition(size: newValue, in: mainWindow, animate: true)
            }
    }

    private func initializeFloatingWindows(to mainWindow: NSWindow? = nil) {
        initializationDispatch?.cancel()
        let dispatch = DispatchWorkItem {
            floatingWindows.addTabBar(to: mainWindow) {
                floatingTabBarView(mainWindow: mainWindow)
                    .environment(floatingWindows)
                    .environment(windowManager)
            }

            floatingWindows.addPlayer(to: mainWindow) {
                floatingPlayerView(mainWindow: mainWindow)
                    .environment(\.namespace, namespace)
                    .environment(windowManager)
                    .environment(playlist)
                    .environment(player)
                    .environment(keyboardControl)
                    .environment(audioVisualizer)
                    .environment(gradientVisualizer)
            }
        }
        initializationDispatch = dispatch
        DispatchQueue.main.async(execute: dispatch)
    }

    private func destroyFloatingWindows(from mainWindow: NSWindow? = nil) {
        initializationDispatch?.cancel()
        floatingWindows.removeTabBar(from: mainWindow)
        floatingWindows.removePlayer(from: mainWindow)
    }
}
