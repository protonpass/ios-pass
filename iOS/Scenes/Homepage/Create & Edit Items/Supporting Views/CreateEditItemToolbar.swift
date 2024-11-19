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

import DesignSystem
import Entities
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CreateEditItemToolbar: ToolbarContent {
    let saveButtonTitle: String
    let isSaveable: Bool
    let isSaving: Bool
    let fileAttachmentsEnabled: Bool
    let canScanDocuments: Bool
    let vault: Vault
    let canChangeVault: Bool
    let itemContentType: ItemContentType
    let shouldUpgrade: Bool
    let isPhone: Bool
    let onSelectVault: () -> Void
    let onGoBack: () -> Void
    let onUpgrade: () -> Void
    let onSelectFileAttachmentMethod: (FileAttachmentMethod) -> Void
    let onScan: () -> Void
    let onSave: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: itemContentType.normMajor2Color,
                         backgroundColor: itemContentType.normMinor1Color,
                         accessibilityLabel: "Close",
                         action: onGoBack)
                .animation(.default, value: isSaving)
                .disabled(isSaving)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Group {
                if shouldUpgrade {
                    UpgradeButton(backgroundColor: itemContentType.normMajor1Color,
                                  action: onUpgrade)
                        .disabled(isSaving)
                } else {
                    if isSaving {
                        ProgressView()
                    } else {
                        buttons
                    }
                }
            }
            .animation(.default, value: isSaving)
        }
    }
}

private extension CreateEditItemToolbar {
    var buttons: some View {
        HStack {
            if canChangeVault {
                vaultButton
            }

            if !ProcessInfo.processInfo.isiOSAppOnMac, canScanDocuments {
                switch itemContentType {
                case .creditCard, .note:
                    if fileAttachmentsEnabled {
                        FileAttachmentsButton(iconColor: itemContentType.normMajor2Color,
                                              backgroundColor: itemContentType.normMinor1Color,
                                              onSelect: onSelectFileAttachmentMethod)
                    }

                    CircleButton(icon: PassIcon.scanner,
                                 iconColor: itemContentType.normMajor2Color,
                                 backgroundColor: itemContentType.normMinor1Color,
                                 accessibilityLabel: "Scan \(itemContentType == .note ? "document" : "credit card")",
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

    var vaultButton: some View {
        HStack {
            Image(uiImage: vault.displayPreferences.icon.icon.bigImage)
                .resizable()
                .scaledToFit()
                .frame(width: 18)
            Text(vault.name)
            Image(systemName: "chevron.down")
                .resizable()
                .scaledToFit()
                .frame(width: 12)
        }
        .frame(height: 40)
        .foregroundStyle(vault.displayPreferences.color.color.color.toColor)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .background(vault.displayPreferences.color.color.color.toColor.opacity(0.16))
        .clipShape(Capsule())
        .if(isPhone) { view in
            view.frame(maxWidth: 150, alignment: .trailing)
        }
        .fixedSize(horizontal: false, vertical: false)
        .buttonEmbeded(action: onSelectVault)
    }
}
