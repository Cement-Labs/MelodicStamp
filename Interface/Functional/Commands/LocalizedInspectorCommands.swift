//
//  LocalizedInspectorCommands.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/1.
//

import SwiftUI

struct LocalizedInspectorCommands: Commands {
    @FocusedValue(WindowManagerModel.self) private var windowManager

    var body: some Commands {
        CommandGroup(after: .sidebar) {
            // MARK: Show / Hide Inspector

            Group {
                if let windowManager {
                    Button {
                        windowManager.isInspectorPresented.toggle()
                    } label: {
                        if windowManager.isInspectorPresented {
                            Text("Hide Inspector")
                        } else {
                            Text("Show Inspector")
                        }
                    }
                } else {
                    Button("Show Inspector") {}
                        .disabled(true)
                }
            }
            .keyboardShortcut("i", modifiers: [.command, .control])
        }
    }
}
