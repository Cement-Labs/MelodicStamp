//
//  Defaults+MotionLevel.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/1.
//

import Defaults
import Foundation

extension Defaults {
    enum MotionLevel: String, Hashable, Equatable, CaseIterable, Identifiable, Codable, Serializable {
        case minimal
        case reduced
        case fancy

        var id: Self { self }
    }
}

extension Defaults.MotionLevel {
    var canBeFancy: Bool {
        switch self {
        case .fancy:
            true
        default:
            false
        }
    }

    var canBeReduced: Bool {
        switch self {
        case .reduced, .fancy:
            true
        default:
            false
        }
    }

    var isMinimal: Bool {
        switch self {
        case .minimal:
            true
        default:
            false
        }
    }
}
