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

private let kTitle = "File attachment viewer"

struct FileAttachmentViewerSection: View {
    var body: some View {
        NavigationLink(destination: { FilePickerOptions() },
                       label: { Text(verbatim: kTitle) })
    }
}

private struct FilePickerOptions: View {
    @State private var showViewer = false

    var body: some View {
        Form {
            Button(action: {
                showViewer.toggle()
            }, label: {
                Text(verbatim: "Pick a photo or video")
            })

            Button(action: {
                showViewer.toggle()
            }, label: {
                Text(verbatim: "Pick a file")
            })
        }
        .navigationTitle(Text(verbatim: kTitle))
        .fullScreenCover(isPresented: $showViewer) {
            FileAttachementViewer(primaryTintColor: PassColor.interactionNormMajor1,
                                  secondaryTintColor: PassColor.interactionNormMinor2,
                                  onSave: { print(#function) },
                                  onRename: { print(#function) },
                                  onDelete: { print(#function) })
        }
    }
}
