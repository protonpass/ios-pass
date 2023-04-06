//
// CreateEditItemToolbar.swift
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

struct CreateEditItemToolbar: ToolbarContent {
    let saveButtonTitle: String
    let isSaveable: Bool
    let isSaving: Bool
    let itemContentType: ItemContentType
    let onGoBack: () -> Void
    let onSave: () async -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         color: itemContentType.tintColor,
                         action: onGoBack)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            if isSaving {
                ProgressView()
            } else {
                CapsuleTextButton(title: saveButtonTitle,
                                  titleColor: PassColor.textNorm,
                                  backgroundColor: itemContentType.tintColor,
                                  disabled: !isSaveable,
                                  action: { Task { await onSave() } })
                .font(.callout)
            }
        }
    }
}
