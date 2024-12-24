//
//  PlaybackLoopingView.swift
//  Melodic Stamp
//
//  Created by KrLite on 2024/12/24.
//

import SwiftUI
import Luminare

struct PlaybackLoopingView: View {
    @Environment(\.luminareAnimation) private var animation
    
    var isEnabled: Bool = false
    
    var body: some View {
        Image(systemSymbol: .repeat1)
            .background {
                if isEnabled {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.quaternary)
                        .padding(-4)
                }
            }
            .animation(animation, value: isEnabled)
    }
}

#Preview {
    @Previewable @State var isEnabled: Bool = false
    
    Button("Toggle") {
        isEnabled.toggle()
    }
    
    PlaybackLoopingView(isEnabled: isEnabled)
        .padding()
}
