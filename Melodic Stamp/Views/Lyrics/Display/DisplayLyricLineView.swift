//
//  DisplayLyricLineView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/3.
//

import SwiftUI

struct DisplayLyricLineView: View {
    @Environment(PlayerModel.self) private var player

    var line: any LyricLine
    var index: Int
    var highlightedRange: Range<Int>
    var elapsedTime: TimeInterval
    var shouldFade: Bool = false
    var shouldAnimate: Bool = true

    @State private var isHovering: Bool = false

    var body: some View {
        // Avoids multiple instantializations
        let isActive = isActive
        let blurRadius = blurRadius(for: index, in: highlightedRange)
        let opacity = opacity(for: index, in: highlightedRange)

        AliveButton(enabledStyle: .white) {
            guard let beginTime = line.beginTime else { return }
            player.time = beginTime
        } label: {
            Group {
                switch line {
                case let line as RawLyricLine:
                    rawLyricLine(line: line, index: index, isHighlighted: isHighlighted)
                case let line as LRCLyricLine:
                    lrcLyricLine(line: line, index: index, isHighlighted: isHighlighted)
                case let line as TTMLLyricLine:
                    ttmlLyricLine(line: line, index: index, isHighlighted: isHighlighted)
                default:
                    EmptyView()
                }
            }
            .padding(8.5)
            .blur(radius: isActive || !shouldFade ? 0 : blurRadius)
            .opacity(isActive || !shouldFade ? 1 : opacity)
            .background {
                Rectangle()
                    .foregroundStyle(.background)
                    .opacity(isHovering ? 0.1 : 0)
            }
            .clipShape(.rect(cornerRadius: 12))
            .onHover { hover in
                isHovering = hover
            }
            .animation(.smooth(duration: 0.25), value: isHovering)
        }
    }

    private var isHighlighted: Bool {
        highlightedRange.contains(index)
    }

    private var isActive: Bool {
        isHighlighted || isHovering || !shouldAnimate
    }

    @ViewBuilder private func rawLyricLine(line: RawLyricLine, index _: Int, isHighlighted _: Bool) -> some View {
        Text(line.content)
            .font(.title)
            .bold()
    }

    @ViewBuilder private func lrcLyricLine(line: LRCLyricLine, index _: Int, isHighlighted: Bool) -> some View {
        LRCDisplayLyricLineView(
            line: line, isHighlighted: isHighlighted
        )
    }

    @ViewBuilder private func ttmlLyricLine(line: TTMLLyricLine, index _: Int, isHighlighted: Bool) -> some View {
        TTMLDisplayLyricLineView(
            line: line, elapsedTime: elapsedTime,
            isHighlighted: isHighlighted,
            shouldAnimate: shouldAnimate
        )
    }

    private func opacity(for index: Int, in highlightedRange: Range<Int>) -> CGFloat {
        let distance = abs(index - (highlightedRange.lowerBound))
        let maxOpacity = 0.55
        let minOpacity = 0.125
        let factor = maxOpacity - (CGFloat(distance) * 0.05)
        return max(minOpacity, min(factor, maxOpacity))
    }

    private func blurRadius(for index: Int, in highlightedRange: Range<Int>) -> CGFloat {
        let distance = abs(index - (highlightedRange.lowerBound))
        let maxBlur = 6.0
        let minBlur = 1.0
        let factor = CGFloat(distance) * 1.0
        return max(minBlur, min(factor, maxBlur))
    }
}
