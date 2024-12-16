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
                HStack(spacing: 0) {
                    Spacer()
                    if viewModel.canModify() {
                        CapsuleLabelButton(icon: IconProvider.pencil,
                                           title: #localized("Edit"),
                                           titleColor: PassColor.textInvert,
                                           backgroundColor: itemContentType.normMajor1Color,
                                           isDisabled: !viewModel.isAllowedToEdit,
                                           action: { viewModel.edit() })
                    }

                    Button {
                        viewModel.share()
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            HStack(spacing: 4) {
                                Image(uiImage: IconProvider.usersPlus)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(itemContentType.normMajor2Color.toColor)
                                    .frame(maxHeight: 20)
                                if viewModel.canShareItem, viewModel.numberOfSharedMembers > 0 {
                                    Text(verbatim: "\(viewModel.numberOfSharedMembers)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(itemContentType.normMinor1Color.toColor)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(itemContentType.normMajor2Color.toColor)
                                        .cornerRadius(20)
                                }
                            }
                            .padding(10)
                            .background(itemContentType.normMinor1Color.toColor)
                            .cornerRadius(20)
                            // swiftlint:disable:next todo
                            // TODO: Add discovering new feature
//                            if !viewModel.isFreeUser, viewModel.itemSharingEnabled, viewModel.canShareItem {
//                                Circle()
//                                    .fill(PassColor.signalInfo.toColor)
//                                    .frame(width: 12, height: 12)
//                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canShareItem)
                    .padding(.leading, 5)

                    Menu(content: {
                        if let vault = viewModel.vault?.vault, vault.isVaultRepresentation {
                            Label("Move to another vault", uiImage: IconProvider.folderArrowIn)
                                .buttonEmbeded { viewModel.moveToAnotherVault() }
                                .hidden(!viewModel.isAllowedToEdit)
                        }

                        Label(viewModel.itemContent.item.pinTitle,
                              uiImage: viewModel.itemContent.item.pinIcon)
                            .buttonEmbeded { viewModel.toggleItemPinning() }

                        if viewModel.itemContent.type == .note {
                            Label("Copy note content", image: IconProvider.note)
                                .buttonEmbeded { viewModel.copyNoteContent() }
                        }

                        if viewModel.itemContent.type != .alias,
                           let vault = viewModel.vault?.vault,
                           vault.isVaultRepresentation {
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

                        if let vault = viewModel.vault?.vault, !vault.isVaultRepresentation {
                            Label("Leave", image: IconProvider.arrowOutFromRectangle)
                                .buttonEmbeded {
                                    viewModel.showingLeaveShareAlert.toggle()
                                }
                        }

                        Label("Move to Trash", image: IconProvider.trash)
                            .buttonEmbeded(action: {
                                if viewModel.aliasSyncEnabled, viewModel.itemContent.isAlias {
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

                    Divider()

                    Label("Delete permanently", image: IconProvider.trashCross)
                        .buttonEmbeded(role: .destructive,
                                       action: { viewModel.itemToBeDeleted = viewModel.itemContent })
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: itemContentType.normMajor2Color,
                                 backgroundColor: itemContentType.normMinor1Color)
                })
                .disabled(!viewModel.isAllowedToEdit)
            }
        }
    }
}
