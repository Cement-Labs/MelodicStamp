//
//  WindowManagerModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/8.
//

import SwiftUI

enum MelodicStampWindowStyle: String, Equatable, Hashable, CaseIterable, Identifiable, Codable {
    case main
    case miniPlayer

    var id: Self { self }
}

enum MelodicStampWindowState: String, Equatable, Hashable, CaseIterable, Identifiable, Codable {
    case idle
    case closePending
    case closeCanceled
    case willClose

    var id: Self { self }

    var shouldForceClose: Bool {
        switch self {
        case .willClose:
            true
        default:
            false
        }
    }
}

@Observable final class WindowManagerModel {
    private weak var appDelegate: AppDelegate?
    private weak var window: NSWindow?
    private(set) var isInFullScreen: Bool = false

    var style: MelodicStampWindowStyle {
        didSet { update(to: style) }
    }

    var isAlwaysOnTop: Bool = false
    var isInspectorPresented: Bool = false
    var selectedContentTab: SidebarContentTab = .playlist
    var selectedInspectorTab: SidebarInspectorTab = .commonMetadata

    var hasConcreteParameters: Bool = false
    var state: MelodicStampWindowState = .idle {
        didSet { update(to: state) }
    }

    init(style: MelodicStampWindowStyle = .main, appDelegate: AppDelegate) {
        self.style = style
        self.appDelegate = appDelegate
    }

    func observe(_ window: NSWindow? = nil) {
        self.window = window
        NotificationCenter.default.removeObserver(self)
        guard let window else { return }

        isInFullScreen = window.isInFullScreen

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidEnterFullScreen),
            name: NSWindow.didEnterFullScreenNotification,
            object: window
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidExitFullScreen),
            name: NSWindow.didExitFullScreenNotification,
            object: window
        )
    }
}

extension WindowManagerModel {
    func update(to style: MelodicStampWindowStyle) {
        switch style {
        case .main:
            isAlwaysOnTop = false
        case .miniPlayer:
            isAlwaysOnTop = true
        }
    }

    func update(to state: MelodicStampWindowState) {
        switch state {
        case .closeCanceled:
            appDelegate?.resumeWindowSuspension()
            self.state = .idle
        case .willClose:
            DispatchQueue.main.async {
                self.window?.performClose(nil)
            }
        default:
            break
        }
    }
}

extension WindowManagerModel {
    @objc func windowDidEnterFullScreen() {
        isInFullScreen = true
    }

    @objc func windowDidExitFullScreen() {
        isInFullScreen = false
    }
}
