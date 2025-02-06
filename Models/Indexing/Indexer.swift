//
//  Indexer.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/29.
//

import Foundation

protocol Indexer: Equatable, Hashable {
    associatedtype Value: Codable

    var fileName: String { get }
    var folderURL: URL { get }

    var value: Value { get set }
}

extension Indexer {
    var fileName: String { ".index" }

    var url: URL {
        folderURL.appending(path: fileName, directoryHint: .notDirectory)
    }

    func read(defaultValue: Value) -> Value {
        read() ?? defaultValue
    }

    func read() -> Value? {
        if
            let data = try? Data(contentsOf: url),
            let value = try? JSONDecoder().decode(Value.self, from: data) {
            value
        } else {
            nil
        }
    }

    func write() throws {
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(value)
        try data.write(to: url)
    }
}
