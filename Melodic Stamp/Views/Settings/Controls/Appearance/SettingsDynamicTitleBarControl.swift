//
//  SettingsDynamicTitleBarControl.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/12.
//

import Defaults
import SwiftUI

struct SettingsDynamicTitleBarControl: View {
    @Default(.isDynamicTitleBarEnabled) var isEnabled

    var body: some View {
        Toggle(isOn: $isEnabled) {
            Text("Dynamic title bar")
            Text("Displays the information of the currently playing track on the title bar.")
        }
    }
}
