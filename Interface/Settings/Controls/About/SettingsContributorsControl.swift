//
//  SettingsContributorsControl.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2025/1/21.
//

import SFSafeSymbols
import SwiftUI

struct SettingsContributorsControl: View {
    var body: some View {
        List {
            contributor(
                avatarSource: .remote(.github.appending(component: "KrLite.png")),
                "KrLite",
                .init(
                    "Settings Control (Contributors): (Description) KrLite",
                    defaultValue: "Organization, design, and development."
                )
            )

            contributor(
                avatarSource: .remote(.github.appending(component: "Xinshao-air.png")),
                "芯梢",
                .init(
                    "Settings Control (Contributors): (Description) 芯梢",
                    defaultValue: "Design, test, and development support."
                )
            )
        }
    }

    @ViewBuilder private func contributor(
        avatarSource: ContributorAvatarSource,
        _ name: String,
        _ description: LocalizedStringResource?
    ) -> some View {
        HStack {
            ContributorAvatarView(source: avatarSource)

            VStack(alignment: .leading) {
                Text(verbatim: name)
                    .font(.headline)

                if let description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    Form {
        SettingsContributorsControl()
    }
    .formStyle(.grouped)
}
