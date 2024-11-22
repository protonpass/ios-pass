//
// FileAttachementPreview.swift
// Proton Pass - Created on 21/11/2024.
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

import DesignSystem
import ProtonCoreUIFoundations
import QuickLook
import SwiftUI

public struct FileAttachementPreview: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL
    let primaryTintColor: UIColor
    let secondaryTintColor: UIColor
    let onSave: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    public init(url: URL,
                primaryTintColor: UIColor,
                secondaryTintColor: UIColor,
                onSave: @escaping () -> Void,
                onRename: @escaping () -> Void,
                onDelete: @escaping () -> Void) {
        self.url = url
        self.primaryTintColor = primaryTintColor
        self.secondaryTintColor = secondaryTintColor
        self.onSave = onSave
        self.onRename = onRename
        self.onDelete = onDelete
    }

    public var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            QuickLookPreview(url: url)
                .padding(.top, 8)
                .ignoresSafeArea(edges: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .navigationStackEmbeded()
    }
}

private extension FileAttachementPreview {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: primaryTintColor,
                         backgroundColor: secondaryTintColor,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu(content: {
                LabelButton(title: "Save",
                            icon: IconProvider.arrowDownCircle,
                            action: onSave)
                LabelButton(title: "Rename",
                            icon: PassIcon.rename,
                            action: onRename)
                Divider()
                LabelButton(title: "Delete",
                            icon: IconProvider.trash,
                            action: onDelete)
            }, label: {
                CircleButton(icon: IconProvider.threeDotsVertical,
                             iconColor: primaryTintColor,
                             backgroundColor: secondaryTintColor)
            })
        }
    }
}

// MARK: - QuickLookPreview

private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        return previewController
    }

    func updateUIViewController(_ uiViewController: QLPreviewController,
                                context: Context) {
        // Not applicable
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: QuickLookPreview

        init(_ parent: QuickLookPreview) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController,
                               previewItemAt index: Int) -> any QLPreviewItem {
            parent.url as QLPreviewItem
        }
    }
}
