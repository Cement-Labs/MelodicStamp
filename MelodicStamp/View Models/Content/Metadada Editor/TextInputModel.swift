//
//  TextInputModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/4.
//

import SwiftUI

@MainActor @Observable final class TextInputModel<V> where V: Equatable & Hashable {
    typealias Entries = MetadataBatchEditingEntries<V?>

    private var checkpoint: Checkpoint<V?> = .invalid
    private var undoTargetCheckpoint: Checkpoint<V?> = .invalid

    func isEmpty(value: V?) -> Bool {
        guard let value else { return true }
        return switch value {
        case let value as any StringRepresentable:
            // Empty strings are empty too, as placeholders will display
            value.stringRepresentation.isEmpty
        default:
            false
        }
    }

    func areIdentical(_ oldValue: V?, _ newValue: V?) -> Bool {
        oldValue == newValue || (isEmpty(value: oldValue) && isEmpty(value: newValue))
    }

    func updateCheckpoint(for entries: Entries) {
        checkpoint.set(entries.projectedUnwrappedValue()?.wrappedValue)
    }

    func registerUndoFromCheckpoint(for entries: Entries, in undoManager: UndoManager?) {
        switch checkpoint {
        case .invalid:
            break
        case let .valid(value):
            registerUndo(value, for: entries, in: undoManager)
        }
    }

    func registerUndo(_ oldValue: V?, for entries: Entries, in undoManager: UndoManager?) {
        let value = entries.projectedUnwrappedValue()?.wrappedValue
        guard !areIdentical(oldValue, value) else { return }

        switch undoTargetCheckpoint {
        case .invalid:
            break
        case let .valid(value):
            guard !areIdentical(oldValue, value) else { return }
        }
        undoTargetCheckpoint.set(oldValue)

        undoManager?.registerUndo(withTarget: entries) { entries in
            Task { @MainActor in
                let fallback = entries.projectedUnwrappedValue()?.wrappedValue
                entries.setAll(oldValue)

                self.registerUndo(fallback, for: entries, in: undoManager)
            }
        }
    }
}
