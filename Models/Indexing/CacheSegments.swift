//
//  CacheSegments.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/6.
//

import Foundation

protocol CacheSegmentIndex: RawRepresentable, CaseIterable, Codable {
    func url(relativeTo root: URL) -> URL
}

extension CacheSegmentIndex where RawValue == String {
    func url(relativeTo root: URL) -> URL {
        root.appending(path: rawValue, directoryHint: .notDirectory)
    }
}

protocol CacheSegment: Equatable, Hashable, Codable {
    associatedtype Index: CacheSegmentIndex
    
    var index: Index { get }
}

protocol CacheSegments: Equatable, Hashable, Codable {
    associatedtype Index: CacheSegmentIndex
}

extension CacheSegments {
    static func read(segment: Index, fromDirectory root: URL) throws -> Data {
        let url = segment.url(relativeTo: root)
        return try Data(contentsOf: url)
    }
    
    static func write(segment: Index, ofData fileData: Data, toDirectory root: URL) throws {
        let url = segment.url(relativeTo: root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try fileData.write(to: url)
    }
}
