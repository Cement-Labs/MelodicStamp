//
//  SimpleGradientView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/2.
//

//
//  SimpleGradientView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/8.
//

import SwiftUI

struct SimpleGradientView<Content>: View where Content: View {
    var color: Color = .accent
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .shadow(radius: 1.5, y: 1)
            .background {
                color

                LinearGradient(
                    colors: [.white, .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .opacity(0.35)
                .blendMode(.luminosity)
            }
    }
}

struct SimpleGradientModifier: ViewModifier {
    var color: Color = .accent

    func body(content: Content) -> some View {
        SimpleGradientView(color: color) {
            content
        }
    }
}

#Preview {
    SimpleGradientView {
        Image(systemSymbol: .gear)
            .font(.title)
    }
    .clipShape(.rect(cornerRadius: 8))
    .padding()
}
