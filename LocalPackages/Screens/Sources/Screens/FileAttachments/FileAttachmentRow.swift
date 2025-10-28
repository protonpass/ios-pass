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

struct FileAttachmentRow: View {
    @State private var name: String

    private let mode: Mode
    private let uiModel: FileAttachmentUiModel
    private let primaryTintColor: Color
    private let secondaryTintColor: Color

    enum Mode: Sendable {
        case view(onOpen: @MainActor () -> Void,
                  onSave: @MainActor () -> Void,
                  onShare: @MainActor () -> Void)
        case edit(onOpen: @MainActor () -> Void,
                  onRename: @MainActor () -> Void,
                  onDelete: @MainActor () -> Void,
                  onRetryUpload: @MainActor () -> Void)
    }

    init(mode: Mode,
         uiModel: FileAttachmentUiModel,
         primaryTintColor: Color,
         secondaryTintColor: Color) {
        self.mode = mode
        _name = .init(initialValue: uiModel.name)
        self.uiModel = uiModel
        self.primaryTintColor = primaryTintColor
        self.secondaryTintColor = secondaryTintColor
    }

    var body: some View {
        VStack {
            content
            if case let .uploading(progress) = uiModel.state {
                ProgressView(value: progress)
            }
        }
        .animation(.default, value: uiModel)
    }
}

private extension FileAttachmentRow {
    @ViewBuilder
    var content: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            uiModel.group.icon
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 20)

            VStack(alignment: .leading) {
                Text(uiModel.name)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .foregroundStyle(PassColor.textNorm)
                if uiModel.state.isError {
                    HStack(spacing: 4) {
                        Text("Upload failed", bundle: .module)
                            .foregroundStyle(ColorProvider.NotificationError)
                        if case let .edit(_, _, _, onRetryUpload) = mode {
                            Text(verbatim: "•")
                                .foregroundStyle(PassColor.textWeak)
                            Text("Retry", bundle: .module)
                                .foregroundStyle(primaryTintColor)
                                .buttonEmbeded(action: onRetryUpload)
                        }
                    }
                    .font(.callout)
                } else if let formattedSize = uiModel.formattedSize {
                    Text(verbatim: formattedSize)
                        .font(.callout)
                        .foregroundStyle(PassColor.textWeak)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .buttonEmbeded {
                switch mode {
                case let .edit(onOpen, _, _, _), let .view(onOpen, _, _):
                    onOpen()
                }
            }

            switch uiModel.state {
            case .uploading:
                ProgressView()

            case .uploaded:
                Menu(content: {
                    switch mode {
                    case let .edit(onOpen, onRename, onDelete, _):
                        LabelButton(title: "Open",
                                    icon: IconProvider.eye.toImage,
                                    action: onOpen)
                        LabelButton(title: "Rename",
                                    icon: PassIcon.rename,
                                    action: onRename)
                        Divider()
                        LabelButton(title: "Delete",
                                    icon: IconProvider.trash,
                                    action: onDelete)

                    case let .view(onOpen, onSave, onShare):
                        LabelButton(title: "Open",
                                    icon: IconProvider.eye.toImage,
                                    action: onOpen)
                        LabelButton(title: "Save",
                                    icon: IconProvider.arrowDownCircle.toImage,
                                    action: onSave)

                        LabelButton(title: "Share",
                                    icon: IconProvider.arrowUpFromSquare.toImage,
                                    action: onShare)
                    }
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: PassColor.textWeak,
                                 backgroundColor: .clear)
                })

            case .error:
                if case let .edit(_, _, onDelete, onRetryUpload) = mode {
                    Menu(content: {
                        LabelButton(title: "Retry",
                                    icon: IconProvider.arrowRotateRight,
                                    action: onRetryUpload)
                        Divider()
                        LabelButton(title: "Delete",
                                    icon: IconProvider.trash,
                                    action: onDelete)
                    }, label: {
                        CircleButton(icon: IconProvider.threeDotsVertical,
                                     iconColor: PassColor.textWeak,
                                     backgroundColor: .clear)
                    })
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
