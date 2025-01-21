//
//  SettingsFeedbackPage.swift
//  Melodic Stamp
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
            Text("""
            We developed this app in our spare time. We are looking forward to your participation in bringing \(Bundle.main.displayName) to perfection!
            """)
        }

        Section {
            Text("""
            Share your feedback on our GitHub page! Whether you find a bug or want to suggest a new feature, feel free to speak up. [Join our QQ Group Chat…](https://qm.qq.com/q/txBDJxnw4i)
            """)
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
