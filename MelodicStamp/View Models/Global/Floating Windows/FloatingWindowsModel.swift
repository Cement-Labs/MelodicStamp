//
//  FloatingWindowsModel.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/22.
//

import AppKit
import SwiftUI

@Observable final class FloatingWindowsModel {
    private weak var targetWindow: NSWindow?

    private var isInFullScreen: Bool = false

    var isHidden: Bool = false {
        didSet {
            if isHidden {
                hide()
                isVisibilityDelegated = true
            } else {
                show()
                isVisibilityDelegated = false
            }
        }
    }

    private var isVisibilityDelegated: Bool = false

    var tabBarWindow: NSWindow?
    var playerWindow: NSWindow?

    var isTabBarAdded: Bool { tabBarWindow != nil }
    var isPlayerAdded: Bool { playerWindow != nil }

    private var observationDispatch: DispatchWorkItem?
    private var tabBarAdditionDispatch: DispatchWorkItem?
    private var playerAdditionDispatch: DispatchWorkItem?

    @MainActor func observe(_ window: NSWindow? = nil) {
        removeTabBar(from: targetWindow)
        removePlayer(from: targetWindow)
        targetWindow = window

        NotificationCenter.default.removeObserver(self)
        guard let window else { return }

        isInFullScreen = window.isInFullScreen

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillEnterFullScreen),
            name: NSWindow.willEnterFullScreenNotification,
            object: window
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidEnterFullScreen),
            name: NSWindow.didEnterFullScreenNotification,
            object: window
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillExitFullScreen),
            name: NSWindow.willExitFullScreenNotification,
            object: window
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidExitFullScreen),
            name: NSWindow.didExitFullScreenNotification,
            object: window
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: window
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: window
        )
    }

    private func show() {
        tabBarWindow?.animator().alphaValue = 1
        playerWindow?.animator().alphaValue = 1
    }

    private func hide() {
        tabBarWindow?.animator().alphaValue = 0
        playerWindow?.animator().alphaValue = 0
    }

    @MainActor func addTabBar(to mainWindow: NSWindow? = nil, @ViewBuilder content: @MainActor @escaping () -> some View) {
        guard !isTabBarAdded else { return }
        guard
            mainWindow == targetWindow,
            let applicationWindow = mainWindow ?? NSApp.mainWindow
        else { return }

        let floatingWindow = NSWindow()
        tabBarWindow = floatingWindow

        floatingWindow.styleMask = .borderless
        floatingWindow.contentView = NSHostingView(rootView: content())
        floatingWindow.backgroundColor = .clear
        floatingWindow.level = .floating
        floatingWindow.collectionBehavior = [.fullScreenNone]

        tabBarAdditionDispatch?.cancel()
        let dispatch = DispatchWorkItem {
            applicationWindow.addChildWindow(floatingWindow, ordered: .above)
            self.updateTabBarPosition(window: floatingWindow, in: applicationWindow)
            self.isHidden = false
        }
        tabBarAdditionDispatch = dispatch
        DispatchQueue.main.async(execute: dispatch)
    }

    @MainActor func addPlayer(to mainWindow: NSWindow? = nil, @ViewBuilder content: @MainActor @escaping () -> some View) {
        guard !isPlayerAdded else { return }
        guard
            mainWindow == targetWindow,
            let applicationWindow = mainWindow ?? NSApp.mainWindow
        else { return }

        let floatingWindow = NSWindow()
        playerWindow = floatingWindow

        floatingWindow.styleMask = .borderless
        floatingWindow.contentView = NSHostingView(rootView: content())
        floatingWindow.backgroundColor = .clear
        floatingWindow.level = .floating
        floatingWindow.collectionBehavior = [.fullScreenNone]

        playerAdditionDispatch?.cancel()
        let dispatch = DispatchWorkItem {
            applicationWindow.addChildWindow(floatingWindow, ordered: .above)
            self.updatePlayerPosition(window: floatingWindow, in: applicationWindow)
            self.isHidden = false
        }
        playerAdditionDispatch = dispatch
        DispatchQueue.main.async(execute: dispatch)
    }

    @MainActor func removeTabBar(from mainWindow: NSWindow? = nil) {
        guard
            mainWindow == targetWindow,
            let tabBarWindow,
            let applicationWindow = mainWindow ?? NSApp.mainWindow
        else { return }

        tabBarAdditionDispatch?.cancel()
        applicationWindow.removeChildWindow(tabBarWindow)
        tabBarWindow.orderOut(nil)
        self.tabBarWindow = nil
    }

    @MainActor func removePlayer(from mainWindow: NSWindow? = nil) {
        guard
            mainWindow == targetWindow,
            let playerWindow,
            let applicationWindow = mainWindow ?? NSApp.mainWindow
        else { return }

        playerAdditionDispatch?.cancel()
        applicationWindow.removeChildWindow(playerWindow)
        playerWindow.orderOut(nil)
        self.playerWindow = nil
    }

    @MainActor func updateTabBarPosition(window: NSWindow? = nil, size: CGSize? = nil, in mainWindow: NSWindow? = nil, animate: Bool = false) {
        guard
            let tabBarWindow = window ?? tabBarWindow,
            let applicationWindow = mainWindow ?? NSApp.keyWindow,
            let screen = NSScreen.main
        else { return }

        let tabBarFrame = tabBarWindow.frame
        let tabBarSize = size ?? tabBarFrame.size
        let windowFrame = applicationWindow.frame
        let screenFrame = screen.frame

        let leadingX = windowFrame.origin.x - 16 - 48
        let bottomY = windowFrame.origin.y + (windowFrame.height - tabBarSize.height) / 2

        tabBarWindow.setFrame(
            .init(
                x: max(screenFrame.minX + 8, leadingX),
                y: bottomY,
                width: tabBarSize.width,
                height: tabBarSize.height
            ),
            display: true,
            animate: animate
        )
    }

    @MainActor func updatePlayerPosition(window: NSWindow? = nil, size: CGSize? = nil, in mainWindow: NSWindow? = nil, animate: Bool = false) {
        guard
            let playerWindow = window ?? playerWindow,
            let applicationWindow = mainWindow ?? NSApp.keyWindow,
            let screen = NSScreen.main
        else { return }

        let playerFrame = playerWindow.frame
        let playerSize = size ?? playerFrame.size
        let windowFrame = applicationWindow.frame
        let screenFrame = screen.frame

        let idealWidth: CGFloat = min(800, windowFrame.width - 2 * 12)

        let centerX = windowFrame.origin.x + (windowFrame.width - idealWidth) / 2
        let bottomY = windowFrame.origin.y - 32

        playerWindow.setFrame(
            .init(
                x: centerX,
                y: max(screenFrame.minY + 8, bottomY),
                width: idealWidth,
                height: playerSize.height
            ),
            display: true,
            animate: animate
        )
    }
}

extension FloatingWindowsModel {
    @objc func windowWillEnterFullScreen(_: Notification) {
        isInFullScreen = true

        guard !isVisibilityDelegated else { return }
        hide()
    }

    @objc func windowDidEnterFullScreen(_: Notification) {
        guard !isVisibilityDelegated else { return }
        show()
    }

    @objc func windowWillExitFullScreen(_: Notification) {
        isInFullScreen = false

        guard !isVisibilityDelegated else { return }
        hide()
    }

    @objc func windowDidExitFullScreen(_: Notification) {
        guard !isVisibilityDelegated else { return }
        show()
    }

    @MainActor @objc func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        updateTabBarPosition(in: window)
        updatePlayerPosition(in: window)
    }

    @MainActor @objc func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        updateTabBarPosition(in: window)
        updatePlayerPosition(in: window)
    }
}
