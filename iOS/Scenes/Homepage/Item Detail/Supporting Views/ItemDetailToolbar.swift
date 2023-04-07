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

import Client
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct ItemDetailToolbar: ToolbarContent {
    @State private var isShowingAlert = false
    let itemContent: ItemContent
    let onGoBack: () -> Void
    let onEdit: () -> Void
    let onMoveToAnotherVault: () -> Void
    let onMoveToTrash: () -> Void
    let onRestore: () -> Void
    let onPermanentlyDelete: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: UIDevice.current.isIpad ? IconProvider.chevronLeft : IconProvider.chevronDown,
                         iconColor: itemContent.type.tintColor,
                         backgroundColor: itemContent.type.backgroundWeakColor,
                         action: onGoBack)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            switch itemContent.item.itemState {
            case .active:
                HStack {
                    CapsuleLabelButton(icon: IconProvider.pencil,
                                       title: "Edit",
                                       titleColor: PassColor.textInvert,
                                       backgroundColor: itemContent.type.tintColor,
                                       action: onEdit)

                    Menu(content: {
                        Button(action: onMoveToAnotherVault,
                               label: { Label(title: { Text("Move to another vault") },
                                              icon: { Image(uiImage: IconProvider.folderArrowIn) }) })

                        Divider()

                        Button(role: .destructive,
                               action: onMoveToTrash,
                               label: { Label(title: { Text("Move to trash") },
                                              icon: { Image(uiImage: IconProvider.trash) }) })
                    }, label: {
                        CircleButton(icon: IconProvider.threeDotsVertical,
                                     iconColor: itemContent.type.tintColor,
                                     backgroundColor: itemContent.type.backgroundWeakColor)
                    })
                }

            case .trashed:
                Menu(content: {
                    Button(action: onRestore,
                           label: { Label(title: { Text("Restore") },
                                          icon: { Image(uiImage: IconProvider.clockRotateLeft) }) })

                    Divider()

                    Button(role: .destructive,
                           action: { isShowingAlert.toggle() },
                           label: { Label(title: { Text("Permanently delete") },
                                          icon: { Image(uiImage: IconProvider.trash) }) })
                }, label: {
                    CapsuleIconButton(icon: IconProvider.threeDotsVertical,
                                      color: itemContent.type.tintColor,
                                      action: {})
                })
                .modifier(PermenentlyDeleteItemModifier(isShowingAlert: $isShowingAlert,
                                                        onDelete: onPermanentlyDelete))
            }
        }
    }
}
