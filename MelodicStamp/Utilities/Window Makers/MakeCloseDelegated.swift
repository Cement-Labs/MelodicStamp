//
//  MakeCloseDelegated.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/26.
//

import SwiftUI

struct MakeCloseDelegated: NSViewControllerRepresentable {
    var shouldClose: Bool = false
    var onClose: (NSWindow, Bool) -> ()

    func makeNSViewController(context: Context) -> NSViewController {
        let hostingController = CloseDelegatedWindowHostingController(
            rootView: EmptyView(),
            parent: self
        )
        context.coordinator.hostingController = hostingController

        return hostingController
    }

    func updateNSViewController(_: NSViewController, context: Context) {
        context.coordinator.hostingController.delegate.parent = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var hostingController: CloseDelegatedWindowHostingController<EmptyView>!
    }
}

class CloseDelegatedWindowHostingController<Content: View>: NSHostingController<Content> {
    var delegate: CloseDelegatedWindowDelegate

    init(rootView: Content, parent: MakeCloseDelegated) {
        self.delegate = .init(parent: parent)
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    @MainActor @preconcurrency dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillLayout() {
        super.viewWillLayout()

        guard let window = view.window else { return }
        if !(window.delegate is CloseDelegatedWindowDelegate) {
            delegate.originalDelegate = window.delegate
            window.delegate = delegate
        }
    }
}

class CloseDelegatedWindowDelegate: NSObject, NSWindowDelegate {
    weak var originalDelegate: NSWindowDelegate?
    var parent: MakeCloseDelegated

    init(parent: MakeCloseDelegated) {
        self.parent = parent
    }

    func windowShouldClose(_ window: NSWindow) -> Bool {
        let shouldClose = parent.shouldClose
        parent.onClose(window, shouldClose)
        return shouldClose
    }

    override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || (originalDelegate?.responds(to: aSelector) ?? false)
    }

    override func forwardingTarget(for _: Selector!) -> Any? {
        originalDelegate
    }
}
