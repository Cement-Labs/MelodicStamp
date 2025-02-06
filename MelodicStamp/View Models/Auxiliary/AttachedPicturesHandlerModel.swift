//
//  AttachedPicturesHandlerModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/1.
//

@preconcurrency import CSFBAudioEngine
import SwiftUI
import UniformTypeIdentifiers

@MainActor @Observable class AttachedPicturesHandlerModel {
    typealias APType = AttachedPicture.`Type`
    typealias Entry = MetadataBatchEditingEntry<Set<AttachedPicture>>
    typealias Entries = MetadataBatchEditingEntries<Set<AttachedPicture>>

    static var allowedContentTypes: [UTType] {
        [.jpeg, .png, .tiff, .bmp, .gif, .heic, .heif, .webP, .rawImage]
    }

    private func isModified(of types: [APType]? = nil, entry: Entry, countAsEmpty fallback: Bool = true) -> Bool {
        guard let types else { return false }
        return !entry.current
            .filter { types.contains($0.type) }
            .filter { currentValue in
                guard
                    let initialValue = entry.initial.filter({
                        $0.type == currentValue.type
                    }).first
                else { return fallback }
                return currentValue != initialValue
            }
            .isEmpty
    }

    func isModified(of types: [APType]? = nil, entries: Entries, countAsEmpty fallback: Bool = true) -> Bool {
        !entries
            .filter { isModified(of: types, entry: $0, countAsEmpty: fallback) }
            .isEmpty
    }

    func types(of entries: Entries) -> Set<APType> {
        Set(entries.flatMap(\.current).map(\.type))
    }

    // MARK: Replace

    private func replacing(
        _ newAttachedPictures: [AttachedPicture],
        in attachedPictures: Set<AttachedPicture>
    ) -> Set<AttachedPicture> {
        let types = newAttachedPictures.map(\.type)
        let removed = attachedPictures.filter { !types.contains($0.type) }
        return removed.union(newAttachedPictures)
    }

    private func replace(_ newAttachedPictures: [AttachedPicture], entry: Entry) {
        entry.current = replacing(newAttachedPictures, in: entry.current)
    }

    func replace(_ newAttachedPictures: [AttachedPicture], entries: Entries, undoManager: UndoManager?) {
        withUndo(for: entries, in: undoManager) {
            entries.forEach { replace(newAttachedPictures, entry: $0) }
        }
    }

    // MARK: Remove

    private func removing(
        of types: [APType]? = nil, in attachedPictures: Set<AttachedPicture>
    ) -> Set<AttachedPicture> {
        if let types {
            attachedPictures.filter { !types.contains($0.type) }
        } else {
            []
        }
    }

    private func remove(of types: [APType]? = nil, entry: Entry) {
        entry.current = removing(of: types, in: entry.current)
    }

    func remove(of types: [APType]? = nil, entries: Entries, undoManager: UndoManager?) {
        withUndo(for: entries, in: undoManager) {
            entries.forEach { remove(of: types, entry: $0) }
        }
    }

    // MARK: Restore

    private func restore(of types: [APType]? = nil, entry: Entry) {
        guard let types else {
            entry.restore()
            return
        }

        let initialAttachedPictures: [AttachedPicture] = entry.initial.filter {
            types.contains($0.type)
        }

        if initialAttachedPictures.isEmpty {
            remove(of: types, entry: entry)
        } else {
            replace(initialAttachedPictures, entry: entry)
        }
    }

    func restore(of types: [APType]? = nil, entries: Entries, undoManager: UndoManager?) {
        guard let types else {
            withUndo(for: entries, in: undoManager) {
                entries.restoreAll()
            }
            return
        }

        withUndo(for: entries, in: undoManager) {
            entries.forEach { restore(of: types, entry: $0) }
        }
    }
}

extension AttachedPicturesHandlerModel {
    func copy(contents entries: Entries) -> Set<AttachedPicture> {
        let oldValue = entries.projectedValue?.wrappedValue ?? []
        var newValue: Set<AttachedPicture> = []
        oldValue.forEach { newValue.insert($0.copy() as! AttachedPicture) }
        return newValue
    }

    func registerUndo(_ oldValue: Set<AttachedPicture>, for entries: Entries, in undoManager: UndoManager?) {
        guard oldValue != entries.projectedValue?.wrappedValue ?? [] else { return }
        undoManager?.registerUndo(withTarget: self) { _ in
            Task { @MainActor in
                let fallback = self.copy(contents: entries)
                entries.setAll(oldValue)

                self.registerUndo(fallback, for: entries, in: undoManager)
            }
        }
    }

    private func withUndo(for entries: Entries, in undoManager: UndoManager?, _ body: () -> ()) {
        let fallback = copy(contents: entries)
        body()
        registerUndo(fallback, for: entries, in: undoManager)
    }
}
