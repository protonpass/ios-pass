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
    let itemContent: ItemContent
    let onGoBack: () -> Void
    let onEdit: () -> Void
    let onRevealMoreOptions: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: UIDevice.current.isIpad ? IconProvider.chevronLeft : IconProvider.chevronDown,
                         color: itemContent.tintColor,
                         action: onGoBack)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            switch itemContent.item.itemState {
            case .active:
                HStack(spacing: 0) {
                    CapsuleLabelButton(icon: IconProvider.pencil,
                                       title: "Edit",
                                       backgroundColor: itemContent.tintColor,
                                       disabled: false,
                                       action: onEdit)

                    CapsuleIconButton(icon: IconProvider.threeDotsVertical,
                                      color: itemContent.tintColor,
                                      action: onRevealMoreOptions)
                }

            case .trashed:
                EmptyView()
            }
        }
    }
}
