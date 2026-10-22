//
// ExportDocumentView.swift
// Proton Pass - Created on 25/11/2024.
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
//

import SwiftUI

public struct ExportDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL

    public init(url: URL) {
        self.url = url
    }

    public var body: some View {
        if FileManager.default.fileExists(atPath: url.path()) {
            DocumentExportPicker(url: url)
        } else {
            Color.clear.onAppear { dismiss() }
        }
    }
}

private struct DocumentExportPicker: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forExporting: [url])
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController,
                                context: Context) {
        // Not applicable
    }
}
