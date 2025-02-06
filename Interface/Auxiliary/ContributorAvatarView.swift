//
//  ContributorAvatarView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/21.
//

import SwiftUI

enum ContributorAvatarSource {
    case local(ImageResource)
    case remote(URL?)
}

struct ContributorAvatarView: View {
    @Environment(\.openURL) private var openURL

    var source: ContributorAvatarSource
    var size: CGFloat = 32

    var body: some View {
        Group {
            switch source {
            case let .local(imageResource):
                Image(imageResource)
                    .resizable()
                    .scaledToFill()
            case let .remote(url):
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .onTapGesture {
                                if let url {
                                    openURL(url)
                                }
                            }
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .padding(.vertical, 6)
    }
}

#Preview {
    ContributorAvatarView(source: .local(.templateArtwork))
}
