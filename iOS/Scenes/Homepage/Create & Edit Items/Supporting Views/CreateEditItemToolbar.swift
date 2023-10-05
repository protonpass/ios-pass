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
import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

struct CreateEditItemToolbar: ToolbarContent {
    let saveButtonTitle: String
    let isSaveable: Bool
    let isSaving: Bool
    let itemContentType: ItemContentType
    let shouldUpgrade: Bool
    let onGoBack: () -> Void
    let onUpgrade: () -> Void
    let onScan: () -> Void
    let onSave: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: itemContentType.normMajor2Color,
                         backgroundColor: itemContentType.normMinor1Color,
                         action: onGoBack)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            if shouldUpgrade {
                UpgradeButton(backgroundColor: itemContentType.normMajor1Color,
                              action: onUpgrade)
            } else {
                if isSaving {
                    ProgressView()
                } else {
                    buttons
                }
            }
        }
    }
}

private extension CreateEditItemToolbar {
    var buttons: some View {
        HStack {
            if !ProcessInfo.processInfo.isiOSAppOnMac {
                switch itemContentType {
                case .creditCard, .note:
                    CircleButton(icon: PassIcon.scanner,
                                 iconColor: itemContentType.normMajor2Color,
                                 backgroundColor: itemContentType.normMinor1Color,
                                 action: onScan)
                default:
                    EmptyView()
                }
            }

            DisablableCapsuleTextButton(title: saveButtonTitle,
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: itemContentType.normMajor1Color,
                                        disableBackgroundColor: itemContentType.normMinor1Color,
                                        disabled: !isSaveable,
                                        action: onSave)
        }
    }
}
