//
//  MetadataEntry.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/5.
//

import SwiftUI

// MARK: - Modifiable

protocol Modifiable {
    var isModified: Bool { get }
}

// MARK: - Restorable

protocol Restorable: Equatable, Modifiable {
    associatedtype V: Equatable

    var current: V { get set }
    var initial: V { get set }

    @MainActor mutating func restore()
    @MainActor mutating func apply()
}

extension Restorable {
    var isModified: Bool {
        current != initial
    }

    @MainActor mutating func restore() {
        current = initial
    }

    @MainActor mutating func apply() {
        initial = current
    }
}

// MARK: - Metadata Entry

@Observable final class MetadataEntry<V: Hashable & Equatable>: Restorable {
    var current: V
    var initial: V

    init(_ value: V) {
        self.current = value
        self.initial = value
    }
}

extension MetadataEntry: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(current)
        hasher.combine(initial)
    }
}

extension MetadataEntry: Equatable {
    static func == (lhs: MetadataEntry<V>, rhs: MetadataEntry<V>) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Metadata Batch Editing Entry

@Observable final class MetadataBatchEditingEntry<V: Hashable & Equatable>: Identifiable {
    typealias Entry = MetadataEntry
    typealias EntryKeyPath = WritableKeyPath<Metadata, Entry<V>>

    let keyPath: EntryKeyPath
    let metadata: Metadata

    init(keyPath: EntryKeyPath, metadata: Metadata) {
        self.keyPath = keyPath
        self.metadata = metadata
    }

    var current: V {
        get {
            metadata[keyPath: keyPath].current
        }

        set {
            metadata[keyPath: keyPath].current = newValue
        }
    }

    private(set) var initial: V {
        get {
            metadata[keyPath: keyPath].initial
        }

        set {
            metadata[keyPath: keyPath].initial = newValue
        }
    }

    var projectedValue: Binding<V> {
        Binding {
            self.current
        } set: { newValue in
            self.current = newValue
        }
    }

    func projectedUnwrappedValue<Wrapped>() -> Binding<Wrapped>? where V == Wrapped? {
        if let current {
            Binding {
                current
            } set: { newValue in
                self.current = newValue
            }
        } else {
            nil
        }
    }

    var isModified: Bool {
        current != initial
    }

    func restore() {
        current = initial
    }

    func apply() {
        initial = current
    }
}

extension MetadataBatchEditingEntry: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(keyPath)
        hasher.combine(metadata)
    }
}

extension MetadataBatchEditingEntry: Equatable {
    static func == (lhs: MetadataBatchEditingEntry<V>, rhs: MetadataBatchEditingEntry<V>) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Metadata Batch Editing Entries

@Observable final class MetadataBatchEditingEntries<V: Hashable & Equatable>: Identifiable {
    typealias Entry = MetadataEntry
    typealias EntryKeyPath = WritableKeyPath<Metadata, Entry<V>>

    let keyPath: EntryKeyPath
    let metadatas: Set<Metadata>

    private var isRestoring: Bool = false

    init(keyPath: EntryKeyPath, metadatas: Set<Metadata>) {
        self.keyPath = keyPath
        self.metadatas = metadatas
    }

    var projectedValue: Binding<V>? {
        switch type {
        case .none, .varied:
            nil
        case .identical:
            if let current = map(\.current).first {
                Binding {
                    current
                } set: { newValue in
                    self.setAll(newValue)
                }
            } else {
                nil
            }
        }
    }

    func projectedUnwrappedValue<Wrapped>() -> Binding<Wrapped>? where V == Wrapped? {
        switch type {
        case .none, .varied:
            nil
        case .identical:
            if let current = map(\.current).first, let current {
                Binding {
                    current
                } set: { newValue in
                    self.setAll(newValue)
                }
            } else {
                nil
            }
        }
    }

    var type: MetadataValueType {
        if metadatas.isEmpty || isRestoring {
            return .none
        } else {
            let values = map(\.current)
            let areIdentical = values.allSatisfy { $0 == values[0] }

            return areIdentical ? .identical : .varied
        }
    }

    var isModified: Bool {
        contains(where: \.isModified)
    }

    func restoreAll() {
        isRestoring = true
        forEach { $0.restore() }
        isRestoring = false
    }

    func applyAll() {
        forEach { $0.apply() }
    }

    func setAll(_ newValue: V) {
        forEach { $0.current = newValue }
    }

    func setAll(updating: @escaping (V) -> V) {
        forEach { $0.current = updating($0.current) }
    }
}

extension MetadataBatchEditingEntries: Sequence {
    func makeIterator() -> Array<MetadataBatchEditingEntry<V>>.Iterator {
        metadatas.compactMap { $0[extracting: keyPath] }.makeIterator()
    }
}

extension MetadataBatchEditingEntries: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(keyPath)
        hasher.combine(metadatas)
    }
}

extension MetadataBatchEditingEntries: Equatable {
    static func == (lhs: MetadataBatchEditingEntries<V>, rhs: MetadataBatchEditingEntries<V>) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Metadata Value Type

enum MetadataValueType: String, Hashable, Equatable, CaseIterable, Identifiable, Codable {
    case none
    case identical
    case varied

    var id: Self { self }
}
