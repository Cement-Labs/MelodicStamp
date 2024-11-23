//
//  FloatingWindowsModel.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/22.
//

import SwiftUI
import AppKit

@Observable class FloatingWindowsModel {
    private(set) var isTabBarAdded: Bool = false
    private(set) var isPlayBarAdded: Bool = false
    
    private var tabBarIdentifier: NSUserInterfaceItemIdentifier?
    private var playerIdentifier: NSUserInterfaceItemIdentifier?
    
    var selectedSidebarItem: SidebarItem = .home

    func addTabBar() {
        guard !isTabBarAdded else { return }
        
        if let applicationWindow = NSApp.mainWindow {
            let content = NSHostingView(rootView: FloatingTabBarView(
                model: self,
                sections: sidebarSections,
                selectedItem: .init {
                    self.selectedSidebarItem
                } set: { newValue in
                    self.selectedSidebarItem = newValue
                }
            ))
            let floatingWindow = NSWindow()
            floatingWindow.styleMask = .borderless
            floatingWindow.contentView = content
            floatingWindow.backgroundColor = .clear
            
            applicationWindow.addChildWindow(floatingWindow, ordered: .above)
            tabBarIdentifier = floatingWindow.identifier
            isTabBarAdded = true
            
            updateTabBarPosition()
        }
    }
    
    func addPlayer(model: PlayerModel) {
        guard !isPlayBarAdded else { return }

        if let applicationWindow = NSApp.mainWindow {
            let content = NSHostingView(rootView: FloatingPlayerView(floatingWindowsModel: self, playerModel: model))
            let floatingWindow = NSWindow()
            floatingWindow.styleMask = .borderless
            floatingWindow.contentView = content
            floatingWindow.backgroundColor = .clear

            applicationWindow.addChildWindow(floatingWindow, ordered: .above)
            playerIdentifier = floatingWindow.identifier
            isPlayBarAdded = true
            updatePlayerPosition()
        }
    }
    
    func updateTabBarPosition() {
        if let floatingWindow = NSApp.windows.first(where: { $0.identifier == tabBarIdentifier }), let applicationWindow = NSApp.mainWindow {
            let windowFrame = applicationWindow.frame
            let tabBarFrame = floatingWindow.frame
            
            let centerX = windowFrame.origin.x - 75
            let bottomY = windowFrame.origin.y + (windowFrame.height - tabBarFrame.height) / 2
            
            floatingWindow.setFrame(
                NSRect(
                    x: centerX,
                    y: bottomY,
                    width: tabBarFrame.width,
                    height: tabBarFrame.height
                ),
                display: true
            )
        }
    }
    
    func updatePlayerPosition() {
        if let floatingWindow = NSApp.windows.first(where: { $0.identifier == playerIdentifier }), let applicationWindow = NSApp.mainWindow {
            let windowFrame = applicationWindow.frame
            let playerFrame = floatingWindow.frame

            let centerX = windowFrame.origin.x + (windowFrame.width - playerFrame.width) / 2
            let bottomY = windowFrame.origin.y - 50

            floatingWindow.setFrame(
                NSRect(
                    x: centerX,
                    y: bottomY,
                    width: playerFrame.width,
                    height: playerFrame.height
                ),
                display: true
            )
        }
    }
}
