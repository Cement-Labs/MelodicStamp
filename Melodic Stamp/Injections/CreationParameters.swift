//
//  CreationParameters.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/17.
//

import Foundation

struct CreationParameters: Hashable, Identifiable, Codable {
    let id: UUID

    var playlist: PlaylistFactory
    var shouldPlay: Bool
    var initialWindowStyle: MelodicStampWindowStyle

    init(
        playlist: PlaylistFactory = .referenced,
        shouldPlay: Bool = false,
        initialWindowStyle: MelodicStampWindowStyle = .main
    ) {
        self.playlist = playlist
        self.shouldPlay = shouldPlay
        self.initialWindowStyle = initialWindowStyle

        self.id = switch playlist {
        case .referenced:
            UUID()
        case let .canonical(id):
            id
        }
    }
}

extension CreationParameters {
    enum PlaylistFactory: Equatable, Hashable, Codable {
        case referenced([URL] = [])
        case canonical(UUID)

        static var referenced: Self { .referenced([]) }
    }
}
