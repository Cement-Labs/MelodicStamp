//
//  LoadingExcerptView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/2/3.
//

import SwiftUI

struct LoadingExcerptView<Content>: View where Content: View {
    var progress: CGFloat?
    @ViewBuilder var content: () -> Content

    init(
        progress: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.progress = progress
        self.content = content
    }

    init(
        _ key: LocalizedStringKey,
        progress: CGFloat? = nil
    ) where Content == Text {
        self.init(progress: progress) {
            Text(key)
        }
    }

    var body: some View {
        VStack {
            ProgressView(value: progress)

            content()
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingExcerptView {
        Text("Loading…")
    }

    LoadingExcerptView {
        Text("Loading…")
    }
    .progressViewStyle(.circular)
}

#Preview {
    @Previewable @State var value: CGFloat = 0.5

    LoadingExcerptView(progress: value) {
        Text("Loading…")
    }

    LoadingExcerptView(progress: value) {
        Text("Loading…")
    }
    .progressViewStyle(.circular)

    Slider(value: $value)
}
