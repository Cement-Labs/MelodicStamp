//
//  SettingsFeedbackPage.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2025/1/21.
//

import SwiftUI

struct SettingsFeedbackPage: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        SettingsExcerptView(
            .feedback,
            descriptionKey: "Communicate directly with us."
        )

        Section {
            SettingsContributorsControl()
        } header: {
            Text("Contributors")
            Text(String(localized: .init(
                "Settings Page (Feedback): (Subtitle) Contributors",
                defaultValue: """
                We developed this app in our spare time. We are looking forward to your participation in bringing \(Bundle.main[localized: .displayName]) to perfection!
                """
            )))
        }

        Section {
            Text(String(localized: .init(
                "Settings Page (Feedback): Footer",
                defaultValue: """
                Share your feedback on our GitHub page! Whether you find a bug or want to suggest a new feature, feel free to speak up. [Join Us in QQ…](https://qm.qq.com/q/txBDJxnw4i)
                """
            )))
            .font(.caption)
            .foregroundStyle(.secondary)
        } header: {
            Text("Feedback")
        } footer: {
            Button("Submit an Issue") {
                openURL(.repository.appending(component: "issues"))
            }
        }
    }
}

#Preview {
    Form {
        SettingsFeedbackPage()
    }
    .formStyle(.grouped)
}
