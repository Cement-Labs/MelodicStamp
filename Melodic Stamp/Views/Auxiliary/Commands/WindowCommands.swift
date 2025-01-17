//
//  WindowCommands.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/8.
//

import SwiftUI

struct WindowCommands: Commands {
    @FocusedValue(\.windowManager) private var windowManager

    var body: some Commands {
        CommandGroup(after: .windowSize) {
            if let windowManager {
                @Bindable var windowManager = windowManager

                Group {
                    switch windowManager.style {
                    case .main:
                        Button("Mini Player") {
                            windowManager.style = .miniPlayer
                        }
                        .disabled(windowManager.isInFullScreen)
                    case .miniPlayer:
                        Button("Main Window") {
                            windowManager.style = .main
                        }
                    }
                }
                .keyboardShortcut("\\", modifiers: .command)
            }
        }
    }
}
