//
//  TypeNameReflectable.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/1.
//

import Foundation
import OSLog

protocol TypeNameReflectable {}

extension TypeNameReflectable {
    static var typeName: String {
        String(describing: Self.self)
    }

    static var logger: Logger {
        .init(subsystem: Bundle.main.bundleIdentifier ?? "Application", category: typeName)
    }

    var logger: Logger {
        Self.logger
    }
}
