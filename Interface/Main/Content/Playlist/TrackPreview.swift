//
//  TrackPreview.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/25.
//

import Luminare
import SwiftUI

struct TrackPreview: View {
    var track: any Track
    var titleEntry: KeyPath<MetadataBatchEditingEntry, String?> = \.initial

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let thumbnail = track.metadata.unwrapped?.thumbnail {
                    MusicCover(images: [thumbnail], cornerRadius: 2)
                } else {
                    MusicCover(cornerRadius: 2)
                }
            }
            .frame(width: 50)
            .overlay(alignment: .topLeading) {
                if let duration = track.metadata.unwrapped?.properties.duration.map(Duration.init) {
                    DurationText(duration: duration)
                        .font(.system(size: 7))
                        .padding(.horizontal, 2)
                        .foregroundStyle(.white)
                        .shadow(color: .black, radius: 2)
                }
            }

            VStack(alignment: .leading) {
                HStack {
                    MusicTitle(track: track, mode: .title, entry: titleEntry)

                    switch track.metadata.unwrapped?.state {
                    case let .interrupted(error), let .dropped(error):
                        Image(systemSymbol: .exclamationmarkCircleFill)
                            .foregroundStyle(.red)
                            .luminarePopover {
                                MetadataErrorView(error: error)
                                    .padding()
                            }
                    default:
                        EmptyView()
                    }
                }
                .font(.callout)

                MusicTitle(track: track, mode: .artists, entry: titleEntry)
                    .font(.caption)
            }
        }
    }
}

#if DEBUG
//    #Preview {
//        TrackPreview(track: PreviewEnvironmentsModifier.sampleTrack)
//    }
#endif
