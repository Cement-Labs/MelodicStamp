//
//  TTMLDisplayLyricLineView.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/12/24.
//

import Defaults
import SwiftUI

struct TTMLDisplayLyricLineView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Default(.lyricsAttachments) private var attachments

    var line: TTMLLyricLine
    var elapsedTime: TimeInterval
    var isHighlighted: Bool = false
    var shouldAnimate: Bool = true

    var inactiveOpacity: Double = 0.55
    var highlightReleasingDelay: TimeInterval = 0.25

    @State private var isActive: Bool = false
    @State private var backgroundContentSize: CGSize = .zero

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                if isActive {
                    activeContent()
                        .frame(maxWidth: .infinity, alignment: alignment)
                } else {
                    inactiveContent()
                        .frame(maxWidth: .infinity, alignment: alignment)
                }
            }

            // Shows background lyrics when necessary
            if !line.backgroundLyrics.isEmpty {
                if isActive {
                    activebackgroundContent()
                        .frame(maxWidth: .infinity, alignment: alignment)
                } else {
                    inactivebackgroundContent()
                        .frame(maxWidth: .infinity, alignment: alignment)
                }
            }
        }
        .multilineTextAlignment(textAlignment)
        .frame(maxWidth: .infinity, alignment: alignment)
        .onChange(of: isHighlighted, initial: true) { _, newValue in
            if !newValue {
                withAnimation(.smooth(duration: 0.8).delay(highlightReleasingDelay)) {
                    isActive = false
                }
            } else {
                withAnimation(.smooth(duration: 0.8)) {
                    isActive = true
                }
            }
        }
    }

    private var textAlignment: TextAlignment {
        switch line.position {
        case .main:
            .leading
        case .sub:
            .trailing
        }
    }

    private var alignment: Alignment {
        switch line.position {
        case .main:
            .leading
        case .sub:
            .trailing
        }
    }

    @ViewBuilder private func activeContent() -> some View {
        VStack(alignment: alignment.horizontal, spacing: 5) {
            Group {
                if shouldAnimate {
                    let lyricsRenderer = textRenderer(for: line.lyrics)

                    Text(line.content)
                        .textRenderer(lyricsRenderer)
                } else {
                    Text(line.content)
                }
            }
            .font(.system(size: 24 * dynamicTypeSize.scale))
            .bold()

            additionalContent(for: line.lyrics)
                .font(.system(size: 14 * dynamicTypeSize.scale))
                .opacity(0.75)
        }
    }

    @ViewBuilder private func inactiveContent() -> some View {
        VStack(alignment: alignment.horizontal, spacing: 5) {
            Text(line.content)
                .font(.system(size: 24 * dynamicTypeSize.scale))
                .bold()
                .opacity(inactiveOpacity)

            additionalContent(for: line.lyrics)
                .font(.system(size: 14 * dynamicTypeSize.scale))
                .opacity(inactiveOpacity)
        }
    }

    @ViewBuilder private func activebackgroundContent() -> some View {
        VStack(alignment: alignment.horizontal, spacing: 5) {
            Group {
                if shouldAnimate {
                    let backgroundLyricsRenderer = textRenderer(for: line.backgroundLyrics)

                    Text(line.backgroundContent)
                        .textRenderer(backgroundLyricsRenderer)
                } else {
                    Text(line.backgroundContent)
                }
            }
            .font(.system(size: 18.5 * dynamicTypeSize.scale))
            .bold()

            additionalContent(for: line.backgroundLyrics)
                .font(.system(size: 14 * dynamicTypeSize.scale))
                .opacity(0.75)
        }
    }

    @ViewBuilder private func inactivebackgroundContent() -> some View {
        VStack(alignment: alignment.horizontal, spacing: 5) {
            Text(line.backgroundContent)
                .font(.system(size: 18.5 * dynamicTypeSize.scale))
                .opacity(inactiveOpacity)
                .bold()

            additionalContent(for: line.backgroundLyrics)
                .font(.system(size: 14 * dynamicTypeSize.scale))
                .opacity(inactiveOpacity)
        }
    }

    @ViewBuilder private func additionalContent(for lyrics: TTMLLyrics) -> some View {
        if attachments.contains(.translation) {
            ForEach(lyrics.translations) { translation in
                Text(translation.text)
            }
        }

        if attachments.contains(.roman), let roman = lyrics.roman {
            Text(roman)
                .bold()
        }
    }

    private func textRenderer(for lyrics: TTMLLyrics) -> some TextRenderer {
        DisplayLyricsRenderer(
            elapsedTime: elapsedTime,
            strings: lyrics.children, vowelTimes: lyrics.vowelTimes,
            inactiveOpacity: inactiveOpacity
        )
    }
}
