//
//  ContentOffsetModifier.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/30.
//

import SwiftUI

struct ContentOffsetModifier: ViewModifier {
    var name: AnyHashable
    @Binding var offset: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    offset = proxy.frame(in: .named(name)).minY
                    return Color.clear
                }
            }
    }
}
