//
//  PresentationManagerModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/1.
//

import SwiftUI

enum MelodicStampPresentationState: String, Equatable, Hashable, CaseIterable, Identifiable, Codable {
    // MARK: Stage 1

    case idle

    // MARK: Stage 2

    case unsavedChangesAlert
    case unsavedChangesSheet

    // MARK: Stage 3

    case unsavedPlaylistAlert

    var id: Self { self }

    var isIdle: Bool {
        switch self {
        case .idle:
            true
        default:
            false
        }
    }

    var nextStep: Self {
        switch self {
        case .idle:
            .unsavedChangesAlert
        case .unsavedChangesAlert:
            .unsavedChangesSheet
        case .unsavedChangesSheet:
            .unsavedPlaylistAlert
        case .unsavedPlaylistAlert:
            .idle
        }
    }

    var nextStage: Self {
        switch self {
        case .idle:
            .unsavedChangesAlert
        case .unsavedChangesAlert:
            .unsavedPlaylistAlert
        case .unsavedChangesSheet:
            .unsavedPlaylistAlert
        case .unsavedPlaylistAlert:
            .idle
        }
    }
}

@Observable final class PresentationManagerModel {
    private weak var windowManager: WindowManagerModel?

    init(windowManager: WindowManagerModel) {
        self.windowManager = windowManager
    }

    var state: MelodicStampPresentationState = .idle {
        didSet { update(to: state) }
    }

    // MARK: Unsaved Changes

    var isUnsavedChangesAlertPresented: Bool = false
    var isUnsavedChangesSheetPresented: Bool = false

    // MARK: Playlist

    var isUnsavedPlaylistAlertPresented: Bool = false
    var isPlaylistSegmentsSheetPresented: Bool = false

    var isPlaylistRemovalAlertPresented: Bool = false
    var isTrackRemovalAlertPresented: Bool = false
}

extension PresentationManagerModel {
    func startStaging() {
        guard state.isIdle else { return }
        windowManager?.state = .closePending
        state = state.nextStage
    }

    func cancelStaging() {
        windowManager?.state = .closeCanceled
        state = .idle
    }

    func nextStep() {
        guard !state.isIdle else {
            state = .idle
            return
        }

        if state.nextStep.isIdle {
            state = .idle
            windowManager?.state = .willClose
        } else {
            state = state.nextStep
        }
    }

    func nextStage() {
        guard !state.isIdle else {
            state = .idle
            return
        }

        if state.nextStep.isIdle {
            state = .idle
            windowManager?.state = .willClose
        } else {
            state = state.nextStage
        }
    }

    func reset() {
        isUnsavedChangesAlertPresented = false
        isUnsavedChangesSheetPresented = false
        isPlaylistSegmentsSheetPresented = false
        isPlaylistRemovalAlertPresented = false
        isTrackRemovalAlertPresented = false
    }

    func update(to state: MelodicStampPresentationState) {
        switch state {
        case .idle:
            reset()
        case .unsavedChangesAlert:
            reset()
            isUnsavedChangesAlertPresented = true
        case .unsavedChangesSheet:
            reset()
            isUnsavedChangesSheetPresented = true
        case .unsavedPlaylistAlert:
            reset()
            isUnsavedPlaylistAlertPresented = true
        }
    }
}
