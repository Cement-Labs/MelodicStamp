//
//  PlaylistMetadataView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/30.
//

import Luminare
import SwiftUI
import SwiftUIIntrospect

struct PlaylistMetadataView: View {
    @Environment(PlaylistModel.self) private var playlist

    @Environment(\.luminareAnimation) private var animation

    @FocusState private var isTitleFocused: Bool

    @State private var isTitleHovering: Bool = false
    @State private var isImagePickerPresented: Bool = false
    @State private var isDescriptionSheetPresented: Bool = false

    var body: some View {
        @Bindable var playlist = playlist

        HStack(spacing: 25) {
            Button {
                isImagePickerPresented = true
            } label: {
                artworkView()
                    .motionCard()
            }
            .buttonStyle(.alive)
            .shadow(color: .black.opacity(0.1), radius: 5)
            .fileImporter(
                isPresented: $isImagePickerPresented,
                allowedContentTypes: AttachedPicturesHandlerModel
                    .allowedContentTypes
            ) { result in
                switch result {
                case let .success(url):
                    guard url.startAccessingSecurityScopedResource() else { break }
                    defer { url.stopAccessingSecurityScopedResource() }

                    guard let image = NSImage(contentsOf: url) else { break }
                    playlist.segments.artwork.tiffRepresentation = image.tiffRepresentation
                    try? playlist.write(segments: [.artwork])
                case .failure:
                    break
                }
            }
            .animation(nil, value: isTitleHovering)
            .animation(nil, value: isTitleFocused)

            VStack(alignment: .leading) {
                titleView()
                    .font(.title)

                Button {
                    isDescriptionSheetPresented = true
                } label: {
                    descriptionView()
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.alive)
                .sheet(isPresented: $isDescriptionSheetPresented) {
                    try? playlist.write(segments: [.info])
                } content: {
                    // In order to make safe area work, we need a wrapper
                    ScrollView {
                        LuminareTextEditor(text: $playlist.segments.info.description)
                            .luminareBordered(false)
                            .luminareHasBackground(false)
                            .scrollDisabled(true)
                    }
                    .scrollContentBackground(.hidden)
                    .scrollClipDisabled()
                    .presentationAttachmentBar(edge: .bottom, attachment: sheetControls)
                    .presentationSizing(.fitted)
                    .frame(minWidth: 725, minHeight: 500, maxHeight: 1200)
                }
            }
        }
        .frame(height: 250)
        // Because this view will be used inside a `List`, so do not apply individual context menus to children views
        // This comprehensive context menu works best
        .expandContextMenuActivationArea()
        .contextMenu {
            Menu("Artwork") {
                artworkContextMenu()
            }

            Menu("Description") {
                descriptionContextMenu()
            }
        }
        .animation(animation, value: isTitleHovering)
        .animation(animation, value: isTitleFocused)
    }

    @ViewBuilder private func artworkView() -> some View {
        if let artwork = playlist.segments.artwork.image {
            MusicCover(images: [artwork], cornerRadius: 8)
        } else {
            MusicCover(cornerRadius: 8)
        }
    }

    @ViewBuilder private func titleView() -> some View {
        @Bindable var playlist = playlist

        HStack {
            TextField("Playlist Title", text: $playlist.segments.info.title)
                .bold()
                .textFieldStyle(.plain)
                .focused($isTitleFocused)
                .onSubmit {
                    isTitleFocused = false
                }

            if !isTitleFocused {
                HStack {
                    if isTitleHovering {
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([playlist.url])
                        } label: {
                            HStack {
                                if let creationDate = playlist.url[attribute: .creationDate] as? Date {
                                    let formattedCreationDate = creationDate.formatted(
                                        date: .complete,
                                        time: .standard
                                    )
                                    Text("Created at \(formattedCreationDate)")
                                        .font(.caption)
                                }

                                Image(systemSymbol: .folder)
                                    .font(.body)
                            }
                            .foregroundStyle(.placeholder)
                        }
                        .buttonStyle(.alive)
                    } else {
                        Text("\(playlist.count) Tracks")
                            .font(.body)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(.placeholder)
                .frame(minHeight: 20)
                .transition(.blurReplace)
            }
        }
        .onHover { hover in
            isTitleHovering = hover
        }
        .onChange(of: isTitleFocused) { _, newValue in
            guard !newValue else { return }
            try? playlist.write(segments: [.info])
        }
    }

    @ViewBuilder private func descriptionView() -> some View {
        let description = playlist.segments.info.description

        if !description.isEmpty {
            Text(description)
        } else {
            Image(systemSymbol: .ellipsisCircleFill)
                .imageScale(.large)
                .padding(.vertical, 2)
        }
    }

    @ViewBuilder private func artworkContextMenu() -> some View {
        Button("Remove") {
            playlist.segments.artwork.tiffRepresentation = nil
            try? playlist.write(segments: [.artwork])
        }
    }

    @ViewBuilder private func descriptionContextMenu() -> some View {
        Button("Edit") {
            isDescriptionSheetPresented = true
        }

        Button("Clear") {
            playlist.segments.info.description = ""
            try? playlist.write(segments: [.info])
        }
    }

    @ViewBuilder private func sheetControls() -> some View {
        Group {
            Text("Playlist Description")
                .bold()

            Spacer()

            Button {
                isDescriptionSheetPresented = false
            } label: {
                Text("Done")
            }
            .foregroundStyle(.tint)
        }
        .buttonStyle(.alive)
    }
}

#if DEBUG
    #Preview(traits: .modifier(PreviewEnvironmentsModifier())) {
        PlaylistMetadataView()
    }
#endif
