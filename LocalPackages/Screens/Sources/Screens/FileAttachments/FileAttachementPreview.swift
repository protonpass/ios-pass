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
    @State private var name: String
    @State private var showRenameAlert = false
    @State private var showDeleteAlert = false
    let url: URL
    let primaryTintColor: UIColor
    let secondaryTintColor: UIColor
    let onSave: () -> Void
    let onShare: () -> Void
    let onRename: (String) -> Void
    let onDelete: () -> Void

    public init(url: URL,
                primaryTintColor: UIColor,
                secondaryTintColor: UIColor,
                onSave: @escaping () -> Void,
                onShare: @escaping () -> Void,
                onRename: @escaping (String) -> Void,
                onDelete: @escaping () -> Void) {
        self.url = url
        _name = .init(initialValue: url.lastPathComponent)
        self.primaryTintColor = primaryTintColor
        self.secondaryTintColor = secondaryTintColor
        self.onSave = onSave
        self.onShare = onShare
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
        .tint(primaryTintColor.toColor)
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.inline)
        .navigationStackEmbeded()
        .alert("Rename file",
               isPresented: $showRenameAlert,
               actions: {
                   TextField(text: $name, label: { EmptyView() })
                   Button("Rename", action: { onRename(name) })
                       .disabled(name.isEmpty)
                   Button("Cancel", role: .cancel, action: {})
               })
        .alert("Delete file?",
               isPresented: $showDeleteAlert,
               actions: {
                   Button("Delete", role: .destructive, action: onDelete)
                   Button("Cancel", role: .cancel, action: {})
               })
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

        ToolbarItem(placement: .principal) {
            Text(verbatim: url.lastPathComponent)
                .lineLimit(1)
                .foregroundStyle(PassColor.textNorm.toColor)
                .fontWeight(.medium)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu(content: {
                LabelButton(title: "Save",
                            icon: IconProvider.arrowDownCircle,
                            action: onSave)
                LabelButton(title: "Share",
                            icon: IconProvider.arrowUpFromSquare,
                            action: onShare)
                LabelButton(title: "Rename",
                            icon: PassIcon.rename,
                            action: { showRenameAlert.toggle() })
                Divider()
                LabelButton(title: "Delete",
                            icon: IconProvider.trash,
                            action: { showDeleteAlert.toggle() })
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
