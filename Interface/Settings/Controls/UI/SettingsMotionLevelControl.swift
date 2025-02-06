//
//  SettingsMotionLevelControl.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/1.
//

import Defaults
import SwiftUI

struct SettingsMotionLevelControl: View {
    @Default(.motionLevel) private var motionLevel

    var body: some View {
        Picker("Motion level", selection: $motionLevel) {
            ForEach(Defaults.MotionLevel.allCases) { level in
                switch level {
                case .minimal:
                    Text("Minimal")
                case .reduced:
                    Text("Reduced")
                case .fancy:
                    Text("Fancy")
                }
            }
        }
    }
}
