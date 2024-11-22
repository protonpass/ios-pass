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
import Screens
import SwiftUI

struct FileAttachmentViewerSection: View {
    @State private var showPicker = false
    @State private var url: URL?

    var body: some View {
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
                FileAttachementPreview(url: url,
                                       primaryTintColor: PassColor.interactionNormMajor1,
                                       secondaryTintColor: PassColor.interactionNormMinor2,
                                       onSave: {},
                                       onRename: {},
                                       onDelete: {})
            }
        }
    }
}
