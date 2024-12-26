//
//  TTMLDisplayLyricLine.swift
//  Melodic Stamp
//
//  Created by Xinshao_Air on 2024/12/24.
//

 import SwiftUI
 import Luminare

 struct TTMLDisplayLyricLine: View {
     @Environment(\.luminareAnimation) private var animation
     
     var line: TTMLLyricLine
     var elapsedTime: TimeInterval
     var isHighlighted: Bool = false
     
     @State var isAnimationHighlighted: Bool = false

     var body: some View {
         VStack(alignment: .center, spacing: 5) {
             Group {
                 if isHighlighted {
                     Text(
                         line.lyrics.children.map { $0.text + String(repeating: " ", count: $0.trailingSpaceCount) }
                             .joined()
                     )
                     .font(.system(size: 36))
                     .bold()
                     .textRenderer(TTMLTextRenderer(
                         elapsedTime: elapsedTime,
                         ttmlLyrics: line.lyrics.children
                     ))
                 } else {
                     Text(
                         line.lyrics.children.map { $0.text + String(repeating: " ", count: $0.trailingSpaceCount) }
                             .joined()
                     )
                     .font(.system(size: 36))
                     .bold()
                     .foregroundStyle(.white.opacity(isAnimationHighlighted ? 1 : 0.1))
                     .brightness(isAnimationHighlighted ? 1.5 : 1.0)
                 }
                 
                 auxiliaryViews(for: line.lyrics)
                     .font(.system(size: 22))
                 
                 if isHighlighted {
                     if !line.backgroundLyrics.isEmpty {
                         Group {
                             Text(
                                 line.backgroundLyrics.children.map { $0.text + String(repeating: " ", count: $0.trailingSpaceCount) }
                                     .joined()
                             )
                             .font(.system(size: 28))
                             .bold()
                             .textRenderer(TTMLTextRenderer(
                                 elapsedTime: elapsedTime,
                                 ttmlLyrics: line.backgroundLyrics.children
                             ))
                             
                             auxiliaryViews(for: line.backgroundLyrics)
                                 .font(.system(size: 22))
                         }
                         .transition(.blurReplace)
                     }
                 }
             }
             .foregroundStyle(.white.opacity(isHighlighted ? 1 : 0.5))
             .multilineTextAlignment(line.position == .main ? .leading : .trailing)
             .frame(maxWidth: .infinity, alignment: line.position == .main ? .leading : .trailing)
         }
         .animation(nil, value: isHighlighted)
         .onChange(of: isHighlighted) { _, newValue in
             withAnimation(animation.delay(0.45)) {
                 isAnimationHighlighted = newValue
             }
         }
     }
     
     @ViewBuilder private func auxiliaryViews(for lyrics: TTMLLyrics) -> some View {
         ForEach(lyrics.translations) { translation in
             Text(translation.text)
         }
         
         if let roman = lyrics.roman {
             Text(roman)
                 .bold()
         }
     }
 }
