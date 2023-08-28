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
    let viewModel: BaseItemDetailViewModel

    private var itemContentType: ItemContentType {
        viewModel.itemContent.type
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: viewModel.isShownAsSheet ? IconProvider.chevronDown : IconProvider.chevronLeft,
                         iconColor: itemContentType.normMajor2Color,
                         backgroundColor: itemContentType.normMinor1Color,
                         action: viewModel.goBack)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            switch viewModel.itemContent.item.itemState {
            case .active:
                HStack {
                    CapsuleLabelButton(icon: IconProvider.pencil,
                                       title: "Edit".localized,
                                       titleColor: PassColor.textInvert,
                                       backgroundColor: itemContentType.normMajor1Color,
                                       action: viewModel.edit)

                    Menu(content: {
                        Button(action: viewModel.moveToAnotherVault,
                               label: { Label(title: { Text("Move to another vault") },
                                              icon: { Image(uiImage: IconProvider.folderArrowIn) }) })

                        Divider()

                        Button(role: .destructive,
                               action: viewModel.moveToTrash,
                               label: { Label(title: { Text("Move to trash") },
                                              icon: { Image(uiImage: IconProvider.trash) }) })
                    }, label: {
                        CircleButton(icon: IconProvider.threeDotsVertical,
                                     iconColor: itemContentType.normMajor2Color,
                                     backgroundColor: itemContentType.normMinor1Color)
                    })
                }

            case .trashed:
                Menu(content: {
                    Button(action: viewModel.restore,
                           label: { Label(title: { Text("Restore") },
                                          icon: { Image(uiImage: IconProvider.clockRotateLeft) }) })

                    Divider()

                    Button(role: .destructive,
                           action: { viewModel.showingDeleteAlert.toggle() },
                           label: { Label(title: { Text("Delete permanently") },
                                          icon: { Image(uiImage: IconProvider.trashCross) }) })
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: itemContentType.normMajor2Color,
                                 backgroundColor: itemContentType.normMinor1Color)
                })
            }
        }
    }
}
