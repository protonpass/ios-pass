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
    @State private var showDeleteAlert = false
    @State private var showFilePreview = false

    private let mode: Mode
    private let itemContentType: ItemContentType
    private let uiModel: FileAttachmentUiModel
    private let primaryTintColor: UIColor
    private let secondaryTintColor: UIColor

    public enum Mode: Sendable {
        case view(onOpen: @MainActor () -> Void,
                  onSave: @MainActor () -> Void,
                  onShare: @MainActor () -> Void)
        case edit(onRename: @MainActor (String) -> Void,
                  onDelete: @MainActor () -> Void,
                  onRetryUpload: @MainActor () -> Void)
    }

    enum Style: Sendable {
        /// Used in both view and edit mode for all item types except note
        case borderless
        /// Used in view mode for note item type
        case bordered
        /// Used in edit mode for note item type
        case borderedWithBackground

        var backgroundColor: Color? {
            switch self {
            case .borderless:
                nil
            case .bordered:
                .clear
            case .borderedWithBackground:
                PassColor.inputBackgroundNorm.toColor
            }
        }
    }

    public init(mode: Mode,
                itemContentType: ItemContentType,
                uiModel: FileAttachmentUiModel,
                primaryTintColor: UIColor,
                secondaryTintColor: UIColor) {
        self.mode = mode
        self.itemContentType = itemContentType
        _name = .init(initialValue: uiModel.name)
        self.uiModel = uiModel
        self.primaryTintColor = primaryTintColor
        self.secondaryTintColor = secondaryTintColor
    }

    public var body: some View {
        VStack {
            content
            if case let .uploading(progress) = uiModel.state {
                ProgressView(value: progress)
            }
        }
        .animation(.default, value: uiModel)
        .alert("Rename file",
               isPresented: $showRenameAlert,
               actions: {
                   TextField(text: $name, label: { EmptyView() })
                   Button("Rename", action: { rename(name) })
                       .disabled(name.isEmpty)
                   Button("Cancel", role: .cancel, action: { name = uiModel.name })
               })
        .alert("Delete file?",
               isPresented: $showDeleteAlert,
               actions: {
                   Button("Delete", role: .destructive, action: delete)
                   Button("Cancel", role: .cancel, action: {})
               },
               message: { Text(verbatim: uiModel.name) })
        .fullScreenCover(isPresented: $showFilePreview) {
            if let url = uiModel.url {
                FileAttachmentPreview(mode: .pending(url),
                                      primaryTintColor: primaryTintColor,
                                      secondaryTintColor: secondaryTintColor)
            }
        }
    }
}

private extension FileAttachmentRow {
    @ViewBuilder
    var content: some View {
        let style = itemContentType.style(for: mode)
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
            case let .uploading(progress):
                ProgressView(value: progress)
                    .progressViewStyle(.circular)

            case .uploaded:
                Menu(content: {
                    switch mode {
                    case .edit:
                        LabelButton(title: "Rename",
                                    icon: PassIcon.rename,
                                    action: { showRenameAlert.toggle() })
                        Divider()
                        LabelButton(title: "Delete",
                                    icon: IconProvider.trash,
                                    action: { showDeleteAlert.toggle() })

                    case let .view(onOpen, onSave, onShare):
                        LabelButton(title: "Open",
                                    icon: IconProvider.eye,
                                    action: onOpen)
                        LabelButton(title: "Save",
                                    icon: IconProvider.arrowDownCircle,
                                    action: onSave)

                        LabelButton(title: "Share",
                                    icon: IconProvider.arrowUpFromSquare,
                                    action: onShare)
                    }
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: PassColor.textWeak,
                                 backgroundColor: .clear)
                })

            case .error:
                RetryButton(tintColor: primaryTintColor, onRetry: retryUpload)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .padding(style == .borderless ? 0 : DesignConstant.sectionPadding)
        .background(background(for: style))
        .buttonEmbeded {
            if uiModel.url != nil {
                showFilePreview.toggle()
            } else if case let .view(onOpen, _, _) = mode {
                onOpen()
            }
        }
    }
}

private extension FileAttachmentRow {
    func rename(_ newName: String) {
        if case let .edit(onRename, _, _) = mode {
            onRename(name)
        } else {
            assertionFailure("Should be in edit mode in order to rename file")
        }
    }

    func delete() {
        if case let .edit(_, onDelete, _) = mode {
            onDelete()
        } else {
            assertionFailure("Should be in edit mode in order to delete file")
        }
    }

    func retryUpload() {
        if case let .edit(_, _, onRetryUpload) = mode {
            onRetryUpload()
        } else {
            assertionFailure("Should be in edit mode in order to retry upload file")
        }
    }
}

private extension FileAttachmentRow {
    @ViewBuilder
    func background(for style: Style) -> some View {
        if let backgroundColor = style.backgroundColor {
            backgroundColor
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(PassColor.inputBorderNorm.toColor, lineWidth: 1))
        }
    }
}

private extension ItemContentType {
    func style(for mode: FileAttachmentRow.Mode) -> FileAttachmentRow.Style {
        if case .note = self {
            switch mode {
            case .view:
                .bordered
            case .edit:
                .borderedWithBackground
            }
        } else {
            .borderless
        }
    }
}
