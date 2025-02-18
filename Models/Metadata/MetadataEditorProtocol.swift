//
//  MetadataEditorProtocol.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/26.
//

import Foundation

struct MetadataEditingState: OptionSet {
    let rawValue: Int

    static let fine = MetadataEditingState(rawValue: 1 << 0)
    static let saving = MetadataEditingState(rawValue: 1 << 1)

    var isFine: Bool {
        switch self {
        case .fine:
            true
        default:
            false
        }
    }

    var isSaving: Bool {
        switch self {
        case .saving:
            true
        default:
            false
        }
    }
}

@MainActor protocol MetadataEditorProtocol: Modifiable {
    var metadataSet: Set<Metadata> { get }
    var hasMetadata: Bool { get }
    var state: MetadataEditingState { get }
}

extension MetadataEditorProtocol {
    var hasMetadata: Bool { !metadataSet.isEmpty }

    var state: MetadataEditingState {
        guard hasMetadata else { return [] }

        var result: MetadataEditingState = []
        let states = metadataSet.map(\.state)

        for state in states {
            switch state {
            case .fine:
                result.formUnion(.fine)
            case .saving:
                result.formUnion(.saving)
            default:
                break
            }
        }

        return result
    }

    @MainActor func restoreAll() {
        metadataSet.forEach { $0.restore() }
    }

    func updateAll(completion: (() -> ())? = nil) {
        var pending: Set<URL> = Set(metadataSet.map(\.url))
        for metadata in metadataSet {
            Task.detached {
                do {
                    try await metadata.update {
                        pending.remove(metadata.url)
                    }
                } catch {
                    pending.remove(metadata.url)
                }
            }
        }

        if let completion {
            Task.detached {
                var iteration = 0
                repeat {
                    try await Task.sleep(for: .milliseconds(100))
                    iteration += 1
                } while !pending.isEmpty && iteration < 100
                completion()
            }
        }
    }

    func writeAll(completion: (() -> ())? = nil) {
        var pending: Set<URL> = Set(metadataSet.map(\.url))
        for metadata in metadataSet {
            Task.detached {
                do {
                    try await metadata.write {
                        pending.remove(metadata.url)
                    }
                } catch {
                    pending.remove(metadata.url)
                }
            }
        }

        if let completion {
            Task.detached {
                var iteration = 0
                repeat {
                    try await Task.sleep(for: .milliseconds(100))
                    iteration += 1
                } while !pending.isEmpty && iteration < 100
                completion()
            }
        }
    }
}

extension MetadataEditorProtocol {
    var isModified: Bool {
        metadataSet.contains(where: \.isModified)
    }
}
