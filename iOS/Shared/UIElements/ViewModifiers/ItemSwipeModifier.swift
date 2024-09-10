//
// ItemSwipeModifier.swift
// Proton Pass - Created on 28/03/2023.
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
import ProtonCoreUIFoundations
import SwiftUI

struct ItemSwipeModifier: ViewModifier {
    @Binding var itemToBePermanentlyDeleted: (any ItemTypeIdentifiable)?
    let item: any ItemTypeIdentifiable
    let isEditMode: Bool
    let isTrashed: Bool
    let isEditable: Bool
    let itemContextMenuHandler: ItemContextMenuHandler

    @State private var showingTrashAliasAlert = false

    /// Active item:  swipe right-to-left to move to trash
    /// Trashed item: swipe left-to-right to restore, swipe right-to-left to permanently delete
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                if isEditMode || !isEditable {
                    EmptyView()
                } else if isTrashed {
                    Button(action: {
                        itemContextMenuHandler.restore(item)
                    }, label: {
                        Label(title: {
                            Text("Restore")
                        }, icon: {
                            IconProvider.clockRotateLeft
                        })
                    })
                    .tint(PassColor.signalSuccess.toColor)
                }
            }
            .swipeActions(edge: .trailing) {
                if isEditMode || !isEditable {
                    EmptyView()
                } else if isTrashed {
                    Button(action: {
                        itemToBePermanentlyDeleted = item
                    }, label: {
                        Label(title: {
                            Text("Permanently delete")
                        }, icon: {
                            IconProvider.trashCross
                        })
                    })
                    .tint(PassColor.signalDanger.toColor)
                } else {
                    Button(action: {
                        if item.type == .alias {
                            showingTrashAliasAlert.toggle()
                        } else {
                            itemContextMenuHandler.trash(item)
                        }
                    }, label: {
                        Label(title: {
                            Text("Trash")
                        }, icon: {
                            IconProvider.trash
                        })
                    })
                    .tint(PassColor.signalDanger.toColor)
                }
            }
            .alert("Move to Trash", isPresented: $showingTrashAliasAlert) {
                if item.aliasEnabled {
                    Button("Disable instead") {
                        itemContextMenuHandler.disableAlias(item) /* viewModel.disableAlias()*/
                    }
                }
                Button("Move to Trash") { itemContextMenuHandler.trash(item) }
                Button("Cancel", role: .cancel) {}
            } message: {
                if item.aliasEnabled {
                    // swiftlint:disable:next line_length
                    Text("Aliases in Trash will continue forwarding emails. If you want to stop receiving emails on this address, disable it instead.")
                }
            }
    }
}
