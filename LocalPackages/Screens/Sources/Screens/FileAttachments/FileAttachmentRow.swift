//
// FileAttachmentRow.swift
// Proton Pass - Created on 03/12/2024.
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
import Entities
import ProtonCoreUIFoundations
import SwiftUI

public struct FileAttachmentRow: View {
    @State private var name: String
    @State private var showRenameAlert = false
    @State private var showFilePreview = false

    let uiModel: FileAttachmentUiModel
    let primaryTintColor: UIColor
    let secondaryTintColor: UIColor
    let onRename: (String) -> Void
    let onRetryUpload: () -> Void
    let onDelete: () -> Void

    public init(file: FileAttachment,
                primaryTintColor: UIColor,
                secondaryTintColor: UIColor,
                onRename: @escaping (String) -> Void,
                onRetryUpload: @escaping () -> Void,
                onDelete: @escaping () -> Void) {
        let uiModel = file.toUiModel()
        _name = .init(initialValue: uiModel.name)
        self.uiModel = uiModel
        self.primaryTintColor = primaryTintColor
        self.secondaryTintColor = secondaryTintColor
        self.onRename = onRename
        self.onRetryUpload = onRetryUpload
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack {
            Image(uiImage: uiModel.state.isError ?
                IconProvider.exclamationCircleFilled : uiModel.group.icon)
                .renderingMode(uiModel.state.isError ? .template : .original)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 20)
                .foregroundStyle(uiModel.state.isError ?
                    PassColor.passwordInteractionNormMajor2.toColor : Color.clear)

            VStack(alignment: .leading) {
                Text(uiModel.name)
                    .foregroundStyle(PassColor.textNorm.toColor)
                if let formattedSize = uiModel.formattedSize {
                    Text(verbatim: formattedSize)
                        .foregroundStyle(PassColor.textWeak.toColor)
                }
            }

            Spacer()

            switch uiModel.state {
            case .uploading:
                ProgressView()
            case .uploaded:
                Menu(content: {
                    LabelButton(title: "Rename",
                                icon: PassIcon.rename,
                                action: { showRenameAlert.toggle() })
                    Divider()
                    LabelButton(title: "Delete",
                                icon: IconProvider.trash,
                                action: onDelete)
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: PassColor.textWeak,
                                 backgroundColor: .clear)
                })
            case .error:
                RetryButton(tintColor: primaryTintColor, onRetry: onRetryUpload)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .buttonEmbeded {
            showFilePreview.toggle()
        }
        .alert("Rename file",
               isPresented: $showRenameAlert,
               actions: {
                   TextField(text: $name, label: { EmptyView() })
                   Button("Rename", action: { onRename(name) })
                       .disabled(name.isEmpty)
                   Button("Cancel", role: .cancel, action: { name = uiModel.name })
               })
        .fullScreenCover(isPresented: $showFilePreview) {
            if let url = uiModel.url {
                FileAttachmentPreview(url: url,
                                      primaryTintColor: primaryTintColor,
                                      secondaryTintColor: secondaryTintColor,
                                      onRename: { onRename($0) },
                                      onDelete: onDelete)
            }
        }
    }
}
