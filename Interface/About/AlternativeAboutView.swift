//
//  AlternativeAboutView.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2025/1/22.
//

import SwiftUI

struct AlternativeAboutView: View {
    var body: some View {
        let version = Bundle.main[.appVersion]
        let build = Bundle.main[.appBuild]
        let combined = "\(version) \(build)"

        VStack {
            ContinuousRippleEffectView {
                Text(verbatim: "Melodic Stamp ")
                    .fontDesign(.serif)
                    .font(.title)
                    .bold()

                    +

                    Text(verbatim: "Preview\n")
                    .foregroundStyle(Color.white.opacity(0.45))
                    .fontDesign(.serif)
                    .font(.title)
                    .italic()

                    +

                    Text(verbatim: "\nOpen Sourced On GitHub\n")
                    .fontDesign(.monospaced)
                    .font(.subheadline)

                    +

                    Text(verbatim: "\(combined)\n\n")
                    .foregroundStyle(Color.white.opacity(0.45))
                    .fontDesign(.monospaced)
                    .font(.subheadline)

                    +

                    Text(verbatim: "Cement")
                    .font(.custom("SFPro-ExpandedLight", size: 12))

                    +

                    Text(verbatim: " Labs\n")
                    .font(.custom("SFPro-CompressedLight", size: 12))

                    +

                    Text(verbatim: "© 2024 → Future")
                    .foregroundStyle(Color.white.opacity(0.45))
                    .font(.custom("SFPro-CompressedLight", size: 12))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .multilineTextAlignment(.leading)
        .preferredColorScheme(.dark)
        .frame(width: 350, height: 150)
    }
}

#Preview {
    AlternativeAboutView()
}
