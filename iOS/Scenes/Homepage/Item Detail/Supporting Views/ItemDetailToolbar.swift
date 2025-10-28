//
// ItemDetailToolbar.swift
// Proton Pass - Created on 08/02/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

@MainActor
struct ItemDetailToolbar: ToolbarContent {
    @ObservedObject var viewModel: BaseItemDetailViewModel

    private var itemContentType: ItemContentType {
        viewModel.itemContent.type
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: viewModel.isShownAsSheet ? IconProvider.chevronDown : IconProvider.chevronLeft,
                         iconColor: itemContentType.normMajor2Color,
                         backgroundColor: itemContentType.normMinor1Color,
                         accessibilityLabel: "Close") {
                viewModel.goBack()
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            switch viewModel.itemContent.item.itemState {
            case .active:
                HStack {
                    if viewModel.isAllowedToEdit {
                        CapsuleLabelButton(icon: IconProvider.pencil,
                                           title: #localized("Edit"),
                                           titleColor: PassColor.textInvert,
                                           backgroundColor: itemContentType.normMajor1Color,
                                           isDisabled: !viewModel.isAllowedToEdit,
                                           action: { viewModel.edit() })
                    }

                    if viewModel.canShareItem {
                        ShareCounterButton(iconColor: itemContentType.normMajor2Color,
                                           backgroundColor: itemContentType.normMinor1Color,
                                           numberOfSharedMembers: viewModel.numberOfSharedMembers,
                                           action: {
                                               viewModel.share()
                                           })
                    }

                    Menu(content: {
                        if viewModel.itemIsLinkToVault, viewModel.isAllowedToEdit {
                            Label("Move to another vault", uiImage: IconProvider.folderArrowIn)
                                .buttonEmbeded {
                                    if viewModel.itemContent.shared {
                                        viewModel.showingVaultMoveAlert.toggle()
                                    } else {
                                        viewModel.moveToAnotherVault()
                                    }
                                }
                        }

                        Label(viewModel.itemContent.item.pinTitle,
                              uiImage: viewModel.itemContent.item.pinIcon)
                            .buttonEmbeded { viewModel.toggleItemPinning() }

                        if viewModel.itemContent.type == .note {
                            Label("Copy note content", image: IconProvider.note)
                                .buttonEmbeded { viewModel.copyNoteContent() }
                        }

                        if viewModel.isAllowedToClone {
                            Label("Clone", image: IconProvider.squares)
                                .buttonEmbeded { viewModel.clone() }
                        }

                        if viewModel.itemContent.type == .login {
                            let title: LocalizedStringKey = viewModel.isMonitored ?
                                "Exclude from monitoring" : "Include for monitoring"
                            let icon: UIImage = viewModel.isMonitored ? IconProvider.eyeSlash : IconProvider
                                .eye

                            Label(title, uiImage: icon)
                                .buttonEmbeded { viewModel.toggleMonitoring() }
                        }

                        Divider()

                        leaveButton

                        Label("Move to Trash", image: IconProvider.trash)
                            .buttonEmbeded(action: {
                                if viewModel.itemContent.isAlias {
                                    viewModel.showingTrashAliasAlert.toggle()
                                } else {
                                    viewModel.moveToTrash()
                                }
                            })
                            .hidden(!viewModel.isAllowedToEdit)
                    }, label: {
                        CircleButton(icon: IconProvider.threeDotsVertical,
                                     iconColor: itemContentType.normMajor2Color,
                                     backgroundColor: itemContentType.normMinor1Color,
                                     accessibilityLabel: "Item's action Menu")
                    })
                }

            case .trashed:
                Menu(content: {
                    Label("Restore", image: IconProvider.clockRotateLeft)
                        .buttonEmbeded { viewModel.restore() }
                        .hidden(!viewModel.isAllowedToEdit)

                    Divider()

                    Label("Delete permanently", image: IconProvider.trashCross)
                        .buttonEmbeded(role: .destructive,
                                       action: {
                                           if viewModel.itemContent.shared {
                                               viewModel.deleteShareItemAlert.toggle()
                                           } else {
                                               viewModel.itemToBeDeleted = viewModel.itemContent
                                           }
                                       })
                        .hidden(!viewModel.isAllowedToEdit)

                    leaveButton
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: itemContentType.normMajor2Color,
                                 backgroundColor: itemContentType.normMinor1Color)
                })
            }
        }
    }
}

private extension ItemDetailToolbar {
    @ViewBuilder
    var leaveButton: some View {
        if !viewModel.itemIsLinkToVault {
            Label("Leave", image: IconProvider.arrowOutFromRectangle)
                .buttonEmbeded {
                    viewModel.showingLeaveShareAlert.toggle()
                }
        }
    }
}

private struct ShareCounterButton: View {
    private let iconColor: Color
    private let backgroundColor: Color
    private let numberOfSharedMembers: Int
    private let action: () -> Void

    init(iconColor: Color,
         backgroundColor: Color,
         numberOfSharedMembers: Int,
         action: @escaping () -> Void) {
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.numberOfSharedMembers = numberOfSharedMembers
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(uiImage: IconProvider.usersPlus)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(iconColor)
                    .frame(maxHeight: 20)
                if numberOfSharedMembers > 0 {
                    Text(verbatim: "\(numberOfSharedMembers)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(backgroundColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(iconColor)
                        .cornerRadius(20)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(10)
            .background(backgroundColor)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
