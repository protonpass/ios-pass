//
// FileAttachmentViewerSection.swift
// Proton Pass - Created on 22/11/2024.
// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

import DesignSystem
import Factory
import Screens
import SwiftUI

struct FileAttachmentViewerSection: View {
    @State private var showPicker = false
    @State private var url: URL?
    @State private var dismissedFileAttachmentsBanner = false

    private let preferencesManager = resolve(\SharedToolingContainer.preferencesManager)

    var body: some View {
        Section(content: {
            StaticToggle(.verbatim("Dismissed file attachments banner"),
                         isOn: dismissedFileAttachmentsBanner,
                         action: {
                             Task {
                                 try? await preferencesManager
                                     .updateAppPreferences(\.dismissedFileAttachmentsBanner,
                                                           value: false)
                                 dismissedFileAttachmentsBanner = false
                             }
                         })
            Button(action: emptyTempDir) {
                Text(verbatim: "Empty temporary directory")
            }
            picker
            NavigationLink(destination: { StorageCounterPreview() },
                           label: { Text(verbatim: "Storage counter preview") })
        }, header: {
            Text(verbatim: "File attachments")
        })
        .task {
            dismissedFileAttachmentsBanner =
                preferencesManager.appPreferences.unwrapped().dismissedFileAttachmentsBanner
        }
    }
}

private extension FileAttachmentViewerSection {
    var picker: some View {
        Button(action: {
            showPicker.toggle()
        }, label: {
            Text(verbatim: "File attachment preview")
        })
        .fileImporter(isPresented: $showPicker,
                      allowedContentTypes: [.item],
                      allowsMultipleSelection: false,
                      onCompletion: { result in
                          if case let .success(urls) = result {
                              url = urls.first
                          }
                      })
        .fullScreenCover(isPresented: $url.mappedToBool()) {
            if let url {
                FileAttachmentPreview(mode: .pending(url),
                                      primaryTintColor: PassColor.interactionNormMajor1,
                                      secondaryTintColor: PassColor.interactionNormMinor2)
            }
        }
    }

    func emptyTempDir() {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory

        do {
            let tempFiles = try fileManager.contentsOfDirectory(at: tempDir,
                                                                includingPropertiesForKeys: nil,
                                                                options: [])
            for file in tempFiles {
                try fileManager.removeItem(at: file)
                print("Deleted \(file.path())")
            }
            print("Temporary directory emptied successfully.")
        } catch {
            print("Failed to empty temporary directory: \(error)")
        }
    }
}

private struct StorageCounterPreview: View {
    @State private var used: Float = 0
    private let total: Float = 10_000_000
    private let step: Float = 100_000

    var body: some View {
        VStack {
            StorageCounter(used: Int(used), total: Int(total), onUpgrade: {})
            Slider(value: $used, in: step...total, step: step)
        }
        .padding()
    }
}
