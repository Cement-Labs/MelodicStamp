//
//  FileImporters.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/30.
//

import SwiftUI

struct FileImporters: View {
    @Environment(FileManagerModel.self) private var fileManager

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var fileManager = fileManager

        Color.clear
            .fileImporter(
                isPresented: $fileManager.isFileOpenerPresented,
                allowedContentTypes: .init(allowedContentTypes)
            ) { result in
                switch result {
                case let .success(url):
                    fileManager.open(url: url, openWindow: openWindow)
                case .failure:
                    break
                }
            }

        Color.clear
            .fileImporter(
                isPresented: $fileManager.isFileAdderPresented,
                allowedContentTypes: .init(allowedContentTypes.union([.folder])),
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case let .success(urls):
                    fileManager.add(urls: urls, openWindow: openWindow)
                case .failure:
                    break
                }
            }
    }
}
