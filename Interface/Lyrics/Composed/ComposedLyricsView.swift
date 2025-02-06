//
//  ComposedLyricsView.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/12/28.
//

import SwiftUI

struct ComposedLyricsView: View {
    @Environment(PlayerModel.self) private var player
    @Environment(LyricsModel.self) private var lyrics

    var body: some View {
        Group {
            let highlightedRange = highlightedRange
            let index = highlightedRange.upperBound - 1

            if lyrics.lines.indices.contains(index) {
                let line = lyrics.lines[index]

                if highlightedRange.contains(index), !line.content.isEmpty {
                    ComposedLyricLineView(
                        line: line, index: index,
                        highlightedRange: highlightedRange,
                        elapsedTime: elapsedTime
                    )
                } else {
                    emptyView()
                }
            } else {
                emptyView()
            }
        }
    }

    private var elapsedTime: CGFloat {
        player.unwrappedPlaybackTime.elapsed
    }

    private var highlightedRange: Range<Int> {
        lyrics.highlight(at: elapsedTime)
    }

    @ViewBuilder private func emptyView() -> some View {
        ProgressDotsView(elapsedTime: 0, beginTime: 0, endTime: 0)
            .scaleEffect(0.7)
    }
}
