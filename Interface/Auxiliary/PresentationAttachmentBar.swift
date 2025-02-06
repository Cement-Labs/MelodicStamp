//
//  PresentationAttachmentBar.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/27.
//

import Luminare
import SwiftUI

struct PresentationAttachmentBar<Content, Attachment, Label>: View where Content: View, Attachment: View, Label: View {
    @Environment(\.luminareMinHeight) private var minHeight

    var edge: VerticalEdge
    var material: Material
    @ViewBuilder var content: () -> Content
    @ViewBuilder var attachment: () -> Attachment
    @ViewBuilder var label: () -> Label

    init(
        edge: VerticalEdge, material: Material = .regular,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder attachment: @escaping () -> Attachment,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.edge = edge
        self.material = material
        self.content = content
        self.attachment = attachment
        self.label = label
    }

    init(
        _ key: LocalizedStringKey,
        edge: VerticalEdge, material: Material = .regular,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder attachment: @escaping () -> Attachment
    ) where Label == Text {
        self.init(
            edge: edge, material: material,
            content: content, attachment: attachment
        ) {
            Text(key)
        }
    }

    init(
        edge: VerticalEdge, material: Material = .regular,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder label: @escaping () -> Label
    ) where Attachment == EmptyView {
        self.init(
            edge: edge, material: material,
            content: content
        ) {
            EmptyView()
        } label: {
            label()
        }
    }

    init(
        _ key: LocalizedStringKey,
        edge: VerticalEdge, material: Material = .regular,
        @ViewBuilder content: @escaping () -> Content
    ) where Attachment == EmptyView, Label == Text {
        self.init(
            key, edge: edge, material: material,
            content: content
        ) {
            EmptyView()
        }
    }

    var body: some View {
        content()
            .safeAreaInset(edge: edge) {
                HStack {
                    attachment()
                }
                .padding()
                .frame(height: minHeight + 2 * 8)
                .background(material)
                .clipShape(.capsule)
                .shadow(color: .black.opacity(0.1), radius: 15)
                .padding()
            }
    }
}

struct PresentationAttachmentBarModifier<Attachment, Label>: ViewModifier where Attachment: View, Label: View {
    var edge: VerticalEdge
    var material: Material = .regular
    @ViewBuilder var attachment: () -> Attachment
    @ViewBuilder var label: () -> Label

    init(
        edge: VerticalEdge, material: Material = .regular,
        @ViewBuilder attachment: @escaping () -> Attachment,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.edge = edge
        self.material = material
        self.attachment = attachment
        self.label = label
    }

    init(
        _ key: LocalizedStringKey,
        edge: VerticalEdge, material: Material = .regular,
        @ViewBuilder attachment: @escaping () -> Attachment
    ) where Label == Text {
        self.init(
            edge: edge, material: material,
            attachment: attachment
        ) {
            Text(key)
        }
    }

    init(
        edge: VerticalEdge, material: Material = .regular,
        @ViewBuilder label: @escaping () -> Label
    ) where Attachment == EmptyView {
        self.init(
            edge: edge, material: material
        ) {
            EmptyView()
        } label: {
            label()
        }
    }

    init(
        _ key: LocalizedStringKey,
        edge: VerticalEdge, material: Material = .regular
    ) where Attachment == EmptyView, Label == Text {
        self.init(
            key, edge: edge, material: material
        ) {
            EmptyView()
        }
    }

    func body(content: Content) -> some View {
        PresentationAttachmentBar(edge: edge, material: material) {
            content
        } attachment: {
            attachment()
        } label: {
            label()
        }
    }
}

#Preview {
    PresentationAttachmentBar("Attachment", edge: .top) {
        List {
            ForEach(0 ..< 100) { index in
                Text("\(index)")
                    .frame(maxWidth: .infinity)
                    .background(.red)
            }
        }
    } attachment: {
        Group {
            Button("Button") {}

            Spacer()

            Text("Text")
                .bold()

            Divider()

            Button("Button") {}
        }
        .buttonStyle(.alive)
    }
}
