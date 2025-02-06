//
//  AppleMusicLyricsViewInteractionModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/5.
//

import SwiftUI

@Observable final class AppleMusicLyricsViewInteractionModel {
    var state: AppleMusicLyricsViewInteractionState = .following {
        didSet { update(to: state) }
    }

    var countDownDelay: TimeInterval = 1
    var countDownDuration: TimeInterval = 3

    var hasProgressRing: Bool = true
    var delegationProgress: CGFloat = .zero

    private var dispatch: DispatchWorkItem?

    func reset() {
        guard !state.isIsolated else { return }
        state = .intermediate
    }

    func update(to state: AppleMusicLyricsViewInteractionState) {
        switch state {
        case .following:
            dispatch?.cancel()
            hasProgressRing = false
            delegationProgress = .zero
        case .countingDown:
            dispatch?.cancel()
            hasProgressRing = true
            delegationProgress = .zero

            let dispatch = DispatchWorkItem {
                withAnimation(.smooth(duration: self.countDownDuration)) {
                    self.delegationProgress = 1
                }

                let dispatch = DispatchWorkItem {
                    self.state = .following
                }
                self.dispatch = dispatch
                DispatchQueue.main.asyncAfter(deadline: .now() + self.countDownDuration, execute: dispatch)
            }
            self.dispatch = dispatch
            DispatchQueue.main.async(execute: dispatch)
        case .isolated:
            dispatch?.cancel()
            hasProgressRing = false
            delegationProgress = .zero

            let dispatch = DispatchWorkItem {
                withAnimation(.smooth) {
                    self.delegationProgress = 1
                }
            }
            self.dispatch = dispatch
            DispatchQueue.main.async(execute: dispatch)
        case .intermediate:
            dispatch?.cancel()
            hasProgressRing = false
            delegationProgress = .zero

            let dispatch = DispatchWorkItem {
                let dispatch = DispatchWorkItem {
                    self.state = .countingDown
                }
                self.dispatch = dispatch
                DispatchQueue.main.asyncAfter(deadline: .now() + self.countDownDelay, execute: dispatch)
            }
            self.dispatch = dispatch
            DispatchQueue.main.async(execute: dispatch)
        }
    }
}
