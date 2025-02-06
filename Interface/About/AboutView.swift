//
//  AboutView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/24.
//

import Luminare
import SFSafeSymbols
import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) private var openURL

    @State private var isVersionCopied: Bool = false
    @State private var copyVersionDispatch: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 25) {
            VStack {
                appIconView()

                Text(appNameText)
                    .font(.title3)
                    .bold()

                versionView()
                    .font(.caption)
            }

            VStack {
                Button {
                    openURL(.organization)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(copyrightText)
                            .bold()

                        Image(.cementLabsBar)
                            .resizable()
                            .scaledToFill()
                            .padding(.vertical, 0.5)
                            .padding(.top, 1)
                            .padding(.bottom, -1)
                            .frame(height: .preferredPointSize(forTextStyle: .caption1))
                    }
                    .fixedSize()
                    .foregroundStyle(.tertiary)
                }

                Button {
                    openURL(.repository)
                } label: {
                    HStack {
                        Text("Open sourced on GitHub")
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            .font(.caption)
        }
        .buttonStyle(.alive)
        .padding(50)
        .padding(.horizontal)
        .ignoresSafeArea()
        .fixedSize()
        .navigationTitle(.init(verbatim: ""))
        .preferredColorScheme(.light)
    }

    private var appNameText: String {
        String(localized: .init("About: Application Name", defaultValue: "Melodic Stamp"))
    }

    private var copyrightText: String {
        String(localized: .init("About: Copyright", defaultValue: "© 2024→Future"))
    }

    @ViewBuilder private func appIconView() -> some View {
        ZStack {
            Image(.appIconBackground)
                .resizable()

            Image(.appIconForeground)
                .resizable()
                .motionCard(scale: 1.02, angle: .degrees(5))
        }
        .shadow(color: .black.opacity(0.1), radius: 10)
        .aspectRatio(contentMode: .fit)
        .frame(width: 100)
    }

    @ViewBuilder private func versionView() -> some View {
        let version = Bundle.main[.appVersion]
        let build = Bundle.main[.appBuild]
        let hasBuild = !build.isEmpty

        let combined: String = if hasBuild {
            String(localized: .init(
                "About: Version Template",
                defaultValue: "\(version) (\(build))"
            ))
        } else {
            version
        }

        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(combined, forType: .string)

            copyVersionDispatch?.cancel()
            withAnimation {
                isVersionCopied = true
            }

            let dispatch = DispatchWorkItem {
                withAnimation {
                    isVersionCopied = false
                }
            }
            copyVersionDispatch = dispatch
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: dispatch)
        } label: {
            Group {
                if isVersionCopied {
                    Text("Copied to clipboard!")
                } else {
                    Text(combined)
                        .monospaced()
                }
            }
//            .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    AboutView()
}
