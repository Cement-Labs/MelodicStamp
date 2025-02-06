//
//  SettingsAsksForPlaylistInformationControl.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/30.
//

import Defaults
import SwiftUI

struct SettingsAsksForPlaylistInformationControl: View {
    @Default(.asksForPlaylistInformation) private var asksForPlaylistInformation

    var body: some View {
        Toggle("Asks for information when creating a new playlist", isOn: $asksForPlaylistInformation)
    }
}
