//
//  MetadataErrorView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/26.
//

import SwiftUI

struct MetadataErrorView: View {
    var error: MetadataError

    var body: some View {
        Group {
            switch error {
            case .invalidFormat:
                Text("Invalid format.")
            case .fileNotFound:
                Text("File not found.")
            case .readingPermissionNotGranted:
                Text("Reading permission not granted.")
            case .writingPermissionNotGranted:
                Text("Writing permission not granted.")
            }
        }
        .foregroundStyle(.red)
    }
}
